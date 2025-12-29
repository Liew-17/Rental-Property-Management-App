from flask import Blueprint, request, jsonify
from models.user import User
from services.user_service import update_user_location
from services import user_service

user_bp = Blueprint("user", __name__, url_prefix="/user")

@user_bp.route("/update_location", methods=["PUT"])
def update_location():
    data = request.json

    id = data.get("id")
    state = data.get("state")
    city = data.get("city")
    district = data.get("district")

    # validate required fields
    if not id:
        return jsonify({"success": False, "message": "Missing fields"}), 400

    success, user = update_user_location(id, state, city, district)

    if success:
        return jsonify({
            "success": True,
            "user": {
                "state": user.state,
                "city": user.city,
                "district": user.district
            }
        }), 200
    else:
        return jsonify({"success": False, "message": "User not found or update failed"}), 400

@user_bp.route("/get_current_user", methods=["GET"])
def get_user():
    uid = request.args.get("uid")  # GET ?uid=xxx

    if not uid:
        return jsonify({"success": False, "message": "Missing uid"}), 400

    user = User.find_by_uid(uid)

    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404

    return jsonify({
        "success": True,
        "user": {
            "id": user.id,
            "username": user.username,
            "role": user.role,
            "state": user.state,
            "city": user.city,
            "district": user.district,
            "address": user.address,
            "profile_pic_url": user.profile_pic_url
        }
    }), 200

@user_bp.route("/get_user_info/<int:id>", methods=["GET"])
def get_user_info(id):
    # Query the database using filter_by
    user = User.query.filter_by(id=id).first()

    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404

    return jsonify({
        "success": True,
        "user": {
            "id": user.id,
            "username": user.username,
            "role": user.role,
            "state": user.state,
            "city": user.city,
            "district": user.district,
            "address": user.address,
            "profile_pic_url": user.profile_pic_url
        }
    }), 200

@user_bp.route("/update_role", methods=["PUT"])
def update_role():
    data = request.json
    user_id = data.get("user_id")
    role = data.get("role")

    if not user_id or not role:
        return jsonify({"success": False, "message": "Missing user_id or role"}), 400

    success, message = user_service.update_user_role(user_id, role)

    if success:
        return jsonify({"success": True, "message": message}), 200
    else:
        return jsonify({"success": False, "message": message}), 400

@user_bp.route("/upload_profile_pic", methods=["POST"])
def upload_profile_pic():

    user_id = request.form.get("user_id")
    file = request.files.get("profile_pic")

    if not user_id:
        return jsonify({"success": False, "message": "user_id is required"}), 400
    
    if not file:
        return jsonify({"success": False, "message": "No profile_pic file uploaded"}), 400

    success, message, url = user_service.set_profile_pic(user_id, file)

    if success:
        return jsonify({
            "success": True, 
            "message": message,
            "profile_pic_url": url
        }), 200
    else:
        return jsonify({"success": False, "message": message}), 400

@user_bp.route("/get_user_request/<int:user_id>", methods=["GET"])
def get_user_request(user_id):

    requests = user_service.get_user_rent_requests(user_id)

    return jsonify({
        "success": True,
        "requests": requests
    }), 200

@user_bp.route("/favourite/toggle", methods=["POST"])
def toggle_favourite_route():
    data = request.get_json()
    
    user_id = data.get("user_id")
    property_id = data.get("property_id")

    if not user_id or not property_id:
        return jsonify({"success": False, "message": "user_id and property_id are required"}), 400

    success = user_service.toggle_favourite(user_id, property_id)

    if success:
        return jsonify({
            "success": True, 
            "message": "Favorite toggled successfully"
        }), 200
    else:
        return jsonify({"success": False, "message": "Favourite toggled failed"}), 500

@user_bp.route("/favourites/<int:user_id>", methods=["GET"])
def get_favourites_route(user_id):
    if not user_id:
        return jsonify({"success": False, "message": "user_id is required"}), 400

    favourites = user_service.get_user_favourites(user_id)

    return jsonify({
        "success": True,
        "favourites": favourites
    }), 200