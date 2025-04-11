/**
 * A class offering a variety of helpful methods to enhance coding flexibility.
 * @author Edgar Kamdem
 * @date 2025-04-08
 */
public class Utils {
    
    /**
     * Take old and new version of SObject and a Field and return true if the field value is changed;
     * if oldSo is null, it returns true if the field is not null
     * @author Edgar Kamdem
     * @date 2025-04-08
     * @param oldSo old SObject record version (can be null)
     * @param newSo new SObject record version
     * @param field todo
     * @return returns true :
     *  - if the field value is changed 
     *  - or if oldSo is null, and newSo.field is not null
     */
    public static Boolean isFieldValueChanged(SObject oldSo, SObject newSo, Schema.SObjectField field) {
        return newSo.get(field) != oldSo?.get(field);
    }
    
}