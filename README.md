# Rental Property Management Mobile App

**Author:** Liew Yiqi  
**Student ID:** B230107B

---

## Overview

This project is a **mobile application for rental property management**, designed to help landlords and property managers efficiently handle rental properties, tenants, and automated tasks. The system includes:

- Backend server  
- Flutter-based frontend app  
- AI module for predictive analytics  

---

## System Structure

The project has three main directories:

1. **Backend**: Server-side code for requests, database operations, and automated tasks.  
2. **Flutter Application**: Mobile app frontend built with Flutter.  
3. **AI_Training**: Code for data collection, cleaning, and AI model training.  

---

## Prerequisites

- Python 3.x  
- Flutter SDK  
- Required Python packages (install via `pip install -r requirements.txt`)  
- A connected device or emulator for Flutter  

---

## Execution Steps

### 1. Run Backend

Navigate to the `backend` directory and start the server:

```bash
python app.py
```


Note: The backend server updates automatically every 10 seconds to handle automated tasks.

2. Run Frontend
Navigate to the flutter_application directory and run the Flutter app:

```bash
flutter run
```

3. Configure Server Connection
To ensure the frontend connects successfully:

Open:

text
Copy code
flutter_application/lib/services/api_service.dart
Update the baseURL to match your backend server address.

Debug Option: On the login page, press the settings icon to manually input your server address.
⚠️ This is only for debugging purposes and not part of the system’s intended functionality.

4. AI Model Training
The ai_training folder contains scripts for:

Data collection

Data cleaning

Training AI prediction models

Notes
Backend updates automatically every 10 seconds.

Ensure backend is running before launching the frontend app.

Author
Name: Liew Yi Qi
Student ID: B230107B
