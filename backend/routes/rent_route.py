
from flask import Blueprint, jsonify, request
from services import rent_service

rent_bp = Blueprint("rent_bp", __name__, url_prefix="/rent")

@rent_bp.route("/request", methods=["POST"])
def upload_rent_request():
    try:
        user_id = request.form.get("user_id")
        property_id = request.form.get("property_id")
        start_date = request.form.get("start_date")
        duration = request.form.get("duration_months")
        files = request.files.getlist("files[]")

        # Validate required fields
        if not user_id or not property_id or not start_date or not duration:
            return jsonify({"success": False, "message": "Missing required fields"}), 400

        # Convert duration to int
        try:
            duration = int(duration)
        except ValueError:
            return jsonify({"success": False, "message": "Duration must be an integer"}), 400

        # Call the service
        success, message = rent_service.rent_property_request(user_id, property_id, start_date, duration, files)

        if success:
            return jsonify({"success": True, "message": message}), 200
        else:
            return jsonify({"success": False, "message": message}), 400

    except Exception as e:
        return jsonify({"success": False, "message": f"Internal server error: {str(e)}"}), 400
    

@rent_bp.route("/request/<int:request_id>", methods=["GET"])
def get_request_route(request_id):

    success, data = rent_service.get_request(request_id)

    if not success:
        return jsonify({
            "success": False,
            "message": data
        }), 404

    return jsonify({
        "success": True,
        "request": data
    }), 200