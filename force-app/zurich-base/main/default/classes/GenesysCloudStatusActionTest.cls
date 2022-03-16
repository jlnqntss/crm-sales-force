@isTest
public with sharing class GenesysCloudStatusActionTest
{
    @isTest
    static void test_genesysCloudStatusActionTest_status_ok()
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
        emailMessage.GenesysInteractionId__c = '1111AAAA';
        insert emailMessage;

        List<EmailMessage> listaTemp = new List<EmailMessage>();
        listaTemp.add(emailMessage);

        List<List<EmailMessage> > listaInput = new List<List<EmailMessage> >();
        listaInput.add(listaTemp);

        System.debug('+++++ ' + listaTemp);
        System.debug('+++++ ' + listaInput);
        String body = '{"id": "1788029f-ad65-41ea-bc5f-ce41673fe109",'
                      + '"participants": [{"id": "20714c8e-9a60-4efd-9e75-0efb4b95267f","name": "Javier García Martínez", "purpose": "customer", "state": "disconnected"},'
                      + '{"id": "25fcb71d-9ff3-4c45-8a07-091831376cdd", "name": "Email_CCS_Soporte", "purpose": "acd", "state": "connected"},'
                      + '{"id": "77f648d0-354f-4d07-8540-14604b87bffc", "name": "Agente1","purpose": "agent","state": "disconnected"}]}';
        Integer code = 200;
        GenesysCloud.StatusService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<List<String> > inserciones = GenesysCloudStatusAction.execute(listaInput);
        Test.stopTest();

        List<String> listaStatus = new List<String>();
        if (inserciones.size() > 0)
        {
            listaStatus = inserciones.get(0);
        }

        System.assertEquals( 1, listaStatus.size() );
    }
}