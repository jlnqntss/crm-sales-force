/**
 * Clase batch encargada de procesar las external request de forma directa para priorizar su procesado
 * Actualmente procesa la entidad NOTE
 *
 * @author nts (agonzalezisasi)
 * @date 12/02/2021
 */
global class ExternalJobPriorityQueueBatch implements Database.Batchable<sObject>
{
    private String query;
    private String origin;
    private String classHandler;

    private Transformer transformer;

    // Constructors
    
    global ExternalJobPriorityQueueBatch(String origin)
    {
        this.origin = origin;

        getSettingsByOrigin(origin);
    }

    global ExternalJobPriorityQueueBatch(String origin, String query)
    {
        this(origin);
        
        this.query = query;
    }

    // Start
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if( String.isBlank(query) ) {
            String exReqRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(origin).getRecordTypeId();
            query = 'SELECT Id FROM ExternalRequest__c ';
            query += ' WHERE RecordTypeId = \'' + exReqRecordTypeId + '\' AND Processed__c = false';
            query += ' AND Entity__c IN ' + INFOHandler.PriorityEntitiesToString;
        }

        return Database.getQueryLocator(query);
    }

    // Execute
    global void execute(Database.BatchableContext bc, List<ExternalRequest__c> externalRequestScope)
    {
        Set<Id> externalRequestIds = new Set<Id>();

        try {
            // 1 - Recuperar los ids de los registros recuperados en el inicio del batch
            for(ExternalRequest__c externalRequest : externalRequestScope) {
                externalRequestIds.add(externalRequest.Id);
            }

            // 2 - Recuperar la información necesaria de las external request
            List<ExternalRequest__c> externalRequests = new ExternalRequestsSelector(
                new List<Schema.SObjectField> {
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
            systemHandler.prepare(transformer, externalRequests);

            // 5 - Convertir los registros del origen en registros Salesforce
            systemHandler.process(externalRequests);

            // 6 - Realizar las operaciones DML sobre los registros de Salesforce generados
            systemHandler.persists(externalRequests);

            // 7 - Actualizar las external request con el resultado correspondiente
            systemHandler.manageResult(bc.getJobId(), externalRequests);
        }
        catch (Exception e) {
            ErrorLogUtil.commitError(e, 'ExternalJobPriorityQueueBatch');
        }
    }

    // Finish
    global void finish(Database.BatchableContext bc)
    {
        System.debug('---------- finish - origin: ' + origin);
        // check if there are more Priority entities to process..
        String exReqRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(origin).getRecordTypeId();
        String queryNum = 'SELECT count() FROM ExternalRequest__c '; 
        queryNum += ' WHERE RecordTypeId = \'' + exReqRecordTypeId + '\' AND Processed__c = false';
        queryNum += ' AND Entity__c IN ' + INFOHandler.PriorityEntitiesToString;

        Integer num = Database.countQuery(queryNum);
        // if there are any, execute the batch again...
        if( num > 0 ) {
            //if( !Test.isRunningTest() )
            ExternalJobQueueBatchController.checkExternalJobPriorityQueueBatch();
        }
    }

    /**
     * Obtiene la configuración correspondiente al sistema de origen de las external request
     **
     * @author adelgado
     * @date 17/11/2020
     * @param origin Origen de las external request
     * @return
     */
    private void getSettingsByOrigin(String origin)
    {
        List<ExternalJobQueueBatch__mdt> settings = new ExternalJobQueueBatchesSelector(
            new List<Schema.SObjectField>{ExternalJobQueueBatch__mdt.HandlerClassName__c}
        ).selectByOrigin(new Set<String> {origin});

        if( settings != null && !settings.isEmpty() ) {
            classHandler = settings.get(0).HandlerClassName__c;
            transformer = new Transformer(origin);
        }
    }
}