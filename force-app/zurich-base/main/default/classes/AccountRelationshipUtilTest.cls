@isTest
public with sharing class AccountRelationshipUtilTest
{
    @TestSetup
    static void makeData()
    {
        /* ----------------------------- CUSTOM SETTINGS ---------------------------- */
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';
        insert ventaCruzada;

        /* -------------------------------- ACCOUNTS -------------------------------- */
        // Cliente
        List<Account> customerAccounts = TestDataFactory.generateAccounts('001', 'Customer', 2);
        insert customerAccounts;

        //Agrupaciones
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'AgrupacionMediador', 1);
        insert agrupaciones;

        // Mediador
        List<Account> intermediarios = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        for(Integer i = 0; i < intermediarios.size(); i++)
        {
            intermediarios[i].IntermediaryGroup__c = agrupaciones[i].Id;
        }
        insert intermediarios;

        /* -------------------------------- CONTACTS -------------------------------- */
        // Mediador
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediarios, ContactsSelector.RT_NAME_CONTACT, 1);
        insert intermediaryContacts;

        /* ---------------------------------- USERS --------------------------------- */
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Id portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        List<User> users = TestDataFactory.generateUsersByProfile(portalProfile, 1);
        for(Integer i = 0; i < users.size(); i++)
        {
            users[i].UserRole = portalRole;
            users[i].ContactId = intermediaryContacts[i].Id;
        }

        insert users;
    }

    @isTest
    static void testOnBeforeInsertChangeOwner()
    {
        /* -------------------------------- TEST DATA ------------------------------- */
        List<Account> customerAccounts = [SELECT Id, OwnerId FROM Account WHERE Name LIKE 'testlastname%'];
        User defaultOwner = AccountRelationshipUtil.getDefaultOwnerUser();

        AccountRelationship__c ar = new AccountRelationship__c();
        ar.Account__c = customerAccounts[0].Id;
        ar.RelatedAccount__c = customerAccounts[1].Id;
        ar.RelationshipType__c = 'Otros';

        /* ---------------------------------- TEST ---------------------------------- */
        Test.startTest();
        AccountRelationshipUtil.onBeforeInsertChangeOwner(new List<AccountRelationship__c> {ar});
        Test.stopTest();

        /* --------------------------------- ASSERTS -------------------------------- */
        Assert.areEqual(defaultOwner.Id, ar.OwnerId, 'Owner should be the default owner user.');
    }

    @isTest
    static void testUpdateIntermediaryId()
    {
        /* -------------------------------- TEST DATA ------------------------------- */
        List<Account> customerAccounts = [SELECT Id, OwnerId FROM Account WHERE Name LIKE 'testlastname%'];
        User agenteVentas = [SELECT Id, Account.IntermediaryGroup__c FROM User WHERE Profile.Name = 'Agente Ventas' LIMIT 1];

        AccountRelationship__c ar = new AccountRelationship__c();
        ar.Account__c = customerAccounts[0].Id;
        ar.RelatedAccount__c = customerAccounts[1].Id;
        ar.RelationshipType__c = 'Otros';

        /* ---------------------------------- TEST ---------------------------------- */
        Test.startTest();
        System.runAs(agenteVentas)
        {
            AccountRelationshipUtil.updateIntermediaryId(new List<AccountRelationship__c> {ar}, null);
        }
        Test.stopTest();

        /* --------------------------------- ASSERTS -------------------------------- */
        Assert.areEqual(agenteVentas.Account.IntermediaryGroup__c, ar.IntermediaryId__c, 'IntermediaryId should be the same as the Agente Ventas Account.IntermediaryGroup__c');
    }
}