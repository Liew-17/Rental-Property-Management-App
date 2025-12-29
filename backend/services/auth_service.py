from models.user import User

def register(uid, username, email, role="tenant", ):
    user = User.find_by_uid(uid)

    if not user:
        user = User.create(uid, username, role, email)
    return user

def user_exists(uid):
    user = User.find_by_uid(uid)
    if user:
        return True, user
    else:
        return False, None