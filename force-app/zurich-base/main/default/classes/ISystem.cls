global interface ISystem
{
    void prepare(List<ExternalRequest__c> externalRequestList);

    void process(List<ExternalRequest__c> externalRequestList);

    void persists(List<ExternalRequest__c> externalRequestList);

    void manageResult(Id jobId, List<ExternalRequest__c> externalRequestList);
}
