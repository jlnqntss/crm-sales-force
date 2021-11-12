/**
 * Test para la clase PlanComercialSDMBatch
 *
 * @author nts (agonzalezisasi)
 * @date 27/07/2021
 */
@isTest
private class PlanComercialSDMBatchTest
{
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @TestSetup
    static void makeData() 
    {
        TestDataFactorySDM.PlanComercialSetupData();
    }

    /**
     * Test del metodo execute del batch
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @isTest
    static void execute()
    {
        PlanComercialSDMBatch batch = new PlanComercialSDMBatch();

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        // Comprobacion del restulado -----------------------------------------
        List<PlanComercial__c> checkPlans = [
            SELECT Id, Actual_KPI__c FROM PlanComercial__c
            WHERE Actual_KPI__c != null
        ];
        System.assertEquals(4, checkPlans.size(), 'Deberia haber 4 planes');
    }

    /**
     * Test del error desconocido en el execute
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @isTest
    static void execute_ko()
    {
        String query = 'SELECT Id FROM Account';
        PlanComercialSDMBatch batch = new PlanComercialSDMBatch(query); // para cobertura
        batch.testUnknownError = true;

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'Deberia haber Error Logs');
    }
    
    /**
	 * Test of the batch scheduling
	 */
	@isTest 
	static void schedule() {
		Test.startTest();
        PlanComercialSDMBatch.createStandardSchedule(null, null, null);
		Test.stopTest();
	}
}