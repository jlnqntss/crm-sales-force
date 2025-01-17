@isTest
private with sharing class GenesysCloudRouteEmailActionTest
{
    @isTest
    private static void test_GenesysCloudRouteEmailAction_execute_ok()
    {
        List<purecloud__PureCloud_Queue__c> queues = new List<purecloud__PureCloud_Queue__c>();
        queues = TestDataFactory.generateGenesysQueues(1);
        insert queues;

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

        email.queueId = queues[0].Name;
        //email.flowId = 'debe ser null si hay queueId';
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
    private static void test_GenesysCloudRouteEmailAction_execute_ko()
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
        System.assertEquals(true, errors[0].Message__c.contains(GenesysCloud.ERROR_RESPONSE_SDK), 'El error logado no coincide');
    }
}