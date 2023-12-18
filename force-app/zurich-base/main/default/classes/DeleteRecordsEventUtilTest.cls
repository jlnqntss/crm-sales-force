/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 04-03-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class DeleteRecordsEventUtilTest 
{
    static final String CRITERIA_QUERY =  'CanBeRemoved__c = true';
    //IMPORTANTE: Se ha probado y validado con 18k de registros pero el test tarda 2min en ejecutar
    //así que se ha reducido el volumen para que tarde menos, pero se puede cambiar aquí para probar
    private static Integer numRecordsInsert = 9; //9000
    private static Integer numRecordsTotal = 18; //18000 

    @TestSetup
    private static void makeData()
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
    private static void test_handleEvents_ok()
    {
        List<DeleteRecordsEvent__e> events = new List<DeleteRecordsEvent__e>();
        for(Integer j=0; j<2; j++)
        {
            DeleteRecordsEvent__e event = new DeleteRecordsEvent__e(ObjectName__c = 'Survey__c', Criteria__c = CRITERIA_QUERY, LaunchedCount__c = 1);
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
    private static void test_handleEvents_ko()
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

    /**
     * Test que comprueba que si hay más de un registro a borrar se pública el evento a borrar los registros
     * @author aberuete
     * @date 03/04/2023
     */
    @isTest
    private static void test_ifNumEventsGreaterThanOneRelaunchEvents()
    {
        List<DeleteRecordsEvent__e> events = new List<DeleteRecordsEvent__e>();
        for(Integer j=0; j<2; j++)
        {
            DeleteRecordsEvent__e event = new DeleteRecordsEvent__e(ObjectName__c = 'Survey__c', Criteria__c = CRITERIA_QUERY, LaunchedCount__c = 1);
            events.add(event);
        } 
        List<Survey__c> surveyBefore = [Select id from Survey__c where CanBeRemoved__c = true ];

        Test.startTest();
        DeleteRecordsEventUtil.ifNumEventsGreaterThanOneRelaunchEvents (events);
        Test.stopTest();

        List<Survey__c> surveyAfter = [Select id from Survey__c where CanBeRemoved__c = true ];

        System.assertEquals(9, surveyBefore.size(), 'El número de encuentas ha borrar debe ser nueve');
        System.assertEquals(0, surveyAfter.size(), 'El evento se debería haber publicado y lanzado el borrado de todas las encuestas');
        
    }

    /**
     * Test que comprueba que la query para obtener los registros a borrar se forma correctamente
     * @author aberuete
     * @date 03/04/2023
     */
    @isTest
    private static void test_getQueryToDeleteRecords()
    {
        List<DeleteRecordsEvent__e> events = new List<DeleteRecordsEvent__e>();
        for(Integer j=0; j<2; j++)
        {
            DeleteRecordsEvent__e event = new DeleteRecordsEvent__e(ObjectName__c = 'Survey__c', Criteria__c = CRITERIA_QUERY, LaunchedCount__c = 1);
            events.add(event);
        } 

        Test.startTest();
        String query = DeleteRecordsEventUtil.getQueryToDeleteRecords(events[0],events.size());
        Test.stopTest();
        
        List<Survey__c> surveys = Database.query(query);

        System.assertEquals(numRecordsInsert, surveys.size(),'Debe haber obtenido nueve encuestas');
    }
}
