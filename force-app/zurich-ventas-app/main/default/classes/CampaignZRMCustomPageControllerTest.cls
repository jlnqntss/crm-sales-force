/**
 * @description       : Clase de test unitaria que comprueba los diferentes métodos
 *                      de la clase 'CampaignZRMCustomPageController'
 *
 * @author            : amiranda
 * @date              : 03-01-2024
 * @last modified on  : 03-01-2024
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   30-10-2023   amiranda   Initial Version
 **/
@isTest
private with sharing class CampaignZRMCustomPageControllerTest
{
    @TestSetup
    private static void setup()
    {
        // Se crea una cuenta de tipo Mediador para preparar el usuario de la comunidad ZRM
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 1);
        insert intermediaries;

        // Se crea el contacto relacionado con la cuenta anterior, necesario para el usuario de la comunidad ZRM
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries,
                                                                                          ContactsSelector.RT_NAME_CONTACT,
                                                                                          1);
        insert intermediaryContacts;

        // Obtener el rol para el usuario de la comunidad
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        // Se crea el usuario de la comunidad
        Id portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        List<User> users = TestDataFactory.generateUsersByProfile(portalProfile, 1);

        users.get(0).FirstName = 'Agente';
        users.get(0).LastName = 'Mediador';
        users.get(0).Alias = 'amedtest';
        users.get(0).UserRole = portalRole;
        users.get(0).ContactId = intermediaryContacts.get(0).Id;

        insert users;

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
        for (Account accountToInsert : accountsToInsert)
        {
            accountToInsert.IntermediaryVisibilityAcc__c = intermediaries.get(0).Id;
        }
        insert accountsToInsert;

        // Se recuperan las cuentas personales generadas para recuperar el campo 'PersonContactId'
        List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true];
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
    private static void getCampaigns_assignedCustomers()
    {
        Integer numberCampaignMemberToRetrieve = 5;
        String gestionMediadorStatus = 'Gestión Mediador';
        User intermediary = [SELECT Contact.AccountId FROM User WHERE Alias = 'amedtest' LIMIT 1];

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
        List<CampaignZRMCustomPageController.CampaignData> campaigns = CampaignZRMCustomPageController.getCampaigns(intermediary.Contact.AccountId);
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

    // TODO Crear test unitarios para los métodos 'updateOfferAndCampaignMember' y 'cloneOffer'

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
    private static void getCampaigns_assignedCC()
    {
        Integer numberCampaignMemberToRetrieve = 5;
        List<String> gestionCCStatus = new List<String> {'Gestión CC', 'Pdte. Revisión Mediador'};
        User intermediary = [SELECT Contact.AccountId FROM User WHERE Alias = 'amedtest' LIMIT 1];

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
        List<CampaignZRMCustomPageController.CampaignData> campaigns = CampaignZRMCustomPageController.getCampaigns(intermediary.Contact.AccountId);
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
    private static void getCampaignMembers_ok()
    {
        Campaign campanya = [SELECT id FROM Campaign LIMIT 1];

        List<CampaignZRMCustomPageController.CampaignMemberData> retorno = new List<CampaignZRMCustomPageController.CampaignMemberData>();
        
        Test.startTest();
        retorno = CampaignZRMCustomPageController.getCampaignMembers(campanya.id);
        Test.stopTest();

        System.assertEquals(false, retorno.isEmpty(), 'Se deben encontrar miembros de campaña');
        // Para los datos obtenidos, comprobamos que ha cargado información del CM y de la oferta asociada mediante la comprobación de algunos campos
        for(CampaignZRMCustomPageController.CampaignMemberData cmData : retorno)
        {
            // Comprobamos que contiene datos del CampaignMember
            System.assertEquals(true, String.isNotBlank(cmData.cmId), 'Ha de contener el Id del miembro de campaña');
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
    private static void getCampaignMembers_ko()
    {
        List<CampaignZRMCustomPageController.CampaignMemberData> retorno = new List<CampaignZRMCustomPageController.CampaignMemberData>();

        Test.startTest();
        retorno = CampaignZRMCustomPageController.getCampaignMembers(null);
        Test.stopTest();

        System.assertEquals(true, retorno.isEmpty(), 'No se deben encontrar miembros de campaña');
    }
}