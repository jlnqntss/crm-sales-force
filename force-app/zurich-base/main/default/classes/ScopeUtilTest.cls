/**
 * Test class for ScopeUtil
 *
 * @author nts (agonzalezisasi)
 * @date 30/11/2020
 */
@isTest
public class ScopeUtilTest 
{
    private static final Boolean showDebug = false;
    static final String MESSAGE_TWO_ACCOUNTS = 'There should be 2 accounts';
    static final String MESSAGE_SYNC_MC_FALSE = 'Sync MC should be false';
    static final String TEST_PRIMARY_EMAIL = 'my_email@invalid.com';
    static final String MESSAGE_ACCOUNT_SYNC = 'The first account should be sync.';

    @TestSetup
    static void makeData() {
        
        // Create 2 personal accounts
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        accounts[0].SincronizarMC__pc = false;
        accounts[1].SincronizarMC__pc = false;
        insert accounts;
    }

    /**
     * When inserting scopes, test that the Contactable__c field is filled taking in consideration this fields:
     *  - PrimaryEmail__c
     *  - HasOptedOutOfEmail__c
     *  - PrimaryPhone__c
     * Test that the field SincronizarMC__pc of the personal accounts is also filled correctly depending on 
     * the Contactable__c field of the related Scope
     * 
     * Also test that the field HashedId__c of the Scope is generated correctly.
     * 
     * In scope, 2 should be contactables and 2 not contactables
     * In contact, all should be sync MC because of the 2 scopes contactable
     * 
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     * 
     * @change 15/12/2020 - nts (agonzalezisasi) - Add the test for the HashedId__c field
     */
    @isTest
    static void test_insertScopes_ok()
    {
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account];
        System.assertEquals(2, accounts.size(), MESSAGE_TWO_ACCOUNTS);
        System.assertEquals(false, accounts[0].SincronizarMC__pc, MESSAGE_SYNC_MC_FALSE);
        Account a = accounts[0];

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(new List<Account> {a}, 'ZE', 4);
        System.assertEquals(4, scopes.size(), 'There should be 4 scopes');

        scopes[0].PrimaryPhone__c = '555';
        
        scopes[1].PrimaryEmail__c = TEST_PRIMARY_EMAIL;
        scopes[1].HasOptedOutOfEmail__c = false;

        scopes[2].PrimaryEmail__c = TEST_PRIMARY_EMAIL;
        scopes[2].HasOptedOutOfEmail__c = true;

        scopes[3].PrimaryPhone__c = null;
        scopes[3].PrimaryEmail__c = null;

        
        Test.startTest();
        insert scopes;
        Test.stopTest();

        List<Scope__c> scopesResult = [SELECT Id, Contactable__c, HashedId__c FROM Scope__c WHERE Id IN :scopes];
        // Check Contactable
        System.assertEquals(4, scopesResult.size(), 'There should exist 4 new scopes');
        System.assertEquals(true, scopesResult[0].Contactable__c, 'The first one should be Contactable');
        System.assertEquals(true, scopesResult[1].Contactable__c, 'The Second one should be Contactable');
        System.assertEquals(false, scopesResult[2].Contactable__c, 'The Third one should NOT be Contactable');
        System.assertEquals(false, scopesResult[3].Contactable__c, 'The Fourth one should NOT be Contactable');
        // Check generated Hash Id
        System.assertNotEquals(null, scopesResult[0].HashedId__c, 'The HashedId for the first scope should not be null');
        System.assertNotEquals(null, scopesResult[1].HashedId__c, 'The HashedId for the second scope should not be null');
        System.assertNotEquals(null, scopesResult[2].HashedId__c, 'The HashedId for the third scope should not be null');
        System.assertNotEquals(null, scopesResult[3].HashedId__c, 'The HashedId for the fourth scope should not be null');

        List<Account> accountResults = [SELECT Id, SincronizarMC__pc FROM Account WHERE Id = :a.Id];
        System.assertEquals(1, accountResults.size(), 'There should be 1 account');
        System.assertEquals(true, accountResults[0].SincronizarMC__pc, MESSAGE_ACCOUNT_SYNC);
    }

    /**
     * When updating scopes, check that the field Contactable__c of the Scope and the field SincronizarMC__pc of the
     * personal Account are filled correctly (check test_insertScopes_ok for more details about the logic).
     * 
     * In scope, 1 should not be contactables at first (insert) and then change to contactables after update
     * In contact, all should be sync MC because of the 2 scopes contactable
     * 
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     */
    @isTest
    static void test_updateScopes_ok()
    {
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account ORDER BY Id ASC];
        System.assertEquals(2, accounts.size(), MESSAGE_TWO_ACCOUNTS);
        System.assertEquals(false, accounts[0].SincronizarMC__pc, MESSAGE_SYNC_MC_FALSE);
        System.assertEquals(false, accounts[1].SincronizarMC__pc, MESSAGE_SYNC_MC_FALSE);


        // Scope for the first account
        List<Scope__c> scopesAcc1 = TestDataFactory.generateScopesForEachAccount(new List<Account> {accounts[0]}, 'ZE', 1);
        System.assertEquals(1, scopesAcc1.size(), 'There should be 1 scope');
        scopesAcc1[0].PrimaryEmail__c = TEST_PRIMARY_EMAIL;
        scopesAcc1[0].HasOptedOutOfEmail__c = true;

        // Scope for the second account
        List<Scope__c> scopesAcc2 = TestDataFactory.generateScopesForEachAccount(new List<Account> { accounts[1]}, 'ZEO', 1);
        System.assertEquals(1, scopesAcc2.size(), 'There should be 1 scope');
        scopesAcc2[0].PrimaryPhone__c = '5555';



        List<Scope__c> scopesAll = new List<Scope__c>(scopesAcc1);
        scopesAll.addAll(scopesAcc2);
        insert scopesAll;

        // Check scopes after insert
        List<Scope__c> scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc1];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 new scopes');
        System.assertEquals(false, scopesResult[0].Contactable__c, 'The first scope should not be Contactable');
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc2];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 new scopes');
        System.assertEquals(true, scopesResult[0].Contactable__c, 'The second scope should be Contactable');
        // Check Accounts after insert
        List<Account> accountResult = [SELECT Id, SincronizarMC__pc FROM Account ORDER BY Id ASC];
        System.assertEquals(2, accountResult.size(), MESSAGE_TWO_ACCOUNTS);
        System.assertEquals(false, accountResult[0].SincronizarMC__pc, MESSAGE_ACCOUNT_SYNC);
        System.assertEquals(true, accountResult[1].SincronizarMC__pc, 'The Second account should be sync.');

        Test.startTest();
            scopesAcc1[0].HasOptedOutOfEmail__c = false;
            scopesAcc2[0].PrimaryPhone__c = null;
            update scopesAll;
        Test.stopTest();


        // Check scopes after update
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc1];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 scopes');
        System.assertEquals(true, scopesResult[0].Contactable__c, 'The first scope should be Contactable');
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc2];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 scopes');
        System.assertEquals(false, scopesResult[0].Contactable__c, 'The second scope should NOT be Contactable');

        // Check Accounts after update
        accountResult = [SELECT Id, SincronizarMC__pc FROM Account ORDER BY Id ASC];
        System.assertEquals(2, accountResult.size(), MESSAGE_TWO_ACCOUNTS);
        System.assertEquals(true, accountResult[0].SincronizarMC__pc, MESSAGE_ACCOUNT_SYNC);
        System.assertEquals(false, accountResult[1].SincronizarMC__pc, 'The Second account should be sync.');

        delete scopesResult; // for testing and coverage
    }

    /**
     * Test que comprueba que se añade correctamente el scope a la lista para cambiar el valor Contactable
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_ifAddScopeTrueAddToScopesToSetContatable()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        scopeContext.scopesToSetContatable = new List<Scope__c>();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        Map<Id, Scope__c> oldMap = new Map<Id, Scope__c>();
        oldMap.put(scopes[0].id, scopes[0]);

        Test.startTest();
        scopeContext.ifAddScopeTrueAddToScopesToSetContatable (new Scope__c (Id = scopes[0].Id,Scope__c = scopes[0].Scope__c, PrimaryPhone__c = '607324587'), oldMap);
        Test.stopTest();

        System.assertEquals(1, scopeContext.scopesToSetContatable.size(), 'Debería haber un scope ');
        System.assertEquals(scopes[0].Id, scopeContext.scopesToSetContatable[0].id, 'El scope a actualizar no es correcto');
    }

    /**
     * Test que comprueba que se añade correctamente la cuenta a la lista para actualizar cuentas y actualiza correctamente el campo SincronizarMC__pc 
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_checkIfAccountHasToBeUpdated()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        scopeContext.accountsToUpdate = new List<Account>();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        Account accountToCheck = [Select id,SincronizarMC__pc, (Select id,Contactable__c from Scope__r) from Account where id =:accounts[0].id];
        accountToCheck.SincronizarMC__pc = true;

        Test.startTest();
        scopeContext.checkIfAccountHasToBeUpdated(accountToCheck);
        Test.stopTest();

        System.assertEquals(1, scopeContext.accountsToUpdate.size(), 'Debería haber una cuenta a actualizar ');
        System.assertEquals(accounts[0].Id, scopeContext.accountsToUpdate[0].id, 'La cuenta a actualizar no es correcta');
        System.assertEquals(false, scopeContext.accountsToUpdate[0].SincronizarMC__pc, 'El valor a actualizar no es correcto');
    }

    /**
     * Test que comprueba que se genera correctamente un hashid para el scope si el mapa de scopes a actualizar es nulo
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_generateHashForScopeMapNull()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        scopeContext.scopesToUpdateAfter = new Map<ID, Scope__c>();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        Test.startTest();
        scopeContext.generateHashForScope (scopes[0]);
        Test.stopTest();

        System.assertEquals(1, scopeContext.scopesToUpdateAfter.size(), 'Debería haber un scope ha actualizar');
        System.assertNotEquals(null, scopeContext.scopesToUpdateAfter.values()[0].HashedId__c, 'El hashid no debería ser nulo');
    }

    /**
     * Test que comprueba que se genera correctamente un hashid para el scope si el mapa de scopes a actualizar no es nulo
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_generateHashForScopeMapNotNull()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        scopeContext.scopesToUpdateAfter = new Map<ID, Scope__c>();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        scopeContext.scopesToUpdateAfter.put (scopes[0].id, scopes[0]);

        Test.startTest();
        scopeContext.generateHashForScope (scopes[0]);
        Test.stopTest();

        System.assertNotEquals(null, scopeContext.scopesToUpdateAfter.values()[0].HashedId__c, 'El hashid no debería ser nulo');
    }

    /**
     * Test que comprueba que se añaden correctamente los errores si ha habido algún error al actualizar el objeto
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_checkIfThereAnyErrorInUpdate()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        scopes[0].Contactable__c = true;

        List<Database.SaveResult> listaSaveResult = Database.update(scopes, false);

        Test.startTest();
        Map<ID, List<Database.Error>> mapOfErrors = scopeContext.checkIfThereAnyErrorInUpdate (listaSaveResult);
        Test.stopTest();

        System.assertEquals(1, mapOfErrors.size(), 'Debería haber un error');
    }

    /**
     * Test que comprueba que se generan correctamente los errores al actualizar un objeto
     *
     * @author aberuete
     * @date 27/04/2023
     */
    @isTest
    static void test_doUpdateWithErrors()
    {
        ScopeUtil scopeContext = new ScopeUtil();
        List<Account> accounts = [SELECT Id, SincronizarMC__pc FROM Account limit 1];
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        scopes[0].Contactable__c = true;

        Test.startTest();
        scopeContext.doUpdate(scopes);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
    }

}