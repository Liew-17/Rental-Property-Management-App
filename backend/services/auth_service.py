from models.user import User

def register(uid, username, role="user"):
    user = User.find_by_uid(uid)

    if not user:
        user = User.create(uid, username, role)
    return user

def user_exists(uid):
    user = User.find_by_uid(uid)
    if user:
        return True, user.id
    else:
        return False, None