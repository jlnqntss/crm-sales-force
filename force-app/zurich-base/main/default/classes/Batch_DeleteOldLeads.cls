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

    public Batch_DeleteOldLeads() 
    {

    }

    /**
    * @description          : Método start del batch, devuelve la lista de Leads que se borran en el execute 
    * @author rserrano | 09/04/2024 
    * @param bc             : Batch context
    * @return List<Account> : Lista de Leads que se borrarán
    **/
    global List<Account> start(Database.BatchableContext bc)
    {
        Scope_Setting__mdt ventasScopeMdt = Scope_Setting__mdt.getInstance(VENTAS_SCOPE_NAME);

        Set<String> accountIdSet = Batch_DeleteOldLeads.findZRMOldLeadOffers(ventasScopeMdt.BusinessCode__c, 3);
        
        return (new AccountsSelector()).findAccountsById(accountIdSet);        
    }

    /**
    * @description : Método execute del batch, borra los Leads
    * @author rserrano | 09/04/2024 
    * @param bc    : Batch context
    * @param scope : Lista de Leads procedentes del método start
    **/
    global void execute(Database.BatchableContext bc, List<Account> scope)
    {
        try {

            delete scope;
            
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
    * @description        : Método auxiliar que devuelve el id de los Leads más antiguos 
    * @author rserrano | 08/04/2024 
    * @param businessCode : Único valor del código de negocio de la Oportunidad que puede tener el Lead para ser borrado 
    * @param months       : Mínimo número de meses de antiguedad que tiene que tener el Lead para para ser borrado
    * @return Set<String> : Set con los Id's de los Leads a borrar
    **/
    private static Set<String> findZRMOldLeadOffers (String businessCode, Integer months)
    {
        Datetime thresholdDatetime = Datetime.now().addMonths(months);
        Set<String> accountIdSet = new Set<String>();
        List<Opportunity> zrmOldOpportunityLst = 
        [SELECT Id, AccountId, StageName, BusinessCode__c FROM Opportunity 
        WHERE Account.RecordType.Name = 'Lead'
        AND Account.CreatedDate < :thresholdDatetime
        ];

        Map<String, List<Opportunity>> leadOpportunitiesMap = new Map<String, List<Opportunity>>();
        for (Opportunity opp : zrmOldOpportunityLst)
        {
            if(leadOpportunitiesMap.containsKey(opp.AccountId))
            {
                leadOpportunitiesMap.get(opp.AccountId).add(opp);
            }
            else 
            {
                leadOpportunitiesMap.put(opp.AccountId, new List<Opportunity>{opp});
            }
        }
        for (String accountId : leadOpportunitiesMap.keyset())
        {
            if(leadOpportunitiesMap.get(accountId).size() > 1)
            {
                continue;
            }
            if(leadOpportunitiesMap.get(accountId).get(0).StageName == 'Legit Lead' && (leadOpportunitiesMap.get(accountId).get(0).BusinessCode__c == businessCode || String.isBlank(leadOpportunitiesMap.get(accountId).get(0).BusinessCode__c)))
            {
                accountIdSet.add(accountId);
            }
        }
        return accountIdSet;
    }
}