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
}