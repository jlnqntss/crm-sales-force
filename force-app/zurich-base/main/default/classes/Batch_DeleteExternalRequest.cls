/**
 * @description       : 
 * @author            : jchavez
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : jchavez
**/
global with sharing class Batch_DeleteExternalRequest implements Database.Batchable<sObject>, Schedulable
{
    global String query;
    public static final String PROCESSED_RESULT_OK = 'OK';
    public static final String PROCESSED_RESULT_KO = 'KO';
    private static final AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
    private static Integer daysKO;
    private static Integer daysOK;
    
	// Inicio métodos batchable
	//Constructor
    global Batch_DeleteExternalRequest(String query) {

        this.query = query;
    }

    //Obtiene la query para eliminar los External Request

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
            
        return Database.getQueryLocator(query);
    }
    
   global void execute(Database.BatchableContext BC, List<ExternalRequest__c> scope)
    {
         try
        {
            List<ExternalRequest__c> lstExternalRequestToDelete = new List<ExternalRequest__c>();
            
            for (ExternalRequest__c er:scope) {
                if (er.processed__c) {
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
    
     global void finish(Database.BatchableContext BC)
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
    
    // Formateo de query para External Request con resultado = KO 
    public static String scheduleExternalRequestClearKOs()
    {
        String  query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestKO__c.intValue(), PROCESSED_RESULT_KO);
    
        return scheduleExternalRequestClear('Clear_External_Request_KO', ' 0 0 2 * * ?', query);
    }
    
    public static String scheduleExternalRequestClearOKs()
    {
       String query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestOK__c.intValue(), PROCESSED_RESULT_OK);
       
       return scheduleExternalRequestClear('Clear_External_Request_OK', '0 0 2 * * ?', query);
    }        
    
    // FIN métodos batchable
    
    // Inicio métodos Schedulable
    global void execute(SchedulableContext sc)
    {
        database.executeBatch( new Batch_DeleteExternalRequest(query), 2000 );
    }

    // Fin métodos Schedulable
}