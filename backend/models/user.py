from database import db

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    uid = db.Column(db.String(80), nullable=False)
    username = db.Column(db.String(80), nullable=False)
    role = db.Column(db.String(20), default="user")

    @classmethod
    def create(cls, uid, username, role="user"):
        new_user = cls(uid=uid, username=username, role=role)
        db.session.add(new_user)
        db.session.commit()
        return new_user

    @classmethod
    def find_by_uid(cls, uid):
        return cls.query.filter_by(uid=uid).first()
