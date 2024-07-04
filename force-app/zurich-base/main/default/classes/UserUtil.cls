/**
 * @description       : Trigger Before update que actualiza el campo ActiveAgent__c a false si el campo IsActive está a false
 * @author            : lgonzalez
 * @group             : Seidor
 * @last modified on  : 05-24-2023
 * @last modified by  : lgonzalez
**/
public with sharing class UserUtil 
{
    public static void userDesactive(List<User> newList,Map<Id, SObject> oldMap)
    {
        // Se marca el campo ActiveAngent__c a false en el caso de querer dar de baja al usuario y olvidar desmarcar ActiveAngent__c
        for (User usr : newList) 
        {
            if ( (usr.IsActive== false ) && (usr.ActiveAgent__c == true)) {
                usr.ActiveAgent__c = false;
            }
        }
    }
}