from flask import Blueprint, request, jsonify
from services import property_service

property_bp = Blueprint("property_bp", __name__, url_prefix="/property")

@property_bp.route("/add_property", methods=["POST"])
def add_property_route():
    data = request.get_json()

    uid = data.get("uid")
    name = data.get("name")
    title = data.get("title")
    description = data.get("description")
    type_ = data.get("type", "general")
    thumbnail_url = data.get("thumbnail_url")

    if not uid or not name:
        return jsonify({"error": "uid and username are required"}), 400

    new_property = property_service.add_property(uid, name, title, description, type_, thumbnail_url)

    if not new_property:
        return jsonify({"error": "User not found"}), 404

    return jsonify({
        "message": "Property created successfully",
        "property_id": new_property.id
    }), 201