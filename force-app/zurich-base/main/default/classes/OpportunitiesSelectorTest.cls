@isTest
private with sharing class OpportunitiesSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 10);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 1);
        insert policies;

        Map<ID, Policy__c> mapPoliciesById = new Map<ID, Policy__c>(policies);

        List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy('Address', policies, 1);
        // Cambiamos los asset para que vayan por oferta en vez de por poliza
        for(Asset a: insuredObjects) {
            a.OfferId__c = mapPoliciesById.get(a.PolicyId__c).OpportunityName__c;
            a.PolicyId__c = null;
        }
        insert insuredObjects;
    }

    @isTest
    static void test_selectByAccountIdAndScopes_matchedRecords()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        for(Scope__c scope: existingScopes)
        {
            scopesIds.add(scope.Id);
        }

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdAndScopes(
            existingScopes.get(0).AccountId__c, scopesIds);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Opportunity matchedOpp: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedOpp.ScopeId__c), 'Set should contain the Id');
            System.assertEquals(true, matchedOpp.AccountId == existingScopes.get(0).AccountId__c, 'AccountId should be the same');
        }
    }

    @isTest
    static void test_selectByAccountIdAndScopes_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdAndScopes(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdScopesAndOwnerProfile_matchedRecords()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        for(Scope__c scope: existingScopes)
        {
            scopesIds.add(scope.Id);
        }

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdScopesAndOwnerProfile(
            existingScopes.get(0).AccountId__c, scopesIds, new Set<String> {'System Administrator'});
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        Set<Id> ownerIds = new Set<Id>();
        for(Opportunity matchedOpp: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedOpp.ScopeId__c), 'Set should contain the Id');
            System.assertEquals(true, matchedOpp.AccountId == existingScopes.get(0).AccountId__c, 'AccountId should be the same');
            ownerIds.add(matchedOpp.OwnerId);
        }

        List<User> owners = [SELECT Id, Profile.Name FROM User WHERE Id IN: ownerIds];
        System.assertEquals(false, owners.isEmpty(), 'List should NOT be empty');
        for(User retrievedOwner: owners)
        {
            System.assertEquals(true, retrievedOwner.Profile.Name == 'System Administrator', 'Profile should be admin');
        }
    }

    @isTest
    static void test_selectByAccountIdScopesAndOwnerProfile_matchedRecords_emptyResults()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        for(Scope__c scope: existingScopes)
        {
            scopesIds.add(scope.Id);
        }

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdScopesAndOwnerProfile(
            existingScopes.get(0).AccountId__c, scopesIds, new Set<String> {'ZE User'});
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdScopesAndOwnerProfile_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdScopesAndOwnerProfile(null, null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_findByAccountIdAndScope()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<Opportunity> offers = new OpportunitiesSelector().findByAccountIdAndScope(
            existingScopes[0].AccountId__c, existingScopes[0].Scope__c
        );
        Test.stopTest();

        System.assertEquals(false, offers.isEmpty(), 'There should be same offers');
    }

    @isTest
    static void test_findById()
    {
        List<Opportunity> existingOpportunities = [SELECT Id FROM Opportunity];

        Test.startTest();
        List<Opportunity> offers = new OpportunitiesSelector().findById(
            existingOpportunities[0].Id
        );
        Test.stopTest();

        System.assertEquals(false, offers.isEmpty(), 'There should be same offers');
    }

    @isTest
    static void test_findById_byUser()
    {

        List<PermissionSetAssignment> usuarios = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'ZE_Advisor' AND Assignee.isActive = True];
        User u = [Select Id FROM User WHERE Id = :usuarios.get(0).AssigneeId];

        List<Opportunity> existingOpportunities = [SELECT Id FROM Opportunity];
        existingOpportunities.get(0).OwnerId = u.id;
        upsert existingOpportunities.get(0);

        System.runAs(u)
        {
            Test.startTest();
            List<Opportunity> offers = new OpportunitiesSelector().findById(
                existingOpportunities[0].Id
            );
            Test.stopTest();

            System.assertEquals(false, offers.isEmpty(), 'There should be same offers');
        }
    }

    @isTest
    static void test_findByAccountIdAndScopeNotId()
    {
        List<Opportunity> existingOpportunities = [SELECT Id, AccountId, ScopeId__c FROM Opportunity];

        Test.startTest();
        List<Opportunity> offers = new OpportunitiesSelector().findByAccountIdAndScopeAndNotId(
            existingOpportunities.get(0).Id, existingOpportunities.get(0).AccountId, existingOpportunities.get(0).ScopeId__c
        );
        Test.stopTest();

        System.assertEquals(false, offers.isEmpty());
    }

    @isTest
    static void test_findByAccountIdAndScopeNotId_byUser()
    {
        List<PermissionSetAssignment> usuarios = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'ZE_Advisor' AND Assignee.isActive = True];
        System.assertNotEquals(0, usuarios.size(), 'Ha de haber por lo menos un usuario con el permission set requerido');
        User u = [Select Id FROM User WHERE Id = :usuarios.get(0).AssigneeId];

        List<Opportunity> existingOpportunities = [SELECT Id, AccountId, ScopeId__c FROM Opportunity];
        for (Opportunity o : existingOpportunities)
        {
            o.OwnerId = u.id;
        }
        upsert existingOpportunities;
        existingOpportunities = [SELECT Id, AccountId, ScopeId__c FROM Opportunity];
        
        System.runAs(u)
        {
            Test.startTest();
            List<Opportunity> offers = new OpportunitiesSelector().findByAccountIdAndScopeAndNotId(
                existingOpportunities.get(0).Id, existingOpportunities.get(0).AccountId, existingOpportunities.get(0).ScopeId__c
            );
            Test.stopTest();
    
            System.assertEquals(false, offers.isEmpty());
        }
    }

    @isTest 
    static void test_findUpdatedFromInfoByQuoteNumber()
    {
        List<Opportunity> existingOpportunities = [SELECT Id, isUpdatedFromINFO__c, InfoQuoteNumber__c FROM Opportunity];
        
        // Actualizamos tres oportunidades metiéndoles InfoNumber y el flag
        existingOpportunities.get(0).InfoQuoteNumber__c = 'ACB123';
        existingOpportunities.get(0).isUpdatedFromINFO__c = true;

        existingOpportunities.get(1).InfoQuoteNumber__c = 'ACB124';
        existingOpportunities.get(1).isUpdatedFromINFO__c = true;

        existingOpportunities.get(2).InfoQuoteNumber__c = 'ACB125';
        existingOpportunities.get(2).isUpdatedFromINFO__c = false;

        existingOpportunities.get(3).InfoQuoteNumber__c = '   ';
        existingOpportunities.get(3).isUpdatedFromINFO__c = true;

        List<Opportunity> optysToUpdate = new List<Opportunity>();
        optysToUpdate.add(existingOpportunities.get(0));
        optysToUpdate.add(existingOpportunities.get(1));
        optysToUpdate.add(existingOpportunities.get(2));
        optysToUpdate.add(existingOpportunities.get(3));

        upsert optysToUpdate;

        Set<String> idsABuscar = new Set<String>{'ACB123', 'ACB124', 'ACB125', '   '};
        Set<String> idsRecuperados;
        Test.startTest();
        idsRecuperados = new OpportunitiesSelector().findUpdatedFromInfoByQuoteNumber(idsABuscar);
        Test.stopTest();

        System.assertEquals(2, idsRecuperados.size(), 'Se han tenido que recuperar los dos identificadores con el flag a true y con quoteNumber');

    }

    /**
     * Test del método que recupera las ofertas en base al InfoQuoteNumber__c y la fecha de creación
     * @author lrodriguez6@seidor.es
     * @date 14/11/2022
     */
    @IsTest
    static void test_findByCreatedOfferAndCreationDate()
    {
        Account cuenta = [SELECT Id, NationalId__c FROM Account LIMIT 1];
        Opportunity oferta= new Opportunity();
        OpportunitiesSelector OppSel = new OpportunitiesSelector(); 
        oferta.InfoQuoteNumber__c='11111';
        oferta.Name='Test';
        oferta.AccountId=cuenta.Id;
        oferta.StageName='Quoted';
        oferta.CloseDate=System.today()+1;

        insert oferta;
        String ofertaGenerada=oferta.InfoQuoteNumber__c;

        Test.startTest();
        List<Opportunity> offersFound = new OpportunitiesSelector().findByCreatedOfferAndCreationDate(new List<String>{ofertaGenerada}, '1');
        Test.stopTest();

        System.assertEquals(1, offersFound.size(), 'Deberia encontrar 1 oferta');
    }

}