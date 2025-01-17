@isTest
private with sharing class GenesysCloudTest
{
    //#region RoutingService

    @isTest
    private static void test_GenesysCloudRoutingService_route_email_ok()
    {
		Test_Data__mdt testdata = Test_Data__mdt.getInstance('GenesysCloudRoutingService');
        String body = testdata.Data_Field_1__c;
		String mockId = testdata.Data_Field_2__c; 

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

        System.assertEquals(mockId, updatedEmail.interactionId); //ID que devuelve el mock
    }

    @isTest
    private static void test_GenesysCloudRoutingService_route_email_ko()
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
    private static void test_GenesysCloudRoutingService_route_emailList_ok()
    {
        // When
        String body = Test_Data__mdt.getInstance('GenesysCloudRoutingService').Data_Field_1__c;
		
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
        emails.add( email.clone() );

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
    private static void test_GenesysCloudRoutingService_route_emailList_ko()
    {
        // When
        String body = Test_Data__mdt.getInstance('GenesysCloudRoutingService').Data_Field_1__c;
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
        emails.add( email.clone() );

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
            Test_Data__mdt testData = Test_Data__mdt.getInstance('GenesysCloudRoutingService');
            for(Object result : results)
            {
                GenesysCloud.Email email = (GenesysCloud.Email) result;

                System.assertEquals(testData.Data_Field_2__c, email.interactionId);
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
    private static void test_GenesysCloudCallbacksService_create_callback_ok()
    {
        //Retrieve Test_Data__mdt throught SOQL to avoid getInstance longtext truncation
        Test_Data__mdt testData = [SELECT Data_Field_1__c, Data_Field_2__c FROM Test_Data__mdt WHERE DeveloperName = 'Genesys_Conversation' LIMIT 1];
        
        String body = testData.Data_Field_1__c;

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

        System.assertEquals(testData.Data_Field_2__c, updatedCallback.genesysId); //ID que devuelve el mock
    }

    @isTest
    private static void test_GenesysCloudCallbacksService_create_callback_ko()
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
    private static void test_GenesysCloudCallbacksService_create_callbackList_ok()
    {
        Test_Data__mdt testData = [SELECT Data_Field_1__c, Data_Field_2__c FROM Test_Data__mdt WHERE DeveloperName = 'Genesys_Conversation' LIMIT 1];
        
        // When
        String body = testData.Data_Field_1__c;
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
        callbacks.add( callback.clone() );

        // Test
        Test.startTest();
        GenesysCloud.CallbacksService.create( callbacks, new CreateAssertCallback() );//El assert está en CreateAssertCallback
        Test.stopTest();
    }

    @isTest
    private static void test_GenesysCloudCallbacksService_create_callbackList_ko()
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
        callbacks.add( callback.clone() );

        // Test
        Test.startTest();
        GenesysCloud.CallbacksService.create( callbacks, new CreateAssertCallback() );//El assert está en CreateAssertCallback
        Test.stopTest();
    }

    class CreateAssertCallback implements GenesysCloud.IAPICallback
    {
        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation');
            for(Object result : results)
            {
                
                GenesysCloud.Callback callback = (GenesysCloud.Callback) result;

                System.assertEquals(testData.Data_Field_2__c, callback.genesysId);
            }
        }

        public void onError(Exception error)
        {
            System.assertEquals(true, error instanceof GenesysCloud.CallbacksServiceException);
        }
    }
    
    @isTest
    private static void test_CallBacksService_cancel()
    {
        // Id de interaccion generado por Genesys
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Interaction');
        String interactionId = testData.Data_Field_1__c;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponse(interactionId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        GenesysCloud.CallbackCancel cmb = new GenesysCloud.CallbackCancel();
        cmb.genesysId = interactionId;

        Test.startTest();
        GenesysCloud.CallbackCancel c = GenesysCloud.CallbacksService.cancel(cmb);
        Test.stopTest();

        System.assertEquals(interactionId, c.genesysId, 'Deberia ser el mismo interactionId');
    }

    @isTest
    private static void test_CallBackService_cancelList()
    {
        // Id de interaccion generado por Genesys
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Interaction');
        String interactionId = testData.Data_Field_1__c;

        // Creamos el ContactRequest que provocaria la creacion del call me back en Genesys
        // Informamos el interactionId directamente aunque se informaria tras llamar a create en Genesys
        ContactRequest contactRequest = new ContactRequest(
            GenesysInteractionId__c= interactionId,
            Status= 'New'
        );
        insert contactRequest;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponse(interactionId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        // Generamos el objeto de cancelacion del callmeback
        GenesysCloud.CallbackCancel cmb = new GenesysCloud.CallbackCancel();
        cmb.genesysId = interactionId;

        // Preparamos el mapa de relacion entre callmeback y los contactRequest
        Map<GenesysCloud.CallbackCancel, String> callbacks = new Map<GenesysCloud.CallbackCancel, String>();
        callbacks.put(cmb, contactRequest.Id);

        Test.startTest();
        GenesysCloud.CallbacksService.cancel(
            new List<GenesysCloud.CallbackCancel>{cmb},
            new UpdateCallbackCancel(callbacks)
        );
        Test.stopTest();

        // Comprobamos que el callmeback se ha cancelado
        List<contactRequest> contactRequests = [
            SELECT Id FROM Contactrequest WHERE Id = :contactRequest.Id AND Status = 'Cancelled'
        ];
        System.assertEquals(1, contactRequests.size(), 'Deberia haber un ContactRequest con estado a Cancelado');
    }

    public class UpdateCallbackCancel implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.CallbackCancel, String> contactRequestIdsByCallback;

        public UpdateCallbackCancel(Map<GenesysCloud.CallbackCancel, String> contactRequestIdsByCallback)
        {
            this.contactRequestIdsByCallback = contactRequestIdsByCallback;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            
            List<ContactRequest> contactReqToUpdate = new List<ContactRequest>();

            for(Object result : results) {
                GenesysCloud.CallbackCancel callback = (GenesysCloud.CallbackCancel) result;
                String contactRequestId = contactRequestIdsByCallback.get(callback);
                
                contactReqToUpdate.add(
                    new ContactRequest(
                        Id= contactRequestId,
                        Status= 'Cancelled'
                    )
                );
                
            }

            if( !contactReqToUpdate.isEmpty() ) {
                update contactReqToUpdate;
            }
        }

        public void onError(Exception error)
        {
            
            ErrorLogUtil.commitError(error);
        }
    }

    @isTest
    private static void test_CallBackService_cancelList_ko()
    {
        // Id de interaccion generado por Genesys
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Interaction');
        String interactionId = testData.Data_Field_1__c;

        // Creamos el ContactRequest que provocaria la creacion del call me back en Genesys
        // Informamos el interactionId directamente aunque se informaria tras llamar a create en Genesys
        ContactRequest contactRequest = new ContactRequest(
            GenesysInteractionId__c= interactionId,
            Status= 'New'
        );
        insert contactRequest;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponseError(interactionId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        // Generamos el objeto de cancelacion del callmeback
        GenesysCloud.CallbackCancel cmb = new GenesysCloud.CallbackCancel();
        cmb.genesysId = interactionId;

        // Preparamos el mapa de relacion entre callmeback y los contactRequest
        Map<GenesysCloud.CallbackCancel, String> callbacks = new Map<GenesysCloud.CallbackCancel, String>();
        callbacks.put(cmb, contactRequest.Id);

        Test.startTest();
        GenesysCloud.CallbacksService.cancel(
            new List<GenesysCloud.CallbackCancel>{cmb},
            new UpdateCallbackCancel(callbacks)
        );
        Test.stopTest();

        // Comprobamos que el callmeback se ha cancelado
        List<contactRequest> contactRequests = [
            SELECT Id FROM Contactrequest WHERE Id = :contactRequest.Id AND Status = 'Cancelled'
        ];
        System.assertEquals(0, contactRequests.size(), 'Deberia NO haber un ContactRequest con estado a Cancelado');
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Deberia haber un Log de errores');
    }

    //#endregion

    //#region InteractionDisconnectService

    @isTest
    private static void test_DisconnectionService_close()
    {
        // Id de interaccion generado por Genesys
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Interaction');
        String interactionId = testData.Data_Field_1__c;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addInteractionDisconnectionMockResponse(interactionId);

        GenesysCloud.InteractionCancel cmb = new GenesysCloud.InteractionCancel();
        cmb.conversationId = interactionId;

        Test.startTest();
        GenesysCloud.DisconnectionService.mock = responsesMock;
        String returnedInteractionID = GenesysCloud.DisconnectionService.close(cmb);
        Test.stopTest();

        System.assertEquals(interactionId, returnedInteractionID, 'Deberia ser el mismo interactionId');
    }

    @isTest
    private static void test_DisconnectionService_cancelList()
    {
        // Id de interaccion generado por Genesys
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Interaction');
        String interactionId = testData.Data_Field_1__c;

        // Creamos el ContactRequest que provocaria la creacion del call me back en Genesys
        // Informamos el interactionId directamente aunque se informaria tras llamar a create en Genesys
        EmailMessage email = new EmailMessage(
            GenesysInteractionId__c= interactionId,
            Status= '3'
        );
        insert email;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addInteractionDisconnectionMockResponse(interactionId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        // Generamos el objeto de cancelacion del callmeback
        GenesysCloud.InteractionCancel cmb = new GenesysCloud.InteractionCancel();
        cmb.conversationId = interactionId;

        // Preparamos el mapa de relacion entre callmeback y los contactRequest
        Map<GenesysCloud.InteractionCancel, String> interactions = new Map<GenesysCloud.InteractionCancel, String>();
        interactions.put(cmb, email.Id);

        Test.startTest();
        GenesysCloud.DisconnectionService.close(
            new List<GenesysCloud.InteractionCancel>{cmb},
            new UpdateInteractionCancel(interactions)
        );
        Test.stopTest();

        // Comprobamos que el callmeback se ha cancelado
        List<EmailMessage> emailMessages = [
            SELECT Id, Status FROM EmailMessage WHERE Id = :email.Id
        ];

        
        System.assertEquals(1, emailMessages.size(), 'Deberia haber un EmailMessage que se haya modificado');
    }

    public class UpdateInteractionCancel implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.InteractionCancel, String> interactionIdsByCallback;

        public UpdateInteractionCancel(Map<GenesysCloud.InteractionCancel, String> interactionIdsByCallback)
        {
            this.interactionIdsByCallback = interactionIdsByCallback;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            
            List<EmailMessage> emailsToUpdate = new List<EmailMessage>();

            for(Object result : results) {
                GenesysCloud.InteractionCancel callback = (GenesysCloud.InteractionCancel) result;
                String interactionId = interactionIdsByCallback.get(callback);
                
                emailsToUpdate.add(
                    new EmailMessage(
                        Id= interactionId,
                        Status= '4'
                    )
                );
                
            }

            if( !emailsToUpdate.isEmpty() ) {
                update emailsToUpdate;
            }
        }

        public void onError(Exception error)
        {
            
            ErrorLogUtil.commitError(error);
        }
    }

    //#endregion

    //#region SMSService

    @isTest
    private static void test_GenesysCloudSMSService_send_ok()
    {
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation');
        String body = testData.Data_Field_3__c;
        Integer code = 202; //Se va a probar un retorno bueno

        //Set MOCK
        GenesysCloud.SMSService.mock = new GenesysCloudMocks(body, code);

        //montar SMS de prueba
        GenesysCloud.SmsData message = new GenesysCloud.SmsData();
        message.fromAddress = '+13178723000';
        message.toAddress = '+15557655942';
        message.textBody = 'hellow sms world';

        Test.startTest();
        GenesysCloud.SmsData updatedCallback = (GenesysCloud.SmsData) GenesysCloud.SMSService.send(message);
        Test.stopTest();

        System.assertEquals(testData.Data_Field_2__c, updatedCallback.smsId); //ID que devuelve el mock
    }

    @isTest
    private static void test_GenesysCloudSMSService_send_ko()
    {
        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        GenesysCloud.SMSService.mock = new GenesysCloudMocks(body, code);

        GenesysCloud.SmsData message = new GenesysCloud.SmsData();

        Test.startTest();
        try
        {
            GenesysCloud.SmsData updatedCallback = (GenesysCloud.SmsData) GenesysCloud.SMSService.send(message);
        }
        catch(GenesysCloud.SMSServiceException e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains(GenesysCloud.ERROR_RESPONSE_SDK) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }

    @isTest
    private static void test_GenesysCloudSMSService_sendList_ok()
    {
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation');
        String body = testData.Data_Field_3__c;
        Integer code = 202; //Se va a probar un retorno bueno

        //Set MOCK
        GenesysCloud.SMSService.mock = new GenesysCloudMocks(body, code);

        //montar SMSs de prueba
        List<GenesysCloud.SmsData> messages = new List<GenesysCloud.SmsData>();
        GenesysCloud.SmsData message = new GenesysCloud.SmsData();
        message.fromAddress = '+13178723000';
        message.toAddress = '+15557655942';
        message.textBody = 'hellow sms world';
        messages.add(message);
        messages.add( message.clone() );

        // Test
        Test.startTest();
        GenesysCloud.SMSService.send( messages, new SMSAssertCallback() );//El assert está en SMSAssertCallback
        Test.stopTest();
    }

    @isTest
    private static void test_GenesysCloudSMSService_sendList_ko()
    {
        // When
        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        //Set MOCK
        GenesysCloud.SMSService.mock = new GenesysCloudMocks(body, code);

        //montar SMSs de prueba
        List<GenesysCloud.SmsData> messages = new List<GenesysCloud.SmsData>();
        GenesysCloud.SmsData message = new GenesysCloud.SmsData();
        messages.add(message);
        for(Integer i=0; i < 50; i++)
        {
            messages.add( message.clone() );
        }

        // Test
        Test.startTest();
        GenesysCloud.SMSService.send( messages, new SMSAssertCallback() );//El assert está en SMSAssertCallback
        Test.stopTest();
    }

    class SMSAssertCallback implements GenesysCloud.IAPICallback
    {
        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation');
            for(Object result : results)
            {
                GenesysCloud.SmsData message = (GenesysCloud.SmsData) result;

                System.assertEquals(testData.Data_Field_2__c, message.smsId);
            }
        }

        public void onError(Exception error)
        {
            System.assertEquals(true, error instanceof GenesysCloud.SMSServiceException);
        }
    }

    //#endregion

    //#region CallsService

    @isTest
    private static void test_CallsService_getActive_ok()
    {
        // When
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();

        // Respuesta al getActive
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation_2');
        String conversationId = testData.Data_Field_1__c;

        responsesMock.addActiveConversationsMockResponse(conversationId);


        Test.setMock(HttpCalloutMock.class, responsesMock);

        // Test
        Test.startTest();

        GenesysCloud.Call[] activeCalls = GenesysCloud.CallsService.getActive();

        Test.stopTest();

        // Then
        System.assertEquals(1, activeCalls.size(), 'No se han devuelto llamadas');
        System.assertEquals(conversationId, activeCalls[0].id, 'No se han devuelto llamadas');
    }

    @isTest
    private static void test_CallsService_getActive_ko()
    {
        // When
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();

        // Respuesta al getActive
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation_2');
        String conversationId = testData.Data_Field_1__c;

        responsesMock.addRawMockResponse(
            'api/v2/conversations/calls',
            new GenesysCloudConversationsAPIMock.APIResponse(
                404,
                new Map<String, Object>
        {
            'message' => 'Not Found'
        }
                )
            );

        // Test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, responsesMock);
        GenesysCloud.GenesysCloudException expectedError;

        try
        {

            GenesysCloud.Call[] activeCalls = GenesysCloud.CallsService.getActive();
        }
        catch (GenesysCloud.GenesysCloudException error)
        {
            expectedError = error;
        }


        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha emitido excepción');
        System.assertEquals(true, expectedError.getMessage().contains('Not Found'), 'El mensaje no coincide');
    }

    @isTest
    private static void test_CallsService_ConferenceTo()
    {
        // Respuesta al getActive
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation_2');
        String conversationId = testData.Data_Field_1__c;

        Map<String, String> attributes = new Map<String, String>{
            'parentConversationId' => conversationId
        };

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addActiveConversationsMockResponse(conversationId);
        responsesMock.addParticipantMockResponse(conversationId);
        responsesMock.addUUIDMockResponse();
        responsesMock.addConsultMockResponse();
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();

        GenesysCloud.CallsService.conferenceTo('+349999999', attributes, true);

        Test.stopTest();

        // no hay asserts porque no devuelve nada el metodo

        // Para cobertura
        GenesysCloud.ConsultTransferDestination destination = new GenesysCloud.ConsultTransferDestination();
        String json = destination.toJSON();
    }

    @isTest
    private static void test_CallsService_getCall()
    {
        // Respuesta al getActive
        Test_Data__mdt conversationTestData = Test_Data__mdt.getInstance('Genesys_Conversation_2');
        Test_Data__mdt interactionTestData = Test_Data__mdt.getInstance('Genesys_Interaction');

        String interactionId =interactionTestData.Data_Field_1__c;
        String conversationId = conversationTestData.Data_Field_1__c;

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallMockResponse(interactionId, conversationId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();

        GenesysCloud.Call c = GenesysCloud.CallsService.get(interactionId);

        Test.stopTest();

        System.assertNotEquals(null, c, 'La llamada deberia existir');
        // para cobertura
        String json = c.toJSON();
        System.assertNotEquals(null, c.participants, 'Deberia haber participantes');
        System.assertNotEquals(true, c.participants.isEmpty(), 'Deberia haber algun participante');
        GenesysCloud.Participant p = c.participants[0];
        json = p.toJSON();
    }

    //#endregion

    @isTest
    private static void test_GenesysCloudValidateResponse_ko()
    {
        Test.startTest();
        try
        {
            GenesysCloud.validateResponse(null, null);
        }
        catch (Exception error)
        {
            System.assertEquals(true, error instanceof GenesysCloud.GenesysCloudException);
        }
        Test.stopTest();
    }

    /**
     * Método de test que prueba el método disconnectBulk
     * 
     * @author rserrano | 22/05/2024 
     **/
    @isTest
    private static void test_disconnectBulk()
    {
        
        Test_Data__mdt testData = Test_Data__mdt.getInstance('Genesys_Conversation');
        String body = testData.Data_Field_3__c;
        Integer code = 202;
 
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks(body, code);

        List<GenesysCloud.CallbackDisconnectIdentifier> callbackDisconnectIdentifierLst = new List<GenesysCloud.CallbackDisconnectIdentifier>();

        for(Integer i = 0; i < 10; i++)
        {
            GenesysCloud.CallbackDisconnectIdentifier callbackDisconnectIdentifier = new GenesysCloud.CallbackDisconnectIdentifier();
            callbackDisconnectIdentifier.conversationId = 'test';
            callbackDisconnectIdentifier.callbackId = 'test';
            callbackDisconnectIdentifierLst.add(callbackDisconnectIdentifier);
        }
        GenesysCloud.BulkCallbackDisconnectRequest bulkCallbackDisconnectRequest = new GenesysCloud.BulkCallbackDisconnectRequest();
        bulkCallbackDisconnectRequest.callbackDisconnectIdentifiers = callbackDisconnectIdentifierLst;

        Test.startTest();
        HttpResponse res = GenesysCloud.CallbacksService.disconnectBulk(bulkCallbackDisconnectRequest);
        Test.stopTest();

        Assert.areEqual('{"conversationId":"test","callbackId":"test"}', callbackDisconnectIdentifierLst[0].toJSON(), 'El JSON no se ha parseado correctamente.');
        Assert.areEqual(202, res.getStatusCode(), 'El código de estado no es igual al esperado.');
    }

    /**
     * Método de test que prueba el método getConversationDetails
     * 
     * @author fpalomo
     * @date 22/05/2024
     */
    @isTest
    private static void test_getConversationDetails()
    {
        GenesysCloud.AnalyticsSession session = new GenesysCloud.AnalyticsSession();
        session.callbackNumbers = new List<String>{'+34777666222'};
        session.callbackScheduledTime = '2024-05-30T11:14:00Z';
        session.direction = 'outbound';
        session.mediaType = 'callback';
        session.sessionId = '7e131fcf-1639-45b2-89e5-9c3787b5dc75';

        GenesysCloud.AnalyticsParticipantWithoutAttributes participant = new GenesysCloud.AnalyticsParticipantWithoutAttributes();
        participant.participantId = '613f1e3a-05ca-4bb2-acc1-1d29d6676437';
        participant.sessions = new List<GenesysCloud.AnalyticsSession>{session};

        GenesysCloud.AnalyticsConversationWithoutAttributes conversation = new GenesysCloud.AnalyticsConversationWithoutAttributes();
        conversation.conversationId = '20558e5f-9024-41c0-954a-b32acf2f8d7b';
        conversation.participants = new List<GenesysCloud.AnalyticsParticipantWithoutAttributes>{participant};

        GenesysCloud.AnalyticsResponseWrapper analyticsResponseMock = new GenesysCloud.AnalyticsResponseWrapper();
        analyticsResponseMock.conversations = new List<GenesysCloud.AnalyticsConversationWithoutAttributes>{conversation};

        String body = analyticsResponseMock.toJSON();
        Integer code = 200;
 
        GenesysCloud.AnalyticsService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        GenesysCloud.AnalyticsResponseWrapper analyticsResponse = GenesysCloud.AnalyticsService.getConversationDetails(new Set<String>{'20558e5f-9024-41c0-954a-b32acf2f8d7b'});
        Test.stopTest();
        
        Assert.areEqual(analyticsResponseMock.toJSON(), analyticsResponse.toJSON(), 'La respuesta recibida no es igual a la esperada.');
    }
}