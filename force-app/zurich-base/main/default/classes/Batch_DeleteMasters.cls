/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes accounts (record type: master) without contacts
 * @date 30/04/2020
 */

global class Batch_DeleteMasters implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_DeleteMasters()
    {
        query = SystemUtil.getMastersToDelete();
    }

    global Batch_DeleteMasters(String q)
    {
        this();
        if ( !String.isBlank(q) )
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
        database.executeBatch(new Batch_DeleteMasters(), 200);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Account> mastersToDelete = (List<Account>) scope;

        try
        {
            if ( scope != null && !scope.isEmpty() )
            {
                delete mastersToDelete;
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteMasters');
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}