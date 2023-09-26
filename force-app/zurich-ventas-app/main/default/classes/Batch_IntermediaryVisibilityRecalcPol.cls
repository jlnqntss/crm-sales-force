/**
 * @description       : Batch que recalcula la visibilidad de poliza de los mediadores ZRM
 * @author            : nts - dmunoz
 * @last modified on  : 20/09/2023
**/
global with sharing class Batch_IntermediaryVisibilityRecalcPol implements Database.Batchable<sObject> {

    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcPol';

    private Set<String> accountIds;

    public Batch_IntermediaryVisibilityRecalcPol() {
        this.accountIds = new Set<String>();
    }

    // constructor para ejecutar el batch sobre registros que lleguen del trigger
    public Batch_IntermediaryVisibilityRecalcPol(Set<String> accountIds) {
        this.accountIds = accountIds;
    }
    
    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos a los que se recalculará la visibilidad
     * @param bc: batch context
     * @return List de policy a procesar
     * @author dmunoz
     * @date 20/09/2023
     */
    global List<Policy__c> start(Database.BatchableContext bc) { 
        if (accountIds != null && !accountIds.isEmpty()) {
            return (new PoliciesSelector()).findPoliciesWithIncorrectVisibilityByAccountId(accountIds);
        } else {
            return (new PoliciesSelector()).findPoliciesWithIncorrectVisibility();
        }
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de polizas procedentes del método start
     * @return void
     * @author dmunoz
     * @date 20/09/2023
     */
    global void execute(Database.BatchableContext bc, List<Policy__c> scope) {
        try {
            List<Policy__c> updatePoliciesVisibilityList = updatePoliciesVisibility(scope);

            update updatePoliciesVisibilityList;
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Metodo finish del batch, se lanza el batch de oferta Batch_IntermediaryVisibilityRecalcOpp
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 20/09/2023
     */
    global void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            // envio siempre el parámetro accountIds ya que en caso que venga del trigger de cliente tendrá datos y hará la query correspondiente, 
            //en caso que se lance a petición por el boton de recalculo, llegará vacio y recalculará todos los registros necesarios
            Database.executeBatch(new Batch_IntermediaryVisibilityRecalcOpp(accountIds), 200); 
        }
    }


    /*********** Métodos Auxiliares **************************************************************************/
    
    /**
     * Actualiza el campo de visibilidad de las polizas recuperadas con la consulta de bd con el valor correcto, 
     * @param bc: batch context
     * @return List<Policy__c>
     * @author dmunoz
     * @date 20/09/2023
     */
    private List<Policy__c> updatePoliciesVisibility(List<Policy__c> scope) {

        for (Policy__c pol: scope) {
            if (pol.PolicyHolder__r.Blocked__c) {
                pol.IntermediaryVisibilityAcc__c = null;
            } else if (pol.IntermediaryId__c != null && !pol.IntermediaryId__r.IsPartner && pol.IntermediaryId__r.IntermediaryGroup__c != null && pol.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c != null) {
                pol.IntermediaryVisibilityAcc__c = pol.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c;
            } else {
                pol.IntermediaryVisibilityAcc__c = pol.IntermediaryId__c; 
            }
        }
        return scope;
    }
}