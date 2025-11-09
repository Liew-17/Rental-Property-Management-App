from database import db

class Property(db.Model):
    __tablename__ = "properties"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    title = db.Column(db.String(150), nullable=True)
    description = db.Column(db.Text, nullable=True)
    type = db.Column(db.String(50), nullable=False)  
    thumbnail_url = db.Column(db.String(255), nullable=True)
    verified = db.Column(db.Boolean, default=False) 

    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False) # link property to user
    
    # One-to-many relationship for additional images
    images = db.relationship(
        "PropertyImage",
        backref="property",
        lazy=True,
        cascade="all, delete-orphan"
    )


    @classmethod
    def create(cls, user_id, name, title=None, description=None, type="house", thumbnail_url=None):
        new_property = cls(
            user_id=user_id,
            name=name,
            title=title,
            description=description,
            type=type,
            thumbnail_url=thumbnail_url
        )
        db.session.add(new_property)
        db.session.commit()
        return new_property

    @classmethod
    def find_by_id(cls, property_id):
        return cls.query.get(property_id)

    @classmethod
    def find_by_user_id(cls, user_id):
        return cls.query.filter_by(user_id=user_id).all()


class PropertyImage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    property_id = db.Column(db.Integer, db.ForeignKey("property.id"), nullable=False)
    image_url = db.Column(db.String(255), nullable=False)

    @classmethod
    def add_image(cls, property_id, image_url):
        new_image = cls(property_id=property_id, image_url=image_url)
        db.session.add(new_image)
        db.session.commit()
        return new_image

    @classmethod
    def get_images_for_property(cls, property_id):
        return cls.query.filter_by(property_id=property_id).all()