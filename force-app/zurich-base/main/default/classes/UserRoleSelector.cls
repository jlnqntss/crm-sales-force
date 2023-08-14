/**
 * @description       : Clase selectora del sobject UserRole
 * @author            : dmunoz
 * @group             : 
 * @last modified on  : 12/06/2023
 * @last modified by  : dmunoz
**/
public with sharing class UserRoleSelector {
    
    public UserRole findUserRoleByDeveloperName(String developerName) {

        UserRole result = null;
        List<UserRole> roles = new List<UserRole>([SELECT Id FROM UserRole WHERE DeveloperName = :developerName LIMIT 1]);
        
        if(roles != null && !roles.isEmpty()) {
            result = roles.get(0);
        }
        return result;
    }
}