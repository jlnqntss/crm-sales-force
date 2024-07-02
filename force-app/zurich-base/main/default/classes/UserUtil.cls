public with sharing class UserUtil {
    // Trigger Before update que actualiza el campo ActiveAgent__c a false si el campo IsActive está a false
    public static void userDesactive(List<User> newList,Map<Id, SObject> oldMap)
    {
        for (User usr : newList) {
            if ( (usr.IsActive== false ) && (usr.ActiveAgent__c == true)) {
                usr.ActiveAgent__c = false;
            }
        }
    }
}