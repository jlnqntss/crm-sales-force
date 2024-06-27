/**
 * @description       : Desmarca el campo Active Agent en el caso que se dé de baja el usuario
 * @author            : lgonzalez
 * @group             : Seidor
 * @last modified on  : 05-24-2023
 * @last modified by  : lgonzalez
**/
trigger UserTrigger on User (before update) {
    for (User usr : Trigger.new) {
        User oldUser = Trigger.oldMap.get(usr.Id);
        if (usr.IsActive != oldUser.IsActive && !usr.IsActive) {
            usr.ActiveAgent__c = false;
        }
    }
}