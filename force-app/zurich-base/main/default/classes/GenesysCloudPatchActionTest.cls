@isTest
public with sharing class GenesysCloudPatchActionTest
{
    @isTest
    static void test_genesysCloudPatchAcdActionTest_status_ok()
    {
        //creamos el caso y el email relacionado
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        String responseAcdMock = 'nok';

        GenesysCloud.InteractionStatus interaccionToPatch = new GenesysCloud.InteractionStatus();
        interaccionToPatch.conversationId = '123';
        interaccionToPatch.participants = '456';

        List<String> acdServiceFirstListMock = new List<String>();
        List<String> acdServiceSecondListMock = new List<String>();
        List<List<String> > combinedAcdListMock = new List<List<String> >();

        acdServiceFirstListMock.add('123#456#pending');
        acdServiceSecondListMock.add('456#789#pending');

        combinedAcdListMock.add(acdServiceFirstListMock);
        combinedAcdListMock.add(acdServiceSecondListMock);

        String bodyAcd = '{"state": "disconnected", "wrapup: [{"code": "123", "name": "válida"}]}';
        Integer codeAcd = 200;
        GenesysCloud.PatchService.mock = new GenesysCloudMocks(bodyAcd, codeAcd);

        Test.startTest();
        GenesysCloudPatchInteractionAction.execute(combinedAcdListMock);
        responseAcdMock = 'ok';
        Test.stopTest();

        System.assertEquals('ok', responseAcdMock);

        /**
         * ---------------
         */
    }

    @isTest
    static void test_genesysCloudPatchAgentActionTest_status_ok()
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        String responseAgentMock = 'nok';

        List<String> agentServiceFirstListMock = new List<String>();
        List<String> agentServiceSecondListMock = new List<String>();
        List<List<String> > combinedAgentListMock = new List<List<String> >();

        agentServiceFirstListMock.add('123#456#working');
        agentServiceFirstListMock.add('456#789#working');

        combinedAgentListMock.add(agentServiceFirstListMock);
        combinedAgentListMock.add(agentServiceFirstListMock);

        String bodyAgent = '{"state": "disconnected"}';
        Integer codeAgent = 200;
        GenesysCloud.PatchService.mock = new GenesysCloudMocks(bodyAgent, codeAgent);

        Test.startTest();
        GenesysCloudPatchInteractionAction.execute(combinedAgentListMock);
        responseAgentMock = 'ok';
        Test.stopTest();
    }
}
