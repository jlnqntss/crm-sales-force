/**
 * @Description Batch that processes external requests
 * @Autor: nbizkarra (31/03/2020)
 **/

global class Batch_ProcessExternalRequest implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
  public String query;

  global Batch_ProcessExternalRequest() {
  }

  global Batch_ProcessExternalRequest(String p_query) {
    if (!String.isBlank(p_query)) {
      query = p_query;
    }
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    if (query == null || query == '') {
      query = SystemUtil.getExternalRequests();
    }

    return Database.getQueryLocator(query);
  }

  global void execute(SchedulableContext SC) {
    Database.executeBatch(new Batch_ProcessExternalRequest(query), 1);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    Savepoint SP = Database.setSavepoint();

    if (scope != null && !scope.isEmpty()) {
      List<ExternalRequest__c> listExternalRequest = (List<ExternalRequest__c>) scope;

      try {
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        update listExternalRequest;
      } catch (Exception e) {
        //Se ha producido una excepción no controlada en ExternalRequestUtil y se debe hacer rollback de las operaciones parcialmente completas
        Database.rollback(SP);

        for (ExternalRequest__c ExtReq : listExternalRequest) {
          ExtReq.Processed__c = true;
          ExtReq.ProcessedDate__c = Datetime.now();
          ExtReq.ProcessResult__c = 'KO';
          ExtReq.Error_Log__c =
            'Internal error: ' +
            e.getLineNumber() +
            ' ' +
            e.getMessage() +
            e;
        }

        ErrorLogUtil.commitError(e, 'Batch_ProcessExternalRequest');

        update listExternalRequest;
      }
    }
  }

  global void finish(Database.BatchableContext BC) {
  }
}