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
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;
        //Actualizar con los datos usados en los test
        contactPointPhones.get(0).TelephoneNumber = '123456789';
        update contactPointPhones.get(0);

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;
        //Actualizar con los datos usados en los test
        contactPointEmails.get(0).EmailAddress = 'nescudero@nts-solutions.com';
        update contactPointEmails.get(0);

        //se crea 1 caso para cada cuenta
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        //Se crea 1 opp para cada cuenta
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        List<Task> tasks = TestDataFactory.generateInteractionTasks(10);
        insert tasks;
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
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
        request.requestURI = '/genesys-cloud/v1/interactions/init';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf( JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        List<Task> createdTasks = [SELECT Id FROM Task];
        Set<Id> tasksIds = new Set<Id>();
        for(Task createdTask: createdTasks)
        {
            tasksIds.add(createdTask.Id);
        }

        GenesysInteractionsService.Interaction expectedInteraction = (GenesysInteractionsService.Interaction) JSON.deserialize(response.responseBody.toString(), GenesysInteractionsService.Interaction.class);

        System.assertEquals(true, tasksIds.contains(expectedInteraction.callLogId), 'Set should contains expectedInteraction.callLogId');
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
        request.requestBody = Blob.valueOf( JSON.serialize(testInteractionLog) );

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped( RestContext.response.responseBody.toString() );

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals( GenesysInteractionsService.MISSING_FIELDS_REQUIRED, (String) responseMap.get('message') );
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
        request.requestBody = Blob.valueOf( JSON.serialize(testInteractionLog) );

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
        request.requestBody = Blob.valueOf( JSON.serialize(testInteractionLog) );

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
