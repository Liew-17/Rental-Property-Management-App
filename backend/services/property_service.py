from models.favourite import Favourite
from services import user_service
from models.lease import Lease
from models.tenant_record import TenantRecord
from models.user import User
from models.property import Property
from models.property import PropertyImage
from models.property import Residence
from database import db
from services.file_service import upload_file
import uuid
from typing import Optional

def add_residence_property(      
    uid,
    name,
    title=None,
    description=None,
    thumbnail=None,
    state=None,
    city=None,
    district=None,
    address=None,
    rules=None,
    features=None,
    num_bedrooms=None,
    num_bathrooms=None,
    land_size=None,
    residence_type=None, 
):
    """
    Create a residence property.
    Returns (success: bool, message: str, property_id, thumbnail_url)
    """
    try:
        # Find user
        user = User.find_by_uid(uid)
        if not user:
            return False, "User not found", None, None

        if not name:
            return False, "Property name is required", None, None

        thumbnail_url = ""

        # Create residence
        new_residence = Residence.create_residence(
            user_id=user.id,
            name=name,
            title=title,
            description=description,
            thumbnail_url=thumbnail_url,
            state=state,
            city=city,
            district=district,
            address=address,
            status="unlisted", # temp test. change to unlisted later
            rules=rules,
            features=features,
            num_bedrooms=num_bedrooms,
            num_bathrooms=num_bathrooms,
            land_size=land_size,
            residence_type=residence_type
        )

        # Handle thumbnail upload
        if thumbnail is not None:
            folder_name = f"properties/{new_residence.id}"
            ext = thumbnail.filename.rsplit('.', 1)[-1].lower()
            filename = f"{uuid.uuid4()}.{ext}"

            thumbnail_url = upload_file(
                image=thumbnail,
                folder=folder_name,
                filename=filename
            )

            new_residence.thumbnail_url = thumbnail_url
            db.session.commit()  # update the thumbnail URL

        return True, "Property and Residence created successfully", new_residence.id, thumbnail_url

    except Exception as e:
        db.session.rollback()
        return False, str(e), None, None

def get_residence_summaries(*,state=None, city=None, district=None, user_id, page):
    props, length = Property.find_by_location(state=state,city=city,district=district,page=page)

    summaries = []

    user_fav_ids = []

    if user_id:
        user_fav = Favourite.get_favourites_by_user(user_id)
        user_fav_ids = [fav.property_id for fav in user_fav]

    for prop in props:
        if not isinstance(prop, Residence): #ensure it is residence
            continue

        summaries.append({
            "id": prop.id,
            "state": prop.state,
            "city": prop.city,
            "district": prop.district,
            "address": prop.address,  
            "name": prop.name,
            "title": prop.title,
            "num_bedrooms": prop.num_bedrooms,
            "num_bathrooms": prop.num_bathrooms,
            "land_size": prop.land_size,
            "price":prop.price,
            "thumbnail_url": prop.thumbnail_url,
            "is_favourited": prop.id in user_fav_ids,
            "residence_type": prop.residence_type,
    })

    return summaries, length

def get_owned_properties(owner_id):
    props = Property.find_by_user_id(owner_id)

    data = []

    for prop in props:
        if not isinstance(prop, Residence): 
            continue

        data.append({         
            "id": prop.id,
            "name": prop.name,
            "title": prop.title,
            "thumbnail_url": prop.thumbnail_url,
            "status": prop.status,
            "owner_id": owner_id,
            "state": prop.state,
            "city": prop.city,
            "district": prop.district,
        })

    return data

def get_rented_properties(tenant_id):
    user = User.query.get(tenant_id)

    data = []

    if not user:
        return data
    
    active_leases = [lease for lease in user.leases if lease.status == "active"]

    if not active_leases:
        return data

    for lease in active_leases:
        prop = lease.property
        if not prop:
            continue
        data.append({
            "id": prop.id,
            "name": prop.name,
            "title": prop.title,
            "thumbnail_url": prop.thumbnail_url,
            "status": prop.status,
            "state": prop.state,
            "city": prop.city,
            "district": prop.district,
        })

    return data

def get_residence_details(property_id, user_id):
    """  Return residence's details information """
    prop = Property.find_by_id(property_id)

    if prop is None:
        return False, "Property does not exist"

    if not isinstance(prop, Residence):
        return False, "Property is not a Residence"
    
    owner: Optional["User"]
    owner = prop.user
   
    if user_id:
        user_fav = Favourite.get_favourites_by_user(user_id)
        user_fav_ids = [fav.property_id for fav in user_fav]


    data = {
        "id": prop.id,
        "name": prop.name,
        "title": prop.title,
        "description": prop.description,
        "thumbnail_url": prop.thumbnail_url,
        "is_verified": prop.verified or False,
        "state": prop.state,
        "city": prop.city,
        "district": prop.district,
        "address": prop.address,
        "price": float(prop.price) if prop.price is not None else 0,
        "deposit": float(prop.deposit) if prop.deposit is not None else 0,
        "status": prop.status,
        "rules": prop.rules,
        "features": prop.features,
        "owner_id": owner.id if owner else None,
        "owner_name": owner.username if owner else None,
        "owner_pic_url": owner.profile_pic_url if owner else None,
        "gallery": [img.image_url for img in prop.images] if prop.images else [],
        "is_favourited": prop.id in user_fav_ids,
        "num_bedrooms": prop.num_bedrooms,
        "num_bathrooms": prop.num_bathrooms,
        "land_size": float(prop.land_size) if prop.land_size is not None else 0,
        "residence_type": prop.residence_type,
    }


    return True, data

def update_residence(property_id, thumbnail, args):
    updated = Property.update(property_id, **args)

    if not updated:
        return False  # property not found

    if thumbnail is not None:
        folder_name = f"properties/{updated.id}"
        ext = thumbnail.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{ext}"

        thumbnail_url = upload_file(
            image=thumbnail,
            folder=folder_name,
            filename=filename
        )

        updated.thumbnail_url = thumbnail_url
        db.session.commit()  # update the thumbnail URL

    return True
    
def add_image(property_id, gallery_image):
    prop = Property.find_by_id(property_id)

    if not prop:
        return False

    if gallery_image is not None:
        folder_name = f"properties/{property_id}/gallery"
        ext = gallery_image.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{ext}"

        image_url = upload_file(
            image=gallery_image,
            folder=folder_name,
            filename=filename
        )
    
    PropertyImage.add_image(property_id,image_url)
    return True

def get_gallery_images(property_id: int):
    prop = Property.find_by_id(property_id)
    if not prop:
        return None

    images = PropertyImage.get_images_for_property(property_id)
    return [img.image_url for img in images]

def delete_image(property_id, image_url):
    # add delete of file on server in future.
    return PropertyImage.delete_image_by_url(property_id=property_id,image_url=image_url)
    
def list_property(property_id, price, deposit):
    prop = Property.query.get(property_id)

    if not prop:
        return False, "Property not found"

    if prop.status != "unlisted":
        return False, "Property is already listed"

    if price is not None:
        if not isinstance(price, (int, float)):
            return False, "Invalid price value"
        elif price == 0:
            return False, "Price cannot be zero"
        
        prop.price = price
   

    if deposit is not None:
        if not isinstance(deposit, (int, float)):
            return False, "Invalid deposit value"
        
        prop.deposit = deposit
        
    prop.status = "listed"
    db.session.commit()

    return True, "Property updated successfully"

def get_lease(property_id, active_only=True):
    """
    Get lease(s) for a property.
    If active_only=True, only fetch the active lease.
    If active_only=False, fetch all leases (past and current).

    Returns (success: bool, data: list of dict)
    """
    if active_only:
        # Only active lease
        leases = Lease.query.filter_by(property_id=property_id, status="active").all()
    else:
        # Fetch all leases for the property, excluding 'terminated' status
        leases = Lease.query.filter(
            Lease.property_id == property_id, 
            Lease.status != "terminated"
        ).all()

    if not leases:
        return False, "Not lease found"

    data = []
    for lease in leases:
        if lease.contract_doc:
            contract_url = lease.contract_doc.file_url
            contract_name = lease.contract_doc.original_filename

        if lease.tenant:
            tenant_name = lease.tenant.username
            tenant_profile_pic_url = lease.tenant.profile_pic_url
            

        data.append({
            "id": lease.id,
            "start_date": lease.start_date.isoformat(),
            "end_date": lease.end_date.isoformat() if lease.end_date else None,
            "termination_date": lease.termination_date.isoformat() if lease.termination_date else None,
            "monthly_rent": lease.monthly_rent,
            "deposit_amount": lease.deposit_amount,
            "gracePeriodDays": lease.gracePeriodDays,
            "status": lease.status,
            "contract_url": contract_url,
            "contract_name": contract_name,
            "tenant_id": lease.tenant_id,
            "tenant_name": tenant_name,
            "tenant_profile_pic_url": tenant_profile_pic_url
        })

    return True, data

def get_tenant_records(lease_id):
    """
    Return only the tenant records for a lease.
    Returns (success: bool, data: list)
    """
    lease = Lease.query.filter_by(id=lease_id).first()

    if not lease:
        return False, "Lease not found"

    records = TenantRecord.query.filter_by(lease_id=lease_id)\
                                .order_by(TenantRecord.start_date)\
                                .all()

    data = []
    for r in records:
        data.append({
            "id": r.id,
            "month": r.month,
            "start_date": r.start_date.isoformat(),
            "due_date": r.due_date.isoformat(),
            "paid_at": r.paid_at.isoformat() if r.paid_at else None,
            "amount_paid": r.amount_paid,
            "status": r.status
        })

    return True, data