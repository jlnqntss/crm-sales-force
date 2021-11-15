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

    @TestSetup
    public static void createScenario()
    {
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts('001', 'Intermediary', 5);
        for(Account a: intermediaryAccounts) {
            a.put(AccountsSelector.SDM_DT_EMAIL_FIELD, DT_EMAIL);
        }
        insert intermediaryAccounts;

        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        for(Account a: intermediaryAccounts) {
            atms.add(new AccountTeamMember(
                AccountId= a.Id,
                UserId= UserInfo.getUserId(),
                TeamMemberRole= AccountTeamMemberSelector.ATM_ROLE_RN_NAME
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
            AccountTeamMemberSelector.ATM_ROLE_RN_NAME,
            AccountsSelector.SDM_DT_EMAIL_FIELD,
            DT_EMAIL
        );
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, atms, 'Deberia haber algun equipo de cuenta devuelto');
        System.assertEquals(5, atms.size(), 'Deberia haber 5 equipos de cuenta');
    }
}
