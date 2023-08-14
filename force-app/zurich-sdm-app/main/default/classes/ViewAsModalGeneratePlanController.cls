public with sharing class ViewAsModalGeneratePlanController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> getSDMUsersList(){
        try {
            List<User> result = new List<User>();
            UserSelector selector = new UserSelector();
            
            result = selector.getSDMUsers(); 
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}