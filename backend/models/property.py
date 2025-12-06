from sqlalchemy import case
from database import db
from typing import Optional
from sqlalchemy.ext.declarative import declared_attr

class Property(db.Model):
    __tablename__ = "properties"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    title = db.Column(db.String(150))
    description = db.Column(db.Text, nullable=True)
    type = db.Column(db.String(50), nullable=False)  # "residence", "vehicle", "item"
    thumbnail_url = db.Column(db.String(255))
    verified = db.Column(db.Boolean, default=False)
    state = db.Column(db.String(100), nullable=True)
    city = db.Column(db.String(100), nullable=True)
    district = db.Column(db.String(100), nullable=True)
    address = db.Column(db.String(255), nullable=True)  # Remaining address details
    status = db.Column(db.String(50), nullable=True) # "listed", "unlisted", "rented" 
    rules = db.Column(db.Text, nullable=True)        
    features = db.Column(db.Text, nullable=True)

    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)  # Link property to user

    price = db.Column(db.Float, nullable=True)
    deposit = db.Column(db.Float, nullable=True)
    required_deposit = db.Column(db.Boolean, default=False, nullable=False)


    user = db.relationship(
        "User",
        backref=db.backref("properties", lazy=True, cascade="all, delete-orphan")
    )

    __mapper_args__ = {
        "polymorphic_identity": "property",
        "polymorphic_on": type
    }

    @classmethod
    def create(
        cls,
        user_id,
        name,
        title=None,
        description=None,
        type="residence",
        thumbnail_url=None,
        state=None,
        city=None,
        district=None,
        address=None,
        status= "unlisted",
        rules = None,       
        features = None
    ):
        """Create and save a new Property record."""
        new_property = cls(
            user_id=user_id,
            name=name,
            title=title,
            description=description,
            type=type,
            thumbnail_url=thumbnail_url,
            state=state,
            city=city,
            district=district,
            address=address,
            price= None,
            deposit = None,
            status=status,
            rules=rules,
            features=features
        )
        db.session.add(new_property)
        db.session.commit()
        return new_property

    @classmethod
    def find_by_id(cls, property_id) -> Optional["Property"]:
        """Find a property by its unique ID."""
        return cls.query.get(property_id)

    @classmethod
    def find_by_user_id(cls, user_id):
        """Find all properties belonging to a specific user."""
        return cls.query.filter_by(user_id=user_id).all()

    @classmethod
    def find_by_location(cls, state=None, city=None, district=None, page = 1):
        """Find properties filtered by any combination of state, city, or district."""
        query = cls.query.filter_by(status="listed") 

        if state:
            query = query.filter_by(state=state)
        if city:
            query = query.filter_by(city=city)
        if district:
            query = query.filter_by(district=district)

        order_case = case(
            (cls.district == district, 3),
            (cls.city == city, 2),
            (cls.state == state, 1),
            else_=0
        )

        query = query.order_by(order_case.desc())
        length = query.count()
        offset = (page - 1) * 10 # ten item per page
        query = query.limit(10).offset(offset)

        return query.all(), length
    
    @classmethod
    def update(cls, property_id: int, **kwargs):
        """
        Update a property by ID. 
        Only updates fields provided in kwargs.
        
        Example:
            Property.update(1, name="New Name", price=1200)
        """
        prop = cls.query.get(property_id)
        if not prop:
            return None  # or raise Exception("Property not found")
        
        for key, value in kwargs.items():
            if hasattr(prop, key):
                setattr(prop, key, value)

        db.session.commit()
        return prop

class PropertyImage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False)
    image_url = db.Column(db.String(255), nullable=False)

    property = db.relationship(
        "Property",
        backref=db.backref("images", lazy=True, cascade="all, delete-orphan")
    )

    @classmethod
    def add_image(cls, property_id, image_url):
        """Add image urls to the property"""
        new_image = cls(property_id=property_id, image_url=image_url)
        db.session.add(new_image)
        db.session.commit()
        return new_image

    @classmethod
    def get_images_for_property(cls, property_id):
        """Return a list of image urls"""
        return cls.query.filter_by(property_id=property_id).all()
    
    @classmethod
    def delete_image_by_url(cls, property_id, image_url):
        """Delete a specific image by URL for a given property"""
        image = cls.query.filter_by(property_id=property_id, image_url=image_url).first()
        if image:
            db.session.delete(image)
            db.session.commit()
            return True
        return False
    
class Residence(Property):
    __tablename__ = "residences" 

    residence_id = db.Column(db.Integer, primary_key=True)
    property_id = db.Column(db.Integer, db.ForeignKey("properties.id"), nullable=False, unique=True) # Link residence details to the property

    __mapper_args__ = {
            "polymorphic_identity": "residence",
        }

    num_bedrooms = db.Column(db.Integer, default = 0)
    num_bathrooms = db.Column(db.Integer, default = 0)
    land_size = db.Column(db.Float, default = 0)  # sqft
    residence_type = db.Column(db.String(50), nullable=True)



    @classmethod
    def create_residence(cls, *, user_id, name, title=None, description=None,
                        thumbnail_url="", state=None, city=None, district=None,
                        address=None, price=None, status="unlisted", rules=None,
                        features=None, num_bedrooms=None, num_bathrooms=None,
                        land_size=None, residence_type=None):
        """
        Create a Residence in one step.
        """
        new_residence = cls(
            user_id=user_id,
            name=name,
            title=title,
            description=description,
            type="residence",
            thumbnail_url=thumbnail_url,
            state=state,
            city=city,
            district=district,
            address=address,
            price=price,
            status=status,
            rules=rules,
            features=features,
            num_bedrooms=num_bedrooms,
            num_bathrooms=num_bathrooms,
            land_size=land_size,
            residence_type=residence_type
        )
        db.session.add(new_residence)
        db.session.commit()
        return new_residence

    def __repr__(self):
        return f"<Residence PropertyID={self.property_id}>"