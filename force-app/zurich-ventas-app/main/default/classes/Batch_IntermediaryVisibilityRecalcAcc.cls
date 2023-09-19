global with sharing class Batch_IntermediaryVisibilityRecalcAcc implements Database.Batchable<sObject>{

    

    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcAcc';


    @InvocableMethod
    global static void invocableExecuteBatch() {
        Database.executeBatch(new Batch_IntermediaryVisibilityRecalcAcc(), 200);
    }
    

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
            /*List<Opportunity> updatedOffersVisibilityList = updateOffersVisibility(scope);

            update updatedOffersVisibilityList;*/
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
}