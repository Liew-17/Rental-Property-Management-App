from datetime import datetime
from database import db

class Furniture(db.Model):
    __tablename__ = "furnitures"

    id = db.Column(db.Integer, primary_key=True)
    
    # Link to the Property
    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    
    name = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(50), default="Good")  # e.g., 'Good', 'Damaged', 'Repaired', 'Disposed'
    purchase_price = db.Column(db.Float, default=0.0)
    image_url = db.Column(db.String(255), nullable=True)
    note = db.Column(db.Text, nullable=True)
    
    added_date = db.Column(db.DateTime, default=datetime.utcnow)

    property = db.relationship("Property", backref=db.backref("furnitures", lazy=True, cascade="all, delete-orphan"))

    @classmethod
    def create(cls, property_id, name, status="Good", purchase_price=0.0, image_url=None, note=None):
        item = cls(
            property_id=property_id,
            name=name,
            status=status,
            purchase_price=purchase_price,
            image_url=image_url,
            note=note
        )
        db.session.add(item)
        db.session.commit()
        return item

    @classmethod
    def find_by_property_id(cls, property_id):
        """Get all furniture for a specific property."""
        return cls.query.filter_by(property_id=property_id).all()

    @classmethod
    def find_by_id(cls, furniture_id):
        return cls.query.get(furniture_id)


class FurnitureLog(db.Model):
    __tablename__ = "furniture_logs"

    id = db.Column(db.Integer, primary_key=True)
    
    # Link to the Furniture Item
    furniture_id = db.Column(db.Integer, db.ForeignKey("furnitures.id"), nullable=False)
    
    log_type = db.Column(db.String(50), default="Maintenance") # e.g., 'Maintenance', 'Damage', 'Repair'
    description = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(255), nullable=True) # Photo of damage or receipt
    
    date = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship to Furniture
    furniture = db.relationship("Furniture", backref=db.backref("logs", lazy=True, cascade="all, delete-orphan"))

    @classmethod
    def create(cls, furniture_id, description, log_type="Maintenance", image_url=None, date=None):
        if date is None:
            date = datetime.utcnow()
            
        log = cls(
            furniture_id=furniture_id,
            description=description,
            log_type=log_type,
            image_url=image_url,
            date=date
        )
        db.session.add(log)
        db.session.commit()
        return log

    @classmethod
    def find_by_furniture_id(cls, furniture_id):
        return cls.query.filter_by(furniture_id=furniture_id).order_by(cls.date.desc()).all()