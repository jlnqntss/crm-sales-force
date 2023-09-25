/**
 * @description       : Batch que recalcula la visibilidad sobre los clientes de los mediadores ZRM
 * @author            : nts - dmunoz
 * @last modified on  : 21/09/2023
**/
global with sharing class Batch_IntermediaryVisibilityRecalcAcc implements Database.Batchable<sObject> {

    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcAcc';

    private Set<String> accountIds;

    public Batch_IntermediaryVisibilityRecalcAcc() {
        this.accountIds = new Set<String>();
    }

    // constructor para ejecutar el batch sobre registros que lleguen del trigger
    public Batch_IntermediaryVisibilityRecalcAcc(Set<String> accountIds) {
        this.accountIds = accountIds;
    }


    @InvocableMethod
    global static void invocableExecuteBatch(List<String> accountIds) {       
        Set<String> accountIdsSet = new Set<String>();
        // al invocarse desde el screen flow Recalculate Intermediaries Visibility la lista vacia llega como "accountIds {null}" por lo que compruebo si el primer elemento llega nulo para que haga la query correcta
        if (accountIds != null && !accountIds.isEmpty() && String.isNotEmpty(new List<String>(accountIds).get(0))) {
           accountIdsSet = new Set<String>(accountIds);
        } 
        Database.executeBatch(new Batch_IntermediaryVisibilityRecalcAcc(accountIdsSet), 200);
    }
    
    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos a los que se recalculará la visibilidad
     * @param bc: batch context
     * @return List de account a procesar
     * @author dmunoz
     * @date 21/09/2023
     */
    global List<Account> start(Database.BatchableContext bc) { 
        if (accountIds != null && !accountIds.isEmpty()) {
            return (new AccountsSelector()).findAccountsWithIncorrectVisibilityByAccountId(accountIds);
        } else {
            return (new AccountsSelector()).findAccountsWithIncorrectVisibility();
        }
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de polizas procedentes del método start
     * @return void
     * @author dmunoz
     * @date 21/09/2023
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        try {
            List<Account> updateAccountVisibilityList = updateAccountVisibility(scope);

            update updateAccountVisibilityList;
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Metodo finish del batch, se lanza el batch de policy Batch_IntermediaryVisibilityRecalcPol
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 21/09/2023
     */
    global void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            // envio siempre el parámetro accountIds ya que en caso que venga del trigger de cliente tendrá datos y hará la query correspondiente, 
            //en caso que se lance a petición por el boton de recalculo, llegará vacio y recalculará todos los registros necesarios
            Database.executeBatch(new Batch_IntermediaryVisibilityRecalcPol(accountIds), 200); 
        }
    }


    /*********** Métodos Auxiliares **************************************************************************/
    
    /**
     * Actualiza el campo de visibilidad de las polizas recuperadas con la consulta de bd con el valor correcto, 
     * @param bc: batch context
     * @return List<Account>
     * @author dmunoz
     * @date 21/09/2023
     */
    private List<Account> updateAccountVisibility(List<Account> scope) {

        for (Account acc: scope) {
            if (acc.Blocked__c) {
                acc.IntermediaryVisibilityAcc__c = null;
            } else if (acc.Intermediary_Name__c  != null && !acc.Intermediary_Name__r.IsPartner && acc.Intermediary_Name__r.IntermediaryGroup__c != null && acc.Intermediary_Name__r.IntermediaryGroup__r.IntermediaryWithUser__c != null) {
                acc.IntermediaryVisibilityAcc__c = acc.Intermediary_Name__r.IntermediaryGroup__r.IntermediaryWithUser__c;
            } else {
                acc.IntermediaryVisibilityAcc__c = acc.Intermediary_Name__c ; 
            }
        }
        return scope;
    }
}