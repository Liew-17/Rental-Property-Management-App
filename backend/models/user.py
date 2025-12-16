from database import db

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    uid = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), nullable=False)
    username = db.Column(db.String(80), nullable=False)
    role = db.Column(db.String(20), default="user")
    state = db.Column(db.String(100), nullable=True)
    city = db.Column(db.String(100), nullable=True)
    district = db.Column(db.String(100), nullable=True)
    address = db.Column(db.String(255), nullable=True)
    profile_pic_url = db.Column(db.String(255), nullable=True)

    @classmethod
    def create(cls, uid, username, email, role="user"):
        new_user = cls(uid=uid, username=username,email = email, role=role)
        db.session.add(new_user)
        db.session.commit()
        return new_user
    
    @classmethod
    def find_by_id(cls, id):
        return cls.query.filter_by(id=id).first()
    

 
    @classmethod
    def find_by_uid(cls, uid):
        return cls.query.filter_by(uid=uid).first()
