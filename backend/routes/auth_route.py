from flask import Blueprint, request, jsonify
from services import auth_service

auth_bp = Blueprint("auth_bp", __name__, url_prefix="/auth")

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    uid = data.get("uid")
    username = data.get("username")
    role = data.get("role", "tenant")
    email = data.get("email")


    if not uid or not username:
        return jsonify({"error": "uid and username are required"}), 400

    user = auth_service.register(uid, username, role, email)

    return jsonify({
        "uid": user.uid,
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "role": user.role
    }), 200

@auth_bp.route("/check/<uid>")
def check_user(uid):
    exists, user = auth_service.user_exists(uid) 

    if exists and user:
        return jsonify({
            "exists": True,
            "user": {
                "id": user.id,
                "uid": user.uid,
                "username": user.username,
                "email": user.email,
                "role": user.role,
                "state": user.state,
                "city": user.city,
                "district": user.district,
                "address": user.address,
                "profilePicUrl": user.profile_pic_url
            }
        }), 200
    else:
        return jsonify({"exists": False, "user": None}), 200