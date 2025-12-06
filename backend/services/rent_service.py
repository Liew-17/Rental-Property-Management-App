from datetime import datetime, timedelta
import uuid
from models.request import Request, RequestDocument
from database import db
from services.file_service import upload_file

def rent_property_request(
    property_id: int,
    tenant_id: int,
    start_date: str,
    duration_months: int,
    files: list
):
    try:
        # Parse start date and compute end date
        start_date_obj = datetime.fromisoformat(start_date).date()
        end_date = start_date_obj + timedelta(days=30 * duration_months)

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

        # Upload all files and save to DB
        for file in files:
            filename = file.filename
            ext = filename.rsplit(".", 1)[-1].lower()

            # Save file with unique UUID filename
            file_url = upload_file(
                image=file,
                folder=f"request/{new_request.id}",
                filename=f"{uuid.uuid4()}.{ext}"
            )

            # Save document record in DB
            RequestDocument.create(
                request_id=new_request.id,
                step_number=step_number,
                doc_type="Financial Proof",  # TODO: update dynamically if type is known
                file_url=file_url,
                original_filename=filename,
                file_format=ext,
                uploaded_by=uploaded_by,
                version=1
            )

        return True, "Request created successfully and files uploaded."

    except Exception as e:
        db.session.rollback()
        return False, f"Request failed: {str(e)}"
    
def get_request(request_id):
    """Get a request by ID, including all related documents, suitable for JSON."""  
    request = Request.get_request(request_id)

    if not request:
        return False, "Request not found"

    request_data = {
        "id": request.id,
        "property_id": request.property_id,
        "tenant_id": request.tenant_id,
        "start_date": request.start_date.isoformat(),
        "end_date": request.end_date.isoformat(),
        "current_step": request.current_step,
        "status": request.status,
        "documents": [
            {
                "id": doc.id,
                "step_number": doc.step_number,
                "doc_type": doc.doc_type,
                "original_filename": doc.original_filename,
                "file_url": doc.file_url,
                "file_format": doc.file_format,
                "uploaded_by": doc.uploaded_by,
            } for doc in request.documents
        ]
    }

    return True,request_data




