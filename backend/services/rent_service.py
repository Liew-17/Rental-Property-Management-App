from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
import uuid
from models.channel import Channel
from models.tenant_record import TenantRecord
from services import tenant_record_service
from models.lease import Lease
from models.request import Request, RequestDocument
from database import db
from services.file_service import upload_file
from services.chat_service import initiate_channel
from extension import socketio

def check_existing_pending_request(user_id, property_id):
    """
    Check if a user already has a pending request for a specific property.
    """
    existing_request = Request.query.filter_by(
        tenant_id=user_id,
        property_id=property_id,
        status='pending'
    ).first()
    
    return existing_request is not None


def rent_property_request(
    property_id,
    tenant_id,
    start_date,
    duration_months,
    files
):
    try:
        # Parse start date and compute end date
        start_date_obj = datetime.fromisoformat(start_date).date()
        end_date = start_date_obj + relativedelta(months=duration_months)

        # Create the rental request
        new_request = Request.create(
            property_id=property_id,
            tenant_id=tenant_id,
            start_date=start_date_obj,
            end_date=end_date
        )

        step_number = 1
        uploaded_by = "tenant"

        if not files:
            return False, "No files provided for upload."

        for file in files:
            filename = file.filename
            ext = filename.rsplit(".", 1)[-1].lower()

            file_url = upload_file(
                image=file,
                folder=f"request/{new_request.id}",
                filename=f"{uuid.uuid4()}.{ext}"
            )

            RequestDocument.create(
                request_id=new_request.id,
                step_number=step_number,
                doc_type="Financial Proof",  
                file_url=file_url,
                original_filename=filename,
                file_format=ext,
                uploaded_by=uploaded_by,
            )

        return True, "Request created successfully and files uploaded."

    except Exception as e:
        db.session.rollback()
        return False, f"Request failed: {str(e)}"
    
def get_request(request_id):
    """Get a request by ID, including all related documents, suitable for JSON."""  
    try:
        request = Request.get_request(request_id)

        if not request:
            return False, "Request not found"

        prop = request.property
        owner = prop.user if prop else None 
        tenant = request.tenant

        request_data = {
            "id": request.id,
            "property_id": request.property_id,
            "tenant_id": request.tenant_id,
            "start_date": request.start_date.isoformat(),
            "end_date": request.end_date.isoformat(),
            "current_step": request.current_step,
            "status": request.status,
            "first_payment_due": request.first_payment_due.isoformat() if request.first_payment_due else None,
            "documents": [
                {
                    "id": doc.id,
                    "step_number": doc.step_number,
                    "doc_type": doc.doc_type,
                    "original_filename": doc.original_filename,
                    "file_url": doc.file_url,
                    "file_format": doc.file_format,
                    "uploaded_by": doc.uploaded_by,
                } for doc in request.documents if doc.is_active
            ],
            
            # --- Embedded Property Details ---
            "property": {
                "id": prop.id,
                "name": prop.name,
                "state": prop.state,
                "city": prop.city,
                "district": prop.district,
                "address": prop.address,
                "thumbnail_url": prop.thumbnail_url,
                "price": float(prop.price) if prop.price else 0.0,
                "deposit": float(prop.deposit) if prop.deposit else 0.0,
            } if prop else None,

            # --- Embedded Owner Details ---
            "owner": {
                "id": owner.id,
                "name": owner.username,
                "profile_pic_url": owner.profile_pic_url
            } if owner else None,

            # --- Embedded Tenant Details ---
            "tenant": {
                "id": tenant.id if tenant else request.tenant_id,
                "name": tenant.username if tenant else "Unknown Tenant",
                "profile_pic_url": tenant.profile_pic_url
            } if tenant else None,
        }

        return True, request_data

    except Exception as e:
        print(f"Error in get_request: {e}")
        return False, str(e)

def get_all_rent_requests(property_id):
    """Get all rent requests for a property (not including docs)."""
    try:
        # Fetch all requests for the property
        requests = Request.query.filter_by(property_id=property_id).all()
        
        if not requests:
            return []

        requests_data = []
        for req in requests:
            prop = req.property
            owner = prop.user if prop else None
            tenant = req.tenant
            
            requests_data.append({
                "id": req.id,
                "property_id": req.property_id,
                "tenant_id": req.tenant_id,
                "start_date": req.start_date.isoformat() if req.start_date else None,
                "end_date": req.end_date.isoformat() if req.end_date else None,
                "current_step": req.current_step,
                "status": req.status,
                "first_payment_due": req.first_payment_due.isoformat() if req.first_payment_due else None,
   
                "property": {
                    "id": prop.id,
                    "name": prop.name,
                    "state": prop.state,
                    "city": prop.city,
                    "district": prop.district,
                    "address": prop.address,
                    "thumbnail_url": prop.thumbnail_url,
                    "price": float(prop.price) if prop.price else 0.0,
                    "deposit": float(prop.deposit) if prop.deposit else 0.0,
                } if prop else None,

                "owner": {
                    "id": owner.id,
                    "name": owner.username,
                } if owner else None,

                "tenant": {
                    "id": tenant.id if tenant else req.tenant_id,
                    "name": tenant.username if tenant else "Unknown Tenant",
                    "profile_pic_url": tenant.profile_pic_url
                } if tenant else None,
            })

        return requests_data

    except Exception as e:
        print(f"Error in get_all_rent_requests: {e}")
        return []

def accept_rent_request(request_id):
    """
    Accept a rent request by its ID.
    Increments current_step by 1 for the accepted request,
    and sets all other requests for the same property to 'rejected'.
    Returns True if successful, False otherwise.
    """
    try:
        request_obj = Request.get_request(request_id)
        if not request_obj:
            return False  # Request not found

        if request_obj.status != "pending" or request_obj.current_step != 1:
            return False  # Only accept pending requests

        # Accept this request
        request_obj.current_step += 1
        request_obj.updated_at = datetime.now(timezone.utc)

        # Reject all other pending requests for the same property
        other_requests = Request.query.filter(
            Request.property_id == request_obj.property_id,
            Request.id != request_obj.id,
            Request.status == "pending"
        ).all()

        for other in other_requests:
            other.status = "rejected"
            other.updated_at = datetime.now(timezone.utc)
            for doc in other.documents:
                if doc.is_active:  
                    doc.is_active = False
                    doc.updated_at = datetime.now(timezone.utc)

            socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{other.tenant_id}")

        prop = request_obj.property
        prop.status = "renting"

        db.session.commit()

        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")

        return True

    except Exception as e:
        print(f"Exception in accept_rent_request: {e}")
        return False

def reject_rent_request(request_id):
    """
    Reject a rent request by its ID.
    Only pending requests can be rejected.
    Returns True if successful, False otherwise.
    """
    try:
        request_obj = Request.get_request(request_id)
        if not request_obj:
            return False  # Request not found

        if request_obj.status != "pending" or request_obj.current_step != 1:
            return False  # Only reject pending requests

        request_obj.status = "rejected"
        request_obj.updated_at = datetime.now(timezone.utc)
        for doc in request_obj.documents:
            if doc.is_active:  # only update active documents
                doc.is_active = False
                doc.updated_at = datetime.now(timezone.utc)

        db.session.commit()

        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")
        return True

    except Exception as e:
        print(f"Exception in reject_rent_request: {e}")
        return False

def terminate_rent_request(request_id):
    """
    Terminate a rent request by its ID.
    Sets status to 'terminated'.
    Returns True if successful, False otherwise.
    """
    try:

        request_obj = Request.get_request(request_id)
        if not request_obj:
            return False  # Request not found

        # Only allow terminating pending one
        if request_obj.status != "pending":
            return False

        request_obj.status = "terminated"
        request_obj.updated_at = datetime.now(timezone.utc)
        for doc in request_obj.documents:
            if doc.is_active:  
                doc.is_active = False
                doc.updated_at = datetime.now(timezone.utc)

        prop = request_obj.property
        prop.status = "listed"

        lease = request_obj.lease
        if lease:
            lease.status = "terminated"

        db.session.commit()
        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")
        return True

    except Exception as e:
        print(f"Exception in terminate_rent_request: {e}")
        return False

def upload_contract(request_id, user_id, contract_file,grace_period_days = None ,rental_price = None ,deposit_price = None):
    """
    Upload a contract file for a request.
    Workflow:
    1. Owner uploads the standard contract (step 2).
    2. Tenant uploads the signed contract (step 3).
    Only allows upload if the request status is 'pending' and the current_step
    matches the expected step for the user.
    Returns True if successful, False otherwise.
    """
    try:
        # Fetch the request
        request_obj = Request.get_request(request_id)

        if not request_obj:
            return False, "Request not found."
        
        if request_obj.status != "pending":
            return False, f"Cannot upload contract. Request status is '{request_obj.status}'."

        # Determine action based on user and current step
        if user_id != request_obj.tenant_id:
            if request_obj.current_step != 2:
                return False, "Cannot upload contract. Request is not at the correct step."
            step_number = 2
            uploaded_by = "owner"
            doc_type = "contract"

            # lease creation occur during step 2
            if(request_obj.lease==None):         
                try:
                    lease = Lease.create(
                        property_id=request_obj.property_id,
                        tenant_id=request_obj.tenant_id,
                        start_date=request_obj.start_date,
                        end_date=request_obj.end_date,
                        request_id=request_obj.id,
                        contract_document_id=None,
                        monthly_rent=rental_price,
                        deposit_amount=deposit_price,
                        gracePeriodDays=grace_period_days,
                        status="pending"
                    )
                    db.session.commit()
            
                except Exception as e:
                    print("Lease creation failed:", e)    
        else:
            if request_obj.current_step != 3:
                return False, "Cannot upload signed contract. Request is not at the correct step."
            step_number = 3
            uploaded_by = "tenant"
            doc_type = "signed_contract"
        
        
        # Save file with unique UUID filename
        filename = contract_file.filename
        ext = filename.rsplit(".", 1)[-1].lower()

        file_url = upload_file(
            image=contract_file,
            folder=f"request/{request_obj.id}",
            filename=f"{uuid.uuid4()}.{ext}"
        )

        # Save document record in DB
        RequestDocument.create(
            request_id=request_obj.id,
            step_number=step_number,
            doc_type=doc_type,
            file_url=file_url,
            original_filename=filename,
            file_format=ext,
            uploaded_by=uploaded_by,
        )

        request_obj.current_step += 1
        request_obj.updated_at = datetime.now(timezone.utc)
        db.session.commit()

        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
        socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")

        return True, "Contract uploaded successfully."

    except Exception as e:
        db.session.rollback()
        return False, f"Upload failed: {str(e)}"

def handle_contract_approval(request_id, is_approved, grace_period_days=None):
    """
    Handle approval/rejection of contract.
    If approved:
        - Move step forward (current_step + 1)
        - Set first_payment_due = today + grace_period_days
    If rejected:
        - Move workflow back to step 2
        - Inactivate step 2 & 3 documents (contract files)
    Returns (True, "message") or (False, "error").
    """
    try:
        request_obj = Request.get_request(request_id)
        if not request_obj:
            return False, "Request not found."

        if request_obj.status != "pending":
            return False, f"Request status '{request_obj.status}' does not allow contract approval."
        
        if request_obj.current_step != 4:
            return False, "Cannot approve contract. Request is not at the correct step."

        if is_approved:
            if grace_period_days is None:
                return False, "Grace period must be provided when approving contract."

            # Set due date for first payment
            request_obj.first_payment_due = datetime.now(timezone.utc) + timedelta(days=grace_period_days)

            # Move to next step
            request_obj.current_step += 1
            request_obj.updated_at = datetime.now(timezone.utc)

            db.session.commit()
            socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
            socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")
            return True, "Contract approved successfully."
        else:
            # Roll back workflow to contract upload step
            request_obj.current_step = 2
            request_obj.updated_at = datetime.now(timezone.utc)

            # Deactivate contract & signed contract docs
            for doc in request_obj.documents:
                if doc.step_number in [2, 3]:
                    doc.is_active = False

            db.session.commit()
            socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
            socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")
            return True, "Contract rejected. Workflow rolled back to step 2."

    except Exception as e:
        db.session.rollback()
        return False, f"Contract handling failed: {str(e)}"

def get_rent_amounts(request_id):
    """
    Get rent price and deposit directly from the linked property.
    Returns dict {price, deposit} or None if request not found.
    """

    request_obj = Request.query.get(request_id)
    if not request_obj:
        return None

    lease_obj = request_obj.lease
    if not lease_obj:
        return None


    return {
        "price": lease_obj.monthly_rent,
        "deposit": lease_obj.deposit_amount
    }


def pay_first_payment(request_id):
    """
    Process the first payment and mark the lease as active.
    Generate the first payment receipt （tenant record）.
    Returns True if successful, False otherwise.
    """
    request_obj = Request.query.get(request_id)
    if not request_obj:
        return False, "Request not found."

    lease_obj = request_obj.lease
    if not lease_obj:
        return False,   "Lease not found."
    
    if request_obj.current_step != 5:
        return False, "Cannot Process Payment. Request is not at the correct step."
    
    first_record = tenant_record_service.generate_next_tenant_record(lease_obj.id, True)
    
    if not first_record:
        return False, "Failed to generate tenant record."

    first_record.amount_paid = lease_obj.monthly_rent
    first_record.paid_at = datetime.now(timezone.utc)
    first_record.status = "paid"

    prop = request_obj.property
    prop.status = "rented"
    
    # Activate lease
    lease_obj.status = "active"
    step_3_doc = RequestDocument.query.filter_by(
        request_id=lease_obj.request_id,
        step_number=3,
        doc_type="signed_contract",
        is_active=True
    ).first()

    if step_3_doc:
        lease_obj.contract_document_id = step_3_doc.id

    success, msg, data = initiate_channel(request_obj.property_id, request_obj.tenant_id)

    if success and data:
        # Retrieve the real channel object from the DB 
        channel = Channel.query.get(data["id"])

        if channel:
            lease_obj.channel_id = channel.id
            channel.type = "lease"
            db.session.commit()  
    else:
        # Handle error case
        print(f"Failed to initiate channel: {msg}")

    request_obj.current_step += 1
    request_obj.status = "completed"
    request_obj.updated_at = datetime.now(timezone.utc)
    

    db.session.commit()

    socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.tenant_id}")
    socketio.emit('refresh_request', {"request_id": request_id}, room=f"user_{request_obj.property.user_id}")

    return True, "Payment completed and lease activated."    

def pay_rent(tenant_record_id, total_amount):
    """
    Process a rent payment for a specific tenant record.
    Updates the record status to 'paid' and records the amount/time.
    """
    try:
        record = TenantRecord.query.get(tenant_record_id)
        
        if not record:
            return False, "Tenant record not found."

        if record.status == 'paid':
            return False, "This rent record is already paid."

        record.amount_paid = total_amount
        record.paid_at = datetime.now(timezone.utc)
        record.status = 'paid'

        db.session.commit()
        
        return True, "Rent payment processed successfully."

    except Exception as e:
        db.session.rollback()
        return False, f"Payment failed: {str(e)}"



