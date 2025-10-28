from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def init_db(app):
    """ Initialize the database with the given Flask app"""
    
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///app.db"  # SQLite 
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False        
    db.init_app(app)