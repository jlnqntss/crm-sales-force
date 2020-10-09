global class ExternalJobQueueBatch implements Database.Batchable<sObject>, Schedulable {
  global String query;

  global ExternalJobQueueBatch() {
  }

  global ExternalJobQueueBatch(String origin) {
  }

  global void execute(SchedulableContext SC) {
    database.executeBatch(new ExternalJobQueueBatch(), 200);
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  global void execute(
    Database.BatchableContext bc,
    List<ExternalRequest__c> externalRequest
  ) {
  }

  global void finish(Database.BatchableContext bc) {
  }
}
