public with sharing class AccountRelationshipSelector {
    
    public List<AccountRelationship__c> findAccountRelationshipToGiveVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        List<AccountRelationship__c> result = new List<AccountRelationship__c>();

        result = new List<AccountRelationship__c>([SELECT Id, IntermediaryId__c, IntermediaryIdOld__c 
                                        FROM AccountRelationship__c
                                        WHERE Account__c IN :accountIdList
                                        AND IntermediaryIdOld__c IN: intermediaryIdList]);

        return result;
    }

    public List<AccountRelationship__c> findAccountRelationshipToDenyVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        List<AccountRelationship__c> result = new List<AccountRelationship__c>();

        result = new List<AccountRelationship__c>([SELECT Id, IntermediaryId__c, IntermediaryIdOld__c 
                                        FROM AccountRelationship__c
                                        WHERE Account__c IN :accountIdList
                                        AND IntermediaryId__c IN: intermediaryIdList]);

        return result;
    }
    
}