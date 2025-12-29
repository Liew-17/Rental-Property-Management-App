import uuid
from services.file_service import upload_file
from models.property import Property, Residence
from models.favourite import Favourite
from models.request import Request
from models.user import User
from database import db

def set_profile_pic(user_id, image_file):
    """
    Uploads a profile picture for the user and updates the profile_pic_url.
    Returns: (success: bool, message: str, url: str)
    """
    user = User.find_by_id(user_id)
    if not user:
        return False, "User not found", None

    if not image_file:
        return False, "No image file provided", None

    try:
        # Define folder structure: uploads/users/{user_id}/
        folder_name = f"users/{user.id}"
        
        # Generate unique filename
        ext = image_file.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{ext}"

        # Upload using the existing file service
        image_url = upload_file(
            image=image_file,
            folder=folder_name,
            filename=filename
        )

        # Update user record
        user.profile_pic_url = image_url
        db.session.commit()

        return True, "Profile picture updated successfully", image_url

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def update_user_location(id, state, city, district):
    user = User.find_by_id(id)

    if not user:
        return False, None

    user.state = state
    user.city = city
    user.district = district

    try:
        db.session.commit()
        return True, user
    except:
        db.session.rollback()
        return False, user
    
def update_user_role(user_id, new_role):

    user = User.find_by_id(user_id)
    if not user:
        return False, "User not found"
    
    user.role = new_role
    try:
        db.session.commit()
        return True, "Role updated successfully"
    except Exception as e:
        db.session.rollback()
        return False, str(e)
    
def get_user_rent_requests(user_id):
    """
    Get all rent requests made by a specific user (tenant).
    Returns a list of request dictionaries (without documents) but with embedded details.
    """
    try:
        # Fetch all requests for the tenant
        requests = Request.query.filter_by(tenant_id=user_id).all()
        
        if not requests:
            return []

        requests_data = []
        for req in requests:
            prop = req.property
            # Assuming 'user' is the relationship name for the property owner
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
                } if owner else None,

                # --- Embedded Tenant Details ---
                "tenant": {
                    "id": tenant.id if tenant else req.tenant_id,
                    "name": tenant.username if tenant else "Unknown Tenant",
                } if tenant else None,
            })

        return requests_data

    except Exception as e:
        print(f"Error in get_user_rent_requests: {e}")
        return []

def toggle_favourite(user_id, property_id):
    """
    If favorite exists, remove it. If not, create it.
    Returns: (bool) is_now_favourited
    """
    if Favourite.is_favourite(user_id, property_id):
        Favourite.delete_favourite(user_id, property_id)
        return False
    else:
        Favourite.create_favourite(user_id, property_id)
        return True

def get_user_favourites(user_id):
    """
    Get all properties favorited by a user.
    Returns a list of property summary dictionaries.
    """
    favourites = Favourite.get_favourites_by_user(user_id)
    
    results = []
    for fav in favourites:
        prop_id = fav.property_id # Access the related Property object
        prop = Property.find_by_id(prop_id)

        # only return listed properties
        if not prop or prop.status != 'listed':
            continue

        # Basic fields common to all properties
        data = {
            "id": prop.id,
            "name": prop.name,
            "title": prop.title,
            "thumbnail_url": prop.thumbnail_url,
            "price": prop.price,
            "state": prop.state,
            "city": prop.city,
            "district": prop.district,
            "is_favourited": True 
        }

        # Add Residence-specific fields if applicable
        if isinstance(prop, Residence):
            data.update({
                "num_bedrooms": prop.num_bedrooms,
                "num_bathrooms": prop.num_bathrooms,
                "land_size": prop.land_size,
                "residence_type": prop.residence_type
            })
            
        results.append(data)

    return results