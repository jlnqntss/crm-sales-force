/**
 * @description       : Batch que borra los Leads más antiguos en base a una serie de criterios
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 25/04/2024
 * @last modified by  : rserrano
**/
global with sharing class Batch_DeleteOldLeads implements Database.Batchable<sObject>, Schedulable {
    
    private static final String CLASS_NAME = 'Batch_DeleteOldLeads';
    private static final String VENTAS_SCOPE_NAME = 'Zurich_Ventas';
    private static final Integer DAYS = 90;

    public Batch_DeleteOldLeads() 
    {

    }

    /**
    * @description          : Método start del batch, devuelve la lista de Leads que se borran en el execute 
    * @author rserrano | 09/04/2024 
    * @param bc             : Batch context
    * @return List<Account> : Lista de Leads que se borrarán
    **/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        Scope_Setting__mdt ventasScopeMdt = Scope_Setting__mdt.getInstance(VENTAS_SCOPE_NAME);

        return Database.getQueryLocator(new AccountsSelector().findZRMOldLeads(DAYS, 'Legit Lead', ventasScopeMdt.BusinessCode__c));        
    }

    /**
    * @description : Método execute del batch, selecciona aquellas cuentas que tienen solo una oportunidad y las borra
    * @author rserrano | 09/04/2024 
    * @param bc    : Batch context
    * @param scope : Lista de Leads procedentes del método start
    **/
    global void execute(Database.BatchableContext bc, List<Account> scope)
    {
        List<Account> oldLeadLst = new List<Account>();

        for (Account acc : scope)
        {
            if(acc.Opportunities.size() == 1)
            {
                oldLeadLst.add(acc);
            }
        }
        List<Database.DeleteResult> drLst = Database.delete(oldLeadLst, false);
        
        String errorMessage = '';
        
        for(Database.DeleteResult dr : drLst)
        {
            if(! dr.isSuccess())
            {
                errorMessage = errorMessage + dr.getErrors() + '; ';
            }
        }
        if(! String.isBlank(errorMessage))
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, errorMessage, CLASS_NAME, null);
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_DeleteOldLeads(), 2000);               
    }

    global void finish(Database.BatchableContext bc)
    {

    }

}