global interface ISystem {
  void prepare(List<ExternalRequest__c> externalRequestList);

  void process(List<ExternalRequest__c> externalRequestList);

  void persists();

  void setResult();
}
