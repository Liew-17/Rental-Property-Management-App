from flask import Blueprint, send_from_directory, current_app

file_bp = Blueprint("media_bp", __name__, url_prefix="/uploads")

@file_bp.route("/<path:filename>")
def serve_file(filename):
    """
    Serve static files (images) from the uploads folder.
    Access via: http://<server_ip>:5000/uploads/properties/...
    """
    return send_from_directory(current_app.config["UPLOAD_FOLDER"], filename)