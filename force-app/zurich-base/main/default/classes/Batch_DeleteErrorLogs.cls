/**
 * @author nbizkarra-NTS
 * @date 27/04/2020
 */
global class Batch_DeleteErrorLogs implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_DeleteErrorLogs()
    {
        query = SystemUtil.getErrorLogs();
    }

    global Batch_DeleteErrorLogs(String q)
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
        Id BatchInstanceId = database.executeBatch(
            new Batch_DeleteErrorLogs(),
            200
            );
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Error_Log__c> errorList = (List<Error_Log__c>) scope;

        if (errorList != null && !scope.isEmpty() )
        {
            try
            {
                delete errorList;
            }
            catch (Exception e)
            {
                System.debug(
                    'Ha habido un error eliminando los registros de Error_Log__c: ' +
                    e.getMessage()
                    );
                ErrorLogUtil.commitError(e, 'Batch_DeleteErrorLogs');
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}