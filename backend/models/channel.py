from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from database import db

class Channel(db.Model):
    __tablename__ = "channels"

    id = db.Column(db.Integer, primary_key=True)
    property_id = db.Column(db.Integer, nullable=False)  # link to property
    type = db.Column(db.String(50), nullable=False)  # 'query', 'communication', 'request'
    status = db.Column(db.String(50), nullable=False, default='open')  # e.g., 'open', 'closed'
    period = db.Column(db.Integer, nullable=True)  # in days, only for 'request' type
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    @classmethod
    def create_channel(cls, property_id, type, status='open', period=None):
        """Create and save a new channel"""
        channel = cls(
            property_id=property_id,
            type=type,
            status=status,
            period=period
        )
        db.session.add(channel)
        db.session.commit()
        return channel
