/**
 * @description       : Clase test para probar el Batch DeleteFollowUps
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-05-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class Batch_DeleteFollowUpsTest 
{
    public static final String TYPE_CAMPAIGN = 'Campaña';
    public static final String TYPE_FORMACION = 'Formación';
    public static final String ATM_ROL_RN = 'Responsable de Negocio';
    public static final String ATM_ROL_CV = 'Consultor Vida';

    @TestSetup
    public static void createScenario()
    {
        List<Account> intermediaryAccount = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, 1
        );
        insert intermediaryAccount;

        Set<Id> idsIntermediaries = new Map<Id,Account>(intermediaryAccount).keySet();

        List<FollowUp__c> seguimientoCampaing = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_CAMPAIGN,ATM_ROL_RN+';'+ATM_ROL_CV);
        List<FollowUp__c> seguimientoFormacion = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CV);

        insert seguimientoCampaing;
        insert seguimientoFormacion;
    }

     /**
     * Comprueba si el batch elimina correctamente los seguimientos del tipo indicado y cuya fecha de creación sea anterior al día de hoy
     */
    @isTest 
    static void test_DeleteFollowUpCampaing()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c  ];
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(seguimientos[0].Id, yesterday);
        Test.setCreatedDate(seguimientos[1].Id, yesterday);

        Integer numFollowupTypeCampaignBefore = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);
        Integer numFollowupTypeFormacionBefore = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_FORMACION);

        Test.startTest(); 
        Batch_DeleteFollowUps batchDeleteFollowUps = new Batch_DeleteFollowUps(TYPE_CAMPAIGN);
        database.executeBatch(batchDeleteFollowUps, 200);
        Test.stopTest();

        Integer numFollowupTypeCampaignAfter= new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);
        Integer numFollowupTypeFormacionAfter = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_FORMACION);

        System.assertEquals(1, numFollowupTypeCampaignBefore, 'Debe haber un seguimientos de tipo campaña creado antes de la fecha de hoy');
        System.assertEquals(numFollowupTypeFormacionBefore, numFollowupTypeFormacionAfter, 'No se debe haber borrado ningún seguimiento de tipo formación');
        System.assertEquals(0, numFollowupTypeCampaignAfter, 'Se debe haber eliminado el seguimiento de tipo campaña');
        
    }

     /**
     * Comprueba si existe algún error al borrar un seguimiento, escribe un log 
     */
    @isTest 
    static void test_ErrorInDelete()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c where Type__c =:TYPE_CAMPAIGN  ]; 
        delete seguimientos;

        Test.startTest(); 
        Batch_DeleteFollowUps batchDeleteFollowUps = new Batch_DeleteFollowUps();
        batchDeleteFollowUps.execute(null,seguimientos);   
        Test.stopTest();

        List<Error_Log__c> error = [select id,Message__c from Error_Log__c ];
        System.assertEquals(1, error.size(), 'Debería haber escrito un error');
        System.assertEquals('Se ha producido un error borrando seguimientos', error[0].Message__c, 'Debería haber escrito correctamente el mensaje de error');

    }
}