/**
 * @description       : Batch que borra los Leads más antiguos en base a una serie de criterios
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 10/04/2024
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
        return Database.getQueryLocator(new AccountsSelector().findZRMOldLeads(DAYS));        
    }

    /**
    * @description : Método execute del batch, filtra los leads en base a una serie de criterios para borrarlos después
    * @author rserrano | 09/04/2024 
    * @param bc    : Batch context
    * @param scope : Lista de Leads procedentes del método start
    **/
    global void execute(Database.BatchableContext bc, List<Account> scope)
    {
        Scope_Setting__mdt ventasScopeMdt = Scope_Setting__mdt.getInstance(VENTAS_SCOPE_NAME);

        List<Account> accLst = filterZRMOldLeads(ventasScopeMdt.BusinessCode__c, scope);

        try {

            delete accLst;
            
        } catch (Exception e) 
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_DeleteOldLeads(), 200);               
    }

    global void finish(Database.BatchableContext bc)
    {

    }

 
    /**
    * @description          : Método auxiliar que filtra los leads a borrar en base a una serie de criterios
    * @author rserrano | 10/04/2024 
    * @param businessCode   : Único código de negocio que pueden tener las ofertas de los leads a borrar
    * @param oldLeadLst     : Lista de leads a filtrar
    * @return List<Account> : Lista de leads filtrada
    **/
    private static List<Account> filterZRMOldLeads (String businessCode, List<Account> oldLeadLst)
    {
        List<Account> filteredOldLst = new List<Account>();

        for (Account acc : oldLeadLst)
        {
            if(acc.Opportunities.size() > 1)
            {
                continue;
            }
            if(acc.Opportunities.get(0).StageName == 'Legit Lead' && (acc.Opportunities.get(0).BusinessCode__c == businessCode || String.isBlank(acc.Opportunities.get(0).BusinessCode__c)))
            {
                filteredOldLst.add(acc);
            }
        }
        return filteredOldLst;
    }
}