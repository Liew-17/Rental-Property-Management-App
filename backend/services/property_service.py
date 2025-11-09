from flask import request
from models.user import User
from models.property import Property
from models.property import PropertyImage

def add_property(uid, name, title, description, type_, thumbnail_url):
    
    user = User.find_by_uid(uid)
    if not user:
        return None  # User not found

    new_property = Property.create(
        user_id=user.id,
        name=name,
        title=title,
        description=description,
        type=type_,
        thumbnail_url=thumbnail_url
    )

    return new_property