/**
 * Clases de test para CampaignMemberUtilTest
 **
 * @author rlopez
 * @date 21/12/2020
 */
@isTest(SeeAllData=false)
private with sharing class CampaignMemberUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';
        insert ventaCruzada;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        campaigns[0].Type = 'Cross Selling';
        campaigns[0].StartDate = Date.today();
        campaigns[0].EndDate = Date.today() + 7;
        insert campaigns;

        List<CampaignMemberStatus> newStatuses = new List<CampaignMemberStatus>();
        for(Campaign campaign: campaigns)
        {
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='New',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=5
                    )
                );
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='Delete',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=6
                    )
                );
        }

        insert newStatuses;

        // hotfix: obtener cuentas de tipo personales con el campo PersonContactId relleno
        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);

        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaigns, 'New');
        campaignMembers[0].OfferAssignedType__c = 'CC';
        insert campaignMembers;

        Profile readOnlyProfile = [SELECT Id FROM Profile WHERE Name = 'Read Only'];
        List<User> users = TestDataFactory.generateUsersByProfile(readOnlyProfile.Id, 1);
        insert users;
    }

    /**
     * Método que comprueba que se eliminan todos los miembros de campaña con Status = Delete
     * al llamar a CampaignMemberUtil.deleteMembers
     *
     * @author rlopez
     * @date 21/12/2020
     */
    @isTest
    static void test_deleteMembers_bulk_ok()
    {
        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        for(CampaignMember member: campaignMembersToUpdate)
        {
            member.Status = 'Delete';
        }

        update campaignMembersToUpdate;

        Test.startTest();
        CampaignMemberUtil.deleteMembers();
        Test.stopTest();

        //Comprobamos que se han eliminado todos los miembros de campaña
        List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
        System.assertEquals(true, deletedMembers.isEmpty(), 'There should not be any CampaignMember with status "Delete"');

        //Comprobamos que hemos borrado todos los miembros de campaña
        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(true, currentCampaignMembers.isEmpty(), 'List should be empty');
    }

    /**
     * Método que comprueba que se eliminan todos los miembros de campaña con Status = Delete
     * al llamar a CampaignMemberUtil.deleteMembers
     *
     * @author rlopez
     * @date 21/12/2020
     */
    @isTest
    static void test_deleteMembers_ok()
    {
        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        campaignMembersToUpdate.get(0).Status = 'Delete';

        update campaignMembersToUpdate;

        Test.startTest();
        CampaignMemberUtil.deleteMembers();
        Test.stopTest();

        //Comprobamos que se han eliminado todos los miembros de campaña
        List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
        System.assertEquals(true, deletedMembers.isEmpty(), 'There should not be any CampaignMember with status "Delete"');

        //Comprobamos que SOLO hemos borrado un miembro de campaña
        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');
    }
    

    /**
     * Método de test que comprueba que al eliminar un miembro de campaña de una campaña, las ofertas relacionadas pasan a estado Cerrado Perdida
     * 
     * @author: arcortazar
     * @date: 13/11/2023
     */
    @IsTest
    static void test_closeRelatedOffer_ok()
    {
        // Recuperamos las ofertas correspondientes a los miembros de campaña que vamos a eliminar
        Set<String> idCampanyas = new Set<String>();
        Set<String> idMiembros = new Set<String>();

        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToDelete = [SELECT Id, Status, CampaignId, Contact.AccountId, LeadOrContactOwnerId FROM CampaignMember WHERE Campaign.Type = 'Cross Selling'];
        System.assertEquals(false, campaignMembersToDelete.isEmpty(), 'List should NOT be empty');

        for(CampaignMember cm : campaignMembersToDelete)
        {
            idCampanyas.add(cm.CampaignId);
            idMiembros.add(cm.Contact.AccountId);
        }

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE id in :idMiembros]);

        List<Opportunity> legitLeadOfferList = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'Ventas', 'Legit Lead', Date.today(), 1);
        List<String> campaignIdList = new List<String>(idCampanyas);
        
        for (Opportunity o: legitLeadOfferList) {
            o.InfoQuoteNumber__c = '';              
            o.CampaignId = campaignIdList.get(0);
            o.ZRM__c = true;
        }

        insert legitLeadOfferList;

        
        
        OpportunitiesSelector selector = new OpportunitiesSelector();
        List<Opportunity> oportunidades = selector.findByCampaignAndCampaignMember(idCampanyas, idMiembros);
        System.assertEquals(false, oportunidades.isEmpty(), 'Ha de haber ofertas para cerrar');

        Test.startTest();
        delete campaignMembersToDelete;
        Test.stopTest();

        // Comprobamos que el miembro se ha borrado
        List<CampaignMember> existMember = [SELECT Id, Status, CampaignId, Contact.AccountId FROM CampaignMember WHERE Id =:campaignMembersToDelete[0].id];
        System.assertEquals(true, existMember.isEmpty(), 'El miembro se tiene que haber borrado');

        oportunidades = selector.findByCampaignAndCampaignMember(idCampanyas, idMiembros);
        System.assertEquals(true, oportunidades.isEmpty(), 'No deben quedar ofertas abiertas para estos miembros de campaña');

        oportunidades = [SELECT id, StageName, Sales_Loss_Reason__c FROM Opportunity WHERE CampaignID IN :idCampanyas AND AccountId IN :idMiembros AND Campaign.Type = 'Cross Selling'];
        for(Opportunity o : oportunidades)
        {
            System.assertEquals('Closed Lost', o.StageName, 'Deberia ser Cerrado Perdido');
            System.assertEquals('Agent removes from the campaign', o.Sales_Loss_Reason__c, 'Deberia ser Cerrado Perdido');
        }
    }
}