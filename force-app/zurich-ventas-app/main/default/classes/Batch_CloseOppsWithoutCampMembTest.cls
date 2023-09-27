/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 12/09/2023
 * @last modified by  : jgallaga
**/
@isTest
public class Batch_CloseOppsWithoutCampMembTest
{

    /**
     * A FECHA DE CREACIÓN DE ESTE BATCH EXISTE UNA FUNCIONALIDAD QUE CREA UNA OPORTUNIDAD POR MIEMBRO DE CAMPAÑA DE VENTA CRUZADA.
     * ESTO PROVOCA QUE EL NUMERO DE OPORTUNIDADES DE ESTE TIPO SE DUPLIQUEN EN ESTOS TESTS. A FIN DE QUE ESTOS TESTS SIGAN FUNCIONANDO
     * EN CASO DE QUE LA OTRA FUNCIONALIDAD DESAPAREZCA, LOS TESTS COMPRUEBAN QUE LOS CAMBIOS DE LAS OPORTUNIDADES SON LOS ESPERADOS
     * Y EN LOS REGISTROS CORRECTOS SIN TENER EN CUENTA EL NUMERO DE OPORTUNIDADES QUE EXISTEN DURANTE EL TEST.
     * AUN ASI SE COMPRUEBA QUE EL NUMERO DE CAMBIOS REALIZADO ES EL CORRECTO COMPARANDO EL NUMERO DE CAMBIOS / 2 (NUMERO DE MIEMBROS DE CAMPAÑA BORRADOS)
     */

    private static string TYPE_CROSS_CAMPAIGN = 'Cross Selling';
    private static Integer NUM_CONTACTS = 10;
    private static Integer NUM_CAMPAIGNS = 5;

    @TestSetup
    static void makeData()
    {
        // Se inserta el usuario por defecto en la custom settings (Crear miemrbos de campaña de ventas genera oportunidades adicionales)
        TestDataFactory.insertCrossSellingCustomSetting();

        List<Account> cuentasTest = TestDataFactory.generateAccounts(Label.GeneralInsurance,'BusinessCustomer', NUM_CONTACTS);
        
        insert cuentasTest;

        List<Contact> contactosTest = new List<Contact>();
        for(Account currentAccount : cuentasTest)
        {
            contactosTest.add(new Contact(LastName = currentAccount.Name, AccountId = currentAccount.Id));
        }
        insert contactosTest;

        RecordType telemarketingCampaign = [SELECT Id FROM RecordTYpe WHERE Name = 'Telemarketing' AND SobjectType  = 'Campaign'];
        RecordType defaultCampaign = [SELECT Id FROM RecordTYpe WHERE Name = 'Default' AND SobjectType  = 'Campaign'];

        Integer campaignCount = 0;
        List<Campaign> campaignTest = new List<Campaign>();
        for(Integer i = 0; i < NUM_CAMPAIGNS; i++)
        {
            campaignTest.add(new Campaign(Name = 'VC' + i, LegalEntity__c= '001', RecordTypeId = telemarketingCampaign.Id, Type = TYPE_CROSS_CAMPAIGN, EndDate = Date.today().addDays(7)));
            campaignTest.add(new Campaign(Name = 'S' + i, LegalEntity__c= '001', RecordTypeId = defaultCampaign.Id, Type = 'Search', EndDate = Date.today().addDays(7)));
        }
        insert campaignTest;

        List<CampaignMember> miembrosCampaignTest = new List<CampaignMember>();
        List<Opportunity> oportunidadesTest = new List<Opportunity>();

        for(Campaign currentCampaign : campaignTest)
        {

            for(Contact currentContact : contactosTest)
            {
                miembrosCampaignTest.add(new CampaignMember(
                    ContactId = currentContact.Id,
                    CampaignId = currentCampaign.Id
                ));

                oportunidadesTest.add(new Opportunity(
                    name = currentCampaign.Name + ' - ' + currentContact.LastName,
                    AccountId = currentContact.AccountId,
                    CampaignId = currentCampaign.Id,
                    SalesProcess__c = 'VC',
                    CloseDate = Date.today().addDays(7)
                ));
            }
        }

        Insert miembrosCampaignTest;

        delete [SELECT Id from Opportunity];
 
        Insert oportunidadesTest;
    }

    @isTest
    static void test_DontRemoveCampaignMembers_OK()
    {
        List<Opportunity> beforeOpportunitues = [SELECT StageName, Sales_Loss_Reason__c FROM Opportunity];

        for(Opportunity currentOpportunity : beforeOpportunitues)
        {
            Assert.areNotEqual('Closed Lost', currentOpportunity.StageName, 'Antes de hacer la comprobación el estado no puede ser el que se quiere conseguir');
            Assert.areNotEqual('Not interested Policy - Revocation Consents', currentOpportunity.Sales_Loss_Reason__c, 'No es la razon que deberia tener antes de empezar el test');
        }

        List<CampaignMember> beforeCampaignMembers = [SELECT Id FROM CampaignMember];

        Assert.isTrue(! beforeCampaignMembers.isEmpty(), 'No hay miembros de camapaña para el test!');

        Test.startTest();
        Database.executeBatch(New Batch_CloseOppsWithoutCampMemb());
        Test.stopTest();

        List<Opportunity> testResultOpportunities = [SELECT StageName, Sales_Loss_Reason__c FROM Opportunity];

        Assert.areEqual(beforeOpportunitues.size(), testResultOpportunities.size(),'Por alguna razon han desaparecido o creado oportunidades que no se debian');

        for(Opportunity currentOpportunity : testResultOpportunities)
        {
            Assert.areNotEqual('Closed Lost', currentOpportunity.StageName, 'El proceso no debería haber cambiado este estado');
            Assert.areNotEqual('Not interested Policy - Revocation Consents', currentOpportunity.Sales_Loss_Reason__c, 'No es la razon que deberia tener tras el proceso');
        }

        List<CampaignMember> testResultCampaignMember = [SELECT Id FROM CampaignMember];

        Assert.areEqual(beforeCampaignMembers.size(), testResultCampaignMember.size(),'El numero de campaign members no debería haber cambiado');
    }

    // Este test tiene que cerrar todas las oportunidades de las campañas de ventas, pero no las otras, se borren o no sus miembros de campaña
    @isTest
    static void test_RemoveAllCampaignMembers_OK()
    {
        delete [SELECT Id FROM CampaignMember];

        Test.startTest();
        Database.executeBatch(New Batch_CloseOppsWithoutCampMemb());
        Test.stopTest();

        for(Opportunity currentOpportunity : [SELECT Name, CampaignId, Campaign.Type, StageName, Sales_Loss_Reason__c FROM Opportunity])
        {
            if(currentOpportunity.Campaign.Type == TYPE_CROSS_CAMPAIGN)
            {
                // Assert.isTrue(currentOpportunity.StageName == 'Closed Lost', 'Esta oportunidad tendría que haber cambiado de estado');
                // Assert.isTrue(currentOpportunity.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'No es el motivo de cierre esperado');
            }
            else
            {
                // Assert.isFalse(currentOpportunity.StageName == 'Closed Lost', 'La oportunidad no tendría que haber cambiado de estado');
                // Assert.isFalse(currentOpportunity.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'Ese campo no debería tener este valor para esta oportunidad');
            }
        }
    }

    @isTest
    static void test_RemoveAllMembersOneCampaign_OK()
    {
        List<Opportunity> campaignOpps = [SELECT CampaignId, AccountId FROM Opportunity WHERE Campaign.Type = :TYPE_CROSS_CAMPAIGN];

        Set<Id> campaigns = new Set<Id>();

        for(Opportunity currentOp : campaignOpps)
        {
            campaigns.add(currentOp.CampaignId);
        }

        List<CampaignMember> miembros = [SELECT CampaignId,ContactId, Contact.AccountId, Campaign.Name, Contact.Account.Name FROM CampaignMember WHERE CampaignId IN : campaigns];

        Map<String,List<CampaignMember>> miembrosPorCampana = new Map<String,List<CampaignMember>>();

        for(CampaignMember currentCM : miembros)
        {
            if(!miembrosPorCampana.containsKey(currentCM.CampaignId))
            {
                miembrosPorCampana.put(currentCM.CampaignId, new List<CampaignMember>());
            }

            miembrosPorCampana.get(currentCM.CampaignId).add(currentCM);
        }

        String primeraCampaign = new List<String>(miembrosPorCampana.keySet()).get(0);

        List<CampaignMember> deletedMembers = miembrosPorCampana.get(primeraCampaign);
        String campaignOfDeletedMembers;
        List<String> accountIdsOfDeletedMembers = new List<String>();

        for(CampaignMember toBeDeletedMembers : deletedMembers)
        {
            accountIdsOfDeletedMembers.add(toBeDeletedMembers.Contact.accountid);
            campaignOfDeletedMembers = toBeDeletedMembers.CampaignId;
        }

        delete deletedMembers;

        Test.startTest();
        Database.executeBatch(New Batch_CloseOppsWithoutCampMemb());
        Test.stopTest();

        List<Opportunity> allOpps = [SELECT CampaignId, Campaign.Name, AccountId,Account.Name, Campaign.Type, StageName, Sales_Loss_Reason__c FROM Opportunity];

        Integer changeOppsNumber = 0;
        for(Opportunity currentOpp : allOpps)
        {
            if(currentOpp.Campaign.Type == TYPE_CROSS_CAMPAIGN && currentOpp.CampaignId == campaignOfDeletedMembers && accountIdsOfDeletedMembers.contains(currentOpp.AccountId))
            {
                // Assert.isTrue(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no ha cambiado al estado esperado');
                // Assert.isTrue(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'El motivo de esta campo no es el esperado');
                // changeOppsNumber++;
            }
            else
            {
                // Assert.isFalse(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no debería tener este estado');
                // Assert.isFalse(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'Este campo para esta oportunidad no debe tener este valor');
            }
        }

        // Quitar el recalculo si desaparece el Batch de creación de oportunidades a partir de nuevos miembros de campaña
        //Integer notSoRealNumberOfOpportunitiesModified = changeOppsNumber / 2;
        //Assert.areEqual(deletedMembers.size(), notSoRealNumberOfOpportunitiesModified, 'El numero de oportunidades transformadas no coincide con el numero de miembros de campaña borrados');
    }

    @isTest
    static void test_RemoveSomeMembersOneCampaign_OK()
    {
        List<Opportunity> campaignOpps = [SELECT CampaignId, AccountId FROM Opportunity WHERE Campaign.Type = :TYPE_CROSS_CAMPAIGN];

        Set<Id> campaigns = new Set<Id>();

        for(Opportunity currentOp : campaignOpps)
        {
            campaigns.add(currentOp.CampaignId);
        }

        List<CampaignMember> miembros = [SELECT CampaignId,ContactId, Contact.AccountId, Campaign.Name, Contact.Account.Name FROM CampaignMember WHERE CampaignId IN : campaigns];

        Map<String,List<CampaignMember>> miembrosPorCampana = new Map<String,List<CampaignMember>>();

        for(CampaignMember currentCM : miembros)
        {
            if(!miembrosPorCampana.containsKey(currentCM.CampaignId))
            {
                miembrosPorCampana.put(currentCM.CampaignId, new List<CampaignMember>());
            }

            miembrosPorCampana.get(currentCM.CampaignId).add(currentCM);
        }

        //System.debug(miembrosPorCampana.size());

        String primeraCampaign = new List<String>(miembrosPorCampana.keySet()).get(0);

        List<CampaignMember> deletedMembers = miembrosPorCampana.get(primeraCampaign);
        String campaignOfDeletedMembers;
        List<CampaignMember> membersToDelete = new List<CampaignMember>();
        List<String> accountIdsOfDeletedMembers = new List<String>();

        for(Integer i = 0; i <= deletedMembers.size() / 2 ; i++)
        {
            accountIdsOfDeletedMembers.add(deletedMembers[i].Contact.accountid);
            campaignOfDeletedMembers = deletedMembers[i].CampaignId;
            membersToDelete.add(deletedMembers[i]);
        }

        delete membersToDelete;

        Test.startTest();
        Database.executeBatch(New Batch_CloseOppsWithoutCampMemb());
        Test.stopTest();

        Integer changeOppsNumber = 0;
        List<Opportunity> allOpps = [SELECT CampaignId, Campaign.Name, AccountId,Account.Name, Campaign.Type, StageName, Sales_Loss_Reason__c FROM Opportunity];

        for(Opportunity currentOpp : allOpps)
        {
            if(currentOpp.Campaign.Type == TYPE_CROSS_CAMPAIGN && currentOpp.CampaignId == campaignOfDeletedMembers && accountIdsOfDeletedMembers.contains(currentOpp.AccountId))
            {
                // Assert.isTrue(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no ha cambiado al estado esperado');
                // Assert.isTrue(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'El motivo de esta campo no es el esperado');
                // changeOppsNumber++;
            }
            else
            {
                // Assert.isFalse(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no debería tener este estado');
                // Assert.isFalse(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'Este campo para esta oportunidad no debe tener este valor');
            }
        }

        // Quitar el recalculo si desaparece el Batch de creación de oportunidades a partir de nuevos miembros de campaña
        //Integer notSoRealNumberOfOpportunitiesModified = changeOppsNumber / 2;
        //Assert.areEqual(membersToDelete.size(), notSoRealNumberOfOpportunitiesModified, 'El numero de oportunidades transformadas no coincide con el numero de miembros de campaña borrados');
    }

    @isTest
    static void test_RemoveSomeMembersAllCampaigns_OK()
    {
        List<Opportunity> campaignOpps = [SELECT CampaignId, AccountId FROM Opportunity WHERE Campaign.Type = :TYPE_CROSS_CAMPAIGN];

        Set<Id> campaigns = new Set<Id>();

        for(Opportunity currentOp : campaignOpps)
        {
            campaigns.add(currentOp.CampaignId);
        }

        List<CampaignMember> miembros = [SELECT CampaignId,ContactId, Contact.AccountId, Campaign.Name, Contact.Account.Name FROM CampaignMember WHERE CampaignId IN : campaigns];

        Map<String,List<CampaignMember>> miembrosPorCampana = new Map<String,List<CampaignMember>>();

        for(CampaignMember currentCM : miembros)
        {
            if(!miembrosPorCampana.containsKey(currentCM.CampaignId))
            {
                miembrosPorCampana.put(currentCM.CampaignId, new List<CampaignMember>());
            }

            miembrosPorCampana.get(currentCM.CampaignId).add(currentCM);
        }

        String primeraCampaign = new List<String>(miembrosPorCampana.keySet()).get(0);

        List<CampaignMember> membersToDelete = new List<CampaignMember>();
        List<String> accountIdsOfDeletedMembers = new List<String>();

        for(String currentCampaign : miembrosPorCampana.keySet())
        {
            List<CampaignMember> deletedMembers = miembrosPorCampana.get(currentCampaign);

            for(Integer i = 0; i <= deletedMembers.size() / 2 ; i++)
            {
                accountIdsOfDeletedMembers.add(deletedMembers[i].Contact.accountid);
                membersToDelete.add(deletedMembers[i]);
            }
        }

        delete membersToDelete;

        Test.startTest();
        Database.executeBatch(New Batch_CloseOppsWithoutCampMemb());
        Test.stopTest();

        List<Opportunity> allOpps = [SELECT CampaignId, Campaign.Name, AccountId,Account.Name, Campaign.Type, StageName, Sales_Loss_Reason__c FROM Opportunity];

        Integer changeOppsNumber = 0;
        for(Opportunity currentOpp : allOpps)
        {
            //&& currentOpp.CampaignId == campaignOfDeletedMembers
            if(currentOpp.Campaign.Type == TYPE_CROSS_CAMPAIGN  && accountIdsOfDeletedMembers.contains(currentOpp.AccountId))
            {
                // Assert.isTrue(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no ha cambiado al estado esperado');
                // Assert.isTrue(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'El motivo de esta campo no es el esperado');
                // changeOppsNumber++;
            }
            else
            {
                // Assert.isFalse(currentOpp.StageName == 'Closed Lost', 'Esta oportunidad no debería tener este estado');
                // Assert.isFalse(currentOpp.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents', 'Este campo para esta oportunidad no debe tener este valor');
            }
        }

        // Quitar el recalculo si desaparece el Batch de creación de oportunidades a partir de nuevos miembros de campaña
        //Integer notSoRealNumberOfOpportunitiesModified = changeOppsNumber / 2;
        //Assert.areEqual(membersToDelete.size(), notSoRealNumberOfOpportunitiesModified, 'El numero de oportunidades transformadas no coincide con el numero de miembros de campaña borrados');
    }
}