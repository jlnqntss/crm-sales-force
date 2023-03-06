/**
 * @description       : Clase de test para el batch Batch_ProcessFollowUps
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class Batch_ProcessFollowUpsTest 
{
    public static final String TYPE_CAMPAIGN = 'Campaña';
    public static final String TYPE_FORMACION = 'Formación';
    public static final String ATM_ROL_RN = 'Responsable de Negocio';
    public static final String ATM_ROL_CV = 'Consultor Vida';
    public static final String ATM_ROL_CP = 'Consultor PYME';
    public static final String ATM_ROL_CE = 'Consultor Empresas';
    public static final String ATM_ROL_CVC = 'Consultor Vida Colectivo';

    @TestSetup
    public static void createScenario()
    {
        List<Profile> profileRN = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        List<User> usersRN = TestDataFactory.generateUsersByProfile(profileRN[0].Id, 5);
       
        for( Integer i=0; i<usersRN.size(); i++ ) 
        {
            usersRN[i].FirstName = 'testUpdateUser';
        }

        insert usersRN;

        List<Account> intermediaryAccount = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, 1
        );
        insert intermediaryAccount;
        
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        List<String> roles = new List<String> {ATM_ROL_RN,ATM_ROL_CV,ATM_ROL_CP,ATM_ROL_CE,ATM_ROL_CVC};

        for (Account intermediary :intermediaryAccount)
        {
            for (Integer i =0;i<roles.size();i++)
            {
                atms.add(new AccountTeamMember(
                    AccountId= intermediary.Id,
                    UserId= usersRN[i].id,
                    TeamMemberRole= roles[i]
                ));
            }
        }
        insert atms;
        
    }

     /**
     * Test que comprueba que el batch actualiza correctamente los seguimientos para indicar que han sido procesados
     */
    @isTest 
    static void test_updateFollowUpsToProcessedTrue()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_CAMPAIGN,ATM_ROL_RN+';'+ATM_ROL_CVC);

        Test.startTest();
        insert seguimientos;
        Batch_ProcessFollowUps batchProcessFolloUps = new Batch_ProcessFollowUps(TYPE_CAMPAIGN);
        database.executeBatch(batchProcessFolloUps, 200);
        Test.stopTest();

        Integer numFollowUpsCampaingProcessedTrue = new FollowUpSelector().countByTypeCreatedDateTodayAndProcessed(TYPE_CAMPAIGN, true);

        System.assertEquals(1, numFollowUpsCampaingProcessedTrue,'El número de seguimientos procesados de tipo campaña debería ser uno');
    }

     /**
     * Test que comprueba que el batch actualiza correctamente los usuarios para indicar que han sido notificados
     */
    @isTest 
    static void test_updateUserToNotify()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();
        List<AccountTeamMember> atmCPBefore = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CP ];
        List<AccountTeamMember> atmsCVBefore = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_CP+';'+ATM_ROL_CVC);

        Test.startTest();
        insert seguimientos;
        Test.stopTest();

        List<AccountTeamMember> atmCPAfter = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CP ];
        List<AccountTeamMember> atmsCVAfter = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];

        System.assertEquals(null, atmCPBefore[0].User.NotifyType__c,'El usuario con rol CP no debería haber sido notificado de ningún tipo de seguimiento'); 
        System.assertEquals(null, atmsCVBefore[0].User.NotifyType__c,'El usuario con rol CV no debería haber sido notificado de ningún tipo de seguimiento');   
        System.assertEquals(TYPE_FORMACION, atmCPAfter[0].User.NotifyType__c,'Se debería haber actualizado correctamente el tipo para el usuario con rol CP'); 
        System.assertEquals(null, atmsCVAfter[0].User.NotifyType__c,'No se debería haber actualizado el tipo para el usuario con rol CV');    
    }

    /**
     * Test que comprueba que el batch elimina correctamente los seguimientos creados anteriores al día de hoy, del tipo de seguimientos que se está cargando
     */
    @isTest 
    static void test_deleteFollowUps()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_CAMPAIGN,ATM_ROL_RN+';'+ATM_ROL_CVC);
        insert seguimientos;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(seguimientos[0].Id, yesterday);

        Integer numFollowUpsCampaingCreatedLessThanToday = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);

        Test.startTest();
        Batch_ProcessFollowUps batchProcessFolloUps = new Batch_ProcessFollowUps(TYPE_CAMPAIGN);
        database.executeBatch(batchProcessFolloUps, 200);
        Test.stopTest();

        Integer numFollowUpsCampaingCreatedLessThanTodayAfter = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(TYPE_CAMPAIGN);

        System.assertEquals(1, numFollowUpsCampaingCreatedLessThanToday,'El número de seguimientos creados de tipo campaña creados antes de hoy debería ser uno');
        System.assertEquals(0, numFollowUpsCampaingCreatedLessThanTodayAfter,'Se deberían de haber borrado los seguimientos de tipo campaña creados antes de hoy');
    }

}