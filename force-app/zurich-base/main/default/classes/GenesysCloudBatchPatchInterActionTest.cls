@isTest
public with sharing class GenesysCloudBatchPatchInterActionTest
{
    @isTest
    static void test_genesysCloudPatchAcdActionTest_status_ok()
    {
        //creamos el caso y el email relacionado
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;


        GenesysCloud.InteractionStatusId interaccionToPatch = new GenesysCloud.InteractionStatusId();
        interaccionToPatch.conversationId = '123';
        interaccionToPatch.participants = '456';

        List<String> acdServiceFirstListMock = new List<String>();
        List<String> acdServiceSecondListMock = new List<String>();
        
        List<List<String> > combinedAcdListMock = new List<List<String> >();

        List<List<String>> salida= new List<List<String>>();

        acdServiceFirstListMock.add('123#456#pending');
        acdServiceSecondListMock.add('456#789#pending');

        combinedAcdListMock.add(acdServiceFirstListMock);
        combinedAcdListMock.add(acdServiceSecondListMock);

        String bodyAcd = '{"state": "disconnected", "wrapup: [{"code": "123", "name": "válida"}]}';
        Integer codeAcd = 200;
        GenesysCloud.PatchService.mock = new GenesysCloudMocks(bodyAcd, codeAcd);

        Test.startTest();
        salida=GenesysCloudBatchPatchInteractionAction.execute(combinedAcdListMock);
        Test.stopTest();

        System.assertEquals(2, salida.size());

        
    }

}