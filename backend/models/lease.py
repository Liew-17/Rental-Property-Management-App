from database import db

class Lease(db.Model):
    __tablename__ = "leases"

    id = db.Column(db.Integer, primary_key=True)

    # Link to property
    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    property = db.relationship("Property", backref=db.backref("leases", lazy=True))

    # Tenant (user)
    tenant_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    tenant = db.relationship("User", backref=db.backref("leases", lazy=True))

    # Lease details
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=True)
    termination_date = db.Column(db.Date, nullable=True)

    monthly_rent = db.Column(db.Float, nullable=False)
    deposit_amount = db.Column(db.Float, nullable=True)

    contract_url = db.Column(db.String(255), nullable=True)  # url of contract
    channel_id = db.Column(db.String(255), nullable=True)    # chat channel id

    status = db.Column(db.String(50), default="active")
    # active, pending, terminated, completed

    @classmethod
    def create(cls, property_id, tenant_id, start_date, monthly_rent,
               end_date=None, deposit_amount=None, contract_url=None,
               channel_id=None, status="active"):

        new_lease = cls(
            property_id=property_id,
            tenant_id=tenant_id,
            start_date=start_date,
            end_date=end_date,
            monthly_rent=monthly_rent,
            deposit_amount=deposit_amount,
            contract_url=contract_url,
            channel_id=channel_id,
            status=status
        )
        db.session.add(new_lease)
        db.session.commit()
        return new_lease

    @classmethod
    def find_by_id(cls, lease_id):
        return cls.query.get(lease_id)
