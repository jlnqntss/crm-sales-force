@isTest
public with sharing class GenesysCloudEmailStatusActionTest
{
    @isTest
    static void test_genesysCloudEmailStatusActionTest_ok()
    {
        //creamos el caso y el email relacionado
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3';
        emailMessage.ParentId = relatedCase.Id;
        emailMessage.FromAddress = 'jgarciamartinez@nts-solutions.com';
        emailMessage.FromName = 'Javi Garcia';
        emailMessage.Subject = 'Prueba';
        emailMessage.GenesysInteractionId__c = '1788029f-ad65-41ea-bc5f-ce41673fe109';
        insert emailMessage;

        List<EmailMessage> listaTemp = new List<EmailMessage>();
        listaTemp.add(emailMessage);

        List<List<EmailMessage> > listaInput = new List<List<EmailMessage> >();
        listaInput.add(listaTemp);

        Test.startTest();
        List<List<String>> inserciones = GenesysCloudEmailStatusAction.execute(listaInput);
        Test.stopTest();

        List<String> listaStatus = new List<String>();
        if (inserciones.size() > 0)
        {
            listaStatus = inserciones.get(0);
        }

        System.assertEquals( 1, listaStatus.size() );
    }
}