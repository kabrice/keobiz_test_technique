/**
 * Class containing all constants used in the application
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class Constants {
    
    // Account mission status values
    public static final String MISSION_STATUS_ACTIVE = 'Active';
    public static final String MISSION_STATUS_CANCELED = 'Canceled';
    
    // API-related constants
    public static final String API_AUTH_TOKEN = 'salesforceAuthToken';
    
    // Batch processing
    public static final Integer MAX_API_BATCH_SIZE = 100;
    
    // HTTP Methods
    public static final String HTTP_METHOD_PATCH = 'PATCH';
    
    // Account fields
    public static final Schema.SObjectField ACCOUNT_MISSION_STATUS = Account.MissionStatus__c;
    public static final Schema.SObjectField ACCOUNT_MISSION_CANCELED_DATE = Account.MissionCanceledDate__c;
    
    // Contact fields
    public static final Schema.SObjectField CONTACT_IS_ACTIVE = Contact.IsActive__c;
}