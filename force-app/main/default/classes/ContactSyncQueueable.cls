/**
 * Queueable class for processing contact synchronization with external API asynchronously
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class ContactSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Map<String, Object>> contactsToSync;
    private Integer batchSize;
    
    /**
     * Constructor with list of contacts to synchronize
     * @param contactsToSync List of contacts to synchronize with API
     */
    public ContactSyncQueueable(List<Map<String, Object>> contactsToSync) {
        this(contactsToSync, Constants.MAX_API_BATCH_SIZE);
    }
    
    /**
     * Constructor with list of contacts and custom batch size
     * @param contactsToSync List of contacts to synchronize with API
     * @param batchSize Size of batches for API calls
     */
    public ContactSyncQueueable(List<Map<String, Object>> contactsToSync, Integer batchSize) {
        this.contactsToSync = contactsToSync;
        this.batchSize = batchSize;
    }
    
    /**
     * Execute method required by Queueable interface
     * Processes contact synchronization in batches
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        try {
            // Split into batches (to optimize API calls)
            List<List<Map<String, Object>>> contactBatches = getBatches(contactsToSync, batchSize);
            
            for (List<Map<String, Object>> batch : contactBatches) {
                callSyncAPI(batch);
            }
            
            // Log successful completion
            LoggingService.logInfo('Contact synchronization completed successfully for ' + 
                                  contactsToSync.size() + ' contacts');
                                  
        } catch (Exception e) {
            // Log any errors that occur during processing
            LoggingService.logError('Error during contact synchronization queueable execution: ' + 
                                   e.getMessage(), e);
        }
    }
    
    /**
     * Calls the synchronization API for a batch of contacts
     * @param contactsBatch Batch of contacts to synchronize
     */
    private void callSyncAPI(List<Map<String, Object>> contactsBatch) {
        // Prepare HTTP request
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint('callout:KeobizAWS');
        req.setMethod(Constants.HTTP_METHOD_PATCH);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', Constants.API_AUTH_TOKEN);
        req.setTimeout(120000); // 2-minute timeout for API calls
        
        // Convert list to JSON
        String jsonBody = JSON.serialize(contactsBatch);
        req.setBody(jsonBody);
        
        // Send request
        Http http = new Http();
        HttpResponse res;
        
        res = http.send(req);
        processResponse(res, contactsBatch);
    }
    
    /**
     * Processes the API response
     * @param response HTTP response from the API
     * @param batch The batch of contacts that were sent
     */
    private void processResponse(HttpResponse response, List<Map<String, Object>> batch) {
        Integer statusCode = response.getStatusCode();
        
        if (statusCode != 200) {
            String errorMessage;
            
            // Handle different error codes
            switch on statusCode {
                when 404 {
                    errorMessage = 'API not found (404)';
                }
                when 401 {
                    errorMessage = 'Invalid authentication (401)';
                }
                when 400 {
                    errorMessage = 'Invalid parameters (400): ' + response.getBody();
                }
                when else {
                    errorMessage = 'Unexpected error (' + statusCode + '): ' + response.getBody();
                }
            }
            
            LoggingService.logError('API Error during contact synchronization: ' + errorMessage, null);
            throw new ContactSyncException(errorMessage);
        }
    }
    
    /**
     * Splits a list into batches of maximum specified size
     * @param inputList List to split
     * @param batchSize Maximum size of a batch
     * @return List<List<T>> List of batches
     */
    private List<List<Map<String, Object>>> getBatches(List<Map<String, Object>> inputList, Integer batchSize) {
        List<List<Map<String, Object>>> batches = new List<List<Map<String, Object>>>();
        
        Integer totalItems = inputList.size();
        Integer totalBatches = Math.ceil(totalItems / (Decimal)batchSize).intValue();
        
        for (Integer i = 0; i < totalBatches; i++) {
            Integer startIndex = i * batchSize;
            Integer endIndex = Math.min(startIndex + batchSize, totalItems);
            
            List<Map<String, Object>> batch = new List<Map<String, Object>>();
            for (Integer j = startIndex; j < endIndex; j++) {
                batch.add(inputList[j]);
            }
            
            batches.add(batch);
        }
        
        return batches;
    }
    
    /**
     * Custom exception for synchronization errors
     */
    public class ContactSyncException extends Exception {}
}