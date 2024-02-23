public with sharing class CompetitorUtil {
    
    /**
     * Metodo que vuelve a dar visibilidad sobre los registros de competencia para los clientes que se da visibilidad
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static void recalculateVisibilityCompetitorSetVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        CompetitorSelector selector = new CompetitorSelector();
        List<Competitor__c> competitorsToUpdate = new List<Competitor__c>();
        
        List<Competitor__c> competitorsToActivate = selector.findCompetitorsToGiveVisibility(accountIdList, intermediaryIdList);        

        Competitor__c aux;
        for (Competitor__c competitor: competitorsToActivate) {
            aux = new Competitor__c();
            aux.Id = competitor.Id;
            aux.IntermediaryId__c = competitor.IntermediaryIdOld__c;
            aux.IntermediaryIdOld__c = null;
            competitorsToUpdate.add(aux);
        }
        if (!competitorsToUpdate.isEmpty()) {
            update competitorsToUpdate;
        }
    }


    /**
     * Metodo que quita visibilidad sobre los registros de competencia para los clientes que se resta visibilidad
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static void recalculateVisibilityCompetitorDenyVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        CompetitorSelector selector = new CompetitorSelector();
        List<Competitor__c> competitorsToUpdate = new List<Competitor__c>();
        
        List<Competitor__c> competitorsToActivate = selector.findCompetitorsToDenyVisibility(accountIdList, intermediaryIdList);        

        Competitor__c aux;
        for (Competitor__c competitor: competitorsToActivate) {
            aux = new Competitor__c();
            aux.Id = competitor.Id;
            aux.IntermediaryIdOld__c = competitor.IntermediaryId__c;
            aux.IntermediaryId__c = null;
            competitorsToUpdate.add(aux);
        }
        if (!competitorsToUpdate.isEmpty()) {
            update competitorsToUpdate;
        }
    }
}