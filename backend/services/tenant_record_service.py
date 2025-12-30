from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
from models.property import Property
from models.request import Request
from models.tenant_record import TenantRecord
from models.lease import Lease
from database import db

def generate_next_tenant_record(lease_id, force_generate=False):
    """
    Generate the next tenant billing record based on the lease's base start date.
    Billing cycles are always calculated as:
        lease.start_date + N months
    to avoid month drift (e.g. Jan 31 → Feb 28 → Mar 31).
    """

    lease = Lease.find_by_id(lease_id)
    if not lease:
        return None

    record_count = TenantRecord.query.filter_by(lease_id=lease.id).count()

    # Generate next start date based on initial lease start date
    next_start_date = lease.start_date + relativedelta(months=record_count)
    next_month_str = next_start_date.strftime("%Y-%m")
    # Stop if beyond lease end date (unless forced)
    if lease.end_date and next_start_date >= lease.end_date and not force_generate:
        return None

    # Due date = start_date + grace period
    due_date = next_start_date + timedelta(days=lease.gracePeriodDays)

    today = datetime.now(timezone.utc).date()

    # Generate only if cycle has started or forced
    if next_start_date <= today or force_generate:

        return TenantRecord.create(
            lease_id=lease.id,
            month=next_month_str,
            start_date=next_start_date,
            due_date=due_date,
            amount_paid=0.0,
            status="unpaid"
        )

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
        print(today)

        for lease in active_leases:

            while True:
                created = generate_next_tenant_record(lease.id)
                if not created:
                    break
            

            unpaid_records = TenantRecord.query.filter(
                TenantRecord.lease_id == lease.id,
                TenantRecord.status == 'unpaid'
            ).all()

            for record in unpaid_records:
                if today > record.due_date:
                    record.status = 'overdue'
                 


            if lease.end_date and today >= lease.end_date:
                # Check if there are ANY unpaid or overdue records
                outstanding_balance = TenantRecord.query.filter(
                    TenantRecord.lease_id == lease.id,
                    TenantRecord.status.in_(['unpaid', 'overdue'])
                ).count()

                if outstanding_balance == 0:
                    lease.status = 'completed'
                    
                    if lease.channel:
                        lease.channel.status = 'closed'
                         
                    # Set Property back to Unlisted
                    if lease.property:
                        lease.property.status = 'unlisted'

                    requests_to_archive = Request.query.filter(
                        Request.property_id == lease.property_id,
                        Request.status.in_(['pending', 'rejected', 'terminated','completed'])
                    ).all()

                    for req in requests_to_archive:
                        req.status = 'archived'
                        
                    print(f"Lease {lease.id} completed and property {lease.property_id} unlisted.")

        # Commit all changes for this batch
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            print(f"Error in daily scheduler task: {e}")