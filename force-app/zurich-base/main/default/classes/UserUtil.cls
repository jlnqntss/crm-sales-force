public class UserUtil {
    public static void userDesactive(List<User> newList,Map<Id, SObject> oldMap)
    {
        for (User usr : newList) {
            if ( (usr.IsActive== false ) && (usr.ActiveAgent__c == true)) {
                usr.ActiveAgent__c = false;
            }
        }
    }
}