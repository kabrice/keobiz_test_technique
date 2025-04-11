/**
 * Service class for synchronizing contact data with external system
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class ContactSyncService {
    
    /**
     * Synchronizes contacts with the external system by enqueueing a queueable job
     * @param contactsToSync List of contacts to synchronize (as Map)
     */
    public static void syncContacts(List<Map<String, Object>> contactsToSync) {
        if (contactsToSync == null || contactsToSync.isEmpty()) {
            return;
        }
        
        try {
            // Enqueue the job for asynchronous processing
            System.enqueueJob(new ContactSyncQueueable(contactsToSync));
            LoggingService.logInfo('Contact synchronization job enqueued for ' + contactsToSync.size() + ' contacts');
        } catch (Exception e) {
            LoggingService.logError('Error enqueueing contact synchronization job: ' + e.getMessage(), e);
            throw e; // Re-throw to allow caller to handle if needed
        }
    }
}