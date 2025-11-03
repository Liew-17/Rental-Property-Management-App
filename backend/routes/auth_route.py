from flask import Blueprint, request, jsonify
from services import auth_service

auth_bp = Blueprint("auth_bp", __name__, url_prefix="/auth")

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    uid = data.get("uid")
    username = data.get("username")
    role = data.get("role", "user")

    if not uid or not username:
        return jsonify({"error": "uid and username are required"}), 400

    user = auth_service.register(uid, username, role)

    return jsonify({
        "uid": user.uid,
        "username": user.username,
        "role": user.role
    }), 200

@auth_bp.route("/check/<uid>")
def check_user(uid):
    if auth_service.user_exists(uid):
        return jsonify({"exists": True}), 200
    else:
        return jsonify({"exists": False}), 200