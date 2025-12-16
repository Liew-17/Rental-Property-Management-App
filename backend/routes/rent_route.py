
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

        try:
            duration = int(duration)   # Convert to integer
        except:
            return {"success": False, "message": "Invalid duration format"}, 400

        # Validate required fields
        if not user_id or not property_id or not start_date or not duration:
            return jsonify({"success": False, "message": "Missing required fields"}), 400

        # Call the service
        success, message = rent_service.rent_property_request(property_id,user_id, start_date, duration, files)

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

@rent_bp.route("/request/accept", methods=["POST"])
def accept_rent_request_route():
    body = request.get_json()
    request_id = body.get("request_id")
    if request_id is None:
        return jsonify({"success": False, "message": "request_id is required"}), 400

    success = rent_service.accept_rent_request(request_id=request_id)
    if success:
        return jsonify({"success": True, "message": "Rent request accepted"}), 200
    return jsonify({"success": False, "message": "Failed to accept rent request"}), 400


@rent_bp.route("/request/reject", methods=["POST"])
def reject_rent_request_route():
    body = request.get_json()
    request_id = body.get("request_id")
    if request_id is None:
        return jsonify({"success": False, "message": "request_id is required"}), 400

    success = rent_service.reject_rent_request(request_id=request_id)
    if success:
        return jsonify({"success": True, "message": "Rent request rejected"}), 200
    return jsonify({"success": False, "message": "Failed to reject rent request"}), 400


@rent_bp.route("/request/terminate", methods=["POST"])
def terminate_rent_request_route():
    body = request.get_json()
    request_id = body.get("request_id")
    if request_id is None:
        return jsonify({"success": False, "message": "request_id is required"}), 400

    success = rent_service.terminate_rent_request(request_id=request_id)
    if success:
        return jsonify({"success": True, "message": "Rent request terminated"}), 200
    return jsonify({"success": False, "message": "Failed to terminate rent request"}), 400


@rent_bp.route("/request/upload_contract", methods=["POST"])
def upload_contract_route():
    request_id = request.form.get("request_id")
    user_id = request.form.get("user_id")
    file = request.files.get("contract")
    grace_period_days = request.form.get("grace_period_days")
    rental_price = request.form.get("rental_price")
    deposit_price = request.form.get("deposit_price")

    grace_period_days = int(grace_period_days) if grace_period_days else None
    rental_price = float(rental_price) if rental_price else None
    deposit_price = float(deposit_price) if deposit_price else None

    if not request_id or not user_id or not file:
        return jsonify({"success": False, "message": "request_id, user_id and contract file are required"}), 400
    
    success = rent_service.upload_contract(
        request_id=int(request_id),
        user_id=int(user_id),
        contract_file=file,
        grace_period_days=grace_period_days,
        rental_price=rental_price,
        deposit_price=deposit_price
    )

    if success:
        return jsonify({"success": True, "message": "Contract uploaded successfully"}), 200
    return jsonify({"success": False, "message": "Failed to upload contract"}), 400


@rent_bp.route("/request/handle_contract", methods=["POST"])
def handle_contract_approval_route():
    body = request.get_json()
    request_id = body.get("request_id")
    approved = body.get("approved")
    grace_period_days = body.get("grace_period_days")

    if request_id is None or approved is None:
        return jsonify({"success": False, "message": "request_id and approved are required"}), 400

    success = rent_service.handle_contract_approval(
        request_id=request_id,
        is_approved=approved,
        grace_period_days=grace_period_days
    )

    if success:
        return jsonify({"success": True, "message": "Contract handled successfully"}), 200
    return jsonify({"success": False, "message": "Failed to handle contract"}), 400


@rent_bp.route("/request/amounts", methods=["POST"])
def get_rent_amounts_route():

    body = request.get_json()
    request_id = body.get("request_id")

    if request_id is None:
        return jsonify({"success": False, "message": "request_id is required"}), 400

    result = rent_service.get_rent_amounts(request_id=request_id)

    if result is None:
        return jsonify({"success": False, "message": "Failed to get rent amounts"}), 400

    return jsonify({
        "success": True,
        "price": result['price'],
        "deposit": result['deposit']
    }), 200


@rent_bp.route("/request/pay_first_payment", methods=["POST"])
def pay_first_payment_route():
    body = request.get_json()
    request_id = body.get("request_id")
    if request_id is None:
        return jsonify({"success": False, "message": "request_id is required"}), 400

    success, message = rent_service.pay_first_payment(request_id=request_id)
    if success:
        return jsonify({"success": True, "message": message}), 200
    return jsonify({"success": False, "message": message}), 400

@rent_bp.route("/requests/<int:property_id>", methods=["GET"])
def get_all_rent_requests_route(property_id):
    if property_id is None:
        return jsonify({"success": False, "message": "property_id is required"}), 400

    # Call the service function to get all requests
    requests_list = rent_service.get_all_rent_requests(property_id=property_id)
    
    if requests_list is not None:
        return jsonify({"success": True, "requests": requests_list}), 200
    
    return jsonify({"success": False, "message": "Failed to fetch requests"}), 400

@rent_bp.route("/pay_rent", methods=["POST"])
def pay_rent_route():
    data = request.get_json()
    
    tenant_record_id = data.get("tenant_record_id")
    total_amount = data.get("total_amount")

    if not tenant_record_id or total_amount is None:
        return jsonify({
            "success": False, 
            "message": "tenant_record_id and total_amount are required"
        }), 400

    try:
        amount = float(total_amount)
    except ValueError:
        return jsonify({"success": False, "message": "Invalid total_amount format"}), 400

    success, message = rent_service.pay_rent(tenant_record_id, amount)

    if success:
        return jsonify({"success": True, "message": message}), 200
    else:
        return jsonify({"success": False, "message": message}), 400