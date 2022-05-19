/**
 * Clases de test para Batch_UpdateSurvey
 **
 * @author aberuete
 * @date 04/05/2022
 */
@isTest
private class Batch_UpdateSurveyTest
{

    /**
     * Create test data
     **
     * @author aberuete
     * @date 04/05/2022
     */
    @TestSetup
    static void makeData()
    {
        List<Survey__c> surveys = Test.loadData(Survey__c.sObjectType, 'TestSurvey');
        List<Survey__c> s = new List<Survey__c>();

        for(Integer i = 1; i <= 5; i++)
        {
            s.add(
                new Survey__c(
                    CanBeRemoved__c = false
                )
            );

        }
        insert s;
    }

    /**
     * Comprobar que el batch actualiza todos los registros de encuestas cuya última actualización sea antes del número de días indicado en el metadato personalizado 
     * *
     * @author aberuete
     * @date 05/05/2022
     */
    @isTest
    static void test_UpdateSurvey()
    {
        String SURVEY_NUMBER_DAYS_RETENTION_LABEL = 'SurveyNumberDaysRetention';
        AdminSetupParameter__mdt valueAdminSetupParameter = AdminSetupParameter__mdt.getInstance(SURVEY_NUMBER_DAYS_RETENTION_LABEL);
        System.assertNotEquals(null, valueAdminSetupParameter.Value__c, 'Metadato No existe');

        Integer numSurveyPreBatch = new SurveySelector().count(0,false);

        Test.startTest();
        database.executeBatch(new Batch_UpdateSurvey(), 200);
        Test.stopTest();

        Integer numSurveyAfterBatchUpdated = new SurveySelector().count(0,true);
    
        System.assertEquals(numSurveyPreBatch,199,'Error encuestas a actualizar');
        System.assertEquals(numSurveyAfterBatchUpdated,194,'Error batch');
    }

     /**
     * Comprobar la programación del batch sin pasar una query como parámetro
     * *
     * @author aberuete
     * @date 04/05/2022
     */
    @isTest
    static void testBatch_schedule_noQuery()
    {
        String SURVEY_NUMBER_DAYS_RETENTION_LABEL = 'SurveyNumberDaysRetention';
        AdminSetupParameter__mdt valueAdminSetupParameter = AdminSetupParameter__mdt.getInstance(SURVEY_NUMBER_DAYS_RETENTION_LABEL);
        System.assertNotEquals(null, valueAdminSetupParameter.Value__c, 'Metadato No existe');
        
        Test.startTest();
        String jobID = system.schedule( 'Update Survey Test', '20 30 8 10 2 ?', new Batch_UpdateSurvey() );
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

    /**
     * Comprobar la programación del batch pasando una query como parámetro
     * *
     * @author aberuete
     * @date 04/05/2022
     */
    @isTest
    static void testBatch_schedule_customQuery()
    {
        String SURVEY_NUMBER_DAYS_RETENTION_LABEL = 'SurveyNumberDaysRetention';
        AdminSetupParameter__mdt valueAdminSetupParameter = AdminSetupParameter__mdt.getInstance(SURVEY_NUMBER_DAYS_RETENTION_LABEL);
        System.assertNotEquals(null, valueAdminSetupParameter.Value__c, 'Metadato No existe');
        Integer daysRetentionSurvey = integer.valueof(valueAdminSetupParameter.Value__c);

        Test.startTest();
        String jobID = system.schedule( 'Update Survey Test', '20 30 8 10 2 ?', new Batch_UpdateSurvey(new SurveySelector().getQueryLastModifiedDateAfterThan(daysRetentionSurvey)));
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }
    
    /**
     * Comprobar la programación del batch 
     * *
     * @author aberuete
     * @date 04/05/2022
     */
    @isTest
    static void testBatch_scheduleUpdateSurveyOCS()
    {
        String SURVEY_NUMBER_DAYS_RETENTION_LABEL = 'SurveyNumberDaysRetention';
        AdminSetupParameter__mdt valueAdminSetupParameter = AdminSetupParameter__mdt.getInstance(SURVEY_NUMBER_DAYS_RETENTION_LABEL);
        System.assertNotEquals(null, valueAdminSetupParameter.Value__c, 'Metadato No existe');

        Test.startTest();
        String jobID = Batch_UpdateSurvey.scheduleSurveyUpdateOCS();
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }
}