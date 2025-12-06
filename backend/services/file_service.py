import os
from flask import current_app

def upload_file(image, folder, filename):
    folder_path = os.path.join(current_app.config["UPLOAD_FOLDER"], folder)

    if not os.path.exists(folder_path):
        os.makedirs(folder_path)

    save_path = os.path.join(folder_path, filename)

    image.save(save_path)

    image_url = f"/uploads/{folder}/{filename}"

    return image_url