from database import db

class TenantRecord(db.Model):
    __tablename__ = "tenant_records"

    id = db.Column(db.Integer, primary_key=True)

    # Link to a lease
    lease_id = db.Column(db.Integer, db.ForeignKey("leases.id"), nullable=False)
    lease = db.relationship("Lease", backref=db.backref("tenant_records", lazy=True))

    month = db.Column(db.String(20), nullable=False)   
    start_date = db.Column(db.Date, nullable=False)    
    due_date = db.Column(db.Date, nullable=False)      
    paid_at = db.Column(db.Date, nullable=True)       
    amount_paid = db.Column(db.Float, nullable=False, default=0.0)  
    status = db.Column(db.String(50), nullable=False, default="unpaid")  

    @classmethod
    def create(cls, lease_id, month, start_date, due_date, amount_paid=0.0, paid_at=None, status="unpaid"):
        """
        Create a tenant payment record for a lease.
        """
        record = cls(
            lease_id=lease_id,
            month=month,
            start_date=start_date,
            due_date=due_date,
            amount_paid=amount_paid,
            paid_at=paid_at,
            status=status
        )
        db.session.add(record)
        db.session.commit()
        return record

    @classmethod
    def find_by_lease(cls, lease_id):
        return cls.query.filter_by(lease_id=lease_id).all()
