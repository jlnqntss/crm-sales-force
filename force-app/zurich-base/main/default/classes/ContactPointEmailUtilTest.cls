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

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromScopes(insertedScopes, 10);
        insert contactPointEmails;
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointEmail marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito
     *
     * @author rlopez
     * @date 20/11/2020
     */
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
        List<ContactPointEmail> currentContactPoints = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {relatedScopes.get(0).Id}, true, null
            );
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointEmail');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {relatedScopes.get(0).Id});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(emailToInsert, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    /**
     * Test que comprueba que al actualizar un ContactPointEmail como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito
     *
     * @author rlopez
     * @date 20/11/2020
     */
    @isTest
    static void test_update_primaryContactPointEmail_ok()
    {
        //List<ContactPointEmail> contactPointEmails = [SELECT Id, IsPrimary, EmailAddress, ParentId, Scope__c, ScopeId__c FROM ContactPointEmail WHERE IsPrimary = false LIMIT 1];
        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> contactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
        contactPointEmails.get(0).IsPrimary = true;

        Test.startTest();
        update contactPointEmails;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        //List<ContactPointEmail> currentContactPoints = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c =: contactPointEmails.get(0).ScopeId__c AND IsPrimary = true];
        List<ContactPointEmail> currentContactPoints = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {contactPointEmails.get(0).ScopeId__c}, true, null
            );
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointEmail');

        //List<Scope__c> updatedScopes = [SELECT Id, PrimaryEmail__c FROM Scope__c WHERE Id =: contactPointEmails.get(0).ScopeId__c];
        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {contactPointEmails.get(0).ScopeId__c});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(contactPointEmails.get(0).EmailAddress, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointEmail marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito y
     * el campo IsPrimary del anterior ContactPointEmail pasa a ser false
     *
     * @author rlopez
     * @date 20/11/2020
     */
    @isTest
    static void test_insert_primaryContactPointEmail_update_related_ok()
    {
        String emailToInsert = 'newemail@nts-solutions.com.invalid';

        //List<ContactPointEmail> firstContactPointEmails = [SELECT Id, IsPrimary, EmailAddress, ParentId, Scope__c, ScopeId__c FROM ContactPointEmail WHERE IsPrimary = false LIMIT 1];
        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> firstContactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
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
        //List<ContactPointEmail> insertedPrimaryContactPoints = [SELECT Id, EmailAddress FROM ContactPointEmail WHERE ScopeId__c =: currentScopeId AND IsPrimary = true];
        List<ContactPointEmail> insertedPrimaryContactPoints = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'EmailAddress'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);
        System.assertEquals(1, insertedPrimaryContactPoints.size(), 'There should be 1 primary ContactPointEmail');
        System.assertEquals(insertedPrimaryContactPoints.get(0).Id, newContactPoints.get(0).Id, 'Id should be the same');

        //List<Scope__c> updatedScopes = [SELECT Id, PrimaryEmail__c FROM Scope__c WHERE Id =: currentScopeId];
        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {currentScopeId});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(insertedPrimaryContactPoints.get(0).EmailAddress, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');

        //List<ContactPointEmail> updatedNotPrimaryContactPoints = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c =: currentScopeId AND IsPrimary = false];
        List<ContactPointEmail> updatedNotPrimaryContactPoints = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {currentScopeId}, false, null
            );
        Set<Id> updatedNotPrimaryContactPointsIds = new Set<Id>();
        for(ContactPointEmail notPrimaryContactPoint: updatedNotPrimaryContactPoints)
        {
            updatedNotPrimaryContactPointsIds.add(notPrimaryContactPoint.Id);
        }

        System.assertEquals(true, updatedNotPrimaryContactPointsIds.contains(firstContactPointEmails.get(0).Id), 'Set should contains the first primary ContactPointEmail already updated');
    }

    /**
     * Test que comprueba que al actualizar un ContactPointEmail como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito y
     * el campo IsPrimary del anterior ContactPointEmail pasa a ser false
     *
     * @author rlopez
     * @date 20/11/2020
     */
    @isTest
    static void test_update_primaryContactPointEmail_update_related_ok()
    {
        String emailToInsert = 'newemail@nts-solutions.com.invalid';

        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'There should be 1 ContactPointEmail');

        List<ContactPointEmail> firstContactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
        Id currentScopeId = firstContactPointEmails.get(0).ScopeId__c;

        //Actualizamos un ContactPointEmail primero
        firstContactPointEmails.get(0).IsPrimary = true;
        update firstContactPointEmails;

        notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, false, null);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> secondContactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
        secondContactPointEmails.get(0).IsPrimary = true;

        Test.startTest();
        update secondContactPointEmails;
        Test.stopTest();

        //Comprobamos que se ha actualizado correctamente
        List<ContactPointEmail> updatedPrimaryContactPoints = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'EmailAddress'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);
        System.assertEquals(1, updatedPrimaryContactPoints.size(), 'There should be 1 primary ContactPointEmail');
        System.assertEquals(updatedPrimaryContactPoints.get(0).Id, secondContactPointEmails.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {currentScopeId});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(updatedPrimaryContactPoints.get(0).EmailAddress, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');

        List<ContactPointEmail> updatedNotPrimaryContactPoints = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {currentScopeId}, false, null
            );
        Set<Id> updatedNotPrimaryContactPointsIds = new Set<Id>();
        for(ContactPointEmail notPrimaryContactPoint: updatedNotPrimaryContactPoints)
        {
            updatedNotPrimaryContactPointsIds.add(notPrimaryContactPoint.Id);
        }

        System.assertEquals(true, updatedNotPrimaryContactPointsIds.contains(firstContactPointEmails.get(0).Id), 'Set should contains the first primary ContactPointEmail already updated');
    }

    /**
     * Test que comprueba que si existe un ContactPointEmail marcado como IsPrimary
     * e intentamos desmarcarlo para que IsPrimary sea false, nos salta un error de
     * que al menos debe existir un ContactPointEmail marcado como IsPrimary
     *
     * @author rlopez
     * @date 20/11/2020
     */
    @isTest
    static void test_update_uncheck_primaryContactPointEmail_ko()
    {
        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> firstContactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
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

    /**
     * Test que comprueba que al insertar un nuevo ContactPointEmail que no esta marcado como IsPrimary,
     * NO se actualiza el campo PrimaryEmail__c del ámbito
     *
     * @author rlopez
     * @date 20/11/2020
     */
    @isTest
    static void test_insert_not_primaryContactPointEmail_ok()
    {
        String emailToInsert = 'newemail@nts-solutions.com.invalid';
        List<Scope__c> relatedScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c LIMIT 1];
        System.assertEquals(1, relatedScopes.size(), 'There should be 1 account');

        Set<Id> relatedScopesIds = new Set<Id>();
        for(Scope__c related: relatedScopes)
        {
            relatedScopesIds.add(related.Id);
        }

        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(relatedScopesIds, false, null);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> relatedContactPointEmails = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
        relatedContactPointEmails.get(0).IsPrimary = true;
        update relatedContactPointEmails;

        List<ContactPointEmail> newContactPoints = new List<ContactPointEmail>();
        newContactPoints.add(
            new ContactPointEmail(
                EmailAddress = emailToInsert,
                ParentId = relatedScopes.get(0).AccountId__c,
                Scope__c = relatedScopes.get(0).Scope__c,
                ScopeId__c = relatedScopes.get(0).Id,
                IsPrimary = false
                )
            );

        Test.startTest();
        insert newContactPoints;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        List<ContactPointEmail> currentContactPoints = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(new Set<Id> {relatedScopes.get(0).Id}, emailToInsert);
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 ContactPointEmail with this EmailAddress');

        //Comprobamos que no está marcado IsPrimary = true en el nuevo ContactPointEmail
        System.assertEquals(false, currentContactPoints.get(0).IsPrimary, 'It should be false');

        //Comprobamos que el ContactPointEmail que estaba marcado como IsPrimary sigue estando marcado
        List<ContactPointEmail> primaryContactPointEmail = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'EmailAddress'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {relatedScopes.get(0).Id}, true, null);
        System.assertEquals(1, primaryContactPointEmail.size(), 'There should be 1 primary ContactPointEmail');

        List<Scope__c> currentScope = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {relatedScopes.get(0).Id});
        System.assertEquals(1, currentScope.size(), 'There should be 1 scope');
        System.assertNotEquals(emailToInsert, currentScope.get(0).PrimaryEmail__c, 'Email should NOT be the same');
        System.assertEquals(primaryContactPointEmail.get(0).EmailAddress, currentScope.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    /**
     * Test que comprueba que si borramos el primary ContactPointEmail de un ámbito,
     * no se marca ningún otro como primary y el ámbito mantiene el valor de PrimaryEmail__c
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_delete_contactPointEmail_ok()
    {
        List<ContactPointEmail> notPrimaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> contactPointEmailsToDelete = new List<ContactPointEmail> {notPrimaryContactPointEmails.get(0)};
        Id currentScopeId = contactPointEmailsToDelete.get(0).ScopeId__c;

        //Actualizamos un ContactPointEmail primero
        contactPointEmailsToDelete.get(0).IsPrimary = true;
        update contactPointEmailsToDelete;

        String currentPrimaryEmail = contactPointEmailsToDelete.get(0).EmailAddress;

        Test.startTest();
        delete contactPointEmailsToDelete;
        Test.stopTest();

        List<ContactPointEmail> primaryContactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary', 'EmailAddress', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);
        System.assertEquals(true, primaryContactPointEmails.isEmpty(), 'List should be empty');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryEmail__c'}
            ).selectById(new Set<Id> {currentScopeId});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(currentPrimaryEmail, updatedScopes.get(0).PrimaryEmail__c, 'Email should be the same');
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada vía de contacto de email
     *
     * @author adelgado
     * @date 09/12/2020
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointEmails.size(); i++)
        {
            contactPointEmails[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointEmails;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts]; //10 creados en el testSetup y 10 creados en el trigger de eventos
        List<ContactPointEmail> contactPointEmailsUpdated = [SELECT Scope__c, ScopeId__c FROM ContactPointEmail];

        System.assertEquals(20, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(ContactPointEmail cpe : contactPointEmailsUpdated)
        {
            System.assert (String.isNotBlank(cpe.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (cpe.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

}