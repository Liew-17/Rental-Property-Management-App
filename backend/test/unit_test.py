import unittest
from unittest.mock import MagicMock, patch
from datetime import date
import sys
import os

# Ensure backend directory is in sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from services import chat_service
from services import tenant_record_service

class TestChatService(unittest.TestCase):

    @patch('services.chat_service.Channel')
    @patch('services.chat_service.Property')
    @patch('services.chat_service.db')
    def test_initiate_channel_redirects_to_existing_lease(self, mock_db, mock_property_model, mock_channel_model):
        """Test redirection to an existing lease channel when creating a query channel."""

        property_id, tenant_id = 1, 2
        
        mock_lease_channel = MagicMock()
        mock_lease_channel.id = 999
        mock_lease_channel.type = 'lease'
        mock_lease_channel.status = 'open'
        mock_lease_channel.property.id = property_id
        
        # Configure filter_by to always return the lease channel
        mock_channel_model.query.filter_by.return_value.first.return_value = mock_lease_channel

        success, message, data = chat_service.initiate_channel(property_id, tenant_id, type='query')

        self.assertTrue(success)
        self.assertEqual(message, "Active lease channel retrieved")
        self.assertEqual(data['type'], 'lease')
        mock_channel_model.create_channel.assert_not_called()

    @patch('services.chat_service.Channel')
    def test_initiate_channel_returns_existing_channel(self, mock_channel_model):
        """Test returning an existing channel of the requested type."""
     
        mock_existing_channel = MagicMock()
        mock_existing_channel.id = 888
        mock_existing_channel.type = 'query'
        mock_existing_channel.status = 'open'
        
        # Side effect: 1. Check lease (None), 2. Check query (Found)
        mock_channel_model.query.filter_by.return_value.first.side_effect = [None, mock_existing_channel]

        success, message, data = chat_service.initiate_channel(1, 2, type='query')

        self.assertTrue(success)
        self.assertEqual(message, "Channel retrieved successfully")
        self.assertEqual(data['id'], 888)
        mock_channel_model.create_channel.assert_not_called()

    @patch('services.chat_service.Channel')
    @patch('services.chat_service.Property')
    def test_initiate_channel_property_not_found(self, mock_property_model, mock_channel_model):
        """Test failure when property does not exist."""
        mock_channel_model.query.filter_by.return_value.first.return_value = None
        mock_property_model.find_by_id.return_value = None 

        success, message, data = chat_service.initiate_channel(999, 1, type='query')

        self.assertFalse(success)
        self.assertEqual(message, "Property not found")

    @patch('services.chat_service.Channel')
    @patch('services.chat_service.Property')
    @patch('services.chat_service.db')
    def test_initiate_channel_creates_new(self, mock_db, mock_property_model, mock_channel_model):
        """Test creating a new channel when none exist."""
        mock_channel_model.query.filter_by.return_value.first.return_value = None
        mock_property_model.find_by_id.return_value = MagicMock(id=101)

        new_channel = MagicMock()
        new_channel.id = 777
        new_channel.status = 'open'
        new_channel.type = 'query'
        mock_channel_model.create_channel.return_value = new_channel

        success, message, data = chat_service.initiate_channel(101, 202, type='query')

        self.assertTrue(success)
        self.assertEqual(message, "Channel created successfully")
        self.assertEqual(data['id'], 777)
        mock_channel_model.create_channel.assert_called_once()


class TestTenantRecordService(unittest.TestCase):

    # --- generate_next_tenant_record Tests ---

    @patch('services.tenant_record_service.Lease')
    def test_generate_record_lease_not_found(self, mock_lease_model):
        """Test returns None if lease does not exist."""
        mock_lease_model.find_by_id.return_value = None
        result = tenant_record_service.generate_next_tenant_record(1)
        self.assertIsNone(result)

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    def test_generate_record_stop_end_date_reached(self, mock_record_model, mock_lease_model):
        """Test does not generate record if past lease end date."""
        mock_lease = MagicMock()
        mock_lease.start_date = date(2023, 1, 1)
        mock_lease.end_date = date(2023, 6, 30)
        mock_lease_model.find_by_id.return_value = mock_lease
        
        mock_record_model.query.filter_by.return_value.count.return_value = 6 

        result = tenant_record_service.generate_next_tenant_record(1)
        self.assertIsNone(result)

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    @patch('services.tenant_record_service.datetime')
    def test_generate_record_stop_future_date(self, mock_datetime, mock_record_model, mock_lease_model):
        """Test does not generate record if the next cycle is in the future."""
        mock_lease = MagicMock()
        mock_lease.start_date = date(2024, 1, 1)
        mock_lease.end_date = None
        mock_lease.gracePeriodDays = 7  
        mock_lease_model.find_by_id.return_value = mock_lease
        
        mock_record_model.query.filter_by.return_value.count.return_value = 0
        mock_datetime.now.return_value.date.return_value = date(2023, 12, 1)

        result = tenant_record_service.generate_next_tenant_record(1)
        self.assertIsNone(result)

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    @patch('services.tenant_record_service.datetime')
    def test_generate_record_success_due_date_calculation(self, mock_datetime, mock_record_model, mock_lease_model):
        """Test successfully generates record with correct start and due dates."""
        mock_lease = MagicMock()
        mock_lease.id = 1
        mock_lease.start_date = date(2024, 1, 1)
        mock_lease.end_date = None
        mock_lease.gracePeriodDays = 7
        mock_lease_model.find_by_id.return_value = mock_lease
        
        mock_record_model.query.filter_by.return_value.count.return_value = 1
        mock_datetime.now.return_value.date.return_value = date(2024, 2, 2)

        tenant_record_service.generate_next_tenant_record(1)

        mock_record_model.create.assert_called_once()
        _, kwargs = mock_record_model.create.call_args
        self.assertEqual(kwargs['start_date'], date(2024, 2, 1))
        self.assertEqual(kwargs['due_date'], date(2024, 2, 8))

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    def test_generate_record_force_generate(self, mock_record_model, mock_lease_model):
        """Test force_generate flag overrides future date checks."""
        mock_lease = MagicMock()
        mock_lease.start_date = date(2025, 1, 1)
        mock_lease.end_date = None  
        mock_lease.gracePeriodDays = 7
        
        mock_lease_model.find_by_id.return_value = mock_lease
        mock_record_model.query.filter_by.return_value.count.return_value = 0

        tenant_record_service.generate_next_tenant_record(1, force_generate=True)
        
        mock_record_model.create.assert_called_once()


    # --- process_daily_tasks Tests ---

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    @patch('services.tenant_record_service.db')
    @patch('services.tenant_record_service.generate_next_tenant_record')
    @patch('services.tenant_record_service.datetime')
    def test_process_daily_tasks_mark_overdue(self, mock_datetime, mock_generate_fn, mock_db, mock_record_model, mock_lease_model):
        """Test identifying and marking unpaid records as overdue."""
        mock_lease = MagicMock()
        mock_lease.id = 1
        mock_lease.end_date = None
        mock_lease_model.query.filter_by.return_value.all.return_value = [mock_lease]

        mock_generate_fn.return_value = None # Stop infinite loop

        overdue_record = MagicMock()
        overdue_record.status = 'unpaid'
        overdue_record.due_date = date(2024, 1, 1)
        
        future_record = MagicMock()
        future_record.status = 'unpaid'
        future_record.due_date = date(2024, 3, 1)

        mock_record_model.query.filter.return_value.all.return_value = [overdue_record, future_record]
        mock_datetime.now.return_value.date.return_value = date(2024, 2, 1)

        tenant_record_service.process_daily_tasks()

        self.assertEqual(overdue_record.status, 'overdue')
        self.assertEqual(future_record.status, 'unpaid')
        mock_db.session.commit.assert_called()

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    @patch('services.tenant_record_service.Request')
    @patch('services.tenant_record_service.db')
    @patch('services.tenant_record_service.generate_next_tenant_record')
    @patch('services.tenant_record_service.datetime')
    def test_process_daily_tasks_complete_lease_success(self, mock_datetime, mock_generate_fn, mock_db, mock_request_model, mock_record_model, mock_lease_model):
        """Test successfully completing a lease when it ends and has 0 balance."""
        mock_lease = MagicMock()
        mock_lease.id = 1
        mock_lease.end_date = date(2023, 12, 31)
        mock_lease.status = 'active'
        mock_lease_model.query.filter_by.return_value.all.return_value = [mock_lease]

        mock_generate_fn.return_value = None
        mock_datetime.now.return_value.date.return_value = date(2024, 1, 15)
        mock_record_model.query.filter.return_value.count.return_value = 0 # No debt
        
        mock_req = MagicMock()
        mock_request_model.query.filter.return_value.all.return_value = [mock_req]

        tenant_record_service.process_daily_tasks()

        self.assertEqual(mock_lease.status, 'completed')
        self.assertEqual(mock_lease.channel.status, 'closed')
        self.assertEqual(mock_lease.property.status, 'unlisted')
        self.assertEqual(mock_req.status, 'archived')
        mock_db.session.commit.assert_called()

    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord')
    @patch('services.tenant_record_service.db')
    @patch('services.tenant_record_service.generate_next_tenant_record')
    @patch('services.tenant_record_service.datetime')
    def test_process_daily_tasks_completion_blocked_by_debt(self, mock_datetime, mock_generate_fn, mock_db, mock_record_model, mock_lease_model):
        """Test lease is NOT completed if there is outstanding debt."""
        mock_lease = MagicMock()
        mock_lease.id = 1
        mock_lease.end_date = date(2023, 12, 31)
        mock_lease.status = 'active'
        mock_lease_model.query.filter_by.return_value.all.return_value = [mock_lease]

        mock_generate_fn.return_value = None
        mock_datetime.now.return_value.date.return_value = date(2024, 1, 1)

        mock_record_model.query.filter.return_value.count.return_value = 1 # Debt exists

        tenant_record_service.process_daily_tasks()

        self.assertEqual(mock_lease.status, 'active') 


    @patch('services.tenant_record_service.Lease')
    @patch('services.tenant_record_service.TenantRecord') 
    @patch('services.tenant_record_service.generate_next_tenant_record')
    @patch('services.tenant_record_service.db')
    def test_process_daily_tasks_exception_handling(self, mock_db, mock_generate_fn, mock_record_model, mock_lease_model):
        """Test database rollback on exception."""

        mock_db.session.commit.side_effect = Exception("DB Error")
        
        mock_lease = MagicMock()
        mock_lease.id = 1
        mock_lease.end_date = None
        mock_lease_model.query.filter_by.return_value.all.return_value = [mock_lease]
        
        mock_generate_fn.return_value = None

        tenant_record_service.process_daily_tasks()
        
        mock_db.session.rollback.assert_called_once()

if __name__ == '__main__':
    unittest.main()