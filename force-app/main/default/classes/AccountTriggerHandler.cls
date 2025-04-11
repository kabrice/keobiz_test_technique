/**
 * Handler class for the Account trigger
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class AccountTriggerHandler {
    
    /**
     * Method called before Account records are inserted
     * @param newAccountsList List of new Account records
     */
    public static void beforeInsert(List<Account> newAccountsList) {
        System.debug('Entered Account beforeInsert handler');
        AccountTriggerActions.handleMissionCancellationBeforeEvents(null, newAccountsList);
    }
    
    /**
     * Method called before Account records are updated
     * @param oldAccountsMap Map of old Account records
     * @param newAccountsList List of new Account records
     */
    public static void beforeUpdate(Map<ID, Account> oldAccountsMap, List<Account> newAccountsList) {
        System.debug('Entered Account beforeUpdate handler');
        AccountTriggerActions.handleMissionCancellationBeforeEvents(oldAccountsMap, newAccountsList);
    }
    
    /**
     * Method called after Account records are inserted
     * @param oldAccountsMap Map of old Account records
     * @param newAccountsList List of new Account records
     */
    public static void afterInsert(Map<ID, Account> oldAccountsMap, List<Account> newAccountsList) {
        System.debug('Entered Account afterInsert handler');
        AccountTriggerActions.handleMissionCancellationAfterEvents(oldAccountsMap, newAccountsList);
    }
    
    /**
     * Method called after Account records are updated
     * @param oldAccountsMap Map of old Account records
     * @param newAccountsList List of new Account records
     */
    public static void afterUpdate(Map<ID, Account> oldAccountsMap, List<Account> newAccountsList) {
        System.debug('Entered Account afterUpdate handler');
        AccountTriggerActions.handleMissionCancellationAfterEvents(oldAccountsMap, newAccountsList);
    }
}