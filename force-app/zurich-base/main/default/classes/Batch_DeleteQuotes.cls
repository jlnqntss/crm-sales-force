/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old quotes
 * @date 27/04/2020
 * change aberuete - 19/04/2023 - Refactorizar método execute 
 */

global class Batch_DeleteQuotes implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_DeleteQuotes()
    {}

    global Batch_DeleteQuotes(String q)
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
            query = SystemUtil.getQuotesToDelete();
        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch(new Batch_DeleteQuotes(), 200);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Order> quotesToDelete = (List<Order>) scope;

        try
        {
            if ( scope != null && !scope.isEmpty() )
            {
                //Borrar los casos asociados
                OrderUtil.deleteCasesRelatedWithOrder (quotesToDelete);

                //Borrar las coberturas y subcoverturas asociadas
                OrderUtil.deleteConversAndSubcoversRelatedWithOrdersItem (quotesToDelete);

                delete quotesToDelete;
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteQuotes');
        }
    }

    global void finish(Database.BatchableContext bc)
    {}
}