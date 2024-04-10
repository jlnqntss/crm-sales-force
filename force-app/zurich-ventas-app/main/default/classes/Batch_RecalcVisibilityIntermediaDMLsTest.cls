@isTest
public with sharing class Batch_RecalcVisibilityIntermediaDMLsTest {

    private static final String BUSINESS_CODE = '320000001';
    
    @TestSetup
    static void makeData(){
        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1);
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 2);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        intermediaryAccounts.get(1).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(1).Name = 'MediadorTest2';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 2);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();
        List<User> userAGRList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            // Usuario Nominal
            String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 1);
            userList[0].ContactId = contacts[0].Id;
            insert userList;

            // Usuario AGR
            String portalAGRProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas - AGR' LIMIT 1].Id;

            userAGRList = TestDataFactory.generateUsersByProfile(portalAGRProfile, 1);            
            userAGRList[0].ContactId = contacts[1].Id;

            insert userAGRList;
        }

        // Añado cliente y poliza asociado al mediador del usuario zrm
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
        accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'PartnerOCS', 1);
        accounts[0].INFOBusinessCode__c = BUSINESS_CODE;
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        User intermediaryUser = [SELECT Id, Contact.AccountId FROM User WHERE Contact.Account.Name = 'MediadorTest'];

        for (Policy__c policy: policies) {
            policy.IntermediaryId__c = intermediaryUser.Contact.AccountId;
        }

        insert policies;
    }


    @isTest
    private static void testCalculateIntermediaryAGR() {
        User user = [SELECT Id, Contact.AccountId FROM User WHERE Contact.Account.Name like 'MediadorTest%' AND Profile.Name = 'Agente Ventas - AGR'];

        List<Account> intermediariesToProcess = new List<Account>([SELECT Id, IntermediaryGroup__c FROM Account WHERE Id = :user.Contact.AccountId]);
        Integer numDMLs = 5000;

        Test.startTest();
        String jobId = Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, new Set<String>(), new List<AccountTeamMember>(), new List<AccountTeamMember>(), numDMLs, 'CALCULATE'), numDMLs);
        Test.stopTest();

        List<AsyncApexJob> apexJob = new List<AsyncApexJob>([SELECT Id  FROM AsyncApexJob WHERE id = :jobId]);

        System.assertEquals(1, apexJob.size(), 'Debe haber un job');
    }


    @isTest
    private static void testProcessDelete() {
        User user = [SELECT Id, Contact.AccountId FROM User WHERE Contact.Account.Name like 'MediadorTest%' AND Profile.Name = 'Agente Ventas - AGR'];

        List<Account> intermediariesToProcess = new List<Account>([SELECT Id, IntermediaryGroup__c FROM Account WHERE Id = :user.Contact.AccountId]);
        Integer numDMLs = 1;

        List<AccountTeamMember> accountsTeamsToDelete = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember]);

        Test.startTest();
        String jobId = Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, accountsTeamsToDelete, new List<AccountTeamMember>(), numDMLs, 'DELETE'), 5000);
        Test.stopTest();

        List<AsyncApexJob> apexJob = new List<AsyncApexJob>([SELECT Id  FROM AsyncApexJob WHERE id = :jobId]);

        System.assertEquals(1, apexJob.size(), 'Debe haber un job');
    }


    @isTest
    private static void testProcessInsert() {
        User user = [SELECT Id, Contact.AccountId FROM User WHERE Contact.Account.Name like 'MediadorTest%' AND Profile.Name = 'Agente Ventas - AGR'];

        List<Account> intermediariesToProcess = new List<Account>([SELECT Id, IntermediaryGroup__c FROM Account WHERE Id = :user.Contact.AccountId]);
        Integer numDMLs = 1;

        List<AccountTeamMember> accountsTeamsToInsert = new List<AccountTeamMember>([SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember]);

        if (!accountsTeamsToInsert.isEmpty()) {
            AccountTeamMember atm = accountsTeamsToInsert.get(0);
            AccountTeamMember atm1 = accountsTeamsToInsert.get(1);

            AccountTeamMember atmCloned = atm.clone(false, false, false, false);
            AccountTeamMember atm1Cloned = atm1.clone(false, false, false, false);
    
            delete atm;
            delete atm1;

            accountsTeamsToInsert.clear();
            accountsTeamsToInsert.add(atmCloned);
            accountsTeamsToInsert.add(atm1Cloned);
    
            Test.startTest();
            String jobId = Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, new List<AccountTeamMember>(), accountsTeamsToInsert, numDMLs, 'INSERT'), 5000);
            Test.stopTest();
    
            List<AsyncApexJob> apexJob = new List<AsyncApexJob>([SELECT Id  FROM AsyncApexJob WHERE id = :jobId]);
    
            System.assertEquals(1, apexJob.size(), 'Debe haber un job');
        }
    }

}