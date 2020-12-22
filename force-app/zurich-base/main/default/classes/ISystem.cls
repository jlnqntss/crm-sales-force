public interface ISystem
{
    void prepare(Transformer transformer, List<ExternalRequest__c> externalRequestList);

    void process(List<ExternalRequest__c> externalRequestList);

    void persists(List<ExternalRequest__c> externalRequestList);

    void manageResult(Id jobId, List<ExternalRequest__c> externalRequestList);
}