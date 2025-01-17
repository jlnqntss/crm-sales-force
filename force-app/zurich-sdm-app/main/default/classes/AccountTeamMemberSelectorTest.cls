/**
 * Clase de test para la clase selectora del sobject AccountTeamMember
 * 
 * @author nts (agonzalezisasi)
 * @date 09/11/2021
 */
@isTest
private with sharing class AccountTeamMemberSelectorTest 
{
    public static final String DT_EMAIL = 'sdm.rn@zurich.invalid';
    public static final Integer NUM_INTERMEDIARIES = 5;
    public static final String ATM_ROL_RN = 'Responsable de Negocio';
    public static final String ATM_ROL_CV = 'Consultor Vida';
    public static final String ATM_ROL_CP = 'Consultor PYME';
    public static final String ATM_ROL_CE = 'Consultor Empresas';
    public static final String ATM_ROL_CVC = 'Consultor Vida Colectivo';
    public static final String TYPE_CAMPAIGN = 'Campaña';


    @TestSetup
    public static void createScenario()
    {
        List<Profile> profileRN = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        List<User> usersRN = TestDataFactory.generateUsersByProfile(profileRN[0].Id, 5);
       
        for( Integer i=0; i<usersRN.size(); i++ ) 
        {
            usersRN[i].FirstName = 'testAccountTeam';
            usersRN[i].Email = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(i)});
            if (i<2)
            {
                usersRN[i].NotifyDate__c = date.today();
                usersRN[i].NotifyType__c = TYPE_CAMPAIGN;    
            }
        }

        insert usersRN;
        
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, NUM_INTERMEDIARIES
        );
        for(Account a: intermediaryAccounts) {
            a.NationalID__c = TestDataFactorySDM.AGRUPATION_CIF;
            a.status__c = '001'; // añadido para cumplir el filtro de status intermediary
            a.put(AccountsSelector.SDM_DT_EMAIL_FIELD, DT_EMAIL);
        }
        insert intermediaryAccounts;

        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        for(Account a: intermediaryAccounts) {
            atms.add(new AccountTeamMember(
                AccountId= a.Id,
                UserId= UserInfo.getUserId(),
                TeamMemberRole= SettingsSDM.ATM_ROL_BUSINESS
            ));
        }
        insert atms;
    }

    /**
     * Test del metodo que recupera los usuarios con un rol de un Director Territorial
     */
    @isTest
    static void findUsersByRoleAndEmailField()
    {
        Test.startTest();
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findUsersByRoleAndEmailField(
            SettingsSDM.ATM_ROL_BUSINESS,
            AccountsSelector.SDM_DT_EMAIL_FIELD,
            DT_EMAIL
        );
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto POR ROL Y CAMPO EMAIL');
        System.assertEquals(NUM_INTERMEDIARIES, atms.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' equipos de cuenta');
    }

    /**
     * Test del metodo que recupera los ATMs por los ids de usuario
     */
    @isTest
    static void findIntermediariesByUsers()
    {
        Test.startTest();
        Set<Id> ids = new Set<Id>{UserInfo.getUserId()};
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findIntermediariesByUsers(ids);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto POR USUARIO');
        System.assertEquals(NUM_INTERMEDIARIES, atms.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' equipos de cuenta');
    }

    /**
     * Test del metodo que recupera los ATMs por los ids de usuario
     */
    @isTest
    static void findByIntermediary()
    {
        List<Account> intermediaries = [SELECT Id FROM Account];

        Test.startTest();
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByIntermediary(intermediaries);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto POR MEDIADOR');
        System.assertEquals(NUM_INTERMEDIARIES, atms.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' equipos de cuenta');
    }

    /**
     * Test del metodo que recupera los ATMs por campo NationalId del mediador
     */
    @isTest
    static void findByNationalIDs()
    {
        Test.startTest();
        Set<String> nationalIds = new Set<String>{TestDataFactorySDM.AGRUPATION_CIF};
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByNationalIDs(nationalIds);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto POR CAMPO NATIONALID');
        System.assertEquals(NUM_INTERMEDIARIES, atms.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' equipos de cuenta');
    }

    /**
     * Test del metodo que recupera los ATMs por roles
     */
    @isTest
    static void findByRoles()
    {
        Test.startTest();
        List<String> roles = new List<String>{SettingsSDM.ATM_ROL_BUSINESS};
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByRoles(roles);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto POR ROL');
        System.assertEquals(NUM_INTERMEDIARIES, atms.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' equipos de cuenta');
    }


    /**
     * Test para consultar los demás registros de atm para un usuario y estos registros son los que se actualizan a inactivo en el componente de notificaciones por mediador
     */
    @isTest
    static void findIntermedariesWithInactiveNotifications()
    {

        List<AccountTeamMember> atmsQuery = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember LIMIT 1]);
        List<AccountTeamMember> atms = new List<AccountTeamMember>();

        if (!atmsQuery.isEmpty()) {

            List<String> idAtmQuery = new List<String>();
            idAtmQuery.add(atmsQuery.get(0).Id);

            Test.startTest();
            atms = (new AccountTeamMemberSelector()).findIntermedariesWithInactiveNotifications(UserInfo.getUserId(), idAtmQuery);
            Test.stopTest();
        }
        

        // Comprobamos el resultado
        System.assertEquals(4, atms.size(), 'Se esperan 4 resultados');
    }

    /**
     * Test del método que obtiene los miembros del equipo de cuentas que estén asociados a una lista de cuentas , para unos roles especificos 
     * y cuyos usuarios no hayan sido notificados o si han sido notificados no hayan sido notificados para un tipo de seguimiento en concreto
     */
    @isTest
    static void findUsersByRoleAndAccountIdFields()
    {
        List<Account> intermediaryAccount = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, 1
        );
        insert intermediaryAccount;
        
        List<User> usersList = [Select id,NotifyDate__c,NotifyType__c from User where FirstName like '%testAccountTeam%'];
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        List<String> roles = new List<String> {ATM_ROL_RN,ATM_ROL_CV,ATM_ROL_CP,ATM_ROL_CE,ATM_ROL_CVC};
        for (Integer i =0;i<roles.size();i++)
        {
            atms.add(new AccountTeamMember(
                AccountId= intermediaryAccount[0].Id,
                UserId= usersList[i].id,
                TeamMemberRole= roles[i]
            ));
        }
        insert atms;

        Test.startTest();
        List<AccountTeamMember> atmQueryAllCheckFalse = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(new Set<String>{'Todos'}, new Set<Id>{intermediaryAccount[0].Id}, TYPE_CAMPAIGN);
        List<AccountTeamMember> atmQueryCVC = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(new Set<String>{ATM_ROL_CVC}, new Set<Id>{intermediaryAccount[0].Id}, TYPE_CAMPAIGN);
        List<AccountTeamMember> atmQueryAll = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(new Set<String>{'Todos'}, new Set<Id>{intermediaryAccount[0].Id}, 'Formación');
        List<AccountTeamMember> atmQueryRN = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(new Set<String>{ATM_ROL_RN}, new Set<Id>{intermediaryAccount[0].Id}, TYPE_CAMPAIGN);
        List<AccountTeamMember> atmQuerySomeRoles = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(new Set<String>{ATM_ROL_CP,ATM_ROL_CE,ATM_ROL_CVC}, new Set<Id>{intermediaryAccount[0].Id}, TYPE_CAMPAIGN);
        Test.stopTest();
        System.assertEquals(3, atmQueryAllCheckFalse.size(), 'Se esperan 3 resultados');
        System.assertEquals(1, atmQueryCVC.size(), 'Se espera 1 resultado');
        System.assertEquals(5, atmQueryAll.size(), 'Se esperan 5 resultados');
        System.assertEquals(0, atmQueryRN.size(), 'No se espera ningun resultado');
        System.assertEquals(3, atmQuerySomeRoles.size(), 'Se esperan 3 resultados');
    }

    @isTest
    static void test_findByAccountAndUser_ok()
    {
        Set<id> idAccounts = new Set<Id>();
        Set<id> idUsers = new Set<Id>();
        List<AccountTeamMember> atms = [SELECT id, AccountId, UserId FROM AccountTeamMember WHERE AccountId != '' AND UserId != ''];
        for(AccountTeamMember atm : atms)
        {
            idAccounts.add(atm.AccountId);
            idUsers.add(atm.UserId);
        }

        List<AccountTeamMember> retrievedATMS;
        Test.startTest();
        retrievedATMS = (new AccountTeamMemberSelector()).findByAccountAndUser(idAccounts, idUsers);
        Test.stopTest();

        System.assertEquals(false, retrievedATMS.isEmpty(), 'Ha debido encontrar AccountTeamMembers');
        System.assertEquals(atms.size(), retrievedATMS.size(), 'Ha debido encontrar los mismos miembros');
    }

    @isTest
    static void test_findByAccountAndUser_ko()
    {
        Set<id> idAccounts = new Set<Id>();
        Set<id> idUsers = new Set<Id>();

        List<AccountTeamMember> retrievedATMS;
        Test.startTest();
        retrievedATMS = (new AccountTeamMemberSelector()).findByAccountAndUser(idAccounts, idUsers);
        Test.stopTest();

        System.assertEquals(true, retrievedATMS.isEmpty(), 'Ha de devolver una lista vacia');
    }
}
