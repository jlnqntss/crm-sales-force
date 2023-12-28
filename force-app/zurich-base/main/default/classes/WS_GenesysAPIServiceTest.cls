/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 20-10-2021
 * @last modified by  : jjuaristi
**/
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
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, RecordsSelector.Scope.Z.name(), 'New', System.today().addDays(10), 1);
        insert opportunities;

        List<Task> tasks = TestDataFactory.generateInteractionTasks(10);
        tasks.get(0).WhatId = cases.get(0).Id; //Una task relacionada con un caso para los tests de DoPost_Survey
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
        testInteractionLog.scope = RecordsSelector.Scope.Z.name();

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

    /**
     * Valida la entrada al GET cuando algún parámetro es nulo
     **
     * @author jjuaristi    
     * @date 18/10/2021
     */
    @isTest
    static void test_doGet_nullsInSearchString()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/people';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('searchType', ' ');
        request.addParameter('filterBy', 'customers');
        request.addParameter('value', '77788899F');
        request.addParameter('legalEntity', 'gi');
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }

    /**
     * Valida la entrada al GET para el recurso /people
     **
     * @author adelgado
     * @date 27/01/2021
     */
    @isTest
    static void test_doGet_people_OK()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/people';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('scope', 'ccs');
        request.addParameter('searchType', 'document');
        request.addParameter('filterBy', 'customers');
        request.addParameter('value', '77788899F');
        request.addParameter('legalEntity', 'gi');


        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Valida la excepción lanzada al llamar al GET para el recurso /people
     **
     * @author jjuaristi
     * @date 20/10/2021
     */
    @isTest
    static void test_doGet_people_KO()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/people';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('scope', 'ccs');
        request.addParameter('value', '77788899F');
        request.addParameter('legalEntity', 'gi');


        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }

    /**
     * Valida la entrada al GET para el recurso /policies
     **
     * @author adelgado
     * @date 27/01/2021
     */
    @isTest
    static void test_doGet_policies_OK()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/policies';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('', '54456465');

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Valida la excepción lanzada al llamar al GET para el recurso /policies/
     **
     * @author jjuaristi
     * @date 20/10/2021
     */
    @isTest
    static void test_doGet_policies_KO()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        // La forma en la que está programado en servicio obliga a añadir la barra después de policies
        // para poder testear la excepción
        request.requestURI = '/genesys-cloud/v1/policies/';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }

    /**
     * Valida la entrada al GET para el recurso /claims
     **
     * @author adelgado
     * @date 27/01/2021
     */
    @isTest
    static void test_doGet_claims_OK()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/claims';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('searchType', 'claim_number');
        request.addParameter('searchTerm', '3435HTR');

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Valida la excepción lanzada al llamar al GET para el recurso /claims
     **
     * @author jjuaristi
     * @date 20/10/2021
     */
    @isTest
    static void test_doGet_claims_KO()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/claims';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }


    // #endregion

    // #region Test POST Surveys

    @isTest
    static void test_doPost_surveys_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.callOriginQueueId = 'genesys_call_queue_id';
        survey.surveyFlowId = 'genesys_survey_flow_name';
        survey.numberOfQuestions = 5;
        survey.questionId = '123456789-1';
        survey.questionType = 'ivr';
        survey.answer = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt'+
        'ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper'+
        'suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate'+
        'velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim'+
        'qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi';

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/surveys';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(survey));

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        List<Survey__c> createdSurvey = [SELECT Id, CaseId__c FROM Survey__c];
        List<SurveyResponse__c> createdResponse = [SELECT Id, Answer__c, LongAnswer__c FROM SurveyResponse__c];

        System.assertEquals(200, response.statusCode, 'Debería haer devuelto un 200-OK');
        System.assertEquals(1,createdSurvey.size(), 'Se debería haber creado 1 survey');
        System.assertEquals(1,createdResponse.size(), 'Se debería haber creado 1 survey response');
        System.assertNotEquals(null,createdSurvey[0].CaseId__c, 'Se debería haber enlazado con un Caso');//Es el caso que se añadió en CreateScenario()
        System.assertEquals(254,createdResponse[0].Answer__c.length(), 'El campo Answer debería tener el máximo de caracteres rellenos por el String.abbreviate(254)');
        System.assertEquals(survey.answer,createdResponse[0].LongAnswer__c, 'El campo LongAnswer debería contener la respuesta completa');
    }

    @isTest
    static void test_doPost_surveys_ko_invalidInput()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.callOriginQueueId = 'genesys_call_queue_id';
        survey.surveyFlowId = 'genesys_survey_flow_name';
        survey.numberOfQuestions = 5;
        survey.questionId = '123456789-1';
        survey.questionType = 'invalidInput';//solo permite ivr y asr de inputs
        //Falta answer que es campo obligatorio

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/surveys';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(survey));

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        List<Survey__c> createdSurvey = [SELECT Id, CaseId__c FROM Survey__c];
        List<SurveyResponse__c> createdResponse = [SELECT Id, Answer__c, LongAnswer__c FROM SurveyResponse__c];

        System.assertEquals(500, response.statusCode, 'Debería haer devuelto un 500');
        System.assertEquals(0,createdSurvey.size(), 'Se debería haber creado 0 survey');
        System.assertEquals(0,createdResponse.size(), 'Se debería haber creado 0 survey response');
    }

    @isTest
    static void test_doPost_surveys_ko_noExistTask()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'noExisteTaskConEsteCallObject';//Va a fallar porque no existe una task con este CallObject
        survey.callOriginQueueId = 'genesys_call_queue_id';
        survey.surveyFlowId = 'genesys_survey_flow_name';
        survey.numberOfQuestions = 5;

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/surveys';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(survey));

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doPost();
        Test.stopTest();

        // Then
        List<Survey__c> createdSurvey = [SELECT Id, CaseId__c FROM Survey__c];
        List<SurveyResponse__c> createdResponse = [SELECT Id, Answer__c, LongAnswer__c FROM SurveyResponse__c];

        System.assertEquals(500, response.statusCode, 'Debería haer devuelto un 500');
        System.assertEquals(0,createdSurvey.size(), 'Se debería haber creado 0 survey');
        System.assertEquals(0,createdResponse.size(), 'Se debería haber creado 0 survey response');
    }
    // #endregion

    @isTest
    static void test_doGet_digitalcustomer_ok()
    {
        //Creación de registros del modelo de datos de KLINC
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;
        Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = newMaster.Id
            );
        insert customer;
        //Generar 10 orders para que las querys devuelvan un listado
        List<Order> orders = TestDataFactory.generateOrdersKlinc(newMaster.Id, customer.Id, customer.CustomerNum__c, Label.PolicyGI, 10);
        insert orders;
        //FIN Creación de registros del modelo de datos de KLINC

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/digitalcustomer';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('searchType', 'document');
        request.addParameter('value', customer.DNI__c);

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Valida la excepción lanzada al llamar al GET para el recurso /digitalcustomer
     **
     * @author jjuaristi
     * @date 20/10/2021
     */
    @isTest
    static void test_doGet_digitalcustomer_ko()
    {
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestURI = '/genesys-cloud/v1/digitalcustomer';
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        request.addParameter('searchType', 'document');
        //request.addParameter('value', customer.DNI__c); Va a fallar porque falta un parámetro obligatorio

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WS_GenesysAPIService.doGet();
        Test.stopTest();

        // Then
        System.assertEquals(400, RestContext.response.statusCode);
    }
}