from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
from models.property import Property
from models.tenant_record import TenantRecord
from models.lease import Lease
from database import db

def generate_next_tenant_record(lease_id, force_generate=False):
    """
    Check the lease's latest tenant record and generate the next one if start date has been reached.
    """
    lease = Lease.find_by_id(lease_id)
    
    if not lease:
        
        return None

    latest_record = TenantRecord.query.filter_by(lease_id=lease.id)\
                                      .order_by(TenantRecord.start_date.desc())\
                                      .first()

    # Determine next month's start_date
    if latest_record:
        next_start_date = latest_record.start_date + relativedelta(months=1)
        next_month_str = (datetime.strptime(latest_record.month + "-01", "%Y-%m-%d") + relativedelta(months=1)).strftime("%Y-%m")
    else:
        next_start_date = lease.start_date
        next_month_str = lease.start_date.strftime("%Y-%m")

    if lease.end_date and next_start_date > lease.end_date and not force_generate:
        return None

    # Determine due date (start_date + grace period)
    due_date = next_start_date + timedelta(days=lease.gracePeriodDays)
    today = datetime.now(timezone.utc).date()
  
    # Generate next record if pass the start date / force generate is true
    if next_start_date <= today or force_generate == True:
        new_record = TenantRecord.create(
            lease_id=lease.id,
            month=next_month_str,
            start_date=next_start_date,
            due_date=due_date,
            amount_paid=0.0,
            status="unpaid"
        )
        return new_record
    else:
        return None  

def process_daily_tasks():
    """
    1. Generate missing tenant records (handling date jumps).
    2. Update overdue statuses.
    3. Complete leases if ended and fully paid.
    """
    with db.session.no_autoflush:
        # Fetch all active leases
        active_leases = Lease.query.filter_by(status='active').all()
        today = datetime.now(timezone.utc).date()

        for lease in active_leases:
            # --- TASK 1: Generate ALL missing records (Catch-up) ---
            # We loop until generate_next_tenant_record returns None 
            # (either because it's caught up to today, or hit end_date)
            while True:
                created = generate_next_tenant_record(lease.id)
                if not created:
                    break
            
            # --- TASK 2: Update Overdue Status ---
            # Check all unpaid records for this lease
            unpaid_records = TenantRecord.query.filter(
                TenantRecord.lease_id == lease.id,
                TenantRecord.status == 'unpaid'
            ).all()

            for record in unpaid_records:
                if today > record.due_date:
                    record.status = 'overdue'
                    # Optional: Add logic to notify tenant here

            # --- TASK 3: Check Lease Completion ---
            # If today reached or passed the lease end date
            if lease.end_date and today >= lease.end_date:
                # Check if there are ANY unpaid or overdue records
                outstanding_balance = TenantRecord.query.filter(
                    TenantRecord.lease_id == lease.id,
                    TenantRecord.status.in_(['unpaid', 'overdue'])
                ).count()

                # If all records are paid (outstanding == 0)
                if outstanding_balance == 0:
                    lease.status = 'completed'
                    
                    if lease.channel:
                        lease.channel.status = 'closed'
                         
                    # Set Property back to Unlisted
                    if lease.property:
                        lease.property.status = 'unlisted'
                        
                    print(f"Lease {lease.id} completed and property {lease.property_id} unlisted.")

        # Commit all changes for this batch
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            print(f"Error in daily scheduler task: {e}")