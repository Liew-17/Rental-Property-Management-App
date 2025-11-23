from database import db

class TenantRecord(db.Model):
    __tablename__ = "tenant_records"

    id = db.Column(db.Integer, primary_key=True)

    # Link to a lease
    lease_id = db.Column(db.Integer, db.ForeignKey("leases.id"), nullable=False)
    lease = db.relationship("Lease", backref=db.backref("tenant_records", lazy=True))

    month = db.Column(db.String(20), nullable=False)   # Example: "2025-01"
    payment_date = db.Column(db.Date, nullable=True)
    amount_paid = db.Column(db.Float, default=0.0)
    status = db.Column(db.String(50), default="unpaid") # unpaid, paid, partial, overdue
    
    @classmethod
    def create(cls, lease_id, month, amount_paid=0.0, payment_date=None, status="unpaid"):
        record = cls(
            lease_id=lease_id,
            month=month,
            amount_paid=amount_paid,
            payment_date=payment_date,
            status=status
        )
        db.session.add(record)
        db.session.commit()
        return record

    @classmethod
    def find_by_lease(cls, lease_id):
        return cls.query.filter_by(lease_id=lease_id).all()
