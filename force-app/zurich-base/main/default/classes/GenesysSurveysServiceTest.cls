@isTest(SeeAllData = false)
private without sharing class GenesysSurveysServiceTest {

    @testSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        //se crea 1 caso para cada cuenta
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        List<Task> tasks = TestDataFactory.generateInteractionTasks(10);
        tasks.get(0).WhatId = cases.get(0).Id; //Una task relacionada con un caso para los tests de DoPost_Survey
        insert tasks;
    }

    @isTest
    static void test_initSurvey_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        survey.answer = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt'+
        'ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper'+
        'suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate'+
        'velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim'+
        'qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi';

        Test.startTest();
        GenesysSurveysService.initSurvey(survey);
        Test.stopTest();

        // Then
        List<Survey__c> createdSurvey = [SELECT Id, CaseId__c FROM Survey__c];
        List<SurveyResponse__c> createdResponse = [SELECT Id, Answer__c, LongAnswer__c FROM SurveyResponse__c];

        System.assertEquals(1,createdSurvey.size(), 'Se debería haber creado 1 survey');
        System.assertEquals(1,createdResponse.size(), 'Se debería haber creado 1 survey response');
        System.assertNotEquals(null,createdSurvey[0].CaseId__c, 'Se debería haber enlazado con un Caso');//Es el caso que se añadió en CreateScenario()
        System.assertEquals(254,createdResponse[0].Answer__c.length(), 'El campo Answer debería tener el máximo de caracteres rellenos por el String.abbreviate(254)');
        System.assertEquals(survey.answer,createdResponse[0].LongAnswer__c, 'El campo LongAnswer debería contener la respuesta completa');
    }

    @isTest
    static void test_initSurvey_ko()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        //survey.fromId = '123456789';
        survey.interactionId = 'NoExisteLaTask';//va a fallar porque debería tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'invalidInput';
        //Va a fallar porque falta un input y otro es inválido

        GenesysSurveysService.GenesysSurveysServiceException expectedError;

        Test.startTest();
        try
        {
            GenesysSurveysService.initSurvey(survey);
        }
        catch(GenesysSurveysService.GenesysSurveysServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'Se debería haber lanzado una excepción');
    }

    @isTest
    static void test_checkMissingFields_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        survey.answer = '10';

        GenesysSurveysService.GenesysSurveysServiceException expectedError;

        Test.startTest();
        try
        {
            GenesysSurveysService.checkMissingFields(survey);
        }
        catch(GenesysSurveysService.GenesysSurveysServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        // Then
        System.assertEquals(null, expectedError, 'NO Se debería haber lanzado una excepción');
    }

    @isTest
    static void test_checkMissingFields_ko()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        //Va a fallar porque falta el parámetro answer que es obligatorio

        GenesysSurveysService.GenesysSurveysServiceException expectedError;

        Test.startTest();
        try
        {
            GenesysSurveysService.checkMissingFields(survey);
        }
        catch(GenesysSurveysService.GenesysSurveysServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'SI Se debería haber lanzado una excepción');
    }

    @isTest
    static void test_searchInteractionTask_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        survey.answer = '10';

        Test.startTest();
            Task interactionTask = GenesysSurveysService.searchInteractionTask(survey);
        Test.stopTest();

        // Then
        //No falla porque existe una Task cuyo CallObject es igual al Survey.InteractionId
        System.assertNotEquals(null, interactionTask, 'Se debería haber devuelto la Task');
        System.assertNotEquals(null, interactionTask.WhatId, 'Se debería haber devuelto la Task');
    }

    @isTest
    static void test_searchInteractionTask_ko()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'NoExisteLaTask';//va a fallar porque debería tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        survey.answer = '10';

        GenesysSurveysService.GenesysSurveysServiceException expectedError;
        Task interactionTask;

        Test.startTest();
        try
        {
            interactionTask = GenesysSurveysService.searchInteractionTask(survey);
        }
        catch(GenesysSurveysService.GenesysSurveysServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        // Then
        System.assertEquals(null, interactionTask, 'Se debería haber devuelto la Task vacía');
        System.assertNotEquals(null, expectedError, 'SI Se debería haber lanzado una excepción');
    }

    @isTest
    static void test_createSurveyResponse_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject
        survey.questionId = 'questionId0';
        survey.questionType = 'avr';
        survey.answer = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt'+
        'ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper'+
        'suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate'+
        'velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim'+
        'qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi';

        Test.startTest();
            SurveyResponse__c surveyResponse = GenesysSurveysService.createSurveyResponse(survey);
        Test.stopTest();

        // Then
        System.assertEquals(254,surveyResponse.Answer__c.length(), 'El campo Answer debería tener el máximo de caracteres rellenos por el String.abbreviate(254)');
        System.assertEquals(survey.answer,surveyResponse.LongAnswer__c, 'El campo LongAnswer debería contener la respuesta completa');
    }

    @isTest
    static void test_createSurvey_ok()
    {
        GenesysSurveysService.Survey survey = new GenesysSurveysService.Survey();

        survey.fromId = '123456789';
        survey.interactionId = 'ucid0';//tiene que tener lo mismo que Task.CallObject

        Test.startTest();
            Task interactionTask = GenesysSurveysService.searchInteractionTask(survey);
            Survey__c surveySF = GenesysSurveysService.createSurvey(survey, interactionTask);
        Test.stopTest();

        // Then
        System.assertEquals(interactionTask.WhatId, surveySF.CaseId__c, 'Se debería haber enlazado con un Caso');//Es el caso que se añadió en CreateScenario()
    }

}
