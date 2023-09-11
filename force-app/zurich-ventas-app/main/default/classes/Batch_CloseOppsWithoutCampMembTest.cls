/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11/09/2023
 * @last modified by  : jgallaga
**/
@isTest
public class Batch_CloseOppsWithoutCampMembTest
{

    private static Integer NUM_CONTACTS = 10;
    private static Integer NUM_CAMPAIGNS = 5;

    @TestSetup
    static void makeData()
    {
        TestDataFactory.insertCrossSellingCustomSetting();

        List<Account> cuentasTest = new List<Account>();
        for(Integer i = 0; i < NUM_CONTACTS; i++)
        {
            cuentasTest.add(new Account(Name = 'TestCuenta' + i));
        }
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
            campaignTest.add(new Campaign(Name = 'CampañaVC'+i, LegalEntity__c= '001', RecordTypeId = telemarketingCampaign.Id, Type = 'Cross Selling', EndDate = Date.today().addDays(7)));
            campaignTest.add(new Campaign(Name = 'Campaña'+i, LegalEntity__c= '001', RecordTypeId = defaultCampaign.Id, Type = 'Search', EndDate = Date.today().addDays(7)));
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
                    name = currentCampaign.Name + currentContact.LastName,
                    AccountId = currentContact.AccountId,
                    CampaignId = currentCampaign.Id,
                    CloseDate = Date.today().addDays(7)
                ));
            }
        }

        Insert miembrosCampaignTest;
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
            if(currentOpportunity.Campaign.Type == 'Cross Selling')
            {
                Assert.isTrue(currentOpportunity.StageName == 'Closed Lost');
                Assert.isTrue(currentOpportunity.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents');
            }
            else
            {
                Assert.isFalse(currentOpportunity.StageName == 'Closed Lost');
                Assert.isFalse(currentOpportunity.Sales_Loss_Reason__c == 'Not interested Policy - Revocation Consents');
            }
        }
    }

    @isTest
    static void test_DontSomeCampaignMembers_OK()
    {}
}