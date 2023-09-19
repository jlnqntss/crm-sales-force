global with sharing class Batch_IntermediaryVisibilityRecalcOpp implements Database.Batchable<sObject>{
    
    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcOpp';
    

    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos a los que se recalculará la visibilidad
     * @param bc: batch context
     * @return List los campaign member a clonar
     * @author dmunoz
     * @date 18/09/2023
     */
    global List<Opportunity> start(Database.BatchableContext bc) { 
        return (new OpportunitiesSelector()).findOffersWithIncorrectVisibility();        
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Offers procedentes del método start
     * @return void
     * @author dmunoz
     * @date 18/09/2023
     */
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        try {
            List<Opportunity> updatedOffersVisibilityList = updateOffersVisibility(scope);

            update updatedOffersVisibilityList;
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 18/09/2023
     */
    global void finish(Database.BatchableContext bc) {
        // nothing
    }
    
    


    /*********** Métodos Auxiliares **************************************************************************/
    
    /**
     * Actualiza el campo de visibilidad de las ofertas recuperadas con la consulta de bd con el valor correcto, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 18/09/2023
     */
    private List<Opportunity> updateOffersVisibility(List<Opportunity> scope) {

        for (Opportunity op: scope) {
            if (op.IntermediaryId__c != null && !op.IntermediaryId__r.IsPartner && op.IntermediaryId__r.IntermediaryGroup__c != null && op.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c != null) {
                op.IntermediaryVisibilityAcc__c = op.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c;
            } else {
                op.IntermediaryVisibilityAcc__c = op.IntermediaryId__c; 
            }
        }
        return scope;
    }
}