from datetime import datetime
from services.file_service import upload_file
from models.message import Message
import database as db

def create_image_message(sender_id: int, channel_id: int, image_file=None):
    """
    Upload an image and create a message with the image URL.
    
    Returns:
        success (bool), message (str), Message object or None
    """
    try:
        if not image_file:
            return False, "No image file provided", None

        ext = image_file.filename.rsplit('.', 1)[-1].lower()
        timestamp_str = datetime.utcnow().strftime("%Y%m%d%H%M%S%f")
        filename = f"channel{channel_id}_{timestamp_str}.{ext}"

        folder = f"messages/{channel_id}"

        image_url = upload_file(
            image=image_file,
            folder=folder,
            filename=filename
        )

        msg = Message.create_message(
            sender_id=sender_id,
            channel_id=channel_id,
            message_body=image_url,
            type="image"
        )

        return True, "Image message created successfully", msg

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def create_text_message(sender_id: int, channel_id: int, message_body: str):
    """
    Create a normal text message.
    """
    try:
        if not message_body or message_body.strip() == "":
            return False, "Message body cannot be empty", None

        msg = Message.create_message(
            sender_id=sender_id,
            channel_id=channel_id,
            message_body=message_body,
            type="text"
        )

        return True, "Text message created successfully", msg

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def get_messages(channel_id: int, limit=None, offset=None):
    """
    Retrieve messages for a specific channel with optional limit and offset.
    """
    try:
        messages = Message.get_messages_by_channel(
            channel_id=channel_id,
            limit=limit,
            offset=offset
        )
        return True, "Messages retrieved", messages
    except Exception as e:
        return False, str(e), None
