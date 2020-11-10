@isTest(SeeAllData = false)
private class WS_GenesysAPIServiceTest
{
    /**
     * creación de registros necesarios
     **
     * @author nescudero
     * @date 23/10/2020
     */
    @testSetup
    static void createScenario()
    {
        Account acc = new Account();
        acc.LastName = 'nescudero';
        acc.LegalEntity__pc = Label.GeneralInsurance;
        insert acc;

        ContactPointPhone cpp = new ContactPointPhone();
        cpp.ParentId = acc.Id;
        cpp.TelephoneNumber = '123456789';
        insert cpp;

        ContactPointEmail cpe = new ContactPointEmail();
        cpe.ParentId = acc.Id;
        cpe.EmailAddress = 'nescudero@nts-solutions.com';
        insert cpe;

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.Scope__c = 'General';
        insert opp;
    }

    /**POST
     * Prueba que se reciba una petición
     * y se responda correctamente lo esperado
     * @author nescudero
     * @date 26/10/2020
     */
    @isTest
    static void test_doPost()
    {
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults(new List<Id>(recordIds) );

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
        request.requestURI = '/genesys-cloud/v1/interactions/init';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        Task createdTask = [SELECT id FROM Task][0];

        GenesysInteractionsService.Interaction expectedInteraction = (GenesysInteractionsService.Interaction) JSON.deserialize(response.responseBody.toString(), GenesysInteractionsService.Interaction.class);

        System.assertEquals(createdTask.Id, expectedInteraction.callLogId);
        System.assertEquals(UserInfo.getUserEmail(), expectedInteraction.bestAgentId);
    }


    @isTest
    static void test_doPost_invalidInput_requiredFields()
    {
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
        request.requestURI = '/genesys-cloud/v1/interactions/init';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString() );

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals(GenesysInteractionsService.MISSING_FIELDS_REQUIRED, (String) responseMap.get('message') );
    }

    @isTest
    static void test_doPost_invalidVersion()
    {
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
        request.requestURI = '/genesys-cloud/asv/interactions/init';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void test_doPost_invalidContentType()
    {
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
        request.requestURI = '/genesys-cloud/v1/interactions/init';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }


    // #region Test GET Resources

    /**
     * Valida la entrada al GET
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @isTest
    static void test_doGet_noSearchString()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/people?searchType=phone';
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }

    // #endregion
}
