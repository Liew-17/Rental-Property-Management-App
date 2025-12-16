from datetime import datetime
from models.lease import Lease
from models.property import Property
from models.channel import Channel
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

def initiate_channel(property_id, tenant_id, type = 'query'):
    """
    Get an existing open channel for this property/tenant, or create a new one.
    Returns: (success, message, data_dict)
    """
    try:
        channel = Channel.query.filter_by(
            property_id=property_id, 
            tenant_id=tenant_id, 
            status='open',
            type= type
        ).first()

        created_new = False

        if not channel:
            prop = Property.find_by_id(property_id)
            if not prop:
                return False, "Property not found", None

            channel = Channel.create_channel(
                property_id=property_id,
                tenant_id=tenant_id,
                status='open'
            )
            created_new = True

        prop = channel.property
        owner = prop.user if prop else None
        tenant = channel.tenant

        data = {
            "id": channel.id,
            "status": channel.status,
            "type": channel.type,
            "property_id": prop.id if prop else None,
            "property_title": prop.title if prop else None,
            "property_name": prop.name if prop else None, 
            "owner_id": owner.id if owner else None,
            "owner_name": owner.username if owner else "Unknown",
            "owner_profile": owner.profile_pic_url if owner else None,
            "tenant_id": tenant.id if tenant else None,
            "tenant_name": tenant.username if tenant else "Unknown",
            "tenant_profile": tenant.profile_pic_url if tenant else None,
        }
        
        msg = "Channel created successfully" if created_new else "Channel retrieved successfully"
        return True, msg, data

    except Exception as e:
        db.session.rollback()
        return False, str(e), None

def get_user_channels(user_id):
    """
    Get all channels where the user is either the tenant or the owner.
    Includes the latest message for preview.
    """
    try:
        tenant_channels = Channel.query.filter_by(tenant_id=user_id ).all()

        owner_channels = Channel.query.join(Property).filter(Property.user_id == user_id).all()

        all_channels = []
        
        def process_channels(channel_list, role):
            for channel in channel_list:
                prop = channel.property
                
                if role == "tenant":
                    counterpart = prop.user
                else:
                    counterpart = channel.tenant


                last_msg = Message.query.filter_by(channel_id=channel.id)\
                                        .order_by(Message.sent_at.desc())\
                                        .first()

                all_channels.append({
                    "id": channel.id,
                    "type": channel.type, # 'query' or 'lease'
                    "status": channel.status,
                    "my_role": role, # 'tenant' or 'owner'
                    

                    "property_id": prop.id,
                    "property_title": prop.title if prop.title else prop.name,
                    "property_image": prop.thumbnail_url,

                    "other_user_id": counterpart.id,
                    "other_user_name": counterpart.username,
                    "other_user_profile": counterpart.profile_pic_url,

                    "last_message": last_msg.message_body if last_msg else "No messages yet",
                    "last_message_time": last_msg.sent_at.isoformat() if last_msg else None,
                    "last_message_type": last_msg.type if last_msg else "text"
                })

        process_channels(tenant_channels, "tenant")
        process_channels(owner_channels, "owner")

        # Sort by latest message time (descending)
        all_channels.sort(key=lambda x: x['last_message_time'] or "", reverse=True)

        return True, "Channels retrieved", all_channels

    except Exception as e:
        return False, str(e), []
    
def get_channel_by_lease_id(lease_id):
    """
    Retrieve the channel associated with a specific lease.
    """
    try:
        lease = Lease.find_by_id(lease_id)
        if not lease:
            return False, "Lease not found", None

        if not lease.channel_id:
            return False, "No chat channel associated with this lease", None

        channel = lease.channel
        print("hi")
        
        # Prepare data structure matching initiate_channel for frontend compatibility
        prop = channel.property
        owner = prop.user if prop else None
        tenant = channel.tenant

        data = {
            "id": channel.id,
            "status": channel.status,
            "type": channel.type,
            "property_id": prop.id if prop else None,
            "property_title": prop.title if prop else prop.name,
            "property_name": prop.name if prop else None, 
            "owner_id": owner.id if owner else None,
            "owner_name": owner.username if owner else "Unknown",
            "owner_profile": owner.profile_pic_url if owner else None,
            "tenant_id": tenant.id if tenant else None,
            "tenant_name": tenant.username if tenant else "Unknown",
            "tenant_profile": tenant.profile_pic_url if tenant else None,
        }

        return True, "Channel retrieved successfully", data

    except Exception as e:
        return False, str(e), None