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
        System.assertEquals(2, accounts.size(), 'There should be 2 accounts');
        System.assertEquals(false, accounts[0].SincronizarMC__pc, 'Sync MC should be false');
        Account a = accounts[0];

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(new List<Account> {a}, 'ZE', 4);
        System.assertEquals(4, scopes.size(), 'There should be 4 scopes');

        scopes[0].PrimaryPhone__c = '555';
        
        scopes[1].PrimaryEmail__c = 'my_email@invalid.com';
        scopes[1].HasOptedOutOfEmail__c = false;

        scopes[2].PrimaryEmail__c = 'my_email@invalid.com';
        scopes[2].HasOptedOutOfEmail__c = true;

        scopes[3].PrimaryPhone__c = null;
        scopes[3].PrimaryEmail__c = null;

        // insert scopes;
        Test.startTest();
        insert scopes;
        Test.stopTest();

        if( showDebug ) 
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
        System.assertEquals(true, accountResults[0].SincronizarMC__pc, 'The first account should be sync.');
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
        System.assertEquals(2, accounts.size(), 'There should be 2 accounts');
        System.assertEquals(false, accounts[0].SincronizarMC__pc, 'Sync MC should be false');
        System.assertEquals(false, accounts[1].SincronizarMC__pc, 'Sync MC should be false');


        // Scope for the first account
        List<Scope__c> scopesAcc1 = TestDataFactory.generateScopesForEachAccount(new List<Account> {accounts[0]}, 'ZE', 1);
        System.assertEquals(1, scopesAcc1.size(), 'There should be 1 scope');
        scopesAcc1[0].PrimaryEmail__c = 'my_email@invalid.com';
        scopesAcc1[0].HasOptedOutOfEmail__c = true;
        // scopes[0].PrimaryPhone__c = '5555';


        // Scope for the second account
        List<Scope__c> scopesAcc2 = TestDataFactory.generateScopesForEachAccount(new List<Account> { accounts[1]}, 'ZEO', 1);
        System.assertEquals(1, scopesAcc2.size(), 'There should be 1 scope');
        scopesAcc2[0].PrimaryPhone__c = '5555';



        List<Scope__c> scopesAll = new List<Scope__c>(scopesAcc1);
        scopesAll.addAll(scopesAcc2);
        insert scopesAll;

        if( showDebug ) 
        // Check scopes after insert
        List<Scope__c> scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc1];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 new scopes');
        System.assertEquals(false, scopesResult[0].Contactable__c, 'The first scope should not be Contactable');
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc2];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 new scopes');
        System.assertEquals(true, scopesResult[0].Contactable__c, 'The second scope should be Contactable');
        // Check Accounts after insert
        List<Account> accountResult = [SELECT Id, SincronizarMC__pc FROM Account ORDER BY Id ASC];
        System.assertEquals(2, accountResult.size(), 'There should be 2 accounts');
        System.assertEquals(false, accountResult[0].SincronizarMC__pc, 'The first account should be sync.');
        System.assertEquals(true, accountResult[1].SincronizarMC__pc, 'The Second account should be sync.');

        // update scopes;
        Test.startTest();
            scopesAcc1[0].HasOptedOutOfEmail__c = false;
            scopesAcc2[0].PrimaryPhone__c = null;
            update scopesAll;
        Test.stopTest();

        if( showDebug ) 

        // Check scopes after update
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc1];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 scopes');
        System.assertEquals(true, scopesResult[0].Contactable__c, 'The first scope should be Contactable');
        scopesResult = [SELECT Id, Contactable__c FROM Scope__c WHERE Id IN :scopesAcc2];
        System.assertEquals(1, scopesResult.size(), 'There should exist 1 scopes');
        System.assertEquals(false, scopesResult[0].Contactable__c, 'The second scope should NOT be Contactable');

        // Check Accounts after update
        accountResult = [SELECT Id, SincronizarMC__pc FROM Account ORDER BY Id ASC];
        System.assertEquals(2, accountResult.size(), 'There should be 2 accounts');
        System.assertEquals(true, accountResult[0].SincronizarMC__pc, 'The first account should be sync.');
        System.assertEquals(false, accountResult[1].SincronizarMC__pc, 'The Second account should be sync.');

        delete scopesResult; // for testing and coverage
    }
}
