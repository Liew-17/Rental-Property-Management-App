from models.user import User
from database import db


def update_user_location(id, state, city, district):
    user = User.find_by_id(id)

    if not user:
        return False, None

    user.state = state
    user.city = city
    user.district = district

    try:
        db.session.commit()
        return True, user
    except:
        db.session.rollback()
        return False, user