from database import db

class Lease(db.Model):
    __tablename__ = "leases"

    id = db.Column(db.Integer, primary_key=True)

    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    property = db.relationship("Property", backref=db.backref("leases", lazy=True))

    request_id = db.Column(db.Integer, db.ForeignKey("requests.id"), unique=True, nullable=True)
    request = db.relationship("Request", backref=db.backref("lease", uselist=False))

    tenant_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    tenant = db.relationship("User", backref=db.backref("leases", lazy=True))

    channel_id = db.Column(db.Integer, db.ForeignKey("channels.id"), nullable=True)
    channel = db.relationship("Channel", backref=db.backref("lease", uselist=False))

    start_date = db.Column(db.Date, nullable=False)
    gracePeriodDays = db.Column(db.Integer, nullable=False, default=3)
    end_date = db.Column(db.Date, nullable=True)
    termination_date = db.Column(db.Date, nullable=True)

    monthly_rent = db.Column(db.Float, nullable=False)
    deposit_amount = db.Column(db.Float, nullable=True)

    contract_document_id = db.Column(db.Integer, db.ForeignKey("request_documents.id"), nullable=True)
    contract_doc = db.relationship("RequestDocument", foreign_keys=[contract_document_id])

    status = db.Column(db.String(50), default="pending")

    @classmethod
    def create(cls, *, property_id, tenant_id, start_date, end_date,
           request_id, monthly_rent, deposit_amount=None,
           contract_document_id=None, channel_id=None,
           gracePeriodDays=3, status="pending"):
    
        new_lease = cls(
            property_id=property_id,
            tenant_id=tenant_id,
            request_id=request_id,
            start_date=start_date,
            end_date=end_date,
            monthly_rent=monthly_rent,
            deposit_amount=deposit_amount,
            gracePeriodDays=gracePeriodDays,
            contract_document_id=contract_document_id,
            channel_id=channel_id,
            status=status
        )
        db.session.add(new_lease)
        db.session.commit()
        return new_lease

    @classmethod
    def find_by_id(cls, lease_id):
        return cls.query.get(lease_id)