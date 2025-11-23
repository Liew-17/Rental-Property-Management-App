from database import db, init_db
from models.user import User
from models.property import Property
from models.message import Message
from models.channel import Channel
from models.property import PropertyImage
from models.property import Residence
from routes.auth_route import auth_bp
from routes.property_route import property_bp
from routes.file_route import file_bp
from routes.chat_route import chat_bp
from flask_cors import CORS
from flask import Flask, send_from_directory
import os

# Initialize Flask app
app = Flask(__name__)
CORS(app)  

# Initialize DB
init_db(app)
with app.app_context():
    db.create_all()

# Uploads folder configuration
app.config["UPLOAD_FOLDER"] = os.path.join(os.getcwd(), "uploads")

# Register Blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(property_bp)
app.register_blueprint(file_bp)
app.register_blueprint(chat_bp)

# Run the app
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
