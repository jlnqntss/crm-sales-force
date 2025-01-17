/**
 * Test para la clase IntermediarySDMBatch
 *
 * @author nts (agonzalezisasi)
 * @date 05/07/2021
 */
@isTest
private with sharing class IntermediarySDMBatchTest
{
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     */
    @TestSetup
    private static void makeData() 
    {
        TestDataFactorySDM.IntermediarySetupData();
    }

    /**
     * Test del metodo execute del batch
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     */
    @isTest
    private static void execute()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');

        IntermediarySDMBatch batch = new IntermediarySDMBatch();
        // Preparamos la configuracion para el campo que nos interesa
        batch.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        batch.testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            SettingsSDM.ACR_ROL_MAINEMAIL, AccountsSelector.SDM_MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        // Comprobamos que se han asignado las Agrupaciones de Mediadores
        List<Account> result = [SELECT Id FROM Account WHERE Id IN :intermediaries AND ParentId != null];
        System.assertEquals(10, result.size(), 'Deberia haber 10 mediadores con el ParentId de la agrupacion rellenado');
        
        // Comprobamos que se han creado los Equipos de Cuenta para los mediadores
        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(10, atms.size(), 'Deberia haber 10 ATMs para los mediadores');

        // Comprobamos que se han creado los Equipos de Cuenta para la agrupacion
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        List<AccountTeamMember> atmsAgrupation = [
            SELECT Id FROM AccountTeamMember WHERE Account.RecordTypeId = :rtAgrupationId
        ];
        System.assertEquals(10, atmsAgrupation.size(), 'Deberia haber 10 ATMs para la agrupacion');

        // Comprobamos que se han creado las relaciones (ACR) correctamente
        String roleLabel = (new SettingsSDM()).getACRRoleLabel(SettingsSDM.ACR_ROL_MAINEMAIL);
        List<AccountContactRelation> acrs = [
            SELECT Id, Roles FROM AccountContactRelation 
            WHERE AccountId IN :intermediaries
            AND Roles includes(:roleLabel)
        ];
        System.assertEquals(10, acrs.size(), 'Deberia haber 10 ACRs');
    }

    @isTest
    private static void execute_ko()
    {
        String query = 'SELECT Id FROM Account';
        IntermediarySDMBatch batch = new IntermediarySDMBatch(query); // para cobertura
        batch.testUnknownError = true;

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'Deberia haber Error Logs');
    }

    @isTest
    private static void execute_ko_finish()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');
        delete intermediaries;

        IntermediarySDMBatch batch = new IntermediarySDMBatch();
        batch.testUnknownErrorFinish = true;

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
	private static void schedule() {
		Test.startTest();
        IntermediarySDMBatch.createStandardSchedule(null, null, null);
		Test.stopTest();
	}
}