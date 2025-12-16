from flask import Blueprint, send_from_directory, current_app, request 
file_bp = Blueprint("media_bp", __name__, url_prefix="/uploads")

@file_bp.route("/<path:filename>")
def serve_file(filename):
    """
    Serve static files.
    - URL?download=true  -> Forces download (Attachment)
    - URL                -> Displays inline (Preview)
    """
    # Check for the query parameter
    should_download = request.args.get('download', 'false').lower() == 'true'

    return send_from_directory(
        current_app.config["UPLOAD_FOLDER"], 
        filename, 
        as_attachment=should_download  # Dynamic switching
    )