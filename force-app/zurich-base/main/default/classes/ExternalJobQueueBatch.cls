/**
 * Clase batch encargada de procesar las external request de los diferentes sistemas de origen integrados con el CRM
 **
 * @author adelgado
 * @date 13/10/2020
 */
global class ExternalJobQueueBatch implements Database.Batchable<sObject>, Schedulable {
  global String query;
  global String origin;
  global String classHandler;
  global Integer maxRetries;
  global Id jobId;
  global Boolean onlyThisOrigin = false;

  private static Map<String, ExternalJobQueueBatch__mdt> settingsByOrigin {
    get {
      if (settingsByOrigin == null) {
        settingsByOrigin = new Map<String, ExternalJobQueueBatch__mdt>();

        for (ExternalJobQueueBatch__mdt setting : [
          SELECT
            Origin__c,
            HandlerClassName__c,
            Priority__c,
            Retries__c,
            Active__c
          FROM ExternalJobQueueBatch__mdt
        ]) {
          settingsByOrigin.put(setting.Origin__c, setting);
        }
      }

      return settingsByOrigin;
    }
    private set;
  }

  global ExternalJobQueueBatch() {
  }

  global ExternalJobQueueBatch(String origin) {
    this.origin = origin;

    if (settingsByOrigin.containsKey(origin)) {
      maxRetries = (Integer) settingsByOrigin.get(origin).Retries__c;
      classHandler = settingsByOrigin.get(origin).HandlerClassName__c;

      query = 'SELECT Origin__c, Entity__c, Action__c, Payload__c, ContentFormat__c, NumRetry__c, ProcessResult__c, CreatedDate, Processed__c, Error_Log__c FROM ExternalRequest__c ';
      query += 'WHERE Origin__c = :origin AND Processed__c = false AND NumRetry__c < :maxRetries ORDER BY CreatedDate, NumRetry__c';
    }
  }

  global void execute(SchedulableContext SC) {
    jobId = database.executeBatch(new ExternalJobQueueBatch(), 200);
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  global void execute(
    Database.BatchableContext bc,
    List<ExternalRequest__c> externalRequest
  ) {
    try {
      // 1 - Obtener el handler correspondiente al sistema de origen
      ISystem systemHandler = (ISystem) Type.forName(classHandler)
        .newInstance();

      // 2 - Preparar la información necesaria para procesar las external request
      systemHandler.prepare(externalRequest);

      // 3 - Convertir los registros del origen en registros Salesforce
      systemHandler.process(externalRequest);

      // 4 - Realizar las operaciones DML sobre los registros de Salesforce generados
      systemHandler.persists(externalRequest);

      // 5 - Actualizar las external request con el resultado correspondiente
      systemHandler.manageResult(jobId, externalRequest);
    } catch (Exception e) {
      ErrorLogUtil.commitError(e, 'ExternalJobQueueBatch');
    }
  }

  global void finish(Database.BatchableContext bc) {
    /*if(!onlyThisOrigin)
    {
      List<String> originCondition = new List<String>();
      String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = false AND (';

      for(String origin : settingsByOrigin.KeySet())
      {
        if(settingsByOrigin.get(origin).Active__c)
        {
          originCondition.add('(Origin__c = \'' + origin + '\' AND NumRetry__c < ' + settingsByOrigin.get(origin).Retries__c + ')');
          activeOrigin = true;
        }
      }

      if(activeOrigin)
      {
        List<sObject> pendingExternalRequest = Database.query(query + String.join(originCondition, ' OR ') + ') LIMIT 1');

        if(!pendingExternalRequest.isEmpty())
        {
          Id classId = [SELECT Id FROM ApexCLass WHERE Name = 'ExternalJobQueueBatch'].Id;

          List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE Id != :jobId AND Status NOT IN ('Completed', 'Aborted', 'Failed') AND ApexClassId = :classId AND JobType = 'BatchApex'];

          if (jobs.isEmpty()) 
          {
            database.executeBatch(new ExternalJobQueueBatch(), 200);
          }
        }
      }
    }*/
  }
}
