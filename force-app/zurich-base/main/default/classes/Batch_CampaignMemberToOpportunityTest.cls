/**
 * Clase de test para el batch Batch_CampaignMemberToOpportunity
 * @author nts (jfherrero)
 * @date 27/07/2023
 */

@IsTest(SeeAllData=false)
private with sharing class Batch_CampaignMemberToOpportunityTest
{

    @TestSetup
    private static void makeData()
    {
        /********************************  INTERMEDIARIOS  ********************************/
        // Crear cuentas de intermediarios
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 4);
        // Crear grupo de intermediarios
        intermediaries.addAll( TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1) );

        insert intermediaries;

        // Crear contactos de intermediarios
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 1);

        insert intermediaryContacts;

        // Crear los usuarios
        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        // Create portal account owner
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        // Partners
        String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        List<User> listUser=TestDataFactory.generateUsersByProfile(portalProfile, 3);

        listUser[0].FirstName='Usuario';
        listUser[0].LastName='Generico CC';
        listUser[0].Alias='generico';
        listUser[0].ContactId = intermediaryContacts[0].Id;
        listUser[1].FirstName='Agente';
        listUser[1].LastName='Mediador 1';
        listUser[1].Alias='ag.med.1';
        listUser[1].UserRole = portalRole;
        listUser[1].ContactId = intermediaryContacts[1].Id;
        listUser[2].FirstName='Agente';
        listUser[2].LastName='Mediador 1';
        listUser[2].Alias='ag.med.2';
        listUser[2].UserRole = portalRole;
        listUser[2].ContactId = intermediaryContacts[2].Id;

        // No Partner
        String partnerProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        listUser.add(TestDataFactory.generateUsersByProfile(partnerProfile, 1)[0]);

        listUser[3].FirstName='No';
        listUser[3].LastName='Partner';
        listUser[3].Alias='no.part';

        System.runAs (adminUser)
        {
            insert listUser;
        }

        // No tiene Parent y tiene informado IntermediaryWithUser__c
        intermediaries[0].IntermediaryGroup__c = null;
        intermediaries[0].IntermediaryWithUser__c = intermediaries[1].Id;
        // No tiene Parent y no tiene informado IntermediaryWithUser__c
        intermediaries[1].IntermediaryGroup__c = null;
        // IsPartner=true, tiene un Parent con el campo IntermediaryWithUser__c informado
        intermediaries[2].IntermediaryGroup__c = intermediaries[4].Id;
        // IsPartner=false, tiene un Parent con el campo IntermediaryWithUser__c informado
        intermediaries[3].IntermediaryGroup__c = intermediaries[4].Id;
        // Intermediary Group
        intermediaries[4].IntermediaryWithUser__c = intermediaries[0].Id;

        update intermediaries;

        /********************************  CLIENTES  ********************************/
        // Crear cuentas de clientes
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'BusinessCustomer', 10);

        for (Account account : accounts)
        {
            account.INFOCustomerNumber__c = String.valueOf( (Math.random() * 1000000000).intValue() );
        }

        accounts[0].Intermediary_Name__c = intermediaries[0].Id;
        accounts[1].Intermediary_Name__c = intermediaries[0].Id;
        accounts[2].Intermediary_Name__c = intermediaries[1].Id;
        accounts[3].Intermediary_Name__c = intermediaries[1].Id;
        accounts[4].Intermediary_Name__c = intermediaries[2].Id;
        accounts[5].Intermediary_Name__c = intermediaries[2].Id;
        accounts[6].Intermediary_Name__c = intermediaries[0].Id;
        accounts[7].Intermediary_Name__c = intermediaries[0].Id;
        accounts[8].Intermediary_Name__c = intermediaries[3].Id;
        accounts[9].Intermediary_Name__c = intermediaries[3].Id;

        insert accounts;

        //Crear contactos de clientes
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, ContactsSelector.RT_NAME_CONTACT, 1);

        insert contacts;

        /*****************************  CUSTOM SETTINGS  ****************************/
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        /********************************  CAMPAÑAS  ********************************/
        List<Campaign> campaigns = TestDataFactory.generateCampaigns(Label.GeneralInsurance, 2);

        List<Schema.PicklistEntry> picklistProductBranch = Campaign.ProductBranch__c.getDescribe().getPicklistValues();

        for (Campaign c : campaigns)
        {
            c.StartDate = Date.today();
            c.EndDate = Date.today() + 7;
            c.ExternalId__c = String.valueOf( (Math.random() * 1000000000).intValue() );
            c.ProductBranch__c = picklistProductBranch[0].getValue();
            c.BusinessCode__c = c.ExternalId__c;
        }

        campaigns[0].Type = 'Cross Selling';
        campaigns[1].Type = 'Suscripcion';

        insert campaigns;

        /**************************  MIEMBROS DE CAMPAÑAS  *************************/
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(contacts, campaigns, 'New');
        for (Integer i=0; i < campaignMembers.size(); i++)
        {
            if ( ( (Decimal) i / campaignMembers.size() ) < 0.5 )
            {
                campaignMembers[i].OfferAssignedType__c = 'M';

                if (Math.mod(i,5) == 0)
                {
                    campaignMembers[i].OfferAssignedCode__c = null;
                }

                else if (Math.mod(i,4) == 0)
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[3].INFOIntermediaryCode__c;
                }

                else if (Math.mod(i,3) == 0)
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[2].INFOIntermediaryCode__c;
                }

                else if (Math.mod(i,2) == 0)
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[1].INFOIntermediaryCode__c;
                }

                else
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[0].INFOIntermediaryCode__c;
                }
            }
            else
            {
                campaignMembers[i].OfferAssignedType__c = 'CC';
                campaignMembers[i].OfferAssignedCode__c = String.valueOf( (Math.random() * 1000000000).intValue() );
            }
        }

        insert campaignMembers;
    }

    @IsTest
    private static void test_CampaignMemberToOpportunityTest_OK()
    {
        // Primero se van a borrar las oportunidades que se pudiesen haber generado automáticamente por el flow
        // si, éste está activo, al insertar los miembros de Campaña

        List<Opportunity> opportunitiesGenerated = [SELECT Id FROM Opportunity];
        delete opportunitiesGenerated;

        // Recuperamos los miembros de campaña para lanzar el batch

        List<CampaignMember> campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c FROM CampaignMember];

        Set<Id> campaignMembersIdSet = (new Map<Id, CampaignMember>(campaignMembers)).keySet();

        Batch_CampaignMemberToOpportunity batch = new Batch_CampaignMemberToOpportunity(campaignMembersIdSet);

        /* ---------------------------------- TEST ---------------------------------- */
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        /* --------------------------------- ASSERTS -------------------------------- */
        opportunitiesGenerated = [SELECT Id FROM Opportunity];
        campaignMembers = [SELECT Id FROM CampaignMember WHERE Campaign.Type = 'Cross Selling'];

        Assert.areEqual(campaignMembers.size(), opportunitiesGenerated.size(), 'Deberían haberse creado el mismo numero de oportunidades que de miembros de campaña');
    }

    @IsTest
    private static void test_CampaignMemberToOpportunityTest_KO()
    {
        // Primero se van a borrar las oportunidades que se pudiesen haber generado automáticamente por el flow
        // si, éste está activo, al insertar los miembros de Campaña

        List<Opportunity> opportunitiesGenerated = [SELECT Id FROM Opportunity];
        delete opportunitiesGenerated;

        // Recuperamos los miembros de campaña para lanzar el batch

        List<CampaignMember> campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c FROM CampaignMember];

        Set<Id> campaignMembersIdSet = (new Map<Id, CampaignMember>(campaignMembers)).keySet();

        Batch_CampaignMemberToOpportunity batch = new Batch_CampaignMemberToOpportunity(campaignMembersIdSet);

        /* ---------------------------------- TEST ---------------------------------- */
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        /* --------------------------------- ASSERTS -------------------------------- */
        opportunitiesGenerated = [SELECT Id FROM Opportunity];
        campaignMembers = [SELECT Id FROM CampaignMember WHERE Campaign.Type = 'Cross Selling'];

        Assert.areNotEqual(campaignMembers.size(), opportunitiesGenerated.size(), 'No deberían haberse creado el mismo numero de oportunidades que de miembros de campaña');
    }

}