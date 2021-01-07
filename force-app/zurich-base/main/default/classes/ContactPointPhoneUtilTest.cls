/**
 * Clases de test para ContactPointPhoneUtil
 **
 * @author rlopez
 * @date 23/11/2020
 */
@isTest(SeeAllData=false)
private with sharing class ContactPointPhoneUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Scope__c> insertedScopes = [SELECT Id, AccountId__c, Scope__c, AccountId__r.Name FROM Scope__c WHERE Id IN: scopes];

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromScopes(insertedScopes, 10);
        insert contactPointPhones;
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointPhone marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryPhone__c del ámbito
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_insert_primaryContactPointPhone_ok()
    {
        String phoneToInsert = '123456789';
        List<Scope__c> relatedScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c LIMIT 1];
        System.assertEquals(1, relatedScopes.size(), 'There should be 1 account');

        List<ContactPointPhone> newContactPoints = new List<ContactPointPhone>();
        newContactPoints.add(
            new ContactPointPhone(
                TelephoneNumber = phoneToInsert,
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
        List<ContactPointPhone> currentContactPoints = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {relatedScopes.get(0).Id}, true, null
            );
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointPhone');

        List<Scope__c> updatedScopes = new ScopesSelector(new Set<String> {'Id', 'PrimaryPhone__c'}).selectById(new Set<Id> {relatedScopes.get(0).Id});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(phoneToInsert, updatedScopes.get(0).PrimaryPhone__c, 'Phone should be the same');
    }

    /**
     * Test que comprueba que al actualizar un ContactPointPhone como IsPrimary,
     * se actualiza correctamente el campo PrimaryPhone__c del ámbito
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_update_primaryContactPointPhone_ok()
    {
        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ScopeId__c'}).selectByIsPrimary(false);
        System.assertEquals(false, contactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> contactPointPhonesToUpdate = new List<ContactPointPhone> {contactPointPhones.get(0)};
        contactPointPhonesToUpdate.get(0).IsPrimary = true;

        Test.startTest();
        update contactPointPhonesToUpdate;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        //List<ContactPointPhone> currentContactPoints = [SELECT Id FROM ContactPointPhone WHERE ScopeId__c =: contactPointPhonesToUpdate.get(0).ScopeId__c AND IsPrimary = true];
        List<ContactPointPhone> currentContactPoints = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {contactPointPhonesToUpdate.get(0).ScopeId__c}, true, null
            );
        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 primary ContactPointPhone');

        List<Scope__c> updatedScopes = new ScopesSelector(new Set<String> {'Id', 'PrimaryPhone__c'}).selectById(new Set<Id> {contactPointPhonesToUpdate.get(0).ScopeId__c});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(contactPointPhonesToUpdate.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, 'Phone should be the same');
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointPhone marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryPhone__c del ámbito y
     * el campo IsPrimary del anterior ContactPointPhone pasa a ser false
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_insert_primaryContactPointPhone_update_related_ok()
    {
        String phoneToInsert = '123456789';

        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> firstContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        Id currentScopeId = firstContactPointPhones.get(0).ScopeId__c;

        //Actualizamos un ContactPointPhone primero
        firstContactPointPhones.get(0).IsPrimary = true;
        update firstContactPointPhones;

        List<ContactPointPhone> newContactPoints = new List<ContactPointPhone>();
        newContactPoints.add(
            new ContactPointPhone(
                TelephoneNumber = phoneToInsert,
                ParentId = firstContactPointPhones.get(0).ParentId,
                Scope__c = firstContactPointPhones.get(0).Scope__c,
                ScopeId__c = currentScopeId,
                IsPrimary = true
                )
            );

        Test.startTest();
        insert newContactPoints;
        Test.stopTest();

        //Comprobamos que se ha insertado correctamente
        List<ContactPointPhone> insertedPrimaryContactPoints = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'TelephoneNumber'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);

        System.assertEquals(1, insertedPrimaryContactPoints.size(), 'There should be 1 primary ContactPointPhone');
        System.assertEquals(insertedPrimaryContactPoints.get(0).Id, newContactPoints.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {currentScopeId});

        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(insertedPrimaryContactPoints.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, 'Phone should be the same');

        List<ContactPointPhone> updatedNotPrimaryContactPoints = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {currentScopeId}, false, null
            );
        Set<Id> updatedNotPrimaryContactPointsIds = new Set<Id>();
        for(ContactPointPhone notPrimaryContactPoint: updatedNotPrimaryContactPoints)
        {
            updatedNotPrimaryContactPointsIds.add(notPrimaryContactPoint.Id);
        }

        System.assertEquals(true, updatedNotPrimaryContactPointsIds.contains(firstContactPointPhones.get(0).Id), 'Set should contains the first primary ContactPointPhone already updated');
    }

    /**
     * Test que comprueba que al actualizar un ContactPointPhone como IsPrimary,
     * se actualiza correctamente el campo PrimaryPhone__c del ámbito y
     * el campo IsPrimary del anterior ContactPointPhone pasa a ser false
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_update_primaryContactPointPhone_update_related_ok()
    {
        String phoneToInsert = '123456789';

        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> firstContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        Id currentScopeId = firstContactPointPhones.get(0).ScopeId__c;

        //Actualizamos un ContactPointPhone primero
        firstContactPointPhones.get(0).IsPrimary = true;
        update firstContactPointPhones;

        notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, false, null);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> secondContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};
        secondContactPointPhones.get(0).IsPrimary = true;

        Test.startTest();
        update secondContactPointPhones;
        Test.stopTest();

        //Comprobamos que se ha actualizado correctamente
        List<ContactPointPhone> updatedPrimaryContactPoints = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'TelephoneNumber'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);
        System.assertEquals(1, updatedPrimaryContactPoints.size(), 'There should be 1 primary ContactPointPhone');
        System.assertEquals(updatedPrimaryContactPoints.get(0).Id, secondContactPointPhones.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {currentScopeId});

        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(updatedPrimaryContactPoints.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, 'Phone should be the same');

        List<ContactPointPhone> updatedNotPrimaryContactPoints = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {currentScopeId}, false, null
            );
        Set<Id> updatedNotPrimaryContactPointsIds = new Set<Id>();
        for(ContactPointPhone notPrimaryContactPoint: updatedNotPrimaryContactPoints)
        {
            updatedNotPrimaryContactPointsIds.add(notPrimaryContactPoint.Id);
        }

        System.assertEquals(true, updatedNotPrimaryContactPointsIds.contains(firstContactPointPhones.get(0).Id), 'Set should contains the first primary ContactPointPhone already updated');
    }

    /**
     * Test que comprueba que si existe un ContactPointPhone marcado como IsPrimary
     * e intentamos desmarcarlo para que IsPrimary sea false, nos salta un error de
     * que al menos debe existir un ContactPointPhone marcado como IsPrimary
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_update_uncheck_primaryContactPointPhone_ko()
    {
        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> firstContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        Id currentScopeId = firstContactPointPhones.get(0).ScopeId__c;

        //Actualizamos un ContactPointPhone primero
        firstContactPointPhones.get(0).IsPrimary = true;
        update firstContactPointPhones;

        firstContactPointPhones.get(0).IsPrimary = false;

        Test.startTest();
        try
        {
            update firstContactPointPhones;
        }
        catch (DmlException ex)
        {
            System.assertEquals(true, ex.getMessage().contains('There should be at least one primary contact point phone'), 'It should contains that error message');
        }
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointPhone que no esta marcado como IsPrimary,
     * NO se actualiza el campo PrimaryPhone__c del ámbito
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_insert_not_primaryContactPointPhone_ok()
    {
        String phoneToInsert = '123456789';
        List<Scope__c> relatedScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c LIMIT 1];
        System.assertEquals(1, relatedScopes.size(), 'There should be 1 scope');

        Set<Id> relatedScopesIds = new Set<Id>();
        for(Scope__c scope: relatedScopes)
        {
            relatedScopesIds.add(scope.Id);
        }

        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(relatedScopesIds, false, null);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> relatedContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        relatedContactPointPhones.get(0).IsPrimary = true;
        update relatedContactPointPhones;

        List<ContactPointPhone> newContactPoints = new List<ContactPointPhone>();
        newContactPoints.add(
            new ContactPointPhone(
                TelephoneNumber = phoneToInsert,
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
        List<ContactPointPhone> currentContactPoints = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(new Set<Id> {relatedScopes.get(0).Id}, phoneToInsert);

        System.assertEquals(1, currentContactPoints.size(), 'There should be 1 ContactPointPhone with this TelephoneNumber');

        //Comprobamos que no está marcado IsPrimary = true en el nuevo ContactPointPhone
        System.assertEquals(false, currentContactPoints.get(0).IsPrimary, 'It should be false');

        //Comprobamos que el ContactPointPhone que estaba marcado como IsPrimary sigue estando marcado
        List<ContactPointPhone> primaryContactPointPhone = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'TelephoneNumber'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {relatedScopes.get(0).Id}, true, null);

        System.assertEquals(1, primaryContactPointPhone.size(), 'There should be 1 primary ContactPointPhone');

        List<Scope__c> currentScope = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {relatedScopes.get(0).Id});

        System.assertEquals(1, currentScope.size(), 'There should be 1 scope');
        System.assertNotEquals(phoneToInsert, currentScope.get(0).PrimaryPhone__c, 'Phone should NOT be the same');
        System.assertEquals(primaryContactPointPhone.get(0).TelephoneNumber, currentScope.get(0).PrimaryPhone__c, 'Phone should be the same');
    }

    /**
     * Test que comprueba que si borramos el primary ContactPointPhone de un ámbito,
     * no se marca ningún otro como primary y el ámbito mantiene el valor de PrimaryPhone__c
     *
     * @author rlopez
     * @date 23/11/2020
     */
    @isTest
    static void test_delete_ContactPointPhone_ok()
    {
        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> contactPointPhonesToDelete = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        Id currentScopeId = contactPointPhonesToDelete.get(0).ScopeId__c;

        //Actualizamos un ContactPointPhone primero
        contactPointPhonesToDelete.get(0).IsPrimary = true;
        update contactPointPhonesToDelete;

        String currentPrimaryEmail = contactPointPhonesToDelete.get(0).TelephoneNumber;

        Test.startTest();
        delete contactPointPhonesToDelete;
        Test.stopTest();

        List<ContactPointPhone> primaryContactPointPhones = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(
            new Set<Id> {currentScopeId}, true, null
            );
        System.assertEquals(true, primaryContactPointPhones.isEmpty(), 'List should be empty');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {currentScopeId});
        System.assertEquals(1, updatedScopes.size(), 'There should be 1 scope');
        System.assertEquals(currentPrimaryEmail, updatedScopes.get(0).PrimaryPhone__c, 'Phone should be the same');
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

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointPhones.size(); i++)
        {
            contactPointPhones[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointPhones;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts]; //10 creados en el testSetup y 10 creados en el trigger de eventos
        List<ContactPointPhone> contactPointPhonesUpdated = [SELECT Scope__c, ScopeId__c FROM ContactPointPhone];

        System.assertEquals(20, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(ContactPointPhone cpp : contactPointPhonesUpdated)
        {
            System.assert (String.isNotBlank(cpp.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (cpp.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

    /**
     * Test que comprueba que se informa el email primario en el scope
     *
     * @author adelgado
     * @date 04/01/2021
     */
    @isTest
    static void test_setScopePrimaryPhone()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointPhones.size(); i++)
        {
            contactPointPhones[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointPhones;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, PrimaryPhone__c FROM Scope__c WHERE AccountId__c IN : accounts];

        System.assertEquals(20, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(Scope__c scope : scopes)
        {
            System.assert (String.isNotBlank(scope.PrimaryPhone__c), 'No se ha informado el teléfono principal del scope');
        }
    }
}