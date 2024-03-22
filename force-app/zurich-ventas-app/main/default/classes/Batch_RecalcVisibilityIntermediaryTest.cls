@isTest(seeAllData=false)
public with sharing class Batch_RecalcVisibilityIntermediaryTest {

    private static final String BUSINESS_CODE = '320000001';
    
    @TestSetup
    private static void makeData() {
        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 2);
        Integer cont = 1;
        for (Account agrupacion: agrupaciones) {
            agrupacion.Name = 'Agrupacion' + cont;
            cont++;
            
        }
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 1);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 1);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();

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
        }

        // Añado cliente y poliza asociado al mediador del usuario zrm
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 1);
        insert accounts;
        accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'PartnerOCS', 1);
        accounts[0].INFOBusinessCode__c = BUSINESS_CODE;
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);

        for (Policy__c policy: policies) {
            policy.IntermediaryId__c = intermediaryAccounts.get(0).Id;
        }

        insert policies;
    }

    @isTest
    private static void testRecalculoMediador() {

        Date yesterdayDate = Date.today();
        yesterdayDate = yesterdayDate.addDays(-1);

        // Obtener mediador y cambiar la agrupacion
        Account intermediary = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'Intermediary' AND Name = 'MediadorTest' LIMIT 1];

        List<Account> intermediaryToBatch = new List<Account>([SELECT Id, IntermediaryGroup__c, LastIntermediaryGroup__c FROM Account WHERE Id = :intermediary.Id]);

        Test.startTest();
        Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediaryToBatch, true, 5000), 5000); 
        Test.stopTest();

        List<AccountTeamMember> atmsAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE TeamMemberRole = 'MediadorZRM']);

        System.assert(atmsAfter != null, 'Debe haber atms generados por el batch');
    }

    @isTest
    private static void testRecalculoMediadorInvocableMethod() {

        Date yesterdayDate = Date.today();
        yesterdayDate = yesterdayDate.addDays(-1);

        // Obtener mediador y cambiar la agrupacion
        Account intermediary = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'Intermediary' AND Name = 'MediadorTest' LIMIT 1];

        Batch_RecalcVisibilityIntermediary.Requests request = new Batch_RecalcVisibilityIntermediary.Requests();
        request.intermediaryId = intermediary.Id;
        request.numDMLs = 5000;

        List<Batch_RecalcVisibilityIntermediary.Requests> requests = new List<Batch_RecalcVisibilityIntermediary.Requests>();
        requests.add(request);

        Test.startTest();
        Batch_RecalcVisibilityIntermediary.invocableExecuteBatch(requests);
        Test.stopTest();

        List<AccountTeamMember> atmsAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE TeamMemberRole = 'MediadorZRM']);

        System.assert(atmsAfter != null, 'Debe haber atms generados por el batch');
    }


    @isTest
    private static void testCambioAgrupacionMediador() {

        Date yesterdayDate = Date.today();
        yesterdayDate = yesterdayDate.addDays(-1);

        List<AccountTeamMember> atmsBefore = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE TeamMemberRole = 'MediadorZRM']);

        // Obtener mediador y cambiar la agrupacion
        Account intermediary = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'Intermediary' AND Name = 'MediadorTest' LIMIT 1];
        String intermdiaryGroup = intermediary.IntermediaryGroup__c;
        
        // Obtener la segunda agrupacion
        Account intermediaryGroup = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'AgrupacionMediador' AND Id != :intermdiaryGroup LIMIT 1];

        intermediary.IntermediaryGroup__c = null;
        intermediary.LastIntermediaryGroup__c = intermdiaryGroup;
        intermediary.LastIntermediaryGroupChange__c = yesterdayDate;   
        intermediary.IntermediaryGroup__c = intermediaryGroup.Id;

        update intermediary;

        List<Account> intermediaryToBatch = new List<Account>([SELECT Id, IntermediaryGroup__c, LastIntermediaryGroup__c FROM Account WHERE Id = :intermediary.Id]);

        Test.startTest();
        Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediaryToBatch, false, 5000), 5000); 
        Test.stopTest();

        List<AccountTeamMember> atmsAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE TeamMemberRole = 'MediadorZRM']);

        System.assert(atmsAfter != null, 'Debe haber atms generados por el batch');

    }

    @isTest
    private static void testBajaMediador() {

        Date yesterdayDate = Date.today();
        yesterdayDate = yesterdayDate.addDays(-1);

        // Obtener cliente y dar de baja de la agrupación
        Account intermediary = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'Intermediary' AND Name = 'MediadorTest' LIMIT 1];

        String intermdiaryGroup = intermediary.IntermediaryGroup__c;

        intermediary.IntermediaryGroup__c = null;
        intermediary.LastIntermediaryGroup__c = intermdiaryGroup;
        intermediary.LastIntermediaryGroupChange__c = yesterdayDate;        

        update intermediary;

        List<Account> intermediaryToBatch = new List<Account>([SELECT Id, IntermediaryGroup__c, LastIntermediaryGroup__c FROM Account WHERE Id = :intermediary.Id]);

        Test.startTest();
        Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediaryToBatch, false, 5000), 5000); 
        Test.stopTest();

        List<AccountTeamMember> atmsAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE TeamMemberRole = 'MediadorZRM']);

        System.assert(atmsAfter != null, 'Debe haber atms generados por el batch');

    }
}