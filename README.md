# Rental Property Management Mobile App

**Author:** Liew Yiqi  
**Student ID:** B230107B

---

## 📖 Overview

This project is a comprehensive mobile application designed to streamline rental property management. It empowers owner to efficiently handle rental properties, manage tenant relationships, and provide AI-based rental price suggestion.

The system is built on a robust architecture comprising a Python-based backend, a Flutter mobile frontend, and an integrated AI module for predictive analytics.

## 📂 System Structure

The project is organized into three primary directories:

| Component | Directory | Description |
| :--- | :--- | :--- |
| **Backend** | `/backend` | Server-side code handling API requests, database operations, and automated scheduled tasks. |
| **Frontend** | `/flutter_application` | The mobile user interface built with the Flutter framework. |
| **AI Module** | `/AI_Training` | Scripts for data collection, cleaning, and training the predictive AI models. |

---

## ⚙️ Prerequisites

Before running the system, ensure you have the following installed:

* **Python 3.x**
* **Flutter SDK**
* **Connected Device:** An Android/iOS emulator or a physical device connected via USB.

---

## 🚀 Installation & Execution

### 1. Backend Setup
The backend handles database logic and background automation.

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Install required dependencies:
    ```bash
    pip install -r requirements.txt
    ```
3.  Start the server:
    ```bash
    python app.py
    ```

> **Note:** The backend server is configured to update automatically every **10 seconds** to handle automated tasks.

### 2. Frontend Setup
1.  Open a new terminal and navigate to the application directory:
    ```bash
    cd flutter_application
    ```
2.  Launch the application:
    ```bash
    flutter run
    ```

---

## 🔌 Configuration & Connection

To ensure the Flutter frontend communicates correctly with the Python backend:

### Standard Configuration
1.  Open the API service file:
    `flutter_application/lib/services/api_service.dart`
2.  Locate the `baseURL` variable.
3.  Update it to match your local backend server address (e.g., `http://192.168.x.x:5000` or `http://10.0.2.2:5000` for Android emulators).

### Debugging Connection
If you are testing on different networks or need to switch hosts quickly:
* On the **Login Page**, tap the **Settings Icon**.
* Manually input your server address.
* *⚠️ **Warning:** This feature is strictly for debugging purposes and is not part of the system’s standard user flow.*

---

## 🧠 AI Model Training

The `/AI_Training` folder contains the logic for the system's predictive capabilities. It includes scripts for:
1.  **Data Collection:** Gathering historical rental data.
2.  **Data Cleaning:** Pre-processing data for accuracy.
3.  **Model Training:** Generating the AI models used by the backend.

---

## 📝 Important Notes

* **Backend Uptime:** Ensure the backend (`app.py`) is running and active *before* launching the mobile app to avoid connection errors.
* **Automation:** The system relies on the backend's 10-second interval checks for automated tasks; do not terminate the terminal running `app.py` while testing these features.
