/**
 * Clase de test para el batch Batch_CampaignMemberToOpportunity
 * @author nts (jfherrero)
 * @date 27/07/2023
 */

@IsTest(SeeAllData=false)
public class Batch_CampaignMemberToOpportunityTest
{

    @TestSetup
    static void makeData()
    {
        // Crear cuentas de intermediarios
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 3);

        intermediaries[0].ParentId = null;
        intermediaries[1].ParentId = null;
        intermediaries[2].ParentId = null;

        insert intermediaries;

        // Crear cuentas de clientes
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 3);

        for (Account account : accounts)
        {
            account.INFOCustomerNumber__c = String.valueOf( (Math.random() * 1000000000).intValue() );
        }

        accounts[0].Intermediary_Name__c = intermediaries[0].Id;
        accounts[1].Intermediary_Name__c = intermediaries[0].Id;
        accounts[2].Intermediary_Name__c = intermediaries[1].Id;

        insert accounts;

        //Crear contactos de intermediarios
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 1);

        insert intermediaryContacts;

        //Crear contactos de clientes
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, ContactsSelector.RT_NAME_CONTACT, 1);

        insert contacts;

        // Crear custom setting que indica el usuario genérico
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        // Crear campañas
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

        // Crear miembros de campaña
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(contacts, campaigns, 'New');
        for (Integer i=0; i < campaignMembers.size(); i++)
        {
            campaignMembers[i].OfferAssignedCode__c = String.valueOf( (Math.random() * 1000000000).intValue() );

            if ( ( (Decimal) i / campaignMembers.size() ) < 0.5 )
            {
                campaignMembers[i].OfferAssignedType__c = 'M';

                if (Math.mod(i,2) == 0)
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[1].INFOIntermediaryCode__c;
                }

                else
                {
                    campaignMembers[i].OfferAssignedCode__c = intermediaries[2].INFOIntermediaryCode__c;
                }

            }
            else
            {
                campaignMembers[i].OfferAssignedType__c = 'CC';
            }
        }

        insert campaignMembers;

        // Crear los usuarios
        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1];

            String portalProfileId= portalProfile.Id;

            List<User> listUser=TestDataFactory.generateUsersByProfile(portalProfileId, 3);

            // Usuario genérico del CC
            listUser[0].FirstName='Usuario';
            listUser[0].LastName='Generico CC';
            listUser[0].Alias='generico';
            listUser[0].ContactId = intermediaryContacts[0].Id;

            // Agentes mediadores
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

            insert listUser;
        }
    }

    @IsTest
    static void test_CampaignMemberToOpportunityTest_OK()
    {
        // Primero se van a borrar las oportunidades que se pudiesen haber generado automáticamente por el flow
        // si, éste está activo, al insertar los miembros de Campaña

        List<Opportunity> opportunitiesGenerated = [SELECT Id, CampaignId, OwnerId, IntermediaryId__c, IntermediaryCode__c, CreatedDate, CreatedBy.Name FROM Opportunity];

        delete opportunitiesGenerated;

        // Recuperamos los miembros de campaña para lanzar el batch

        List<CampaignMember> campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c
                                                FROM CampaignMember];

        Set<Id> campaignMembersIdSet = ( new Map<Id,CampaignMember>(campaignMembers) ).keySet();

        Batch_CampaignMemberToOpportunity batch = new Batch_CampaignMemberToOpportunity(campaignMembersIdSet);

        // Ejecución del test

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Obtención de los datos para hacer la comprobación de las inserciones
        // Hay que tener en cuenta que sólo se crean ofertas para campañas de venta cruzada

        opportunitiesGenerated = [SELECT Id, CampaignId, OwnerId, IntermediaryId__c, IntermediaryCode__c, CreatedDate, CreatedBy.Name FROM Opportunity];

        campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c
                           FROM CampaignMember
                           WHERE Campaign.Type = 'Cross Selling'];

        System.assertEquals( campaignMembers.size(), opportunitiesGenerated.size() );
    }

}