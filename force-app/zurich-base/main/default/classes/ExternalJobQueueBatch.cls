/**
 * Clase batch encargada de procesar las external request de los diferentes sistemas de origen integrados con el CRM
 **
 * @author adelgado
 * @date 13/10/2020
 */
global class ExternalJobQueueBatch implements Database.Batchable<sObject>, Schedulable
{
    global String query;
    global String origin;
    global String classHandler;
    global Id jobId;

    global Map<String, ExternalJobQueueBatch__mdt> settingsByOrigin = new Map<String, ExternalJobQueueBatch__mdt>();

    global ExternalJobQueueBatch()
    {
    }

    global ExternalJobQueueBatch(String origin)
    {
        this.origin = origin;

        for ( ExternalJobQueueBatch__mdt setting : new ExternalJobQueueBatchesSelector(new List<Schema.SObjectField>
        {
            ExternalJobQueueBatch__mdt.Origin__c,
            ExternalJobQueueBatch__mdt.HandlerClassName__c,
            ExternalJobQueueBatch__mdt.Priority__c,
            ExternalJobQueueBatch__mdt.Retries__c,
            ExternalJobQueueBatch__mdt.Active__c
        }).selectByOrigin(new Set<String> {origin}) )
        {
            settingsByOrigin.put(setting.Origin__c, setting);
        }

        if ( settingsByOrigin.containsKey(origin) )
        {
            classHandler = settingsByOrigin.get(origin).HandlerClassName__c;
        }
    }

    global void execute(SchedulableContext SC)
    {
        jobId = database.executeBatch(new ExternalJobQueueBatch(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return new ExternalRequestsSelector
               (
            new List<Schema.SObjectField>
        {
            ExternalRequest__c.Origin__c,
            ExternalRequest__c.Entity__c,
            ExternalRequest__c.Action__c,
            ExternalRequest__c.Payload__c,
            ExternalRequest__c.ContentFormat__c,
            ExternalRequest__c.NumRetry__c,
            ExternalRequest__c.ProcessResult__c,
            ExternalRequest__c.CreatedDate,
            ExternalRequest__c.Processed__c,
            ExternalRequest__c.Error_Log__c
        }
               ).queryLocatorByOrigin(origin);
    }

    global void execute(Database.BatchableContext bc, List<ExternalRequest__c> externalRequest)
    {
        try
        {
            // 1 - Obtener el handler correspondiente al sistema de origen
            ISystem systemHandler = (ISystem) Type.forName(classHandler).newInstance();

            // 2 - Preparar la información necesaria para procesar las external request
            systemHandler.prepare(externalRequest);

            // 3 - Convertir los registros del origen en registros Salesforce
            systemHandler.process(externalRequest);

            // 4 - Realizar las operaciones DML sobre los registros de Salesforce generados
            systemHandler.persists(externalRequest);

            // 5 - Actualizar las external request con el resultado correspondiente
            systemHandler.manageResult(jobId, externalRequest);

        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatch');
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        if( !Test.isRunningTest() )
        {
            ExternalJobQueueBatchController.checkExternalJobQueueBatch();
        }
    }
}