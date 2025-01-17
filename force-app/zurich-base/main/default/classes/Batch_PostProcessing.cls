/**
 * @author nbizkarra-NTS
 * Batch that executes every five minutes and deletes the records related to order (policy and quote) that haven't been received
 * with the external request. The batch compares the processing time stamp or the related record, if it is older than the order, the record is
 * considered to be outdated and must be deleted
 * @date 17/06/2020
 * @change aberuete - 21/04/2023 - Refactorizar método execute
 */

global with sharing class Batch_PostProcessing implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    global String query;

    global Batch_PostProcessing()
    {
        query = SystemUtil.getOutdatedOrderInfo();
    }

    global Batch_PostProcessing(String q)
    {
        this();
        if ( !String.isBlank(q) )
        {
            query = q;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch(new Batch_PostProcessing(), 200);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Order> processedOrders = (List<Order>) scope;
        List<OrderItem> itemsToDelete = new List<OrderItem>();
        List<Discount__c> discountsToDelete = new List<Discount__c>();
        List<Cover__c> coversToDelete = new List<Cover__c>();
        SET<ID> keys = new Set<ID>();

        try
        { 
            if ( scope != null && !scope.isEmpty() )
            {
                for (Order ord : processedOrders)
                {
                    keys.add(ord.id); //guardar ids para la query de las covers
                    itemsToDelete = getItemsToDelete (ord, itemsToDelete);
                    discountsToDelete = getDiscountsToDelete (ord, discountsToDelete);
                    ord.After_Processing_Check__c = false;
                }

                coversToDelete = [
                    SELECT id
                    FROM Cover__c
                    WHERE Updated__c = FALSE AND PolicyProduct__r.OrderId = :keys
                ];

                if ( !coversToDelete.isEmpty() )
                {
                    delete coversToDelete;
                }

                if ( !itemsToDelete.isEmpty() )
                {
                    delete itemsToDelete;
                }

                if ( !discountsToDelete.isEmpty() )
                {
                    delete discountsToDelete;
                }

                update processedOrders;
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_PostProcessing');
        }
    }

    global void finish(Database.BatchableContext bc)
    {}

    /**
    * Método que obtiene una lista de order items a borrar 
    * @author aberuete
    * @date 21/04/2023
    * @param Order ord : Order a procesar
    * @param List<OrderItem> itemsToDelete : Lista de orderitems a borrar
    **/
    @testvisible
    private List<OrderItem> getItemsToDelete (Order ord, List<OrderItem> itemsToDelete)
    {
        if ( !ord.OrderItems.isEmpty() )
        {
            for (OrderItem oi : ord.OrderItems)
            {
                itemsToDelete.add(oi);
            }
        } 
        return itemsToDelete;
    }

    /**
    * Método que obtiene una lista de descuentos a borrar 
    * @author aberuete
    * @date 21/04/2023
    * @param Order ord : Order a procesar
    * @param List<Discount__c> discountsToDelete : Lista de descuentos a borrar
    **/
    @testvisible
    private List<Discount__c> getDiscountsToDelete (Order ord, List<Discount__c> discountsToDelete)
    {
        if ( !ord.Descuentos__r.isEmpty() )
        {
            for (Discount__c dis : ord.Descuentos__r)
            {
                discountsToDelete.add(dis);
            }
        }

        return discountsToDelete;
    }
}