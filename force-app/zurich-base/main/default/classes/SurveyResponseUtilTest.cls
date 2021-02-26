@isTest(SeeAllData = false)
private class SurveyResponseUtilTest {

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

    /**
     * Comprueba si al insertar respuestas se recalcula la cabecera
     */
    @isTest
    static void test_processAnswers_ok()
    {
        //Crear la cabecera
        Survey__c survey = new Survey__c(InteractionId__c = '01', NumberOfQuestions__c = 3);
        insert survey;

        //Crear respuestas
        SurveyResponse__c response1 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-1', QuestionType__c = 'ivr', Answer__c = '10');
        SurveyResponse__c response2 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-2', QuestionType__c = 'asr', LongAnswer__c = 'hola');
        SurveyResponse__c response3 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-3', QuestionType__c = 'ivr', Answer__c = '1');
        SurveyResponse__c response4 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-4', QuestionType__c = 'ivr');
        List<SurveyResponse__c> responses = new List<SurveyResponse__c>();
        responses.add(response1);
        responses.add(response2);
        responses.add(response3);
        responses.add(response4);
        insert responses;

        //Comprobación Insert
        Survey__c checkSurvey1 = [SELECT Id, ShortAnswersProcessed__c, LongAnswerProcessed__c FROM Survey__c WHERE Id = :survey.Id];
        System.assertEquals('hola', checkSurvey1.LongAnswerProcessed__c, 'Debería rellenarse con el contenido de la asr');
        System.assertEquals('10;1;NULL;', checkSurvey1.ShortAnswersProcessed__c, 'Debería rellenarse con el esquema de las ivr 10;1;NULL;');

        //Actualizar
        response2.QuestionType__c = 'ivr';
        update response2;

        //Comprobación Update
        Survey__c checkSurvey2 = [SELECT Id, ShortAnswersProcessed__c, LongAnswerProcessed__c FROM Survey__c WHERE Id = :survey.Id];
        System.assertEquals(null, checkSurvey2.LongAnswerProcessed__c, 'Debería haberse vaciado porque ya no hay asr');
        System.assertEquals('10;NULL;1;NULL;', checkSurvey2.ShortAnswersProcessed__c, 'Debería rellenarse con el esquema de las ivr 10;NULL;1;NULL;');

        //Preparar una actualización y una insercción
        response1.QuestionType__c = 'asr';
        response1.LongAnswer__c = 'response1';
        SurveyResponse__c response5 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-5', QuestionType__c = 'ivr', Answer__c = '5');
        List<SurveyResponse__c> responses2 = new List<SurveyResponse__c>();
        responses2.add(response5);
        responses2.add(response1);
        upsert responses2;

        //Comprobación Upsert
        Survey__c checkSurvey3 = [SELECT Id, ShortAnswersProcessed__c, LongAnswerProcessed__c FROM Survey__c WHERE Id = :survey.Id];
        System.assertEquals('response1', checkSurvey3.LongAnswerProcessed__c, 'Debería haberse actualizado con la asr');
        System.assertEquals('NULL;1;NULL;5;', checkSurvey3.ShortAnswersProcessed__c, 'Debería rellenarse con el esquema de las ivr NULL;1;NULL;5;');
    }


    /**
     * Comprueba si se actualizan varias Surveys a la vez
     */
    @isTest
    static void test_processAnswers_surveys_ok()
    {
        //Crear la cabecera
        Survey__c survey = new Survey__c(InteractionId__c = '01', NumberOfQuestions__c = 1);
        insert survey;
        Survey__c survey2 = new Survey__c(InteractionId__c = '02', NumberOfQuestions__c = 2);
        insert survey2;

        //Crear respuestas
        SurveyResponse__c response1 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-1', QuestionType__c = 'ivr', Answer__c = '10');
        SurveyResponse__c response2 = new SurveyResponse__c(SurveyId__c = survey.Id, QuestionId__c = '01-2', QuestionType__c = 'asr', LongAnswer__c = 'hola');
        SurveyResponse__c response3 = new SurveyResponse__c(SurveyId__c = survey2.Id, QuestionId__c = '02-1', QuestionType__c = 'ivr', Answer__c = '1');
        SurveyResponse__c response4 = new SurveyResponse__c(SurveyId__c = survey2.Id, QuestionId__c = '02-2', QuestionType__c = 'ivr');
        List<SurveyResponse__c> responses = new List<SurveyResponse__c>();
        responses.add(response1);
        responses.add(response2);
        responses.add(response3);
        responses.add(response4);
        insert responses;

        //Comprobación Survey1
        Survey__c checkSurvey1 = [SELECT Id, ShortAnswersProcessed__c, LongAnswerProcessed__c FROM Survey__c WHERE Id = :survey.Id];
        System.assertEquals('hola', checkSurvey1.LongAnswerProcessed__c, 'Debería rellenarse con el contenido de la asr');
        System.assertEquals('10;', checkSurvey1.ShortAnswersProcessed__c, 'Debería rellenarse con el esquema de las ivr 10;');

        //Comprobación Survey2
        Survey__c checkSurvey2 = [SELECT Id, ShortAnswersProcessed__c, LongAnswerProcessed__c FROM Survey__c WHERE Id = :survey2.Id];
        System.assertEquals(null, checkSurvey2.LongAnswerProcessed__c, 'Debería rellenarse con el contenido de la asr');
        System.assertEquals('1;NULL;', checkSurvey2.ShortAnswersProcessed__c, 'Debería rellenarse con el esquema de las ivr 1;NULL;');
    }
}
