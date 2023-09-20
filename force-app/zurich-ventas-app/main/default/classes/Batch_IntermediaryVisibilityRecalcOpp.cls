/**
 * @description       : Batch que recalcula la visibilidad de oferta de los mediadores ZRM
 * @author            : nts - dmunoz
 * @last modified on  : 18/09/2023
**/
global with sharing class Batch_IntermediaryVisibilityRecalcOpp implements Database.Batchable<sObject>{
    
    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcOpp';
    private Set<String> accountIds;

    public Batch_IntermediaryVisibilityRecalcOpp() {
        this.accountIds = new Set<String>();
    }

    // constructor para ejecutar el batch sobre registros que lleguen del trigger
    public Batch_IntermediaryVisibilityRecalcOpp(Set<String> accountIds) {
        this.accountIds = accountIds;
    }
    

    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos a los que se recalculará la visibilidad
     * @param bc: batch context
     * @return Lista de ofertas a recalcular
     * @author dmunoz
     * @date 18/09/2023
     */
    global List<Opportunity> start(Database.BatchableContext bc) { 

        if (accountIds != null && !accountIds.isEmpty()) {
            return (new OpportunitiesSelector()).findOffersWithIncorrectVisibilityByAccountId(accountIds);
        } else {
            return (new OpportunitiesSelector()).findOffersWithIncorrectVisibility(); 
        }
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

        // obtener el default user de zrm
        Id defaultUserId = obtainDefaultUser();

        for (Opportunity op: scope) {

            if (op.Account.Blocked__c) {
                op.IntermediaryVisibilityAcc__c = null;
                
                if ('Agente Ventas'.equals(op.Owner.Profile.Name)) {
                    op.OwnerId = defaultUserId;
                }

            } else if (op.IntermediaryId__c != null && !op.IntermediaryId__r.IsPartner && op.IntermediaryId__r.IntermediaryGroup__c != null && op.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c != null) {
                op.IntermediaryVisibilityAcc__c = op.IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c;
            } else {
                op.IntermediaryVisibilityAcc__c = op.IntermediaryId__c; 
            }
        }
        return scope;
    }


    /**
     * @description Método para recuperar los Ids de los usuarios configurados para ser los
     *              Ids por defecto
     * @author      dmunoz
     * @date        19/09/2023
     */
    private Id obtainDefaultUser() {
        Id result = null;
        String aliasDeaultUserOnError = Cross_Selling__c.getinstance().DefaultUser__c;

        List<User> defaultUsers = (new UsersSelector()).findUsersByAlias(new List<String>{aliasDeaultUserOnError});

        if (!defaultUsers.isEmpty()) {
            result = defaultUsers.get(0).Id;
        }

        return result;
    }
}