/**
 * @author nbizkarra-NTS
 * Batch to delete External Requests
 * @change adelgado 13/11/2020 Accept query as parameter to schedule batch
 * @date 27/04/2020
 */

global class Batch_DeleteExternalRequest implements Database.Batchable<sObject>, Schedulable
{
    global String query;

    global Batch_DeleteExternalRequest()
    {}

    global Batch_DeleteExternalRequest(String query)
    {
        if ( !String.isBlank(query) )
        {
            this.query = query;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if ( String.isBlank(query) )
        {
            query = SystemUtil.getOldExternalRequests();
        }

        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        database.executeBatch( new Batch_DeleteExternalRequest(query), 200 );
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try
        {
            delete scope;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteExternalRequest');
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}