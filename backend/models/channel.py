from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from database import db

class Channel(db.Model):
    __tablename__ = "channels"

    id = db.Column(db.Integer, primary_key=True)
    property_id = db.Column(db.Integer, db.ForeignKey('properties.id')) 
    tenant_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)

    status = db.Column(db.String(50), nullable=False, default='open')  # e.g., 'open', 'closed'
    type = db.Column(db.String(50), nullable=False, default='query')

    property = db.relationship("Property", backref=db.backref("channels", lazy=True))
    tenant = db.relationship("User", backref=db.backref("channels", lazy=True))


    @classmethod
    def create_channel(cls, property_id, tenant_id, status='open', type='query'):
        """Create and save a new channel"""

        channel = cls(
            property_id=property_id,
            tenant_id=tenant_id,
            status=status,
            type=type
        )
        db.session.add(channel)
        db.session.commit()
        return channel
