from flask_apscheduler import APScheduler
from datetime import datetime
from services.tenant_record_service import process_daily_tasks


scheduler = APScheduler()

def start_scheduler(app):
    scheduler.init_app(app)

    def daily_check_job():
        with app.app_context():
            process_daily_tasks()

    scheduler.add_job(
        id="daily_lease_check",
        func=daily_check_job,
        trigger="interval",
        seconds=10  # Running every 10s (demo)
    )

    scheduler.start()
    print("APScheduler started.")