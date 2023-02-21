/**
 * @description       : Clase de test para la clase GetUserIdToNotifyAction
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-21-2023
 * @last modified by  : aberuete
**/
@isTest
public with sharing class GetUserIdToNotifyActionTest 
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
            usersRN[i].Email = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(i)});
            if (i<1)
            {
                usersRN[i].NotifyDate__c = date.today();
                usersRN[i].NotifyType__c = TYPE_CAMPAIGN;    
            }
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
     * Test que comprueba si se devuelve una lista y si al insertar un seguimiento se actualizan los usuarios correctamente 
     */
    @isTest 
    static void test_getUserIdToNotify()
    {
        List<FollowUp__c> seguimientos = [Select id,Type__c,Account__c,Notify__c from FollowUp__c where Type__c =:TYPE_CAMPAIGN ];
        List<AccountTeamMember> atms = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CVC ];
        List<AccountTeamMember> atmsCV = [Select UserId, User.Notified__c,User.NotifyType__c from AccountTeamMember where TeamMemberRole =: ATM_ROL_CV ];
        
        Test.startTest();
        List<List<Id>> returnList = GetUserIdToNotifyAction.getUserIdToNotify(seguimientos);
        Test.stopTest();
        
        System.assertEquals (1,returnList.size(),'El número de listas devuelto no es correcto');
        System.assertEquals(true, atms[0].User.Notified__c, 'El usuario debe  haber sido notificado');
        System.assertEquals(TYPE_CAMPAIGN, atms[0].User.NotifyType__c, 'El usuario debe  haber sido notificado del tipo campaña');
        System.assertEquals(false, atmsCV[0].User.Notified__c, 'El usuario no debe  haber sido notificado');
        System.assertEquals(null, atmsCV[0].User.NotifyType__c, 'El usuario no debe  haber sido notificado del tipo campaña');
        
    }

     /**
     * Test que comprueba si al insertar dos seguimientos de distinto tipo se lanza una excepción
     */
    @isTest 
    static void test_getUserIdToNotifyException()
    {
        List<Account> intermediaries = [Select id from Account];
        List<FollowUp__c> seguimientoFormacion = TestDataFactorySDM.generateFollowUps(1,new Map<Id,Account>(intermediaries).keySet(),TYPE_FORMACION,ATM_ROL_RN+';'+ATM_ROL_CVC);
        insert seguimientoFormacion;
        List<FollowUp__c> seguimientos = [Select id,Type__c,Account__c,Notify__c from FollowUp__c ];

        String messageError;
        List<List<Id>> returnList;
        
        Test.startTest();
        Try 
        {
            returnList = GetUserIdToNotifyAction.getUserIdToNotify(seguimientos);
        }
        catch (Exception e) 
        {
            messageError = e.getMessage();
        }
        
        Test.stopTest();
       
        System.assertEquals(GetUserIdToNotifyAction.ERROR_TYPE, messageError, 'El mensaje de error no es correcto');
    }

    /**
     * Test que comprueba si el método privado de actualizar usuarios funciona correctamente
     */
    @isTest 
    static void test_updateUsersToNotify()
    {
        List<User> usersList = [Select id,NotifyDate__c,NotifyType__c,Notified__c from User where FirstName like '%testUpdateUser%'];
        Set<id> userIds = (new Map <Id,User>(usersList)).keySet();

        System.assertEquals(TYPE_CAMPAIGN, usersList[0].NotifyType__c, 'Valor de tipo esperado incorrecto');
        System.assertEquals(null, usersList[1].NotifyType__c, 'Valor de tipo esperado incorrecto');
        System.assertEquals(false, usersList[1].Notified__c, 'Checkbox del campo notificado incorrecto');

        Test.startTest();
        GetUserIdToNotifyAction.updateUsersToNotify(userIds, TYPE_FORMACION);
        Test.stopTest();

        List<User> userListAfterUpdate = [Select id,NotifyDate__c,NotifyType__c,Notified__c from User where FirstName like '%testUpdateUser%'];

        System.assertEquals(TYPE_CAMPAIGN +';'+ TYPE_FORMACION, userListAfterUpdate[0].NotifyType__c, 'Valor de tipo esperado tras la actualización incorrecto');
        System.assertEquals(TYPE_FORMACION, userListAfterUpdate[1].NotifyType__c, 'Valor de tipo esperado tras la actualización incorrecto');
        System.assertEquals(true, userListAfterUpdate[1].Notified__c, 'Checkbox del campo notificado tras la actualización incorrecto');
    }
}