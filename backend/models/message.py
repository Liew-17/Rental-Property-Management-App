from datetime import datetime
from database import db

class Message(db.Model):
    __tablename__ = "messages"

    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer, nullable=False)
    channel_id = db.Column(db.Integer, nullable=False)
    message_body = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), nullable=False)
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)  # correct default

    @classmethod
    def create_message(cls, sender_id, channel_id, message_body, type):
        """Create and save a new message without receiver_id."""
        msg = cls(
            sender_id=sender_id,
            channel_id=channel_id,
            message_body=message_body,
            type=type
        )
        db.session.add(msg)
        db.session.commit()
        return msg

    @classmethod
    def get_messages_by_channel(cls, channel_id, limit=None, offset=None):
        """
        Retrieve messages for a channel sorted by time DESC.
        Supports optional limit and offset.
        """
        query = cls.query.filter_by(channel_id=channel_id).order_by(cls.sent_at.desc())

        if offset is not None:
            query = query.offset(offset)

        if limit is not None:
            query = query.limit(limit)

        return query.all()
