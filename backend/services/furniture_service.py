import uuid
from datetime import datetime
from database import db
from models.furniture import Furniture, FurnitureLog
from services.file_service import upload_file

def create_furniture(property_id, name, status="Good", purchase_price=0.0, note=None, image=None):
    """
    Create a furniture item and optionally upload an image.
    Folder: properties/{prop_id}/furnitures/{fur_id}/img
    """
    try:
        # 1. Create DB Record first to get the ID
        new_item = Furniture.create(
            property_id=property_id,
            name=name,
            status=status,
            purchase_price=purchase_price,
            note=note
        )

        # 2. Handle Image Upload if provided
        if image:
            folder_name = f"properties/{property_id}/furnitures/{new_item.id}/img"
            ext = image.filename.rsplit('.', 1)[-1].lower()
            filename = f"{uuid.uuid4()}.{ext}"

            image_url = upload_file(image, folder_name, filename)
            
            # Update record with URL
            new_item.image_url = image_url
            db.session.commit()

        return True, "Furniture created successfully", new_item

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def update_furniture(furniture_id, data, image=None):
    """
    Update furniture details.
    """
    item = Furniture.find_by_id(furniture_id)
    if not item:
        return False, "Furniture not found"

    # Update fields if they exist in data
    if "name" in data: item.name = data["name"]
    if "status" in data: item.status = data["status"]
    if "purchase_price" in data: item.purchase_price = float(data["purchase_price"])
    if "note" in data: item.note = data["note"]

    # Handle Image Update
    if image:
        folder_name = f"properties/{item.property_id}/furnitures/{item.id}/img"
        ext = image.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{ext}"

        image_url = upload_file(image, folder_name, filename)
        item.image_url = image_url

    db.session.commit()
    return True, "Furniture updated successfully"

def delete_furniture(furniture_id):
    """
    Delete furniture and all associated logs (Cascade delete handled by DB model usually, 
    but we explicitly commit here).
    """
    item = Furniture.find_by_id(furniture_id)
    if not item:
        return False, "Furniture not found"

    db.session.delete(item)
    db.session.commit()
    return True, "Furniture deleted"

def get_furniture_by_property(property_id):
    items = Furniture.find_by_property_id(property_id)

    result = []

    for i in items:
        result.append({
            "id": i.id,
            "property_id": property_id,
            "name": i.name,
            "status": i.status,
            "purchase_price": i.purchase_price,
            "image_url": i.image_url,
            "note": i.note,
            "added_date": i.added_date.isoformat() if i.added_date else None
        })


    return result



def add_log(furniture_id, log_type, description, date=None, image=None):
    """
    Add a log and perform Smart Actions on furniture status.
    Folder: properties/{prop_id}/furnitures/{fur_id}/logs/{log_id}/img
    """
    item = Furniture.find_by_id(furniture_id)
    if not item:
        return False, "Furniture not found", None

    if item.status == "Disposed":
        return False, "Cannot add logs to a disposed item", None

    try:
        if log_type == "Repair":
            item.status = "Good"
        elif log_type == "Damage":
            item.status = "Damaged"
        elif log_type == "Dispose":
            item.status = "Disposed"

        log_date = datetime.strptime(date, '%Y-%m-%d') if date else datetime.now(datetime.timezone.utc)
        
        new_log = FurnitureLog.create(
            furniture_id=furniture_id,
            log_type=log_type,
            description=description,
            date=log_date
        )

        if image:
            folder_name = f"properties/{item.property_id}/furnitures/{item.id}/logs/{new_log.id}/img"
            ext = image.filename.rsplit('.', 1)[-1].lower()
            filename = f"{uuid.uuid4()}.{ext}"

            image_url = upload_file(image, folder_name, filename)
            new_log.image_url = image_url
            
        db.session.commit()
        return True, "Log added successfully", new_log

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def delete_log(log_id):
    log = FurnitureLog.query.get(log_id)
    if not log:
        return False, "Log not found"

    db.session.delete(log)
    db.session.commit()
    return True, "Log deleted"

def get_furniture_details(furniture_id):
    """
    Get a specific furniture item AND its logs.
    """

    item = Furniture.find_by_id(furniture_id)
    if not item:
        return None

    logs = FurnitureLog.find_by_furniture_id(furniture_id)

    log_list = []
    for l in logs:
        log_list.append({
            "id": l.id,
            "log_type": l.log_type,
            "description": l.description,
            "date": l.date.isoformat(),
            "image_url": l.image_url
        })

    data = {
        "id": item.id,
        "property_id": item.property_id,
        "name": item.name,
        "status": item.status,
        "purchase_price": item.purchase_price,
        "image_url": item.image_url,
        "note": item.note,
        "added_date": item.added_date.isoformat() if item.added_date else None,
        "logs": log_list  
    }

    return data