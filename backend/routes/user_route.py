from flask import Blueprint, request, jsonify
from models.user import User
from services.user_service import update_user_location

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

@user_bp.route("/get_user", methods=["GET"])
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
            "uid": user.uid,
            "username": user.username,
            "role": user.role,
            "state": user.state,
            "city": user.city,
            "district": user.district,
            "address": user.address
        }
    }), 200