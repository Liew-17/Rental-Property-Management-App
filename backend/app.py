from flask import Flask
from database import db, init_db
from models.user import User

app = Flask(__name__)

init_db(app)

with app.app_context():
    db.create_all()

if __name__ == "__main__":
    app.run(debug=True)


counter = 0

@app.route("/test")
def test():
    global counter
    counter += 1
    return f"This is a test response from Flask! You have call this API {counter} time"