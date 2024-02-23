public with sharing class CompetitorSelector {
    

    public List<Competitor__c> findCompetitorsToGiveVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        List<Competitor__c> result = new List<Competitor__c>();

        result = new List<Competitor__c>([SELECT Id, IntermediaryId__c, IntermediaryIdOld__c 
                                        FROM Competitor__c
                                        WHERE Account__c IN :accountIdList
                                        AND IntermediaryIdOld__c IN: intermediaryIdList]);

        return result;
    }


    public List<Competitor__c> findCompetitorsToDenyVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        List<Competitor__c> result = new List<Competitor__c>();

        result = new List<Competitor__c>([SELECT Id, IntermediaryId__c, IntermediaryIdOld__c 
                                        FROM Competitor__c
                                        WHERE Account__c IN :accountIdList
                                        AND IntermediaryId__c IN: intermediaryIdList]);

        return result;
    }
}