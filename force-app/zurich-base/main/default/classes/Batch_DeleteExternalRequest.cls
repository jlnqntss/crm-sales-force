/**
 * @author nbizkarra-NTS
 * Batch that executes every day and deletes old processed External Requests
 * @date 27/04/2020
 */

global class Batch_DeleteExternalRequest implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
  global String query;

  global Batch_DeleteExternalRequest() {
    query = SystemUtil.getOldExternalRequests();
  }

  global Batch_DeleteExternalRequest(String q) {
    this();
    if (!String.isBlank(q)) {
      query = q;
    }
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(SchedulableContext SC) {
    Id BatchInstanceId = database.executeBatch(
      new Batch_DeleteExternalRequest(),
      200
    );
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<ExternalRequest__c> requestList = (List<ExternalRequest__c>) scope;

    if (scope != null && !scope.isEmpty()) {
      try {
        delete requestList;
      } catch (Exception e) {
        System.debug(
          'Ha habido un error eliminando los registros de ExternalRequest__c: ' +
          e.getMessage()
        );
        ErrorLogUtil.commitError(e, 'Batch_DeleteExternalRequest');
      }
    }
  }

  global void finish(Database.BatchableContext BC) {
  }
}
