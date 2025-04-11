/**
 * Service class for logging errors and important events
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class LoggingService {
    
    /**
     * Logs an error
     * @param message Error message
     * @param ex Exception (can be null)
     */
    public static void logError(String message, Exception ex) {
        // In a production environment, we could log to a custom object
        // For this exercise, we simply use debug logs
        
        String logMessage = 'ERROR: ' + message;
        if (ex != null) {
            logMessage += '\nStack trace: ' + ex.getStackTraceString();
        }
        
        System.debug(LoggingLevel.ERROR, logMessage);
        
        // Note: In a real environment, we could implement:
        // 1. Logging to a custom Error_Log__c object
        // 2. Sending email notifications to administrators
        // 3. Integration with an external monitoring platform
    }
    
    /**
     * Logs an informational message
     * @param message Info message
     */
    public static void logInfo(String message) {
        // For this exercise, we simply use debug logs
        String logMessage = 'INFO: ' + message;
        System.debug(LoggingLevel.INFO, logMessage);
    }
}