/**
 * Batch para asignar equitativamente los casos marcados que no tienen gestor preferente (WithoutBestAgent__c) a los usuarios que son gestores activos (ActiveAgent__c)
 * teniendo en cuenta la capacidad de los usuarios. Dicho batch es lanzado por la clase programable Job_WorkRouter. 
 * @author aberuete
 * @date 27/06/2024
 */
public with sharing class Batch_WorkRouter implements Database.Batchable<sObject> 
{
    public String query;

    public Batch_WorkRouter() 
    {}

    public Batch_WorkRouter(String query) 
    {
        if( !String.isBlank(query) )
        {
            this.query = query;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        if( String.isBlank(query) )
        {
            query = new CasesSelector().selectCasesWithoutBestAgent();
        }

        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext bc, List<sObject> scope)
    {
        new WorkRouter().assignCasesWithoutBestAgentToActiveAgent(scope);
    }

    public void finish(Database.BatchableContext bc)
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
    }
}