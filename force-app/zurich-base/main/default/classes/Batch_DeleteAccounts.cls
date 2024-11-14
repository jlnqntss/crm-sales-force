/**
 * @author mfernandezcarrera
 * Batch que borra todas las cuentas que no tienen ofertas asociadas
 * @date 30/04/2020
 */

global class Batch_DeleteAccounts implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    private static final string LEAD_RECORDTYPE_DEVELOPERNAME = 'Lead';

    global Batch_DeleteAccounts()
    {}

    global Batch_DeleteAccounts(String q)
    {
        if ( String.isNotBlank(q) )
        {
            query = q;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        // Llama al método que obtiene los Ids y genera un Database.QueryLocator con ellos
        List<Id> accountsToDelete = AccountsSelector.getAccountsToDelete();
        return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN: accountsToDelete]);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Account> accountsToDelete = (List<Account>) scope;

        Database.DeleteResult[] deleteResults = Database.delete(accountsToDelete, false);

        for (Database.DeleteResult dr : deleteResults)
        {
            if ( !dr.isSuccess() )
            {
                ErrorLogUtil.commitError(dr, 'Batch_DeleteAccounts', 'execute', 'Account');
            }
        }
    }

    global void finish(Database.BatchableContext bc)
    {}
}