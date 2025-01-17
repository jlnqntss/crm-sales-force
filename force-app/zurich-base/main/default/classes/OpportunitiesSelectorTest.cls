/**
 * @description       :
 * @author            : mfernandezcarrera
 * @group             :
 * @last modified on  : 22-12-2023
 * @last modified by  : amiranda
 **/
@isTest
private with sharing class OpportunitiesSelectorTest
{

    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        for (Account account : accounts)
        {
            account.INFOIntermediaryCode__c = String.valueOf( (Math.random() * 100000000).intValue() );
        }
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 10);
        // añado a estas ofertas el campo CreatedDate__c (Fecha creación INFO)
        for (Opportunity opp: opportunities) {
            opp.CreatedDate__c = Date.today(); 
        }
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 1);
        insert policies;

        Map<ID, Policy__c> mapPoliciesById = new Map<ID, Policy__c>(policies);

        List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy('Address', policies, 1);
        // Cambiamos los asset para que vayan por oferta en vez de por poliza
        for(Asset a: insuredObjects)
        {
            a.OfferId__c = mapPoliciesById.get(a.PolicyId__c).OpportunityName__c;
            a.PolicyId__c = null;
        }
        insert insuredObjects;

        //--------------------------------------------------
        // Creamos los elementos necesarios para crear ofertas al insertar un miembro de campaña

        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';
        insert ventaCruzada;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        campaigns[0].Type = 'Cross Selling';
        campaigns[0].StartDate = Date.today();
        campaigns[0].EndDate = Date.today() + 7;
        insert campaigns;

        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);
        List<Account> miembroCampanya = new List<Account>();
        miembroCampanya.add(accounts[0]);

        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(miembroCampanya, campaigns, 'Subscribed');
        campaignMembers[0].OfferAssignedType__c = 'CC';
        insert campaignMembers;

        List<Opportunity> offers = TestDataFactory.generateOpportunities(miembroCampanya, 'Existing Business', 'Legit Lead', System.today() + 7, 2);
        offers[0].ZRM__c = true;
        offers[1].ZRM__c = true;
        insert offers;
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

        List<User> owners = [SELECT Id, Profile.Name FROM User WHERE Id IN : ownerIds];
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
        User u = [Select Id FROM User WHERE Id = : usuarios.get(0).AssigneeId];

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

        System.assertEquals( false, offers.isEmpty() );
    }

    @isTest
    static void test_findByAccountIdAndScopeNotId_byUser()
    {
        List<PermissionSetAssignment> usuarios = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'ZE_Advisor' AND Assignee.isActive = True];
        System.assertNotEquals(0, usuarios.size(), 'Ha de haber por lo menos un usuario con el permission set requerido');
        User u = [Select Id FROM User WHERE Id = : usuarios.get(0).AssigneeId];

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

            System.assertEquals( false, offers.isEmpty() );
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
        optysToUpdate.add( existingOpportunities.get(0) );
        optysToUpdate.add( existingOpportunities.get(1) );
        optysToUpdate.add( existingOpportunities.get(2) );
        optysToUpdate.add( existingOpportunities.get(3) );

        upsert optysToUpdate;

        Set<String> idsABuscar = new Set<String> {'ACB123', 'ACB124', 'ACB125', '   '};
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
        oferta.CloseDate=System.today() + 1;

        insert oferta;
        String ofertaGenerada=oferta.InfoQuoteNumber__c;

        Test.startTest();
        List<Opportunity> offersFound = new OpportunitiesSelector().findByCreatedOfferAndCreationDate(new List<String> {ofertaGenerada}, '1');
        Test.stopTest();

        System.assertEquals(1, offersFound.size(), 'Deberia encontrar 1 oferta');
    }

    /**
     * Test del método que busca las oportunidades por nombre. Resultado OK
     * @author acortazar
     * @date 23/02/2023
     */
    @IsTest
    static void test_findByName_OK()
    {
        List<Opportunity> listaOportunidades = [SELECT Name FROM Opportunity];
        System.debug('++++ listaOportunidades: ' + listaOportunidades);
        Set<String> setNames = new Set<String>();

        for (Opportunity o : listaOportunidades)
        {
            setNames.add(o.Name);
        }

        test.startTest();
        List<Opportunity> resultados = new OpportunitiesSelector().findByName(setNames);
        test.stopTest();

        System.assertEquals(listaOportunidades.size(), resultados.size(), 'Ha debido encontrar los mismos registros');
    }

    /**
     * Test del método que busca las oportunidades por nombre. Resultado KO
     * @author acortazar
     * @date 23/02/2023
     */
    @IsTest
    static void test_findByName_KO()
    {
        Set<String> setNames = new Set<String>();

        test.startTest();
        List<Opportunity> resultados = new OpportunitiesSelector().findByName(setNames);
        test.stopTest();

        System.assertEquals(0, resultados.size(), 'Ls lista devuelta ha de estar vacía');
    }

    /**
     * @description Método que se encarga de comprobar el correcto funcionamiento
     * del método 'findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed'
     * de la clase 'OpportunitiesSelector'.
     *
     * @author amiranda
     * @date 04-09-2023
     **/
    @isTest
    static void test_findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed_OK()
    {
        String productBranchAutos = '0000000001';
        Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
        String PRODUCT_BRANCH_VIDA_CODE = configValues.get('Product_Branch_Vida_Code');
        String OFFER_RECORD_TYPE_NO_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_NoLife')).getRecordTypeId();
        Account accRelatedToOffer = [SELECT INFOIntermediaryCode__c FROM Account LIMIT 1];

        Opportunity offer = [SELECT AccountId, IntermediaryCode__c, ProductBranch__c FROM Opportunity LIMIT 1];
        offer.AccountId = accRelatedToOffer.Id;
        offer.IntermediaryCode__c = accRelatedToOffer.INFOIntermediaryCode__c;
        offer.ProductBranch__c = productBranchAutos;
        offer.StageName = 'Legit Lead';
        update offer;

        Test.startTest();
        List<Opportunity> offers = new OpportunitiesSelector().findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed(
            accRelatedToOffer.Id,
            accRelatedToOffer.INFOIntermediaryCode__c,
            productBranchAutos,
            OFFER_RECORD_TYPE_NO_VIDA,
            Query.last_n_days(7) );
        Test.stopTest();

        Assert.isFalse(offers.isEmpty(), 'Offers list should not be empty');
    }

    @isTest
    static void findCrossSellingCampaignNotClosedOfferTest()
    {

        Test.startTest();
        String offerList = ( new OpportunitiesSelector() ).findCrossSellingCampaignNotClosedOffer();
        Test.stopTest();

        System.assertEquals(true, offerList != null, 'No Debe ser nulo');
    }

    /**
     * Test del  Método selector que recupera aquellas ofertas que se encuentran
     * relacionadas con la campaña y con alguna de las cuentas pasada por parámetro.
     * @author mfernandezcarrera
     * @date 20/11/2023
     */
    @IsTest
    static void test_selectByAccountIdsAndCampaignId()
    {
        // create new account
        List<Account> account = TestDataFactory.generateAccounts('001', 'Business Customer', 1);
        account[0].FirstName='Prueba';
        insert account;

        // create new campaign
        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        insert campaigns;

        // create new offer
        List<Opportunity> newOffers = TestDataFactory.generateOpportunitiesForEachAccount(account, 'General', 'Open',System.today().addDays(10), 1);
        newOffers[0].CampaignId=campaigns.get(0).Id;
        insert newOffers;

        Id campaignToSearch = campaigns.get(0).Id;


        List <Account> listacc = [Select Id,FirstName from Account where FirstName='Prueba'];

        Map<Id,Account> mapAccountsById = new Map<Id,Account> (listacc);

        Test.startTest();
        List<Opportunity> resultados = new OpportunitiesSelector().selectByAccountIdsAndCampaignId(mapAccountsById.keySet(),campaignToSearch, null);
        Test.stopTest();

        System.assertEquals(1, resultados.size(), 'No cumple las condiciones');
    }

    @isTest
    static void findZRMtoReassignTest()
    {

        Test.startTest();
        String offerList = ( new OpportunitiesSelector() ).findZRMtoReassign();
        Test.stopTest();

        System.assertEquals(true, offerList != null, 'No Debe ser nulo');
    }

    @isTest
    static void test_findByAccountAndOwner_ok()
    {
        Set<Id> accountsIDs = new Set<Id>();
        Set<Id> usersIDs = new Set<Id>();
        List<Opportunity> optys = [SELECT id, AccountId, OwnerId FROM Opportunity WHERE AccountId != '' AND OwnerId != '' ];
        for(Opportunity o : optys)
        {
            accountsIDs.add(o.AccountId);
            usersIDs.add(o.OwnerId);
        }

        List<Opportunity> retrievedOpportunities = new List<Opportunity>();
        Test.startTest();
        retrievedOpportunities = ( new OpportunitiesSelector() ).findByAccountAndOwner(accountsIDs, usersIDs);
        Test.stopTest();

        System.assertEquals(false, retrievedOpportunities.isEmpty(), 'Ha debido encontrar oportunidades');
        System.assertEquals(optys.size(), retrievedOpportunities.size(), 'Ha debido encontrar oportunidades');
    }

    @isTest
    static void test_findByAccountAndOwner_ko()
    {
        Set<Id> accountsIDs = new Set<Id>();
        Set<Id> usersIDs = new Set<Id>();

        List<Opportunity> retrievedOpportunities = new List<Opportunity>();
        Test.startTest();
        retrievedOpportunities = ( new OpportunitiesSelector() ).findByAccountAndOwner(accountsIDs, usersIDs);
        Test.stopTest();

        System.assertEquals(true, retrievedOpportunities.isEmpty(), 'Ha de devolver una lista vacia');
    }

    @isTest
    static void findByCampaignAndCampaignMember_OK()
    {
        // Obtenemos las campañas y los miembros
        List<Campaign> listaCampanyas = [SELECT id FROM Campaign];
        Set<String> idCampanya = new Set<String> {listaCampanyas[0].id};

        List<CampaignMember> campaignMembers = [SELECT id, ContactId, CampaignId, Campaign.Type FROM CampaignMember WHERE CampaignId = : listaCampanyas[0].id];
        List<Contact> contacto = [SELECT Id, AccountId FROM Contact WHERE id =: campaignMembers[0].ContactId];
        Set<String> idMiembro = new Set<String> {contacto[0].AccountId};

        List<Opportunity> retrievedOpportunitites = new List<Opportunity>();
        Test.startTest();
        retrievedOpportunitites = ( new OpportunitiesSelector().findByCampaignAndCampaignMember(idCampanya, idMiembro) );
        Test.stopTest();

        System.assertEquals(true, retrievedOpportunitites != null, 'No Debe ser nulo');
    }

    @isTest
    private static void getMostRecentlyOfferByAccountId_OK()
    {
        // Obtenemos lista de clientes
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Customer' LIMIT 1]);

        Test.startTest();
        List<Opportunity> retrievedOpportunitites = ( new OpportunitiesSelector().getMostRecentlyOfferByAccountId(accounts.get(0).Id) );
        Test.stopTest();

        Assert.isTrue(retrievedOpportunitites.size() > 0, 'Debe devolver resultados');
    }
}