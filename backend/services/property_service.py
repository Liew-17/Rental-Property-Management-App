from models.user import User
from models.property import Property
from models.property import PropertyImage
from models.property import Residence
from database import db
from services.image_service import upload_image
import uuid

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
    Returns (success: bool, message: str)
    """
    try:
        user = User.find_by_uid(uid)
        if not user:
            return False, "User not found", None, None
        
        # Create property
        new_property = Property.create(
            user_id=user.id,
            name=name,
            title=title,
            description=description,
            type="residence",
            thumbnail_url="",
            state=state,
            city=city,
            district=district,
            address=address,
            price=price,
            status="unlisted",
            rules=rules,
            features=features
        )

        if thumbnail is not None:
            folder_name = f"properties/{new_property.id}"
            # Extract file extension 
            ext = thumbnail.filename.rsplit('.', 1)[-1].lower()
            # Generate UUID filename
            filename = f"{uuid.uuid4()}.{ext}"

            thumbnail_url = upload_image(
                image=thumbnail,
                folder=folder_name,
                filename=filename
            )

        new_property.thumbnail_url=thumbnail_url

        # Create residence linked to the property
        Residence.create(
            property_id=new_property.id,
            num_bedrooms=num_bedrooms,
            num_bathrooms=num_bathrooms,
            land_size=land_size
        )

        return True, "Property and Residence created successfully", new_property.id, thumbnail_url

    except Exception as e:
        # Rollback in case of any DB error
        db.session.rollback()
        return False, str(e), None, None
