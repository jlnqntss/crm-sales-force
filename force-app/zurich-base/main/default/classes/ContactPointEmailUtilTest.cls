/**
 * Clases de test para ContactPointEmailUtil
 **
 * @author rlopez
 * @date 20/11/2020
 */
@isTest(SeeAllData=false)
private with sharing class ContactPointEmailUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        /*List<Account> businessAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
           insert businessAccounts;*/

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Scope__c> insertedScopes = [SELECT Id, AccountId__c, Scope__c, AccountId__r.Name FROM Scope__c WHERE Id IN: scopes];

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromScopes(insertedScopes, 1);
        insert contactPointEmails;
    }

    @isTest
    static void test_insert_primaryContactPointEmail_ok()
    {
        String emailToInsert = 'newemail@nts-solutions.com.invalid';
        List<Scope__c> relatedScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c LIMIT 1];
        System.assertEquals(1, relatedScopes.size(), 'There should be 1 account');

        List<ContactPointEmail> newContactPoints = new List<ContactPointEmail>();
        newContactPoints.add(
            new ContactPointEmail(
                EmailAddress = emailToInsert,
                ParentId = relatedScopes.get(0).AccountId__c,
                Scope__c = relatedScopes.get(0).Scope__c,
                ScopeId__c = relatedScopes.get(0).Id,
                IsPrimary = true
                )
            );

        Test.startTest();
        insert newContactPoints;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        List<ContactPointEmail> currentContactPoints = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c =: relatedScopes.get(0).Id AND IsPrimary = true];
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointEmail');

        List<Scope__c> updatedScopes = [SELECT Id, PrimaryEmail__c FROM Scope__c WHERE Id =: relatedScopes.get(0).Id];
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(emailToInsert, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    @isTest
    static void test_update_primaryContactPointEmail_ok()
    {
        List<ContactPointEmail> contactPointEmails = [SELECT Id, IsPrimary, EmailAddress, ParentId, Scope__c, ScopeId__c FROM ContactPointEmail WHERE IsPrimary = false LIMIT 1];
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 ContactPointEmail');

        contactPointEmails.get(0).IsPrimary = true;

        Test.startTest();
        update contactPointEmails;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        List<ContactPointEmail> currentContactPoints = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c =: contactPointEmails.get(0).ScopeId__c AND IsPrimary = true];
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointEmail');

        List<Scope__c> updatedScopes = [SELECT Id, PrimaryEmail__c FROM Scope__c WHERE Id =: contactPointEmails.get(0).ScopeId__c];
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(contactPointEmails.get(0).EmailAddress, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    @isTest
    static void test_insert_primaryContactPointEmail_update_related_ok()
    {
        String emailToInsert = 'newemail@nts-solutions.com.invalid';

        List<ContactPointEmail> firstContactPointEmails = [SELECT Id, IsPrimary, EmailAddress, ParentId, Scope__c, ScopeId__c FROM ContactPointEmail WHERE IsPrimary = false LIMIT 1];
        System.assertEquals(1, firstContactPointEmails.size(), 'There should be 1 ContactPointEmail');

        Id currentScopeId = firstContactPointEmails.get(0).ScopeId__c;

        //Actualizamos un ContactPointEmail primero
        firstContactPointEmails.get(0).IsPrimary = true;
        update firstContactPointEmails;

        List<ContactPointEmail> newContactPoints = new List<ContactPointEmail>();
        newContactPoints.add(
            new ContactPointEmail(
                EmailAddress = emailToInsert,
                ParentId = firstContactPointEmails.get(0).ParentId,
                Scope__c = firstContactPointEmails.get(0).Scope__c,
                ScopeId__c = currentScopeId,
                IsPrimary = true
                )
            );

        Test.startTest();
        insert newContactPoints;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        List<ContactPointEmail> updatedPrimaryContactPoints = [SELECT Id, EmailAddress FROM ContactPointEmail WHERE ScopeId__c =: currentScopeId AND IsPrimary = true];
        System.assertEquals(1, updatedPrimaryContactPoints.size(), 'There should be 1 primary ContactPointEmail');
        System.assertEquals(updatedPrimaryContactPoints.get(0).Id, newContactPoints.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = [SELECT Id, PrimaryEmail__c FROM Scope__c WHERE Id =: currentScopeId];
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(updatedPrimaryContactPoints.get(0).EmailAddress, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');

        List<ContactPointEmail> updatedNotPrimaryContactPoints = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c =: currentScopeId AND IsPrimary = false];
        Set<Id> updatedNotPrimaryContactPointsIds = new Set<Id>();
        for(ContactPointEmail notPrimaryContactPoint: updatedNotPrimaryContactPoints)
        {
            updatedNotPrimaryContactPointsIds.add(notPrimaryContactPoint.Id);
        }

        System.assertEquals(true, updatedNotPrimaryContactPointsIds.contains(firstContactPointEmails.get(0).Id), 'Set should contains the first primary ContactPointEmail already updated');
    }

    @isTest
    static void test_update_uncheck_primaryContactPointEmail_ko()
    {
        List<ContactPointEmail> firstContactPointEmails = [SELECT Id, IsPrimary, EmailAddress, ParentId, Scope__c, ScopeId__c FROM ContactPointEmail WHERE IsPrimary = false LIMIT 1];
        System.assertEquals(1, firstContactPointEmails.size(), 'There should be 1 ContactPointEmail');

        Id currentScopeId = firstContactPointEmails.get(0).ScopeId__c;

        //Actualizamos un ContactPointEmail primero
        firstContactPointEmails.get(0).IsPrimary = true;
        update firstContactPointEmails;

        firstContactPointEmails.get(0).IsPrimary = false;

        Test.startTest();
        try
        {
            update firstContactPointEmails;
        }
        catch (DmlException ex)
        {
            System.assertEquals(true, ex.getMessage().contains('There should be at least one primary contact point email'), 'It should contains that error message');
        }
    }
}
