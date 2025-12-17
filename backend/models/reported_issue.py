from datetime import datetime
from database import db

class ReportedIssue(db.Model):
    __tablename__ = "reported_issues"

    id = db.Column(db.Integer, primary_key=True)
    

    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    tenant_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)

    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(50), default="pending")  # e.g., 'pending', 'in_progress', 'resolved'
    priority = db.Column(db.String(20), default="medium") # e.g., 'low', 'medium', 'high'
    

    reported_at = db.Column(db.DateTime, default=datetime.utcnow)
    resolved_at = db.Column(db.DateTime, nullable=True)
    resolution_notes = db.Column(db.Text, nullable=True) 

    property = db.relationship("Property", backref=db.backref("issues", lazy=True))
    tenant = db.relationship("User", backref=db.backref("reported_issues", lazy=True))
    images = db.relationship("IssueImage", backref="issue", lazy=True, cascade="all, delete-orphan")

    @classmethod
    def create(cls, property_id, tenant_id, title, description, priority="medium"):
        issue = cls(
            property_id=property_id,
            tenant_id=tenant_id,
            title=title,
            description=description,
            priority=priority,
            status="pending"
        )
        db.session.add(issue)
        db.session.commit()
        return issue

    @classmethod
    def find_by_id(cls, issue_id):
        return cls.query.get(issue_id)


class IssueImage(db.Model):
    __tablename__ = "issue_images"

    id = db.Column(db.Integer, primary_key=True)
    issue_id = db.Column(db.Integer, db.ForeignKey("reported_issues.id"), nullable=False)
    image_url = db.Column(db.String(255), nullable=False)

    @classmethod
    def create(cls, issue_id, image_url):
        img = cls(issue_id=issue_id, image_url=image_url)
        db.session.add(img)
        db.session.commit()
        return img