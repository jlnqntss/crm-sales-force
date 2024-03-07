@isTest
public with sharing class GenerateZRMLeadATMUtilTest {
    
    @TestSetup
    private static void makeData(){    
        
        /*****************************  CUSTOM SETTINGS  ****************************/
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;
        
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 1);
        insert accounts;

        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1);
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 2);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).Name = 'MediadorTest';
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
    }

    @isTest
    private static void testEventLeadZRM() {

        User u = [SELECT Id FROM User WHERE  Contact.Account.Name = 'MediadorTest' LIMIT 1];

        Account lead = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead' LIMIT 1];

        List<ZRMLeadATM__e> eventListTrigger = new List<ZRMLeadATM__e>();

        ZRMLeadATM__e event = new ZRMLeadATM__e();
        event.accountId__c = lead.Id;
        event.ZRMUserId__c = U.Id;
        eventListTrigger.add(event);

        Test.startTest();

        GenerateZRMLeadATMUtil.handleEventAfterInsert(eventListTrigger);

        Test.stopTest();

        List<AccountTeamMember> atmAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember]);
        System.assert(atmAfter.size() > 0, 'Debe haber un account team');
    }

}