/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old leads
 * @date 30/04/2020
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
        List<Contact> deleteLeads = new List<Contact>();
        List<Contact> subscribersToUpdate = new List<Contact>();

        try
        {
            if ( scope != null && !scope.isEmpty() )
            {
                for ( Contact lead: leads )
                {
                    // nts (nbizkarra) - 17/dic/2020 -  Include Subscribers
                    // Si es lead de IBA, subscriber y no está desuscrito se borra toda la información de la tarificación
                    // Se mantiene: Nombre, email, isSubscriber, SourceCountry, Legal Entity, Record Type, Partner y Status
                    if ( lead.IsSubscriber__c == true && lead.HasOptedOutOfEmail == false)
                    {
                        lead.Balance__c = null;
                        lead.Birthdate = null;
                        lead.CNO__c = null;
                        lead.CreditCard__c = null;
                        lead.CustomerID__c = null;
                        lead.CustomerNum__c = null;
                        lead.DNI__c = null;
                        lead.EmailHash__c = null;
                        lead.Gender__c = null;
                        lead.Job__c = null;
                        lead.JobPosition__c = null;
                        lead.MailingCity = null;
                        lead.MailingCountry = null;
                        lead.MailingPostalCode = null;
                        lead.MailingState = null;
                        lead.MailingStreet = null;
                        lead.MasterPolicy__c = null;
                        lead.MasterPolicyDesc__c = null;
                        lead.MasterPolicyNum__c = null;
                        lead.MobilePhone = null;
                        lead.MonthExpiryDate__c = null;
                        lead.Nationality__c = null;
                        lead.YearExpiryDate__c = null;
                        lead.Abandoned_Lead__c = false;

                        subscribersToUpdate.add(lead);
                    }
                    else
                    {
                        deleteLeads.add(lead);
                    }

                }

                if ( deleteLeads != null && !deleteLeads.isEmpty() )
                {
                    delete deleteLeads;
                }

                if ( subscribersToUpdate != null && !subscribersToUpdate.isEmpty() )
                {
                    update subscribersToUpdate;
                }

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