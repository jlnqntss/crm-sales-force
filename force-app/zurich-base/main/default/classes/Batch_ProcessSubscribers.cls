/**
 * @Description Batch that processes subscribers (Leads) created via web-to-lead
 * @Autor: nbizkarra (16/11/2020)
 **/

global class Batch_ProcessSubscribers implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    public String query;

    global Batch_ProcessSubscribers()
    {}

    global Batch_ProcessSubscribers(String p_query)
    {
        if ( !String.isBlank(p_query) )
        {
            query = p_query;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if (query == null || query == '')
        {
            query = SystemUtil.getSubscribers();

        }

        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new Batch_ProcessSubscribers(query), 1);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Savepoint SP = Database.setSavepoint();

        if ( scope != null && !scope.isEmpty() )
        {
            List<Lead> subscribers = (List<Lead>) scope;

            try
            {
                LeadUtil.NewSubscribers(subscribers);

                delete subscribers;
            }
            catch (Exception e)
            {
                //Se ha producido una excepción no controlada en LeadUtil y se debe hacer rollback de las operaciones parcialmente completas
                Database.rollback(SP);

                ErrorLogUtil.commitError(e, 'Batch_ProcessSubscribers');
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}