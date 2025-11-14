from flask import Blueprint, request, jsonify
from services import property_service

property_bp = Blueprint("property_bp", __name__, url_prefix="/property")

@property_bp.route("/add_residence_property", methods=["POST"])
def add_residence_property_route():
    # Get text fields from form-data
    uid = request.form.get("uid")
    name = request.form.get("name")
    title = request.form.get("title")
    description = request.form.get("description")
    state = request.form.get("state")
    city = request.form.get("city")
    district = request.form.get("district")
    address = request.form.get("address")
    rules = request.form.get("rules")
    features = request.form.get("features")
    num_bedrooms = request.form.get("num_bedrooms")
    num_bathrooms = request.form.get("num_bathrooms")
    land_size = request.form.get("land_size")

    # Thumbnail image
    thumbnail = request.files.get("thumbnail")

    # Required fields check
    if not uid or not name:
        return jsonify({"error_message": "uid and name are required"}), 400

    # Call the service function
    success, message, property_id, thumbnail_url = property_service.add_residence_property(
        uid=uid,
        name=name,
        title=title,
        description=description,
        thumbnail=thumbnail,
        state=state,
        city=city,
        district=district,
        address=address,
        rules=rules,
        features=features,
        num_bedrooms=num_bedrooms,
        num_bathrooms=num_bathrooms,
        land_size=land_size
    )

    if not success:
        return jsonify({"error_message": message}), 400 

    return jsonify({"success_message": message, "property_id": property_id, "thumbnail_url": thumbnail_url}), 201


