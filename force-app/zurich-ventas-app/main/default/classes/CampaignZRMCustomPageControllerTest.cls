/**
 * @description       : Clase de test unitaria que comprueba los diferentes métodos
 *                      de la clase 'CampaignZRMCustomPageController'
 *
 * @author            : amiranda
 * @date              : 30-10-2023
 * @last modified on  : 30-10-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   30-10-2023   amiranda   Initial Version
 **/
@isTest
public with sharing class CampaignZRMCustomPageControllerTest
{
    @TestSetup
    static void setup()
    {
        // Se crea el custom setting que indica el usuario genérico
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        // Se crean las campañas
        List<Campaign> campaignsToInsert = TestDataFactory.generateCampaigns('001', 5);
        for (Campaign campaignToInsert: campaignsToInsert)
        {
            campaignToInsert.Type = 'Cross Selling';
            campaignToInsert.IsActive = true;
            campaignToInsert.StartDate = Date.today();
            campaignToInsert.EndDate = Date.today() + 7;
        }
        insert campaignsToInsert;

        // Se crean las cuentas personales para generar los miembros de campaña
        List<Account> accountsToInsert = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accountsToInsert;

        // Se recuperan las cuentas personales generadas para recuperar el campo 'PersonContactId'
        List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account];
        Assert.areEqual(accountsToInsert.size(), personAccounts.size(), 'El número de cuentas personales no coincide.');

        // Se crean los miembros de campaña asociados a las campañas
        List<CampaignMember> campaignMembersToInsert = TestDataFactory.generateCampaignMembersForEachCampaign(personAccounts, campaignsToInsert, 'Subscribed');
        insert campaignMembersToInsert;

    }

    /**
     * @description Método de test que comprueba que el método 'getCampaigns' devuelve
     * el número de clientes asignados a una campaña correctamente. Se considera como cliente
     * asignado a cada miembro de campaña que tenga como estado el valor 'Gestión Mediador'.
     *
     * @author amiranda
     * @date 30-10-2023
     **/
    @IsTest
    static void getCampaigns_assignedCustomers()
    {
        Integer numberCampaignMemberToRetrieve = 5;
        String gestionMediadorStatus = 'Gestión Mediador';

        /* Se recuperan las campañas a las que se les van a añadir nuevos miembros
         * de campaña y un número determinado de sus miembros de campaña a los que
         * se les asignará alguno de estos estados.
         */
        List<Campaign> campaignsToInsertNewStatus = [SELECT Id,
                                                     (SELECT Id, Status FROM CampaignMembers LIMIT :numberCampaignMemberToRetrieve)
                                                     FROM Campaign LIMIT 2];

        // Se crean los estados para las diferentes campañas y se actualizan los estados de los miembros de campaña
        List<CampaignMemberStatus> campaignMembersStatusToInsert = new List<CampaignMemberStatus>();
        List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();

        for(Campaign campaign: campaignsToInsertNewStatus)
        {
            campaignMembersStatusToInsert.addAll( TestDataFactory.generateCampaignStatus(new List<String> {gestionMediadorStatus},
                                                                                         campaign.Id) );

            // Se actualizan los estados de los miembros de campaña
            for (CampaignMember campaignMember: campaign.CampaignMembers)
            {
                campaignMember.Status = gestionMediadorStatus;
            }

            campaignMembersToUpdate.addAll(campaign.CampaignMembers);
        }

        insert campaignMembersStatusToInsert;
        update campaignMembersToUpdate;

        Test.startTest();
        List<CampaignZRMCustomPageController.CampaignData> campaigns = CampaignZRMCustomPageController.getCampaigns();
        Test.stopTest();

        Assert.isFalse(campaignsToInsertNewStatus.isEmpty(), 'La lista de campañas no debería estar vacía.');

        Set<Id> campaignsIds = new Map<Id, SObject>(campaignsToInsertNewStatus).keySet();
        for (CampaignZRMCustomPageController.CampaignData campaign: campaigns)
        {
            // Se comprueba si el número de clientes asignados a la campañá es correcto.
            if ( campaignsIds.contains(campaign.id) )
            {
                Assert.areEqual(numberCampaignMemberToRetrieve,
                                campaign.assignedToCustomers,
                                'El número de clientes asignados de la campaña no es correcto.');
            }
        }
    }

    /**
     * @description Método de test que comprueba que el método 'getCampaigns' devuelve
     * el número de clientes asignados al CC de una campaña es correcto. Se considera como cliente
     * asignado al CC a cada miembro de campaña que tenga como estado el valor
     * 'Gestión CC' o 'Pdtes. Revisión Mediador'.
     *
     * @author amiranda
     * @date 30-10-2023
     **/
    @IsTest
    static void getCampaigns_assignedCC()
    {
        Integer numberCampaignMemberToRetrieve = 5;
        List<String> gestionCCStatus = new List<String> {'Gestión CC', 'Pdtes. Revisión Mediador'};

        /* Se recuperan las campañas a las que se les van a añadir nuevos miembros
         * de campaña y un número determinado de sus miembros de campaña a los que
         * se les asignará alguno de estos estados.
         */
        List<Campaign> campaignsToInsertNewStatus = [SELECT Id,
                                                     (SELECT Id, Status FROM CampaignMembers LIMIT :numberCampaignMemberToRetrieve)
                                                     FROM Campaign LIMIT 2];

        // Se crean los estados para las diferentes campañas y se actualizan los estados de los miembros de campaña
        List<CampaignMemberStatus> campaignMembersStatusToInsert = new List<CampaignMemberStatus>();
        List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();

        for(Campaign campaign: campaignsToInsertNewStatus)
        {
            campaignMembersStatusToInsert.addAll( TestDataFactory.generateCampaignStatus(gestionCCStatus,
                                                                                         campaign.Id) );

            // Se actualizan los estados de los miembros de campaña
            for (CampaignMember campaignMember: campaign.CampaignMembers)
            {
                // Se le asigna un estado aleatorio
                campaignMember.Status = gestionCCStatus.get( ( Math.random() * (gestionCCStatus.size() - 1) ).intValue() );
            }

            campaignMembersToUpdate.addAll(campaign.CampaignMembers);
        }

        insert campaignMembersStatusToInsert;
        update campaignMembersToUpdate;

        Test.startTest();
        List<CampaignZRMCustomPageController.CampaignData> campaigns = CampaignZRMCustomPageController.getCampaigns();
        Test.stopTest();

        Assert.isFalse(campaignsToInsertNewStatus.isEmpty(), 'La lista de campañas no debería estar vacía.');

        Set<Id> campaignsIds = new Map<Id, SObject>(campaignsToInsertNewStatus).keySet();
        for (CampaignZRMCustomPageController.CampaignData campaign: campaigns)
        {
            /* Se comprueba si el número de clientes asignados a la campañá es correcto.
             * Se considera como cliente asignado al CC a cada miembro de campañá con el estado
             * 'Gestión CC' o 'Pdtes. Revisión Mediador'.
             */
            if ( campaignsIds.contains(campaign.id) )
            {
                Assert.areEqual(numberCampaignMemberToRetrieve,
                                campaign.assignedToCC,
                                'El número de clientes asignados al CC de la campaña no es correcto.');
            }
        }
    }

    /**
     * @description Método de test que comprueba que el método 'getCampaignMembers' devuelve
     * la información correspondiente a los miembros de campaña relacionados con una campaña completa, 
     * ampliada con los datos relativos a la oferta asociada
     *
     * @author arcortazar
     * @date 20-11-2023
     **/
    @isTest
    static void getCampaignMembers_ok()
    {
        Campaign campanya = [SELECT id FROM Campaign LIMIT 1];
        List<CampaignMember> miembros = [SELECT id, Contact.AccountId FROM CampaignMember WHERE CampaignId = :campanya.id];
        System.assertEquals(false, miembros.isEmpty(), 'Hemos de disponer de miembros de campaña');

        List<ID> lstAccountIDS = new List<Id>();
        for(CampaignMember cm : miembros)
        {
            lstAccountIDS.add(cm.Contact.AccountId);
        }
        List<Opportunity> offers = [SELECT Id, AccountId, CampaignId FROM Opportunity WHERE AccountId IN :lstAccountIDS AND CampaignId = :campanya.id];
        System.assertEquals(false, offers.isEmpty(), 'Hemos de tener ofertas asociadas a las cuentas y a esa campaña');

        List<CampaignZRMCustomPageController.CampaignMemberData> retorno = new List<CampaignZRMCustomPageController.CampaignMemberData>();
        Test.startTest();
        retorno = CampaignZRMCustomPageController.getCampaignMembers(campanya.id);
        Test.stopTest();

        System.assertEquals(false, retorno.isEmpty(), 'Se deben encontrar miembros de campaña');
        System.assertEquals(offers.size(), retorno.size(), 'Se han de encontrar las mismas ofertas que manualmente');
        // Para los datos obtenidos, comprobamos que ha cargado información del CM y de la oferta asociada mediante la comprobación de algunos campos
        for(CampaignZRMCustomPageController.CampaignMemberData cmData : retorno)
        {
            // Comprobamos que contiene datos del CampaignMember
            System.assertEquals(true, String.isNotBlank(cmData.cmId), 'Ha de contener el Id del miembro de campaña');

            // Comprobamos que contiene datos de la oferta asociada al CM
            System.assertEquals(true, String.isNotBlank(cmData.offerName), 'Ha de contener el Name de la oferta');
            System.assertEquals(true, String.isNotBlank(cmData.offerId), 'Ha de contener el ID de la oferta');
        }
    }

    /**
     * @description Método de test que comprueba que el método 'getCampaignMembers' no devuelve información cuando se le invoca sin datos
     * de la campaña
     *
     * @author arcortazar
     * @date 20-11-2023
     **/
    @isTest 
    static void getCampaignMembers_ko()
    {
        List<CampaignZRMCustomPageController.CampaignMemberData> retorno = new List<CampaignZRMCustomPageController.CampaignMemberData>();

        Test.startTest();
        retorno = CampaignZRMCustomPageController.getCampaignMembers(null);
        Test.stopTest();

        System.assertEquals(true, retorno.isEmpty(), 'No se deben encontrar miembros de campaña');
    }
}