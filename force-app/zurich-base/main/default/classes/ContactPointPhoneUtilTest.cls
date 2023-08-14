/**
 * Clases de test para ContactPointPhoneUtil
 **
 * @author rlopez
 * @date 23/11/2020
 */
@isTest(SeeAllData=false)
private with sharing class ContactPointPhoneUtilTest
{
    static final String MESSAGE_ONE_CONTACT_POINT_PHONE = 'There should be 1 primary ContactPointPhone';
    static final String MESSAGE_ONE_SCOPE = 'There should be 1 scope';
    static final String MESSAGE_SAME_PHONE = 'Phone should be the same';
    static final String MESSAGE_LIST_NOT_EMPTY = 'List should NOT be empty';
    static final String MESSAGE_FORMATTED_PHONE_WRONG = 'Se ha formateado el teléfono de forma incorrecta';
    static final String PHONE_TEST = '+34123456789';

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
        System.assertEquals(1, currentContactPoints.size(), MESSAGE_ONE_CONTACT_POINT_PHONE);

        List<Scope__c> updatedScopes = new ScopesSelector(new Set<String> {'Id', 'PrimaryPhone__c'}).selectById(new Set<Id> {relatedScopes.get(0).Id});
        System.assertEquals(1, updatedScopes.size(), MESSAGE_ONE_SCOPE);
        System.assertEquals(phoneToInsert, updatedScopes.get(0).PrimaryPhone__c, MESSAGE_SAME_PHONE);
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
        System.assertEquals(false, contactPointPhones.isEmpty(),MESSAGE_LIST_NOT_EMPTY);

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
        System.assertEquals(1, currentContactPoints.size(), MESSAGE_ONE_CONTACT_POINT_PHONE);

        List<Scope__c> updatedScopes = new ScopesSelector(new Set<String> {'Id', 'PrimaryPhone__c'}).selectById(new Set<Id> {contactPointPhonesToUpdate.get(0).ScopeId__c});
        System.assertEquals(1, updatedScopes.size(), MESSAGE_ONE_SCOPE);
        System.assertEquals(contactPointPhonesToUpdate.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, MESSAGE_SAME_PHONE);
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
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), MESSAGE_LIST_NOT_EMPTY);

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

        System.assertEquals(1, insertedPrimaryContactPoints.size(), MESSAGE_ONE_CONTACT_POINT_PHONE);
        System.assertEquals(insertedPrimaryContactPoints.get(0).Id, newContactPoints.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {currentScopeId});

        System.assertEquals(1, updatedScopes.size(), MESSAGE_ONE_SCOPE);
        System.assertEquals(insertedPrimaryContactPoints.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, MESSAGE_SAME_PHONE);

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
        List<ContactPointPhone> notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByIsPrimary(false);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), MESSAGE_LIST_NOT_EMPTY);

        List<ContactPointPhone> firstContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

        Id currentScopeId = firstContactPointPhones.get(0).ScopeId__c;

        //Actualizamos un ContactPointPhone primero
        firstContactPointPhones.get(0).IsPrimary = true;
        update firstContactPointPhones;

        notPrimaryContactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary', 'TelephoneNumber', 'ParentId', 'Scope__c', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, false, null);
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), MESSAGE_LIST_NOT_EMPTY);

        List<ContactPointPhone> secondContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};
        secondContactPointPhones.get(0).IsPrimary = true;

        Test.startTest();
        update secondContactPointPhones;
        Test.stopTest();

        //Comprobamos que se ha actualizado correctamente
        List<ContactPointPhone> updatedPrimaryContactPoints = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'TelephoneNumber'}
            ).selectByScopeIdAndIsPrimary(new Set<Id> {currentScopeId}, true, null);
        System.assertEquals(1, updatedPrimaryContactPoints.size(), MESSAGE_ONE_CONTACT_POINT_PHONE);
        System.assertEquals(updatedPrimaryContactPoints.get(0).Id, secondContactPointPhones.get(0).Id, 'Id should be the same');

        List<Scope__c> updatedScopes = new ScopesSelector(
            new Set<String> {'Id', 'PrimaryPhone__c'}
            ).selectById(new Set<Id> {currentScopeId});

        System.assertEquals(1, updatedScopes.size(), MESSAGE_ONE_SCOPE);
        System.assertEquals(updatedPrimaryContactPoints.get(0).TelephoneNumber, updatedScopes.get(0).PrimaryPhone__c, MESSAGE_SAME_PHONE);

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
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), MESSAGE_LIST_NOT_EMPTY);

        List<ContactPointPhone> firstContactPointPhones = new List<ContactPointPhone> {notPrimaryContactPointPhones.get(0)};

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
        System.assertEquals(false, notPrimaryContactPointPhones.isEmpty(), MESSAGE_LIST_NOT_EMPTY);

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
        System.assertEquals(1, updatedScopes.size(), MESSAGE_ONE_SCOPE);
        System.assertEquals(currentPrimaryEmail, updatedScopes.get(0).PrimaryPhone__c, MESSAGE_SAME_PHONE);
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

    /**
     * Test que comprueba que no se devuelve un teléfono formateado si no viene informado
     *
     * @author adelgado
     * @date 18/01/2021
     */
    @isTest
    static void test_formatPhoneNumber_nullValues()
    {
        Test.startTest();
        String formattedNumber = ContactPointPhoneUtil.formatPhoneNumber(null, null);
        Test.stopTest();

        System.assertEquals(null, formattedNumber, 'Se ha formateado el teléfono y no deberia');
    }

    /**
     * Test que comprueba que se devuelve un teléfono formateado si no viene informado el prefijo
     *
     * @author adelgado
     * @date 18/01/2021
     */
    @isTest
    static void test_formatPhoneNumber_nullAreaCode()
    {
        Test.startTest();
        String formattedNumber = ContactPointPhoneUtil.formatPhoneNumber(null, '123456789');
        Test.stopTest();

        System.assertEquals('123456789', formattedNumber, MESSAGE_FORMATTED_PHONE_WRONG);
    }

    /**
     * Test que comprueba que se devuelve un teléfono formateado si viene informado el prefijo con un '+'
     *
     * @author adelgado
     * @date 18/01/2021
     */
    @isTest
    static void test_formatPhoneNumber_areaCodePlus()
    {
        Test.startTest();
        String formattedNumber = ContactPointPhoneUtil.formatPhoneNumber('+34', '123456789');
        Test.stopTest();

        System.assertEquals(PHONE_TEST, formattedNumber, MESSAGE_FORMATTED_PHONE_WRONG);
    }

    /**
     * Test que comprueba que se devuelve un teléfono formateado si viene informado el prefijo sin un '+'
     *
     * @author adelgado
     * @date 18/01/2021
     */
    @isTest
    static void test_formatPhoneNumber_areaCodeWithoutPlus()
    {
        Test.startTest();
        String formattedNumber = ContactPointPhoneUtil.formatPhoneNumber('34', '123456789');
        Test.stopTest();

        System.assertEquals(PHONE_TEST, formattedNumber, MESSAGE_FORMATTED_PHONE_WRONG);
    }

    /**
     * Test que comprueba que se devuelve un teléfono formateado si viene informado el teléfono con un '+'
     *
     * @author adelgado
     * @date 18/01/2021
     */
    @isTest
    static void test_formatPhoneNumber_phoneNumberPlus()
    {
        Test.startTest();
        String formattedNumber = ContactPointPhoneUtil.formatPhoneNumber('+34', '+34123456789');
        Test.stopTest();

        System.assertEquals(PHONE_TEST, formattedNumber, MESSAGE_FORMATTED_PHONE_WRONG);
    }

    
    /**
     * Test que comprueba que se rellena correctamente el mapa de contact point phones a actualizar
     *
     * @author aberuete
     * @date 26/04/2023
     */
    @isTest
    static void test_updateMapContactPointPhones()
    {
        List<ContactPointPhone> newContactPointPhone = [Select id,ScopeId__c from ContactPointPhone where ScopeId__c != null limit 2];
        System.assertEquals(2, newContactPointPhone.size(), 'Deberían existir al menos dos contact point email con el scopeId distinto a nulo');
        ContactPointPhoneUtil.relatedContactPointPhonesMap = new Map<Id, List<ContactPointPhone> >();
        ContactPointPhoneUtil.contactPointPhonesToUpdate = new Map<Id, ContactPointPhone>();

        ContactPointPhoneUtil.relatedContactPointPhonesMap.put(newContactPointPhone[0].ScopeId__c, newContactPointPhone);

        Test.startTest();
        ContactPointPhoneUtil.updateMapContactPointPhones(newContactPointPhone[0].ScopeId__c, newContactPointPhone[1]);
        Test.stopTest();

        System.assertEquals(new Set<Id>{newContactPointPhone[0].id}, ContactPointPhoneUtil.contactPointPhonesToUpdate.keySet(), 'Debería estar en el mapa a actualizar');
        System.assertEquals(false, ContactPointPhoneUtil.contactPointPhonesToUpdate.values().IsPrimary, 'El campo se debería haber actualizado a falso');
    }

    /**
     * Test que comprueba que se rellena correctamente el mapa de scopes a actualizar
     *
     * @author aberuete
     * @date 26/04/2023
     */
    @isTest
    static void test_updateMapScopesToUpdate()
    {
        List<ContactPointPhone> newContactPointPhone = [Select id,ScopeId__c,TelephoneNumber, AreaCode from ContactPointPhone where ScopeId__c != null and TelephoneNumber != null limit 1];
        System.assertEquals(1, newContactPointPhone.size(), 'Debería existir al menos un contact point email con el scopeId y el teléfono distinto a nulo');

        List<Scope__c> scopeToContactPoint = [Select id from Scope__c where id =:newContactPointPhone[0].ScopeId__c limit 1];
        System.assertEquals(1, scopeToContactPoint.size(), 'Debería existir al menos un scope');

        ContactPointPhoneUtil.scopesToUpdate = new Map<Id, Scope__c>();
        ContactPointPhoneUtil.relatedScopesMap = new Map<Id, Scope__c>();
        ContactPointPhoneUtil.relatedScopesMap.put(scopeToContactPoint[0].id, scopeToContactPoint[0]);

        Test.startTest();
        ContactPointPhoneUtil.updateMapScopesToUpdate(newContactPointPhone[0].ScopeId__c, newContactPointPhone[0]);
        Test.stopTest();

        System.assertEquals(new Set<Id>{scopeToContactPoint[0].id}, ContactPointPhoneUtil.scopesToUpdate.keySet(), 'Debería estar en el mapa a actualizar');
        System.assertEquals(newContactPointPhone[0].TelephoneNumber, ContactPointPhoneUtil.scopesToUpdate.values().PrimaryPhone__c, 'El campo se debería haber actualizado al teléfono del nuevo contact point');
    }

    /**
     * Test que comprueba que en caso de que no haya ningun contact point phone relacionado que sea primario , lanza un error
     *
     * @author aberuete
     * @date 26/04/2023
     */
    @isTest
    static void test_ifIsPrimaryFoundFalseThrowError()
    {
        List<ContactPointPhone> newContactPointPhone = [Select id,ScopeId__c,isPrimary from ContactPointPhone where ScopeId__c != null and isPrimary = false limit 2];
        System.assertEquals(2, newContactPointPhone.size(), 'Deberían existir al menos dos contact point email con el scopeId distinto a nulo');
        ContactPointPhoneUtil.relatedContactPointPhonesMap = new Map<Id, List<ContactPointPhone> >();

        ContactPointPhoneUtil.relatedContactPointPhonesMap.put(newContactPointPhone[0].ScopeId__c, newContactPointPhone);

        Test.startTest();
        ContactPointPhoneUtil.ifIsPrimaryFoundFalseThrowError(newContactPointPhone[0].ScopeId__c, newContactPointPhone[1]);
        Test.stopTest();

        System.assertEquals(Label.PrimaryContactPointPhoneRequired, newContactPointPhone[1].getErrors()[0].getMessage(), 'Debería tener un error asociado');
    }
}