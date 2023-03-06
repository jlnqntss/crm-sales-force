/**
 * @description       : Clase de test para la clase selectora del sobject FollowUp
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class FollowUpSelectorTest 
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

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_CAMPAIGN,ATM_ROL_RN+';'+ATM_ROL_CV);
        insert seguimientos;
    }

    /**
     * Test que comprueba que se obtiene correctamente los seguimientos creados en el mismo día
     */
    @isTest 
    static void test_findByTypeCreatedDateTodayAndProccessed()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CV);

        Test.startTest();
        insert seguimientos;
        String query = new FollowUpSelector().findByTypeCreatedDateTodayAndProccessed(TYPE_FORMACION, false);
        List<FollowUp__c> seguimientosReturn = Database.query (query);
        Test.stopTest();
        
        System.assertEquals(1, seguimientosReturn.size(),'Se debería de obtener un seguimiento de tipo formación');
    }

     /**
     * Test que comprueba que se devuelven seguimientos si han sido creados en días anteriores a hoy y son del mismo tipo
     */
    @isTest 
    static void test_findByTypeAndCreatedDateLessThanToday()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c where Type__c =:TYPE_CAMPAIGN ];
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(seguimientos[0].Id, yesterday);

        Test.startTest();
        String query = new FollowUpSelector().findByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);
        List<FollowUp__c> seguimientosReturn = Database.query (query);
        Test.stopTest();

        System.assertEquals(1, seguimientosReturn.size(),'Debería devolver un seguimiento');
    }

    /**
     * Test que comprueba que no se devuelven seguimientos si han sido creados en días anteriores pero no son del mismo tipo
     */
    @isTest 
    static void test_findByType()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c where Type__c =:TYPE_CAMPAIGN ];
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(seguimientos[0].Id, yesterday);

        Test.startTest();
        String query = new FollowUpSelector().findByTypeAndCreatedDateLessThanToday(TYPE_FORMACION);
        List<FollowUp__c> seguimientosReturn = Database.query (query);
        Test.stopTest();

        System.assertEquals(0, seguimientosReturn.size(),'No debería devolver ningún seguimiento ya que no existe ningún resgistro de ese tipo');
    }

    /**
     * Test que comprueba que se devuelve correctamente el número de seguimientos que hay de un tipo y creados en una fecha anterior a hoy
     */
    @isTest 
    static void test_countFollowUpToDelete()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c where Type__c =:TYPE_CAMPAIGN ];
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(seguimientos[0].Id, yesterday);

        Test.startTest();
        Integer numberFollowUp = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);
        Test.stopTest();

        System.assertEquals(1, numberFollowUp,'Debería haber un seguimiento a eliminar');
    }

     /**
     * Test que comprueba que se devuelve correctamente el número de seguimientos que hay de un tipo, creados en el día de hoy y si han sido procesados o no
     */
    @isTest 
    static void test_countFollowUpCreateToday()
    {
        Test.startTest();
        Integer numberFollowUpProcessed = new FollowUpSelector().countByTypeCreatedDateTodayAndProcessed(TYPE_CAMPAIGN, true);
        Integer numberFollowUpNotProcessed = new FollowUpSelector().countByTypeCreatedDateTodayAndProcessed(TYPE_CAMPAIGN, false);
        Test.stopTest();

        System.assertEquals(1, numberFollowUpProcessed,'Debería haber un seguimiento de tipo campaña procesado');
        System.assertEquals(0, numberFollowUpNotProcessed,'No debería haber ningún seguimiento de tipo campaña no procesado');
    }

}