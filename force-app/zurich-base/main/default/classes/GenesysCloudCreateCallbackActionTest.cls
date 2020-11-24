@isTest
public class GenesysCloudCreateCallbackActionTest
{
    @isTest
    static void test_GenesysCloudCreateCallbackAction_execute_ok()
    {
        // When
        // ContactRequest - Se necesita un ContactRequest que no enrute a través de PB.
        ContactRequest cr = new ContactRequest();
        insert cr;

        // Datos petición
        String body = '{"conversation":{"id":"7e131fcf-1639-45b2-89e5-9c3787b5dc75","selfUri":"/api/v2/conversations/7e131fcf-1639-45b2-89e5-9c3787b5dc75"},'+
        '"callbackIdentifiers":[{"type":"EXTERNAL","id":"4b005d83-8246-4eb5-a89c-3f948751632b"},{"type":"ACD","id":"9f359553-e45b-42c3-8420-99bb01582eb9"}]}';
        Integer code = 202; //Se va a probar un retorno bueno

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<GenesysCloudCreateCallbackAction.CreateCallbackRequest> requests = new List<GenesysCloudCreateCallbackAction.CreateCallbackRequest>();
        GenesysCloudCreateCallbackAction.CreateCallbackRequest request = new GenesysCloudCreateCallbackAction.CreateCallbackRequest();
        request.activityId = cr.Id;
        request.queueId = '5abe8c3b-d894-490b-b41e-ce2ec1bab70a';
        request.callbackUserName = 'Noemi2';
        request.callbackNumbers = '123456789';
        request.languageId = 'En-US';
        request.priority = 1;
        request.skills = new List<String> {'skill1','skill2'};
        request.preferredAgentIds = new List<String> {'agent1','agent2'};
        request.scriptId = 'Ide de script de genesys';
        request.callbackScheduledTime = System.now().addDays(10);
        request.countryCode = 'ES';
        request.screenPopRecordId = 'Id del registro a ahcer screenPop';
        requests.add(request);

        GenesysCloudCreateCallbackAction.execute(requests);
        Test.stopTest();

        // Then
        // El ContactRequest debe tener reflejado el Genesys Interaction Id
        List<ContactRequest> crs = [SELECT Id FROM ContactRequest WHERE GenesysInteractionId__c = '7e131fcf-1639-45b2-89e5-9c3787b5dc75'];
        System.assertEquals(false, crs.isEmpty());
        System.assertEquals(cr.Id, crs[0].Id, 'No coincide el ContactRequest con el enrutado');
    }

    @isTest
    static void test_GenesysCloudCreateCallbackAction_execute_ko()
    {
        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();

        GenesysCloudCreateCallbackAction.execute(new List<GenesysCloudCreateCallbackAction.CreateCallbackRequest>{new GenesysCloudCreateCallbackAction.CreateCallbackRequest()});

        Test.stopTest();

        // Then
        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];

        System.assertEquals(false, errors.isEmpty(), 'No se han generado errores');
        System.assertEquals(GenesysCloud.ERROR_RESPONSE_SDK + code + ' null', errors[0].Message__c, 'El error logado no coincide');
    }
}