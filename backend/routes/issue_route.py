from flask import Blueprint, request, jsonify
from services import issue_service

issue_bp = Blueprint("issue_bp", __name__, url_prefix="/issue")

@issue_bp.route("/create", methods=["POST"])
def create_issue_route():
    try:
        property_id = request.form.get("property_id")
        tenant_id = request.form.get("tenant_id")
        title = request.form.get("title")
        description = request.form.get("description")
        priority = request.form.get("priority", "medium")
        images = request.files.getlist("images") 

        if not property_id or not tenant_id or not title or not description:
            return jsonify({"success": False, "message": "Missing required fields"}), 400

        success, message = issue_service.create_issue(
            property_id, tenant_id, title, description, priority, images
        )

        if success:
            return jsonify({"success": True, "message": message}), 201
        else:
            return jsonify({"success": False, "message": message}), 400

    except Exception as e:
        return jsonify({"success": False, "message": f"Server error: {str(e)}"}), 500

@issue_bp.route("/<int:issue_id>", methods=["GET"])
def get_issue_route(issue_id):

    success, data = issue_service.get_issue_details(issue_id)
    if success:
        return jsonify({"success": True, "data": data}), 200
    else:
        return jsonify({"success": False, "message": data}), 404

@issue_bp.route("/list", methods=["GET"])
def list_issues_route():

    property_id = request.args.get("property_id")
    tenant_id = request.args.get("tenant_id")

    print(tenant_id)
    
    data = issue_service.get_issues(property_id, tenant_id)
    return jsonify({"success": True, "issues": data}), 200

@issue_bp.route("/resolve", methods=["POST"])
def resolve_issue_route():

    data = request.get_json()
    issue_id = data.get("issue_id")
    notes = data.get("resolution_notes", "")
    
    if not issue_id:
        return jsonify({"success": False, "message": "issue_id is required"}), 400
        
    success, message = issue_service.resolve_issue(issue_id, notes)
    if success:
        return jsonify({"success": True, "message": message}), 200
    else:
        return jsonify({"success": False, "message": message}), 400

@issue_bp.route("/update_status", methods=["POST"])
def update_status_route():

    data = request.get_json()
    issue_id = data.get("issue_id")
    status = data.get("status")

    if not issue_id or not status:
        return jsonify({"success": False, "message": "issue_id and status are required"}), 400

    success, message = issue_service.update_issue_status(issue_id, status)
    if success:
        return jsonify({"success": True, "message": message}), 200
    else:
        return jsonify({"success": False, "message": message}), 400