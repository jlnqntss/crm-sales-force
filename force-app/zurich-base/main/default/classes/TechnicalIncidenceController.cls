/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 19-10-2021
 * @last modified by  : jjuaristi
**/
public without sharing class TechnicalIncidenceController {

    @AuraEnabled(cacheable=true)
    public static Boolean getScope(String record){
        try {
            List<Scope__c> scopes = [SELECT Id, TechnicalIncidence__c FROM Scope__c WHERE AccountId__c = :record 
            AND (Scope__c = 'ZE' OR Scope__c = 'ZEO')];
            for(Scope__c scope : scopes)
            {
                if(scope.TechnicalIncidence__c)
                    return true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return false;
    }
}
