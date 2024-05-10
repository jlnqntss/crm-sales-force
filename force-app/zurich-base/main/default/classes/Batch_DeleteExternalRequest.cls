/**
 * @description       : 
 * @author            : jchavez
 * @group             : 
 * @last modified on  : 05-10-2024
 * @last modified by  : jchavez
**/
global with sharing class Batch_DeleteExternalRequest implements Database.Batchable<sObject>, Schedulable
{
    global String query;
    public static final String PROCESSED_RESULT_OK = 'OK';
    public static final String PROCESSED_RESULT_KO = 'KO';
    private static final AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
    private static final String JOBOK = 'Clear_External_Request_OK';
    private static final String JOBKO = 'Clear_External_Request_KO';
    private static final String SCHEDULED_TIME = ' 0 0 2 * * ?';
    
	// Inicio métodos batchable
	//Constructor

    global Batch_DeleteExternalRequest(String query)
    {
        if(!String.isBlank(query))
        {
            this.query = query;
        }
    }

    //Obtiene la query para eliminar los External Request

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(query);
    }
    
   global void execute(Database.BatchableContext bc, List<ExternalRequest__c> scope)
   {
        try
        {
            List<ExternalRequest__c> lstExternalRequestToDelete = new List<ExternalRequest__c>();
            
            for (ExternalRequest__c er : scope)
            {
                if (er.processed__c)
                {
                    lstExternalRequestToDelete.add(er);                    
                }
            }

            Database.delete(lstExternalRequestToDelete, false);
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteExternalRequest');
        }
        
    }
    
    global void finish(Database.BatchableContext bc)
    {
    }
    
    private static String scheduleExternalRequestClear(String jobName, String timeExpression, String query)
    {    
        return  System.schedule
               (
           	    jobName,
         	    timeExpression,
                new Batch_DeleteExternalRequest(query)
               );
    }
    
    // Programa el borrado de External Request con ProcessedResult__c en KO, que hayan sido procesadas y con el límite de tiempo establecido.
    public static String scheduleExternalRequestClearKOs()
    {
        String  query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestKO__c.intValue(), PROCESSED_RESULT_KO);
    
        return scheduleExternalRequestClear(JOBKO, SCHEDULED_TIME , query);
    }
    
    // Programa el borrado de External Request con ProcessedResult__c en OK, que hayan sido procesadas y con el límite de tiempo establecido.
    public static String scheduleExternalRequestClearOKs()
    {
       String query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestOK__c.intValue(), PROCESSED_RESULT_OK);
       
       return scheduleExternalRequestClear(JOBOK, SCHEDULED_TIME, query);
    }        
    
    // FIN métodos batchable
    
    // Inicio métodos Schedulable
    global void execute(SchedulableContext sc)
    {
        database.executeBatch( new Batch_DeleteExternalRequest(query), 2000 );
    }

    // Fin métodos Schedulable
}