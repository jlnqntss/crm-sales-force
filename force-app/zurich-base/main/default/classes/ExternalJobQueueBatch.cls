/**
 * Clase batch encargada de procesar las external request de los diferentes sistemas de origen integrados con el CRM
 **
 * @author adelgado
 * @date 13/10/2020
 */
global class ExternalJobQueueBatch implements Database.Batchable<sObject>, Schedulable
{
    global String query;
    global String exReqRecordTypeId;
    global String classHandler;
    global Id jobId;

    global Map<String, ExternalJobQueueBatch__mdt> settingsByOrigin = new Map<String, ExternalJobQueueBatch__mdt>();

    global ExternalJobQueueBatch()
    {}

    global ExternalJobQueueBatch(String origin)
    {
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
            exReqRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(origin).getRecordTypeId();
        }
    }

    global void execute(SchedulableContext SC)
    {
        jobId = database.executeBatch(new ExternalJobQueueBatch(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return new ExternalRequestsSelector().queryLocatorPendingByRecordtype(exReqRecordTypeId);
    }

    global void execute(Database.BatchableContext bc, List<ExternalRequest__c> externalRequestScope)
    {
        Set<Id> externalRequestIds = new Set<Id>();

        try
        {
            // 1 - Recuperar los ids de los registros recuperados en el inicio del batch
            for(ExternalRequest__c externalRequest : externalRequestScope)
            {
                externalRequestIds.add(externalRequest.Id);
            }

            // 2 - Recuperar la información necesaria de las external request
            List<ExternalRequest__c> externalRequests = new ExternalRequestsSelector
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
                                                        ).selectById(externalRequestIds);

            // 3 - Obtener el handler correspondiente al sistema de origen
            ISystem systemHandler = (ISystem) Type.forName(classHandler).newInstance();

            // 4 - Preparar la información necesaria para procesar las external request
            systemHandler.prepare(externalRequests);

            // 5 - Convertir los registros del origen en registros Salesforce
            systemHandler.process(externalRequests);

            // 6 - Realizar las operaciones DML sobre los registros de Salesforce generados
            systemHandler.persists(externalRequests);

            // 7 - Actualizar las external request con el resultado correspondiente
            systemHandler.manageResult(jobId, externalRequests);

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