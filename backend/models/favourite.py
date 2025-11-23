from database import db

class Favourite(db.Model):
    __tablename__ = "favourites"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    property_id = db.Column(db.Integer, nullable=False)

    # Prevent duplicate favourite for same user + property
    __table_args__ = (
        db.UniqueConstraint('user_id', 'property_id', name='unique_user_property_fav'),
    )

    @classmethod
    def create_favourite(cls, user_id, property_id):
        """Create a favourite if not exists."""
        # Check existing
        existing = cls.query.filter_by(user_id=user_id, property_id=property_id).first()
        if existing:
            return existing  # already favourited

        fav = cls(user_id=user_id, property_id=property_id)
        db.session.add(fav)
        db.session.commit()
        return fav

    @classmethod
    def delete_favourite(cls, user_id, property_id):
        """Delete a favourite if exists."""
        fav = cls.query.filter_by(user_id=user_id, property_id=property_id).first()
        if fav:
            db.session.delete(fav)
            db.session.commit()
            return True
        return False

    @classmethod
    def is_favourite(cls, user_id, property_id):
        """Return True/False if favourited."""
        return cls.query.filter_by(user_id=user_id, property_id=property_id).first() is not None

    @classmethod
    def get_favourites_by_user(cls, user_id):
        """Return all favourited properties by the user."""
        return cls.query.filter_by(user_id=user_id).all()