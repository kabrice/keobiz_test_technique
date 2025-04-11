/**
 * Test class for Account Trigger and related classes
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
@isTest
private class AccountTriggerTest {
    
    /**
     * Set up test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                MissionStatus__c = Constants.MISSION_STATUS_ACTIVE
            ));
        }
        insert testAccounts;
        
        // Create test contacts with AccountId set to establish the primary account relationship
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            FirstName = 'Test',
            LastName = 'Contact 0',
            IsActive__c = true,
            AccountId = testAccounts[0].Id  // Set primary account
        ));
        testContacts.add(new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            IsActive__c = true,
            AccountId = testAccounts[2].Id  // Set primary account
        ));
        insert testContacts;
        
        // Create additional AccountContactRelation records for secondary relationships
        // Contact 0 is already related to Account 0 (primary) and now we add Account 1 (secondary)
        // Contact 1 is already related to Account 2 (primary) and now we add Account 1 (secondary)
        List<AccountContactRelation> testACRs = new List<AccountContactRelation>();
        testACRs.add(new AccountContactRelation(
            AccountId = testAccounts[1].Id,
            ContactId = testContacts[0].Id
        ));
        testACRs.add(new AccountContactRelation(
            AccountId = testAccounts[1].Id,
            ContactId = testContacts[1].Id
        ));
        
        // Insert the secondary relations
        insert testACRs;
    }
    
    /**
     * Test canceling a single account's mission
     */
    @isTest
    static void testSingleAccountCancellation() {
        // Setup: Get the first test account
        Account testAccount = [SELECT Id, MissionStatus__c FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        
        // Setup: Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        
        // Test: Update account mission status to canceled
        Test.startTest();
        testAccount.MissionStatus__c = Constants.MISSION_STATUS_CANCELED;
        update testAccount;
        Test.stopTest();
        
        // Verify: Check if the account's cancellation date is set
        Account updatedAccount = [SELECT Id, MissionCanceledDate__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(Date.today(), updatedAccount.MissionCanceledDate__c, 'Cancellation date should be set to today');
        
        // Verify: Contact 0 should still be active (because only one of its two accounts is canceled)
        Contact contact0 = [SELECT Id, IsActive__c FROM Contact WHERE LastName = 'Contact 0'];
        System.assertEquals(true, contact0.IsActive__c, 'Contact 0 should still be active');
    }
    
    /**
     * Test canceling all accounts for a contact
     */
    @isTest
    static void testAllAccountsCancellationForContact() {
        // Setup: Get both accounts related to Contact 0
        List<Account> contact0Accounts = [
            SELECT Id, MissionStatus__c 
            FROM Account 
            WHERE Name IN ('Test Account 0', 'Test Account 1')
        ];
        
        // Setup: Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        
        // Test: Update all accounts' mission status to canceled
        Test.startTest();
        for (Account acc : contact0Accounts) {
            acc.MissionStatus__c = Constants.MISSION_STATUS_CANCELED;
        }
        update contact0Accounts;
        Test.stopTest();
        
        // Verify: Contact 0 should now be inactive
        Contact contact0 = [SELECT Id, IsActive__c FROM Contact WHERE LastName = 'Contact 0'];
        System.assertEquals(false, contact0.IsActive__c, 'Contact 0 should be inactive');
        
        // Verify: Contact 1 should still be active (because only one of its two accounts is canceled)
        Contact contact1 = [SELECT Id, IsActive__c FROM Contact WHERE LastName = 'Contact 1'];
        System.assertEquals(true, contact1.IsActive__c, 'Contact 1 should still be active');
        
        // Verify: Both accounts should have cancellation date set
        List<Account> updatedAccounts = [
            SELECT Id, MissionCanceledDate__c 
            FROM Account 
            WHERE Id IN :contact0Accounts
        ];
        for (Account acc : updatedAccounts) {
            System.assertEquals(Date.today(), acc.MissionCanceledDate__c, 'Cancellation date should be set to today');
        }
    }
    
    /**
     * Test account cancellation on insert
     */
    @isTest
    static void testAccountCancellationOnInsert() {
        // Setup: Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        
        // Test: Insert a new account with canceled status
        Test.startTest();
        Account newCanceledAccount = new Account(
            Name = 'New Canceled Account',
            MissionStatus__c = Constants.MISSION_STATUS_CANCELED
        );
        insert newCanceledAccount;
        Test.stopTest();
        
        // Verify: The cancellation date should be set
        Account updatedAccount = [SELECT Id, MissionCanceledDate__c FROM Account WHERE Id = :newCanceledAccount.Id];
        System.assertEquals(Date.today(), updatedAccount.MissionCanceledDate__c, 'Cancellation date should be set to today');
    }
    
    /**
     * Test bulk account cancellation
     */
    @isTest
    static void testBulkAccountCancellation() {
        // Setup: Get all test accounts
        List<Account> allAccounts = [SELECT Id, MissionStatus__c FROM Account];
        
        // Setup: Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        
        // Test: Update all accounts' mission status to canceled
        Test.startTest();
        for (Account acc : allAccounts) {
            acc.MissionStatus__c = Constants.MISSION_STATUS_CANCELED;
        }
        update allAccounts;
        Test.stopTest();
        
        // Verify: All accounts' cancellation dates should be set
        List<Account> updatedAccounts = [SELECT Id, MissionCanceledDate__c FROM Account];
        for (Account acc : updatedAccounts) {
            System.assertEquals(Date.today(), acc.MissionCanceledDate__c, 'Cancellation date should be set to today');
        }
        
        // Verify: All contacts should now be inactive
        List<Contact> allContacts = [SELECT Id, IsActive__c FROM Contact];
        for (Contact con : allContacts) {
            System.assertEquals(false, con.IsActive__c, 'All contacts should be inactive');
        }
    }
    
    /**
     * Test the Queueable implementation for contact synchronization
     */
    @isTest
    static void testContactSyncQueueable() {
        // Create test data for sync
        List<Map<String, Object>> testContacts = new List<Map<String, Object>>();
        testContacts.add(new Map<String, Object>{'id' => 'test001', 'is_active' => false});
        testContacts.add(new Map<String, Object>{'id' => 'test002', 'is_active' => false});
        
        // Set up the mock
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        
        // Execute the Queueable
        Test.startTest();
        ContactSyncQueueable queueable = new ContactSyncQueueable(testContacts);
        System.enqueueJob(queueable);
        Test.stopTest();
        
    }
    
    /**
     * Test the Utils.isFieldValueChanged method
     */
    @isTest
    static void testUtilsIsFieldValueChanged() {
        // Create test account
        Account oldAccount = new Account(
            Name = 'Test Utils Account',
            MissionStatus__c = Constants.MISSION_STATUS_ACTIVE
        );
        
        // Clone and modify the account
        Account newAccount = oldAccount.clone(true);
        newAccount.MissionStatus__c = Constants.MISSION_STATUS_CANCELED;
        
        // Test with field that changed
        Boolean statusChanged = Utils.isFieldValueChanged(oldAccount, newAccount, Constants.ACCOUNT_MISSION_STATUS);
        System.assertEquals(true, statusChanged, 'Status field should be detected as changed');
        
        // Test with field that did not change
        Boolean nameChanged = Utils.isFieldValueChanged(oldAccount, newAccount, Account.Name);
        System.assertEquals(false, nameChanged, 'Name field should not be detected as changed');
        
        // Test with null old object
        Boolean nullOldObjectTest = Utils.isFieldValueChanged(null, newAccount, Constants.ACCOUNT_MISSION_STATUS);
        System.assertEquals(true, nullOldObjectTest, 'Should return true when old object is null');
    }
    
    /**
     * Mock class for HTTP callouts
     */
    private class ContactSyncMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Verify the request details
            System.assertEquals(Constants.HTTP_METHOD_PATCH, request.getMethod(), 'Method should be PATCH');
            System.assertEquals(Constants.API_AUTH_TOKEN, request.getHeader('Authorization'), 'Auth token should match');
            
            // Create a mock response
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200); 
            response.setBody('{"status":"success"}');
            return response;
        }
    }
}