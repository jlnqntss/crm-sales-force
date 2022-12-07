@isTest
public with sharing class IntermediaryNotificationsControllerTest {

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

    @isTest
    static void getRecordsTest() {
        
        Test.startTest();
        Map<String, Map<Id, String>> result = IntermediaryNotificationsController.getRecords();
        Test.stopTest();

        Map<Id, String> activeIntermediary = result.get('ActiveIntermediary');

        System.assertEquals(NUM_INTERMEDIARIES, activeIntermediary.size(), 'Debe haber 5 registros activos');
        
    }


    @isTest
    static void updateRecordsTest() {

        // actualizo a false un registro de atm
        List<AccountTeamMember> atmsQuery = new List<AccountTeamMember>([SELECT Id, NotificationsOnPlans__c FROM AccountTeamMember LIMIT 1]);

        if (!atmsQuery.isEmpty()) {
            AccountTeamMember atm = atmsQuery.get(0);
            atm.NotificationsOnPlans__c = false;

            update atm;

            List<String> atmsToActivate = new List<String>();
            atmsToActivate.add(atm.Id);

             // envio ese registro a activar y el resto a inactivar
            Test.startTest();
            IntermediaryNotificationsController.updateIntermediaryNotificationFlag(atmsToActivate);            
            Test.stopTest();

            // query atm de arriba compruebo que está activa el flag
            List<AccountTeamMember> atmsQueryPostUpdate = new List<AccountTeamMember>([SELECT Id, NotificationsOnPlans__c FROM AccountTeamMember WHERE Id = :atm.Id LIMIT 1]);

            System.assertEquals(true, atmsQueryPostUpdate.get(0).NotificationsOnPlans__c, 'Debe estar activa');
        }

       

        
       
    }
}
