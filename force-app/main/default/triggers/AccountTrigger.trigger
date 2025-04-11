/**
 * Trigger on the Account object
 * @author Edgar Kamdem 
 * @date 2025-04-08
 */
trigger AccountTrigger on Account (before update, before insert, after update, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            AccountTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.new);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.afterInsert(Trigger.oldMap, Trigger.new);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}