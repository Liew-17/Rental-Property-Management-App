import uuid
from datetime import datetime
from models.reported_issue import ReportedIssue, IssueImage
from models.property import Property
from models.user import User
from database import db
from services.file_service import upload_file

def create_issue(property_id, tenant_id, title, description, priority, images):

    try:
        prop = Property.find_by_id(property_id)
        if not prop:
            return False, "Property not found"
        
        user = User.find_by_id(tenant_id)
        if not user:
            return False, "User not found"

        issue = ReportedIssue.create(
            property_id=property_id,
            tenant_id=tenant_id,
            title=title,
            description=description,
            priority=priority
        )

        if images:
            for image in images:
                if not image or image.filename == '': 
                    continue

                folder_name = f"issues/{issue.id}"
                ext = image.filename.rsplit('.', 1)[-1].lower()
                filename = f"{uuid.uuid4()}.{ext}"
                

                image_url = upload_file(image, folder_name, filename)
                
                IssueImage.create(issue.id, image_url)
        
        return True, "Issue reported successfully"

    except Exception as e:
        db.session.rollback()
        return False, str(e)

def get_issue_details(issue_id):
    issue = ReportedIssue.find_by_id(issue_id)
    if not issue:
        return False, "Issue not found"
    
    data = {
        "id": issue.id,
        "property_id": issue.property_id,
        "property_name": issue.property.name if issue.property else "Unknown",
        "tenant_id": issue.tenant_id,
        "tenant_name": issue.tenant.username if issue.tenant else "Unknown",
        "tenant_profile": issue.tenant.profile_pic_url if issue.tenant else None,
        "title": issue.title,
        "description": issue.description,
        "status": issue.status,
        "priority": issue.priority,
        "reported_at": issue.reported_at.isoformat(),
        "resolved_at": issue.resolved_at.isoformat() if issue.resolved_at else None,
        "resolution_notes": issue.resolution_notes,
        "images": [img.image_url for img in issue.images]
    }
    return True, data

def get_issues(property_id=None, tenant_id=None):

    query = ReportedIssue.query
    
    if property_id:
        query = query.filter_by(property_id=property_id)
    if tenant_id:
        query = query.filter_by(tenant_id=tenant_id)
        
    issues = query.order_by(ReportedIssue.reported_at.desc()).all() # sort by newest
    
    results = []
    for issue in issues:
        results.append({
            "id": issue.id,
            "title": issue.title,
            "status": issue.status,
            "priority": issue.priority,
            "tenant_name": issue.tenant.username if issue.tenant else "Unknown",
            "reported_at": issue.reported_at.isoformat(),
            "property_name": issue.property.name if issue.property else "Unknown",
            "thumbnail": issue.images[0].image_url if issue.images else None
        })
    return results

def resolve_issue(issue_id, resolution_notes):
    """
    Mark an issue as resolved and add notes.
    """
    issue = ReportedIssue.find_by_id(issue_id)
    if not issue:
        return False, "Issue not found"
    
    issue.status = "resolved"
    issue.resolution_notes = resolution_notes
    issue.resolved_at = datetime.utcnow()
    
    try:
        db.session.commit()
        return True, "Issue resolved successfully"
    except Exception as e:
        db.session.rollback()
        return False, str(e)

def update_issue_status(issue_id, status):

    issue = ReportedIssue.find_by_id(issue_id)
    if not issue:
        return False, "Issue not found"
    
    issue.status = status
    try:
        db.session.commit()
        return True, f"Issue status updated to {status}"
    except Exception as e:
        db.session.rollback()
        return False, str(e)