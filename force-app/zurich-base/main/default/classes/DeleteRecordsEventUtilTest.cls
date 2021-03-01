@isTest
private class DeleteRecordsEventUtilTest {

    //IMPORTANTE: Se ha probado y validado con 18k de registros pero el test tarda 2min en ejecutar
    //así que se ha reducido el volumen para que tarde menos, pero se puede cambiar aquí para probar
    private static Integer numRecordsInsert = 9; //9000
    private static Integer numRecordsTotal = 18; //18000

    @TestSetup
    static void makeData()
    {
        List<Survey__c> surveys = new List<Survey__c>();
        for(Integer i = 0 ; i < numRecordsInsert; i++)
        {
            Survey__c survey = new Survey__c(InteractionId__c='uniqueId'+i, NumberOfQuestions__c=1, CanBeRemoved__c=true);
            surveys.add(survey);
        }
        insert surveys;
    }

    @isTest
    static void test_handleEvents_ok()
    {
        List<DeleteRecordsEvent__e> events = new List<DeleteRecordsEvent__e>();
        for(Integer j=0; j<2; j++)
        {
            DeleteRecordsEvent__e event = new DeleteRecordsEvent__e(ObjectName__c = 'Survey__c', Criteria__c = 'CanBeRemoved__c = true', LaunchedCount__c = 1);
            events.add(event);
        }

        Test.startTest(); //Como se han limpiado los límites se puede volver a insertar (límite de 10.000)
            List<Survey__c> surveys = new List<Survey__c>();
            for(Integer i = 0 ; i < numRecordsInsert; i++)
            {
                Survey__c survey = new Survey__c(InteractionId__c='2uniqueId'+i, NumberOfQuestions__c=1, CanBeRemoved__c=true);
                surveys.add(survey);
            }
            insert surveys;

            List<Survey__c> insertedSurveys = new List<Survey__c>();
            insertedSurveys = [SELECT Id FROM Survey__c];
            System.assertEquals(numRecordsTotal, insertedSurveys.size(), 'Deberían existir 18000 surveys');

            //Test
            EventBus.publish(events);
            Test.getEventBus().deliver(); //Importante para que se terminen de ejecutar los eventos encolados
        Test.stopTest();

        List<Survey__c> deletedSurveys = new List<Survey__c>();
        deletedSurveys = [SELECT Id FROM Survey__c];
        System.assertEquals(0, deletedSurveys.size(), 'Se deberían haber borrado todas las surveys');
    }

    @isTest
    static void test_handleEvents_ko()
    {
        List<DeleteRecordsEvent__e> events = new List<DeleteRecordsEvent__e>();
        for(Integer j=0; j<2; j++)
        {
            DeleteRecordsEvent__e event = new DeleteRecordsEvent__e(ObjectName__c = 'Survey__c', Criteria__c = 'CanBeRemoved__c = false', LaunchedCount__c = 1);
            events.add(event);
        }

        Test.startTest(); //Como se han limpiado los límites se puede volver a insertar (límite DML de 10.000)
            List<Survey__c> surveys = new List<Survey__c>();
            for(Integer i = 0 ; i < numRecordsInsert; i++)
            {
                Survey__c survey = new Survey__c(InteractionId__c='2uniqueId'+i, NumberOfQuestions__c=1, CanBeRemoved__c=true);
                surveys.add(survey);
            }
            insert surveys;

            List<Survey__c> insertedSurveys = new List<Survey__c>();
            insertedSurveys = [SELECT Id FROM Survey__c];
            System.assertEquals(numRecordsTotal, insertedSurveys.size(), 'Deberían existir 18000 surveys');

            //Test
            EventBus.publish(events);
            Test.getEventBus().deliver(); //Importante para que se terminen de ejecutar los eventos encolados
        Test.stopTest();

        List<Survey__c> deletedSurveys = new List<Survey__c>();
        deletedSurveys = [SELECT Id FROM Survey__c];
        System.assertEquals(numRecordsTotal, deletedSurveys.size(), 'No se deberían haber borrado surveys porque no cumplen la condición de la query');
    }

}
