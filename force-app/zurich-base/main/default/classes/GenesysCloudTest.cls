@isTest
private class GenesysCloudTest
{
    //#region RoutingService

    @isTest
    static void test_GenesysCloudRoutingService_route_email_ok()
    {

        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 200; //Se va a probar un retorno bueno

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        GenesysCloud.Email email = new GenesysCloud.Email();
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
        GenesysCloud.Email updatedEmail = (GenesysCloud.Email) GenesysCloud.RoutingService.route(email);
        Test.stopTest();

        System.assertEquals('1JB9ZmJnCCKXlerwxAOZXC', updatedEmail.interactionId); //ID que devuelve el mock
    }

    @isTest
    static void test_GenesysCloudRoutingService_route_email_ko()
    {

        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        GenesysCloud.Email email = new GenesysCloud.Email();
        try
        {
            GenesysCloud.Email updatedEmail = (GenesysCloud.Email) GenesysCloud.RoutingService.route(email);
        }
        catch(GenesysCloud.RoutingServiceException e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains(GenesysCloud.ERROR_RESPONSE_SDK) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }

    /**
     * Valida un OK en un enrutamiento masivo de mails
     *
     * @author jmartinezpisson
     * @date 17/11/2020
     */
    @isTest
    static void test_GenesysCloudRoutingService_route_emailList_ok()
    {
        // When
        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 200; //Se va a probar un retorno bueno

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);
        List<GenesysCloud.Email> emails = new List<GenesysCloud.Email>();

        GenesysCloud.Email email = new GenesysCloud.Email();
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

        emails.add(email);
        emails.add(email.clone() );

        // Test
        Test.startTest();

        GenesysCloud.RoutingService.route(
            emails,
            new RouteAssertCallback()// Then
            );

        Test.stopTest();
    }

    /**
     * Valida un KO en un enrutamiento masivo de mails
     *
     * @author jmartinezpisson
     * @date 17/11/2020
     */
    @isTest
    static void test_GenesysCloudRoutingService_route_emailList_ko()
    {
        // When
        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 400;

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);
        List<GenesysCloud.Email> emails = new List<GenesysCloud.Email>();

        GenesysCloud.Email email = new GenesysCloud.Email();
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

        emails.add(email);
        emails.add(email.clone() );

        // Test
        Test.startTest();

        GenesysCloud.RoutingService.route(
            emails,
            new RouteAssertCallback()// Then
            );

        Test.stopTest();
    }

    class RouteAssertCallback implements GenesysCloud.IAPICallback
    {
        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            for(Object result : results)
            {
                GenesysCloud.Email email = (GenesysCloud.Email) result;

                System.assertEquals('1JB9ZmJnCCKXlerwxAOZXC', email.interactionId);
            }
        }

        public void onError(Exception error)
        {
            System.assertEquals(true, error instanceof GenesysCloud.RoutingServiceException);
        }
    }

    //#endregion RoutingService

    //#region CallbacksService
    @isTest
    static void test_GenesysCloudCallbacksService_create_callback_ok()
    {
        String body = '{"conversation":{"id":"7e131fcf-1639-45b2-89e5-9c3787b5dc75","selfUri":"/api/v2/conversations/7e131fcf-1639-45b2-89e5-9c3787b5dc75"},' +
                      '"callbackIdentifiers":[{"type":"EXTERNAL","id":"4b005d83-8246-4eb5-a89c-3f948751632b"},{"type":"ACD","id":"9f359553-e45b-42c3-8420-99bb01582eb9"}]}';
        Integer code = 202; //Se va a probar un retorno bueno

        //Set MOCK
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        //montar Callback de prueba
        GenesysCloud.Callback callback = new GenesysCloud.Callback();
        GenesysCloud.CallbackRoutingData callbackRoutingData = new GenesysCloud.CallbackRoutingData();
        callbackRoutingData.queueId = '5abe8c3b-d894-490b-b41e-ce2ec1bab70a';
        callbackRoutingData.languageId = 'En-US';
        callbackRoutingData.priority = 1;
        callbackRoutingData.skillIds = new List<String> {'skill1','skill2'};
        callbackRoutingData.preferredAgentIds = new List<String> {'agent1','agent2'};
        callback.routingData = callbackRoutingData;
        callback.scriptId = 'id de script de genesys';
        callback.validateCallbackNumbers = false;
        callback.screenPopRecordId = 'Id del screenPop';
        callback.countryCode = 'ES';
        callback.callbackUserName = 'Noemi';
        callback.callbackNumbers = new List<String> {'123456789'};
        callback.callbackScheduledTime = System.now().addDays(10);

        Test.startTest();
        GenesysCloud.Callback updatedCallback = (GenesysCloud.Callback) GenesysCloud.CallbacksService.create(callback);
        Test.stopTest();

        System.assertEquals('7e131fcf-1639-45b2-89e5-9c3787b5dc75', updatedCallback.genesysId); //ID que devuelve el mock
    }

    @isTest
    static void test_GenesysCloudCallbacksService_create_callback_ko()
    {

        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        GenesysCloud.Callback callback = new GenesysCloud.Callback();

        Test.startTest();
        try
        {
            GenesysCloud.Callback updatedCallback = (GenesysCloud.Callback) GenesysCloud.CallbacksService.create(callback);
        }
        catch(GenesysCloud.CallbacksServiceException e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains(GenesysCloud.ERROR_RESPONSE_SDK) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }

    @isTest
    static void test_GenesysCloudCallbacksService_create_callbackList_ok()
    {
        // When
        String body = '{"conversation":{"id":"7e131fcf-1639-45b2-89e5-9c3787b5dc75","selfUri":"/api/v2/conversations/7e131fcf-1639-45b2-89e5-9c3787b5dc75"},' +
                      '"callbackIdentifiers":[{"type":"EXTERNAL","id":"4b005d83-8246-4eb5-a89c-3f948751632b"},{"type":"ACD","id":"9f359553-e45b-42c3-8420-99bb01582eb9"}]}';
        Integer code = 202; //Se va a probar un retorno bueno

        //Set MOCK
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        //montar Callbacks de prueba
        List<GenesysCloud.Callback> callbacks = new List<GenesysCloud.Callback>();
        GenesysCloud.Callback callback = new GenesysCloud.Callback();
        GenesysCloud.CallbackRoutingData callbackRoutingData = new GenesysCloud.CallbackRoutingData();
        callbackRoutingData.queueId = '5abe8c3b-d894-490b-b41e-ce2ec1bab70a';
        callbackRoutingData.languageId = 'En-US';
        callbackRoutingData.priority = 1;
        callbackRoutingData.skillIds = new List<String> {'skill1','skill2'};
        callbackRoutingData.preferredAgentIds = new List<String> {'agent1','agent2'};
        callback.routingData = callbackRoutingData;
        callback.scriptId = 'id de script de genesys';
        callback.validateCallbackNumbers = false;
        callback.screenPopRecordId = 'Id del screenPop';
        callback.countryCode = 'ES';
        callback.callbackUserName = 'Noemi';
        callback.callbackNumbers = new List<String> {'123456789'};
        callback.callbackScheduledTime = System.now().addDays(10);
        callbacks.add(callback);
        callbacks.add(callback.clone() );

        // Test
        Test.startTest();
        GenesysCloud.CallbacksService.create(callbacks, new CreateAssertCallback() );//El assert está en CreateAssertCallback
        Test.stopTest();
    }

    @isTest
    static void test_GenesysCloudCallbacksService_create_callbackList_ko()
    {
        // When
        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        //Set MOCK
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        //montar Callbacks de prueba
        List<GenesysCloud.Callback> callbacks = new List<GenesysCloud.Callback>();
        GenesysCloud.Callback callback = new GenesysCloud.Callback();
        callbacks.add(callback);
        callbacks.add(callback.clone() );

        // Test
        Test.startTest();
        GenesysCloud.CallbacksService.create(callbacks, new CreateAssertCallback() );//El assert está en CreateAssertCallback
        Test.stopTest();
    }

    class CreateAssertCallback implements GenesysCloud.IAPICallback
    {
        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            for(Object result : results)
            {
                GenesysCloud.Callback callback = (GenesysCloud.Callback) result;

                System.assertEquals('7e131fcf-1639-45b2-89e5-9c3787b5dc75', callback.genesysId);
            }
        }

        public void onError(Exception error)
        {
            System.assertEquals(true, error instanceof GenesysCloud.CallbacksServiceException);
        }
    }

    //#endregion
}