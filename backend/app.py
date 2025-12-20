from database import db, init_db
from models.user import User
from models.property import Property
from models.message import Message
from models.channel import Channel
from models.property import PropertyImage
from models.property import Residence
from models.request import Request, RequestDocument
from models.reported_issue import ReportedIssue, IssueImage
from models.furniture import Furniture, FurnitureLog
from routes.auth_route import auth_bp
from routes.property_route import property_bp
from routes.file_route import file_bp
from routes.chat_route import chat_bp
from routes.user_route import user_bp
from routes.rent_route import rent_bp
from routes.issue_route import issue_bp
from routes.furniture_route import furniture_bp
from flask_cors import CORS
from flask import Flask, send_from_directory
import os
from scheduler import start_scheduler
from datetime import datetime
from extension import socketio, join_room


# Initialize Flask
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Initialize DB
init_db(app)
with app.app_context():
    db.create_all()

# Upload folder
app.config["UPLOAD_FOLDER"] = os.path.join(os.getcwd(), "uploads")

# Socket
socketio.init_app(app)

# Register Blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(property_bp)
app.register_blueprint(file_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(user_bp)
app.register_blueprint(rent_bp)
app.register_blueprint(issue_bp)
app.register_blueprint(furniture_bp)



@socketio.on('join')
def on_join(data):
    user_id = data.get('user_id')
    if user_id:
        join_room(f"user_{user_id}")
        print(f"User {user_id} joined their private room.")



with app.app_context():
    start_scheduler(app)


# Run APP
if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000, debug=True)
