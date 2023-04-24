/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old leads
 * @date 30/04/2020
 * @change aberuete - 03/04/2023 - Refactorización método execute
 */

global class Batch_DeleteLeads implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_DeleteLeads()
    {}

    global Batch_DeleteLeads(String q)
    {
        if ( !String.isBlank(q) )
        {
            query = q;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if (query == null || query == '')
        {
            query = SystemUtil.getLeadsToDelete();
        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch(new Batch_DeleteLeads(), 200);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Contact> leads = (List<Contact>) scope;

        try
        {
            if ( scope != null && !scope.isEmpty() )
            {
                LeadUtil.deleteOrUpdateContacs(leads);
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteLeads');
        }
    }

    global void finish(Database.BatchableContext bc)
    {}
}