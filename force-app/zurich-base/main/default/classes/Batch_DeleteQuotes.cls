/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old quotes
 * @date 27/04/2020
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
        List<Case> casesToDelete = new List<Case>();
        List<Cover__c> coversToDelete = new List<Cover__c>();
        List<Cover__c> subCoversToDelete = new List<Cover__c>();

        try
        {
            if ( scope != null && !scope.isEmpty() )
            {
                //Borrar primero los casos asociados
                for (Order quote : quotesToDelete)
                {
                    if ( !quote.Casos__r.isEmpty() )
                    {
                        for (Case c : quote.Casos__r)
                        {
                            casesToDelete.add(c);
                        }
                    }
                    //Si la order está activada no se puede borrar, settear el valor a Sync
                    quote.Status = Label.Order_Sync;
                }

                if ( !casesToDelete.isEmpty() )
                {
                    delete casesToDelete;
                }

                //Borrar las coberturas y subcoverturas asociadas
                SET<ID> keys = new Set<ID>();
                for (Order q : quotesToDelete)
                {
                    //coger los ids de los orderItems
                    for (OrderItem oi : q.OrderItems)
                    {
                        keys.add(oi.id);
                    }
                }
                //Coger las covers y subcovers asociadas a los orderItems
                coversToDelete = [
                    SELECT id, (SELECT id, CoverId__c FROM Coberturas__r), CoverId__c
                    FROM Cover__c
                    WHERE PolicyProduct__c IN (SELECT id FROM OrderItem WHERE id = :keys)
                ];

                for (Cover__c c : coversToDelete)
                {
                    for (Cover__c sc : c.Coberturas__r)
                    {
                        subCoversToDelete.add(sc);
                    }
                }

                if ( !subCoversToDelete.isEmpty() )
                {
                    delete subCoversToDelete;
                }
                if ( !coversToDelete.isEmpty() )
                {
                    delete coversToDelete;
                }

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