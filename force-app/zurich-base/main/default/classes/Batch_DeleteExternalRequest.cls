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

    /**
     * Programacion del borrado de registros de ExternalRequest__c para el recordtype de Klinc
     * 
     * @author nts (agonzalezisasi)
     * @date 01/06/2021
     */
    public static String scheduleExternalRequestClearKlinc()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        Integer days = adminSetup.NumberDaysDeleteRequests__c.intValue();
        
        Id recordTypeId = 
				Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByName().get('GENERIC').getRecordTypeId();

        String query = 'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + recordTypeId + '\' AND CreatedDate < LAST_N_DAYS:' + days;
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
        Integer days = 15;
        
        Id recordTypeId = 
				Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByName().get('INFOProcessed').getRecordTypeId();

        String query = 'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + recordTypeId + '\' AND CreatedDate < LAST_N_DAYS:' + days + ' LIMIT 50000000';
        return scheduleExternalRequestClear('OCS_Clear_External_Request', '0 0 02 * * ?', query);
    }

    private static String scheduleExternalRequestClear(String jobName, String timeExpression, String query)
    {
        if ( String.isBlank(query) )
        {
            query = SystemUtil.getOldExternalRequests();
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