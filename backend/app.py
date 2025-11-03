from flask import Flask
from database import db, init_db
from models.user import User
from routes.auth_route import auth_bp
from flask_cors import CORS

app = Flask(__name__)
CORS(app) 

init_db(app)

with app.app_context():
    db.create_all()


counter = 0


@app.route("/test")
def test():
    global counter
    counter += 1
    return f"This is a test response from Flask! You have call this API {counter} time"

app.register_blueprint(auth_bp, url_prefix="/auth")

if __name__ == "__main__":
    app.run(debug=True)
