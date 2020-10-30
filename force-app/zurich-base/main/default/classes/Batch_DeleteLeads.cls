/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old leads
 * @date 30/04/2020
 */

global class Batch_DeleteLeads implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_DeleteLeads()
    {
        query = SystemUtil.getLeadsToDelete();
    }

    global Batch_DeleteLeads(String q)
    {
        this();
        if (!String.isBlank(q) )
        {
            query = q;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        Id BatchInstanceId = database.executeBatch(new Batch_DeleteLeads(), 200);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Contact> leadsToDelete = (List<Contact>) scope;

        try
        {
            if (scope != null && !scope.isEmpty() )
            {
                delete leadsToDelete;
            }
        }
        catch (Exception e)
        {
            System.debug(
                'Ha habido un error eliminando los laeads: ' + e.getMessage()
                );
            ErrorLogUtil.commitError(e, 'Batch_DeleteLeads');
        }
    }

    global void finish(Database.BatchableContext BC)
    {
    }
}