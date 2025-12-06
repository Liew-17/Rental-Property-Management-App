from datetime import datetime, timezone
from database import db

class Request(db.Model):
    __tablename__ = "requests"

    id = db.Column(db.Integer, primary_key=True)

    # Property & user association
    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    tenant_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)

    # Property & tenant relation references
    property = db.relationship("Property", backref="requests")
    tenant = db.relationship("User", backref="requests")

    # Rental duration
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)

    # Workflow status & step control
    current_step = db.Column(db.Integer, default=1)  
    status = db.Column(db.String(50), default="pending")
    # possible values: pending, reviewing_docs, contract_uploaded, waiting_sign, 
    # owner_review, deposit_pending, completed, terminated

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=datetime.now(timezone.utc), onupdate=datetime.now(timezone.utc))

    # Relationship to documents
    documents = db.relationship("RequestDocument", backref="request", lazy=True)

    @classmethod
    def create(cls, property_id, tenant_id, start_date, end_date):
        """Create a request record and store in DB."""
        request = cls(
            property_id=property_id,
            tenant_id=tenant_id,
            start_date=start_date,
            end_date=end_date,
            current_step=1,
            status="pending"
        )
        db.session.add(request)
        db.session.commit()
        return request
    
    @classmethod
    def get_request(cls, request_id):
        """Get a pending request by request ID."""
        return cls.query.filter_by(
            id=request_id,
        ).first()

class RequestDocument(db.Model):
    __tablename__ = "request_documents"

    id = db.Column(db.Integer, primary_key=True)

    request_id = db.Column(db.Integer, db.ForeignKey("requests.id"), nullable=False)

    step_number = db.Column(db.Integer, nullable=False)  # document belongs to this workflow step
    doc_type = db.Column(db.String(50), nullable=False)
    # e.g. 'ic_card', 'income_proof', 'contract', 'signed_contract', 'deposit_proof'

    original_filename = db.Column(db.String(255), nullable=False)

    file_url = db.Column(db.String(500), nullable=False)
    file_format = db.Column(db.String(10), nullable=False)  # jpg/png/pdf/etc

    uploaded_by = db.Column(db.String(20), nullable=False)  # 'tenant' / 'owner'

    version = db.Column(db.Integer, default=1)  # contract re-uploads, etc.
    is_active = db.Column(db.Boolean, default=True)

    updated_at = db.Column(db.DateTime, default=datetime.now(timezone.utc), onupdate=datetime.now(timezone.utc))


    @classmethod
    def create(cls, request_id, step_number, doc_type, file_url, original_filename, file_format, uploaded_by, version=1):
        doc = cls(
            request_id=request_id,
            step_number=step_number,
            doc_type=doc_type,
            file_url=file_url,
            original_filename=original_filename,
            file_format=file_format,
            uploaded_by=uploaded_by,
            version=version,
            is_active=True
        )
        db.session.add(doc)
        db.session.commit()
        return doc