@isTest
public class GenesysCloudDisconnectionActionTest {
    @isTest
    static void test_genesysCloudDisconnectionActionTest_disconnection_ok()
    {
        // Creamos el caso y el email relacionado
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'arcortazar@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';
        emailMessage.GenesysInteractionId__c = '1234ABCD';
        insert emailMessage;

        List<EmailMessage> listaTemp = new List<EmailMessage>();
        listaTemp.add(emailMessage);

        List<List<EmailMessage>> listaInput = new List<List<EmailMessage>>();
        listaInput.add(listaTemp);

        // Creamos el mock
        String body = '{"conversionId":"1234ABCD"}';
        Integer code = 200; //Se crea la interacción en Genesys Cloud.
        GenesysCloud.DisconnectionService.mock = new GenesysCloudMocks(JSON.serialize(body), code);
        
        Test.startTest();
        List<List<String>> inserciones = GenesysCloudDisconnectionAction.execute(listaInput);
        Test.stopTest();

        
        List<String> listaStatus = inserciones.get(0);
        System.assertEquals(1, listaStatus.size(), 'Se ha debido de insertar un evento');
    }
}
