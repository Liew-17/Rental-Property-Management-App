from flask import Blueprint, request, jsonify, json
from services import furniture_service

furniture_bp = Blueprint("furniture_bp", __name__, url_prefix="/furniture")


@furniture_bp.route("/create", methods=["POST"])
def create_furniture_route():

    property_id = request.form.get("property_id")
    name = request.form.get("name")
    status = request.form.get("status", "Good")
    purchase_price = request.form.get("purchase_price", 0.0)
    note = request.form.get("note")
    image = request.files.get("image") 

    if not property_id or not name:
        return jsonify({"success": False, "message": "property_id and name are required"}), 400

    success, msg, item = furniture_service.create_furniture(
        property_id=property_id,
        name=name,
        status=status,
        purchase_price=float(purchase_price),
        note=note,
        image=image
    )

    if not success:
        return jsonify({"success": False, "message": msg}), 400

    return jsonify({"success": True, "message": msg, "id": item.id}), 201

@furniture_bp.route("/update", methods=["POST"])
def update_furniture_route():
    furniture_id = request.form.get("furniture_id")
    image = request.files.get("image")
    
    data = {}
    if "name" in request.form: data["name"] = request.form.get("name")
    if "status" in request.form: data["status"] = request.form.get("status")
    if "purchase_price" in request.form: data["purchase_price"] = request.form.get("purchase_price")
    if "note" in request.form: data["note"] = request.form.get("note")

    if not furniture_id:
        return jsonify({"success": False, "message": "furniture_id is required"}), 400

    success, msg = furniture_service.update_furniture(furniture_id, data, image)

    if not success:
        return jsonify({"success": False, "message": msg}), 400
    
    return jsonify({"success": True, "message": msg}), 200

@furniture_bp.route("/delete", methods=["POST"])
def delete_furniture_route():
    data = request.get_json()
    furniture_id = data.get("furniture_id")

    if not furniture_id:
        return jsonify({"success": False, "message": "furniture_id is required"}), 400

    success, msg = furniture_service.delete_furniture(furniture_id)
    
    if not success:
        return jsonify({"success": False, "message": msg}), 400

    return jsonify({"success": True, "message": msg}), 200

@furniture_bp.route("/list/<int:property_id>", methods=["GET"])
def list_furniture_route(property_id):
    result = furniture_service.get_furniture_by_property(property_id)
     
    return jsonify({"success": True, "data": result}), 200


@furniture_bp.route("/log/add", methods=["POST"])
def add_log_route():
    furniture_id = request.form.get("furniture_id")
    log_type = request.form.get("log_type") 
    description = request.form.get("description")
    date = request.form.get("date")
    image = request.files.get("image")

    if not furniture_id or not log_type or not description:
        return jsonify({"success": False, "message": "furniture_id, log_type and description are required"}), 400

    success, msg, log = furniture_service.add_log(
        furniture_id=furniture_id,
        log_type=log_type,
        description=description,
        date=date,
        image=image
    )

    if not success:
        return jsonify({"success": False, "message": msg}), 400

    return jsonify({"success": True, "message": msg, "log_id": log.id}), 201

@furniture_bp.route("/log/delete", methods=["POST"])
def delete_log_route():
    data = request.get_json()
    log_id = data.get("log_id")

    if not log_id:
        return jsonify({"success": False, "message": "log_id is required"}), 400

    success, msg = furniture_service.delete_log(log_id)

    if not success:
        return jsonify({"success": False, "message": msg}), 400

    return jsonify({"success": True, "message": msg}), 200

@furniture_bp.route("/<int:furniture_id>", methods=["GET"])
def get_furniture_details_route(furniture_id):
    """
    Get a single furniture item with its full history log.
    """
    data = furniture_service.get_furniture_details(furniture_id)
    
    if not data:
        return jsonify({"success": False, "message": "Furniture not found"}), 404

    return jsonify({"success": True, "data": data}), 200