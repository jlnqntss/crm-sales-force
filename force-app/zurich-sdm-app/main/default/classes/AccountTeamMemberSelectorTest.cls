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

    @TestSetup
    public static void createScenario()
    {
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, NUM_INTERMEDIARIES
        );
        for(Account a: intermediaryAccounts) {
            a.NationalID__c = TestDataFactorySDM.AGRUPATION_CIF;
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
}
