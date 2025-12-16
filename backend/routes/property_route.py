from flask import Blueprint, json, request, jsonify
from services.ai_service import predict
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
    residence_type = request.form.get("residence_type")

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
        land_size=land_size,
        residence_type=residence_type
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
    id = data.get("id")  

    if property_id is None:
        return jsonify({"success": False, "message": "property_id is required"}), 400

    success, result = property_service.get_residence_details(property_id, id)

    if not success:
        return jsonify({"success": False, "message": result}), 404

    return jsonify({"success": True, "data": result}), 200

@property_bp.route("/residences/summaries", methods=["GET"])
def residences_summaries_route():
    state = request.args.get("state")
    city = request.args.get("city")
    district = request.args.get("district")
    user_id = request.args.get("id", type=int)
    page = request.args.get("page", type=int, default=1)

    summaries, length = property_service.get_residence_summaries(
        state=state, city=city, district=district, user_id=user_id, page=page
    )

    return jsonify({"summaries": summaries, "length": length}), 200


@property_bp.route("/residences/owned", methods=["GET"])
def get_owned_properties_route():
    
    owner_id = request.args.get("owner_id", type=int)

    if owner_id is None:
        return jsonify({
            "success": False,
            "message": "owner_id is required"
        }), 400

    data = property_service.get_owned_properties(owner_id)

    return jsonify({
        "success": True,
        "properties": data
    }), 200

@property_bp.route("/residences/rented/<int:tenant_id>", methods=["GET"])
def get_rented_properties_route(tenant_id):

    data = property_service.get_rented_properties(tenant_id)

    return jsonify({
        "success": True,
        "properties": data
    }), 200


@property_bp.route("/residence/update", methods=["POST"])
def update_residence_route():
    data = request.form  # you can use request.form directly, it behaves like a dict
    property_id = data.get("property_id")
    
    # If 'fields' is sent as JSON string
    fields_json = data.get("fields", "{}")
    try:
        fields = json.loads(fields_json)
    except json.JSONDecodeError:
        fields = {}

    file = request.files.get("thumbnail")  # optional

    success = property_service.update_residence(property_id, file, fields)

    if success:
        return jsonify({"success": True, "message": "Updated successfully"})
    return jsonify({"success": False, "message": "Property not found"}), 404

@property_bp.route("/gallery/add", methods=["POST"])
def add_gallery_image_route():
    property_id = request.form.get("property_id")
    if not property_id:
        return jsonify({"success": False, "message": "Property ID is required"}), 400

    gallery_image = request.files.get("gallery_image")

    if gallery_image is None:
        return jsonify({"success": False, "message": "No image uploaded"}), 400

    success = property_service.add_image(property_id, gallery_image)

    if success:
        return jsonify({"success": True, "message": "Image added successfully"})
    else:
        return jsonify({"success": False, "message": "Property not found"}), 404
    
@property_bp.route("/gallery", methods=["GET"])
def get_gallery_route():
    property_id = request.args.get("property_id")
    if not property_id:
        return jsonify({"success": False, "message": "Property ID is required"}), 400

    urls = property_service.get_gallery_images(property_id)
    
    if urls is None:
        return jsonify({"success": False, "message": "Property not found"}), 404

    return jsonify({"success": True, "images": urls})

@property_bp.route("/gallery/delete", methods=["POST"])
def delete_gallery_image():

    data = request.get_json()
    property_id = data.get("property_id")
    image_url = data.get("image_url")

    if property_id is None or image_url is None:
        return jsonify({"success": False, "message": "property_id and image_url are required"}), 400

    success = property_service.delete_image(property_id, image_url)

    if success:
        return jsonify({"success": True, "message": "Image deleted successfully"})
    else:
        return jsonify({"success": False, "message": "Image not found"})
    

@property_bp.route("/residence/predict/<int:property_id>", methods=["GET"])
def predict_property(property_id):
    success, result = predict(property_id)

    if not success:
        return jsonify({"error": result}), 404

    return jsonify({
        "property_id": property_id,
        "predicted_price": result
    }), 200

@property_bp.route("/residence/list", methods=["POST"])
def list_properties_route():
    data = request.get_json()
    property_id = data.get("property_id")
    price = data.get("price")
    deposit = data.get("deposit")

    if property_id is None or price is None:
        return jsonify({
            "success": False,
            "message": "property_id/price is required"
        }), 400

    success, data = property_service.list_property(property_id, price, deposit)

    if not success:
        return jsonify({
            "success": False,
            "message": data
        }), 400

    return jsonify({
        "success": True,
        "message": data
    }), 200

@property_bp.route("/get_lease/<int:property_id>/<int:active_only>", methods=["GET"])
def get_lease_route(property_id, active_only):
    """
    Call get_lease() with active_only flag.
    active_only: 1 = only active lease, 0 = all leases
    """
    active_only_flag = bool(active_only)

    success, result = property_service.get_lease(property_id, active_only_flag)

    if not success:
        return jsonify({
            "success": False,
            "message": result
        }), 400

    return jsonify({
        "success": True,
        "data": result
    }), 200

@property_bp.route("/get_tenant_records/<int:lease_id>", methods=["GET"])
def get_tenant_records_route(lease_id):
    """
    Call get_tenant_records() for a given lease.
    """
    success, result = property_service.get_tenant_records(lease_id)

    if not success:
        return jsonify({
            "success": False,
            "message": result
        }), 400

    return jsonify({
        "success": True,
        "data": result
    }), 200