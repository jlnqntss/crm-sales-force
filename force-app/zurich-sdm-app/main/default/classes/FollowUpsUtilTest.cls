/**
 * @description       : Clase de test para la clase Util FollowUpsUtil
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-08-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class FollowUpsUtilTest 
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
        Set<Id> idsIntermediaries = new Map<Id,Account>(intermediaryAccount).keySet();
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

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_CAMPAIGN,ATM_ROL_RN+';'+ATM_ROL_CVC);
        insert seguimientos;
    }

     /**
     * Test que comprueba que se actualizan correctamente los seguimientos para indicar que han sido procesados
     */
    @isTest 
    static void test_updateFollowUpsToProcessedTrue()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();

        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CV);
        Boolean errorIsTrue;

        Test.startTest();
        insert seguimientos;
        errorIsTrue = FollowUpsUtil.updateFollowUpsToProcessedTrue (seguimientos);
        Test.stopTest();

        Integer numSeguimientos = new FollowUpSelector().countByTypeCreatedDateTodayAndProcessed(TYPE_FORMACION, true);

        System.assertEquals(1, numSeguimientos,'El número de seguimientos procesados de tipo formación debería ser uno');
        System.assertEquals(false, errorIsTrue,'No debería de haber lanzado ningún error');
        
    }

     /**
     * Test que comprueba que se lance correctamente un error en caso de que falle la actualización de los seguimientos
     */
    @isTest 
    static void test_updateFollowUpsToProcessedTrueWithError()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,CreatedDate from FollowUp__c where Type__c =:TYPE_CAMPAIGN  ];
        delete seguimientos;
        Boolean errorIsTrue;

        Test.startTest();
        errorIsTrue = FollowUpsUtil.updateFollowUpsToProcessedTrue (seguimientos);
        Test.stopTest();
        
        List<Error_Log__c> error = [select id,Message__c from Error_Log__c ];
        System.assertEquals(true, errorIsTrue,'Debería de haber lanzado un error');
        System.assertEquals('Se ha producido un error actualizando seguimientos', error[0].Message__c, 'Debería haber escrito correctamente el mensaje de error');
        
    }

    /**
     * Test que comprueba que se obtiene correctamente el conjunto de ids de usuarios a notificar de la carga de seguimientos
     */
    @isTest 
    static void test_getUserIdToNotify()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        List<AccountTeamMember> atmRN = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_RN ];
        List<AccountTeamMember> atmsCV = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];
        Set<Id> userIdFromATM = new Set<Id>{atmRN[0].UserId,atmsCV[0].UserId};
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();
        Set<Id> userIdsToNotify = new Set<Id> ();
        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CV);

        Test.startTest();
        insert seguimientos;
        userIdsToNotify = FollowUpsUtil.getUserIdToNotify (seguimientos, TYPE_FORMACION, userIdsToNotify);
        Test.stopTest();

        System.assertEquals(2, userIdsToNotify.size(),'Debería de haber 2 usuarios a actualizar');  
        System.assertEquals(true,userIdsToNotify.containsAll(userIdFromATM) ,'Debería de haber devuelto bien los ids de los usuarios');   
    }

    /**
     * Test que comprueba que se actualizan correctamente los usuarios a notificar
     */
    @isTest 
    static void test_updateUsersToNotify()
    {
        List<Account> listAccount = [Select id from Account where recordtype.developerName = 'intermediary'];
        List<AccountTeamMember> atmRNBefore = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_RN ];
        List<AccountTeamMember> atmsCVBefore = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];
        Set<Id> idsIntermediaries = new Map<Id,Account>(listAccount).keySet();
        List<FollowUp__c> seguimientos = TestDataFactorySDM.generateFollowUps(1,idsIntermediaries,TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CV);

        Test.startTest();
        insert seguimientos;
        Test.stopTest();

        List<AccountTeamMember> atmRNAfter = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_RN ];
        List<AccountTeamMember> atmsCVAfter = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];

        System.assertEquals(TYPE_CAMPAIGN, atmRNBefore[0].User.NotifyType__c,'El usuario con rol RN debería haber sido notificado del tipo campaña'); 
        System.assertEquals(null, atmsCVBefore[0].User.NotifyType__c,'El usuario con rol CV no debería haber sido notificado de ningún tipo de seguimiento');   
        System.assertEquals(TYPE_CAMPAIGN+';'+TYPE_FORMACION, atmRNAfter[0].User.NotifyType__c,'Se debería haber actualizado correctamente el tipo para el usuario con rol RN'); 
        System.assertEquals(TYPE_FORMACION, atmsCVAfter[0].User.NotifyType__c,'Se debería haber actualizado correctamente el tipo para el usuario con rol CV');    
    }
    
}