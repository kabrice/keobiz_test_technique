/**
 * Class containing the business logic for Account trigger actions
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class AccountTriggerActions {
    
    /**
     * Handles the mission cancellation process during before events (before insert/update)
     * Sets the mission cancellation date when a mission is canceled
     * @param oldAccountsMap Map of old Account records
     * @param newAccountsList List of new Account records
     */
    public static void handleMissionCancellationBeforeEvents(Map<ID, Account> oldAccountsMap, List<Account> newAccountsList) {
        for (Account newAccount : newAccountsList) {
            // Check if mission status is now canceled
            if (newAccount.MissionStatus__c == Constants.MISSION_STATUS_CANCELED) {
                // For update, check if status changed using Utils method
                Boolean statusChanged = (oldAccountsMap == null) || 
                    Utils.isFieldValueChanged(oldAccountsMap.get(newAccount.Id), newAccount, Constants.ACCOUNT_MISSION_STATUS);
                
                // If it's a new account with canceled status or the status was just changed to canceled
                if (statusChanged) {
                    // Set cancellation date directly on the record (in before context)
                    newAccount.MissionCanceledDate__c = Date.today();
                }
            }
        }
    }
    
    /**
     * Handles the mission cancellation process during after events (after insert/update)
     * Processes related contacts when a mission is canceled
     * @param oldAccountsMap Map of old Account records
     * @param newAccountsList List of new Account records
     */
    public static void handleMissionCancellationAfterEvents(Map<ID, Account> oldAccountsMap, List<Account> newAccountsList) {
        // Identify accounts with newly canceled missions
        Set<Id> canceledAccountIds = new Set<Id>();
        
        for (Account newAccount : newAccountsList) {
            // For update, check if status changed from non-canceled to canceled
            if (newAccount.MissionStatus__c == Constants.MISSION_STATUS_CANCELED) {
                // For update, check if status changed using Utils method
                Boolean statusChanged = (oldAccountsMap == null) || 
                    Utils.isFieldValueChanged(oldAccountsMap.get(newAccount.Id), newAccount, Account.MissionStatus__c);
                
                if (statusChanged) {
                    canceledAccountIds.add(newAccount.Id);
                }
            }
        }
        
        // If there are accounts with newly canceled missions
        if (!canceledAccountIds.isEmpty()) {
            // Process related contacts
            processRelatedContacts(canceledAccountIds);
        }
    }
    
    /**
     * Processes contacts related to canceled accounts
     * @param canceledAccountIds Set of IDs of canceled account records
     */
    private static void processRelatedContacts(Set<Id> canceledAccountIds) {
        // Get all account-contact relations for the canceled accounts
        List<AccountContactRelation> accountContactRelations = [
            SELECT AccountId, ContactId, Contact.IsActive__c
            FROM AccountContactRelation
            WHERE AccountId IN :canceledAccountIds
        ];
        
        // Collect all contacts related to canceled accounts
        Set<Id> relatedContactIds = new Set<Id>();
        for (AccountContactRelation relation : accountContactRelations) {
            relatedContactIds.add(relation.ContactId);
        }

        // If no contacts are related, end processing
        if (relatedContactIds.isEmpty()) {
            return;
        }
        
        // For each contact, check all related accounts and update activity status if needed
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Map<String, Object>> contactsForSync = new List<Map<String, Object>>();
        
        // Get all contacts with their current status
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([
            SELECT Id, IsActive__c
            FROM Contact
            WHERE Id IN :relatedContactIds
        ]);
       
        // Get all account-contact relations for these contacts
        Map<Id, List<String>> contactAccountStatusMap = new Map<Id, List<String>>();

        // Query all account statuses for each contact
        List<AccountContactRelation> allContactRelations = [
            SELECT ContactId, Account.MissionStatus__c
            FROM AccountContactRelation
            WHERE ContactId IN :relatedContactIds
        ];
        
        // Build the map of all account statuses for each contact
        for (AccountContactRelation acr : allContactRelations) {
            if (!contactAccountStatusMap.containsKey(acr.ContactId)) {
                contactAccountStatusMap.put(acr.ContactId, new List<String>());
            }
            contactAccountStatusMap.get(acr.ContactId).add(acr.Account.MissionStatus__c);
        }
        // Check each contact to see if all their accounts are canceled
        for (Id contactId : contactAccountStatusMap.keySet()) {
 
            // If all accounts are canceled and contact is currently active, mark as inactive
            Contact contact = contactsMap.get(contactId);
            List<String> accountStatuses = contactAccountStatusMap.get(contactId);
            if (contact.IsActive__c && !accountStatuses.contains(Constants.MISSION_STATUS_ACTIVE)) {
                contact.IsActive__c = false;
                contactsToUpdate.add(contact);
                
                // Prepare data for API synchronization
                Map<String, Object> contactForSync = new Map<String, Object>{
                    'id' => contactId,
                    'is_active' => false
                };
                contactsForSync.add(contactForSync);
            }
        }
        
        // Update contacts in Salesforce
        update contactsToUpdate;
        // Synchronize with external API
        if (!contactsForSync.isEmpty()) {
            ContactSyncService.syncContacts(contactsForSync);
        }
    }
}
