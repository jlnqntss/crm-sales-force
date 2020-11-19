@isTest
public class GenesysCloudRouteEmailActionTest
{
    @isTest
    static void test_GenesysCloudRouteEmailAction_execute_ok()
    {
        // When
        // EmailMessage - Se necesita un mensaje de email que no enrute a través de PB.
        EmailMessage testMessage = new EmailMessage(
            Subject = 'test'
            );

        insert testMessage;

        // Datos petición
        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 200; //Se va a probar un retorno bueno

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<GenesysCloudRouteEmailAction.RouteEmailRequest> requests = new List<GenesysCloudRouteEmailAction.RouteEmailRequest>();

        GenesysCloudRouteEmailAction.RouteEmailRequest email = new GenesysCloudRouteEmailAction.RouteEmailRequest();

        email.queueId = 'debe ser null si hay flowID';
        email.flowId = 'debe ser null si hay queueId';
        email.skillIds = new List<String> {'skill1','skill2'};
        email.priority = 1;
        email.screenPopRecordId = 'recordID';
        email.subject = 'subjet';
        email.toName = 'toname';
        email.toAddress = 'toaddres';
        email.fromName = 'fromname';
        email.fromAddress = 'fromaddress';
        email.emailMessageId = testMessage.Id;
        requests.add(email);

        GenesysCloudRouteEmailAction.execute(requests);
        Test.stopTest();

        // Then
        // El email Message debe tener reflejado el interactionId
        List<EmailMessage> messages = [SELECT Id FROM EmailMessage WHERE GenesysInteractionId__c = '1JB9ZmJnCCKXlerwxAOZXC'];

        System.assertEquals(false, messages.isEmpty() );
        System.assertEquals(testMessage.Id, messages[0].Id, 'No coincide el email con el enrutado');
    }

    @isTest
    static void test_GenesysCloudRouteEmailAction_execute_ko()
    {
        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();

        GenesysCloudRouteEmailAction.execute(new List<GenesysCloudRouteEmailAction.RouteEmailRequest>
        {
            new GenesysCloudRouteEmailAction.RouteEmailRequest()
        });

        Test.stopTest();

        // Then
        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];

        System.assertEquals(false, errors.isEmpty(), 'No se han generado errores');
        System.assertEquals(GenesysCloud.ERROR_RESPONSE_SDK + 'null', errors[0].Message__c, 'El error logado no coincide');
    }
}