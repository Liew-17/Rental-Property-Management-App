from flask import Blueprint, request, jsonify
from services.chat_service import create_image_message, create_text_message, get_messages

chat_bp = Blueprint("chat_bp", __name__, url_prefix="/chat")

@chat_bp.route("/send_image", methods=["POST"])
def send_image_message():
    try:
        # Required fields
        sender_id = request.form.get("sender_id", type=int)
        channel_id = request.form.get("channel_id", type=int)
        image_file = request.files.get("image_file")

        # Validate
        if sender_id is None or channel_id is None:
            return jsonify({"success": False, "message": "Missing required parameters"}), 400
        if image_file is None:
            return jsonify({"success": False, "message": "No image file provided"}), 400

        # Call the service
        success, message, msg_obj = create_image_message(
            sender_id=sender_id,
            channel_id=channel_id,
            image_file=image_file
        )

        if not success:
            return jsonify({"success": False, "message": message}), 500

        # Return the created message as JSON
        return jsonify({
            "success": True,
            "message": message,
            "data": {
                "id": msg_obj.id,
                "sender_id": msg_obj.sender_id,
                "channel_id": msg_obj.channel_id,
                "message_body": msg_obj.message_body,
                "type": msg_obj.type,
                "sent_at": msg_obj.sent_at.isoformat()
            }
        })

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@chat_bp.route("/send_text", methods=["POST"])
def send_text_message():
    data = request.get_json()

    sender_id = data.get("sender_id")
    channel_id = data.get("channel_id")
    message_body = data.get("message_body")

    if sender_id is None or channel_id is None or not message_body:
        return jsonify({"success": False, "message": "Missing required parameters"}), 400

    success, message, msg_obj = create_text_message(
        sender_id=sender_id,
        channel_id=channel_id,
        message_body=message_body
    )

    if not success:
        return jsonify({"success": False, "message": message}), 400

    return jsonify({
        "success": True,
        "message": message,
        "data": {
            "id": msg_obj.id,
            "sender_id": msg_obj.sender_id,
            "channel_id": msg_obj.channel_id,
            "message_body": msg_obj.message_body,
            "type": msg_obj.type,
            "sent_at": msg_obj.sent_at.isoformat()
        }
    }), 200


@chat_bp.route("/messages", methods=["GET"])
def api_get_messages():
    channel_id = request.args.get("channel_id", type=int)
    limit = request.args.get("limit", type=int)
    offset = request.args.get("offset", type=int)

    if channel_id is None:
        return jsonify({
            "success": False,
            "message": "channel_id is required"
        }), 400

    # Fetch messages
    success, message, messages = get_messages(
        channel_id=channel_id,
        limit=limit,
        offset=offset
    )

    if not success:
        return jsonify({"success": False, "message": message}), 400

    result = [
        {
            "id": m.id,
            "sender_id": m.sender_id,
            "channel_id": m.channel_id,
            "message_body": m.message_body,
            "type": m.type,
            "sent_at": m.sent_at.isoformat(),
        }
        for m in messages
    ]

    return jsonify({
        "success": True,
        "message": message,
        "messages": result
    }), 200

