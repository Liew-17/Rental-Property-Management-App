from flask import Blueprint, request, jsonify
from services import property_service

property_bp = Blueprint("property_bp", __name__, url_prefix="/property")

@property_bp.route("/add_residence_property", methods=["POST"])
def add_residence_property_route():
    """ Add new residence property """
    
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

@property_bp.route("/residence/details", methods=["POST"])
def residence_details_post():
    """ Get residence details by property_id and uid """
    
    data = request.get_json()

    if not data:
        return jsonify({"success": False, "message": "No JSON data provided"}), 400

    property_id = data.get("property_id")
    uid = data.get("uid")  

    if property_id is None:
        return jsonify({"success": False, "message": "property_id is required"}), 400

    success, result = property_service.get_residence_details(property_id, uid)

    if not success:
        return jsonify({"success": False, "message": result}), 404

    return jsonify({"success": True, "data": result}), 200

@property_bp.route("/residences/summaries", methods=["POST"])
def residences_summaries_route():
    data = request.get_json() or {}

    state = data.get("state")
    city = data.get("city")
    district = data.get("district")
    user_id = data.get("id")
    page = data.get("page")

    summaries, length = property_service.get_residence_summaries(state=state, city=city, district=district, user_id=user_id, page=page)

    return jsonify({"summaries": summaries, "length": length}), 200
        