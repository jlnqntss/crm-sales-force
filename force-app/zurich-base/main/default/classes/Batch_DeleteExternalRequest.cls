/**
 * @author nbizkarra-NTS
 * Batch to delete External Requests
 * @change adelgado 13/11/2020 Accept query as parameter to schedule batch
 * @date 27/04/2020
 */
global class Batch_DeleteExternalRequest implements Database.Batchable<sObject>, Schedulable 
{
    global String query;
    public static final String PROCESSED_RESULT_OK = 'OK';
    public static final String PROCESSED_RESULT_KO = 'KO';
    private static final AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
    private static Integer daysKO;
    private static Integer daysOK;

    global Batch_DeleteExternalRequest()
    {
        checkMetadata();
    }

    global Batch_DeleteExternalRequest(String query)
    {
        checkMetadata();
        if ( !String.isBlank(query) )
        {
            this.query = query;
        }
    }

    private static void checkMetadata ()
    {
        if(adminSetup.RetentionExternalRequestKO__c != null && adminSetup.RetentionExternalRequestOK__c != null)
        {
            daysKO = adminSetup.RetentionExternalRequestKO__c.intValue();
            daysOK = adminSetup.RetentionExternalRequestOK__c.intValue();
        }
        else 
        {
            throw new SystemUtil.SystemUtilException('There are not any AdminSetup__mdt defined in the System that contain Retention Dates');
        }
    }

    static 
    {
        checkMetadata();
    }

    /**
     * Programacion del borrado de registros de ExternalRequest__c para el recordtype de Klinc
     * 
     * @author nts (agonzalezisasi)
     * @date 01/06/2021
     */
    public static String scheduleExternalRequestClearKlinc()
    {
        String query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysOK, PROCESSED_RESULT_OK);
        return scheduleExternalRequestClear('Delete Old External Requests Klinc', '0 0 22 * * ?', query);
    }

    /**
     * Programacion del borrado de registros de ExternalRequest__c para el recordtype de Ocs
     * 
     * @author adelgado
     * @date 03/12/2020
     */
    public static String scheduleExternalRequestClearOcs()
    {
        String query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysOK, PROCESSED_RESULT_OK);
        return scheduleExternalRequestClear('OCS_Clear_External_Request', '0 0 22 * * ?', query);
    }

    private static String scheduleExternalRequestClear(String jobName, String timeExpression, String query)
    {
        if ( String.isBlank(query) )
        {
            query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysOK, PROCESSED_RESULT_OK);
        }

        if( String.isNotBlank(jobName) && Test.isRunningTest() ) jobName += ' Test';

        return System.schedule
               (
            String.isBlank(jobName) ? 'Borrado de registros de external request' : jobName,
            String.isBlank(timeExpression) ? '0 0 02 * * ?' : timeExpression,
            new Batch_DeleteExternalRequest(query)
               );
    }

    /**
     * @author adelgado
     * Borrado de registros de ExternalRequestError__c
     * @date 03/12/2020
     */
    public static String scheduleExternalRequestErrorClear()
    {
        return scheduleExternalRequestErrorClear(null, null, null);
    }

    private static String scheduleExternalRequestErrorClear(String jobName, String timeExpression, String query)
    {
        if ( String.isBlank(query) )
        {
            query = SystemUtil.getOldExternalRequestErrors();
        }

        if( String.isNotBlank(jobName) && Test.isRunningTest() ) jobName += ' Test';

        return System.schedule
               (
            String.isBlank(jobName) ? 'Borrado de registros de external request error' : jobName,
            String.isBlank(timeExpression) ? '0 0 04 * * ?' : timeExpression,
            new Batch_DeleteExternalRequest(query)
               );
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if ( String.isBlank(query) )
        {
            query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysOK, PROCESSED_RESULT_OK);
        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch( new Batch_DeleteExternalRequest(query), 2000 );
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        try
        {
            Database.delete(scope, false);
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'Batch_DeleteExternalRequest');
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        Integer numReqToDeleteKO = new ExternalRequestsSelector().count(null, daysKO, PROCESSED_RESULT_KO);
        Integer numReqToDeleteOK = new ExternalRequestsSelector().count(null, daysOK, PROCESSED_RESULT_OK);
        
        if(numReqToDeleteOK != 0 )
        {
             query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysOK, PROCESSED_RESULT_OK);
             database.executeBatch( new Batch_DeleteExternalRequest(query), 2000 );
        }
        else if (numReqToDeleteKO != 0)  
        {
            query = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id}).getQueryProcessedAfterThan(daysKO, PROCESSED_RESULT_KO);
            database.executeBatch( new Batch_DeleteExternalRequest(query), 2000 );  
        }
    }
}