/**
 * Clases de test para CampaignMemberUtilTest
 **
 * @author rlopez
 * @date 21/12/2020
 */
@isTest(SeeAllData=false)
private with sharing class CampaignMemberUtilTest
{
    private static String CALLBACK_CONVERSATION_ID = '20558e5f-9024-41c0-954a-b32acf2f8d7b';
    private static String CALLBACK_SESSION_ID = '7e131fcf-1639-45b2-89e5-9c3787b5dc75';

    @TestSetup
    public static void createScenario()
    {
        // Creamos un usuario Ventas Advisor
        Id advisorProfileId = [SELECT Id FROM Profile WHERE Name = :ProfilesSelector.PROFILE_VENTAS_USER].Id;
        List<User> advisorUsers = TestDataFactory.generateUsersByProfile(advisorProfileId, 1);
        insert advisorUsers;

        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);

        // Insertamos las accounts como ventas advisor
        System.runAs(advisorUsers[0])
        {
            insert accounts;
        }
        
        // Obtenemos los personcontact de las accounts que acabamos de crear
        List<Contact> ctLst = [SELECT Id FROM Contact WHERE AccountId IN :Accounts];

        // Generamos tareas de tipo callback y les asociamos los datos con los que se llamará mas tarde al WS
        RecordType interactionTskRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Interaction' AND SObjectType = 'Task' LIMIT 1];
        Date tskActivityDate = Date.today().addDays(7);

        List<Task> tskLst = new List<Task>();
        for(Contact ct : ctLst)
        {
            tskLst.add(new Task(
                Subject = 'Callback',
                WhoId = ct.Id,
                RecordtypeId = interactionTskRt.Id,
                CallDisposition = 'Agendar',
                CallType = 'Outbound',
                ActivityDate = tskActivityDate,
                CallObject = CALLBACK_CONVERSATION_ID
            ));
        }

        // Insertamos las tareas como ventas advisor ya que una de las condiciones que debe darse para que el proceso borre callbacks, es que
        // el creador de la tarea sea un ventas advisor
        System.runAs(advisorUsers[0])
        {
            insert tskLst;
        }

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

    /**
    * Método de test que prueba el método disconnectGenesysCallbacks
    *
    * @description 
    * @author fpalomo | 27/05/2024 
    **/
    @IsTest
    public static void test_disconnectGenesysCallbacks()
    {
        // Mock WebService Analíticas
        GenesysCloud.AnalyticsSession session = new GenesysCloud.AnalyticsSession();
        session.callbackNumbers = new List<String>{'+34777666222'};
        session.callbackScheduledTime = '2024-05-30T11:14:00Z';
        session.direction = 'outbound';
        session.mediaType = 'callback';
        session.sessionId = CALLBACK_SESSION_ID;

        GenesysCloud.AnalyticsParticipantWithoutAttributes participant = new GenesysCloud.AnalyticsParticipantWithoutAttributes();
        participant.participantId = '613f1e3a-05ca-4bb2-acc1-1d29d6676437';
        participant.sessions = new List<GenesysCloud.AnalyticsSession>{session};

        GenesysCloud.AnalyticsConversationWithoutAttributes conversation = new GenesysCloud.AnalyticsConversationWithoutAttributes();
        conversation.conversationId = CALLBACK_CONVERSATION_ID;
        conversation.participants = new List<GenesysCloud.AnalyticsParticipantWithoutAttributes>{participant};

        GenesysCloud.AnalyticsResponseWrapper analyticsResponseMock = new GenesysCloud.AnalyticsResponseWrapper();
        analyticsResponseMock.conversations = new List<GenesysCloud.AnalyticsConversationWithoutAttributes>{conversation};

        GenesysCloud.AnalyticsService.mock = new GenesysCloudMocks(analyticsResponseMock.toJSON(), 200);

        // Mock WebService Callbacks
        GenesysCloud.CallbacksService.mock = new GenesysCloudMocks('', 202);

        // Test borrado miembro campaña
        List<CampaignMember> cmLst = [SELECT Id FROM CampaignMember];

        Test.startTest();
        delete cmLst;
        Test.stopTest();

        List<Task> updatedTskLst = [SELECT Status, Description FROM Task WHERE Subject = 'Callback'];

        for(Task tsk : updatedTskLst)
        {
            System.assertEquals(Label.ZRM_CampaignMember_Removed_From_Campaign, tsk.Description, 'La descripcion de la tarea callback debería ser \'' + Label.ZRM_CampaignMember_Removed_From_Campaign + '\'');
        }
    }
}