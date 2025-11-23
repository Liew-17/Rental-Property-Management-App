from models.user import User
from models.property import Property
from models.property import PropertyImage
from models.property import Residence
from database import db
from services.image_service import upload_image
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
    price=None,
    rules=None,
    features=None,
    num_bedrooms=None,
    num_bathrooms=None,
    land_size=None
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
            price=price,
            status="listed", # temp test. change to unlisted later
            rules=rules,
            features=features,
            num_bedrooms=num_bedrooms,
            num_bathrooms=num_bathrooms,
            land_size=land_size
        )

        # Handle thumbnail upload
        if thumbnail is not None:
            folder_name = f"properties/{new_residence.id}"
            ext = thumbnail.filename.rsplit('.', 1)[-1].lower()
            filename = f"{uuid.uuid4()}.{ext}"

            thumbnail_url = upload_image(
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
            "is_favourited": False  # TODO: implement user-specific favoriting logic
    })

    return summaries, length

def get_owned_properties(owner_id):
    pass



def get_residence_details(property_id, by_uid):
    """  Return residence's details information """
    prop = Property.find_by_id(property_id)

    if prop is None:
        return False, "Property does not exist"

    if not isinstance(prop, Residence):
        return False, "Property is not a Residence"
    
    owner: Optional["User"]
    owner = prop.user

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
        "status": prop.status,
        "rules": prop.rules,
        "features": prop.features,
        "user_id": owner.id if owner else None,
        "owner_name": owner.username if owner else None,
        "gallery": prop.images if prop.images else [],
        "is_favorited": False,  # replace with actual logic if needed
        "num_bedrooms": prop.num_bedrooms,
        "num_bathrooms": prop.num_bathrooms,
        "land_size": float(prop.land_size) if prop.land_size is not None else 0,
    }


    return True, data