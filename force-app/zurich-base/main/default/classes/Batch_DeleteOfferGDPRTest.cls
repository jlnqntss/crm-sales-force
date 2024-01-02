/*
 * Test for the Batch Batch_DeleteOfferGDPR
 *
 * @author mfernandezcarrera
 * @date 05/07/2023
 */
@isTest
public class Batch_DeleteOfferGDPRTest
{
    private static final string ACCOUNT_LEAD = 'Lead';
    private static final string LEGAL_ENTITY = '001';
    private static final string OFFER_STAGE_NEW = 'New';
    private static final Id LeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(ACCOUNT_LEAD).getRecordTypeId();

    @TestSetup
    static void makeData()
    {
        
        // create 5 accounts ZE
        List<Account> newAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_LEAD, 5);
        for(Integer i=0;i<newAccounts.size();i++)
        {
            newAccounts[i].firstName = 'test';
            newAccounts[i].LastName = 'Lead ' + i;
            newAccounts[i].RecordTypeId = LeadRecordTypeId;
            newAccounts[i].Salutation = 'Mr.';
        }

        newAccounts[0].Type = 'F';
        newAccounts[1].Type = 'F';
        newAccounts[2].Type = 'J';
        newAccounts[3].Type = 'J';
        newAccounts[4].Type = 'Reseller';

        insert newAccounts;

        // create 7 new offers, for each accountsZE
        List<Opportunity> newOffers = TestDataFactory.generateOpportunitiesForEachAccount(newAccounts, 'ZE', OFFER_STAGE_NEW,System.today().addDays(10), 7);
        Set<Id> cuentaAdaptada= new Set<Id>();
        for(Opportunity currentOpp:newOffers)
        {
            if(!cuentaAdaptada.contains(currentOpp.AccountId))
            {
                currentOpp.CommercialStructureCode__c='6200';
            }
        }
        
        insert newOffers;

       // create 3 accounts General
       List<Account> newAccountsG = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_LEAD, 3);
       for(Integer i=0;i<newAccountsG.size();i++)
       {
           newAccountsG[i].firstName = 'test';
           newAccountsG[i].LastName = 'Lead ' + i;
           newAccountsG[i].RecordTypeId = LeadRecordTypeId;
           newAccountsG[i].Salutation = 'Mr.';
       }

       newAccountsG[0].Type = 'J';
       newAccountsG[1].Type = 'F';
       newAccountsG[2].Type = 'Reseller';

       insert newAccountsG;

       // create new 3 offers, for each accountsG
       List<Opportunity> newOffersG = TestDataFactory.generateOpportunitiesForEachAccount(newAccountsG, 'General', OFFER_STAGE_NEW,System.today().addDays(10), 3);
       Set<Id> cuentaAdaptada2= new Set<Id>();
        for(Opportunity currentOppG:newOffersG)
        {
            if(!cuentaAdaptada2.contains(currentOppG.AccountId))
            {
                currentOppG.CommercialStructureCode__c='6200';
            }
        }

       insert newOffersG;
    }

    // Métod del test en el que se deben de borrar 2 ofertas, ya que cumplen las condiciones
    @isTest
    static void test_DeleteTwoOffersZE()
    {
        List<Opportunity> ofertas = [Select id,CreatedDate,CommercialStructureCode__c, Name from Opportunity where Scope__c = 'ZE' and CommercialStructureCode__c='6200'];
        
        Datetime fecha = Datetime.now().addYears(-4);
        Datetime fecha2 = Datetime.now().addDays(-20);
        Datetime fecha3 = Datetime.now().addYears(-7);

        List<Opportunity> nombreOfertasBorradas = new List<Opportunity>();
        List<String> nombreOfertasNoBorradas = new List<String>();

        //Ofertas que se deben de borrar
        nombreOfertasBorradas.add(ofertas[0]);
        nombreOfertasBorradas.add(ofertas[3]);

        nombreOfertasNoBorradas.add(ofertas[1].Name);
        nombreOfertasNoBorradas.add(ofertas[2].Name);
        nombreOfertasNoBorradas.add(ofertas[4].Name);

        Test.setCreatedDate(ofertas[0].Id, fecha);
        Test.setCreatedDate(ofertas[1].Id, fecha2);
        Test.setCreatedDate(ofertas[2].Id, fecha2);
        Test.setCreatedDate(ofertas[3].Id, fecha3);
        Test.setCreatedDate(ofertas[4].Id, fecha2);

        test.startTest();
        Batch_DeleteOfferGDPR batchDeleteOfferGdpr=new Batch_DeleteOfferGDPR();
        Database.executeBatch(batchDeleteOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(42, oppListNew.size());

        for(Opportunity oppborrado: nombreOfertasBorradas)
        {
            system.assertEquals(false, oppListNew.contains(oppborrado));
        }
    }

    // Métod del test en el que no se debe de borrar ninguna cuenta, ya que no son de ZE
    @isTest
    static void test_NoDeleteOffersGeneral()
    {
        List<Opportunity> ofertas = [Select id,CreatedDate, Scope__c from Opportunity where Scope__c = 'General'];
        Datetime fecha = Datetime.now().addYears(-1);
        Datetime fecha2 = Datetime.now().addYears(-3);

        Test.setCreatedDate(ofertas[0].Id, fecha);
        Test.setCreatedDate(ofertas[1].Id, fecha2);
        Test.setCreatedDate(ofertas[2].Id, fecha2);

        test.startTest();
        Batch_DeleteOfferGDPR batchDeleteOfferGdpr=new Batch_DeleteOfferGDPR();
        Database.executeBatch(batchDeleteOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(44, oppListNew.size());
    }

    // Métod del test en el que añadimos una cuenta fisica, con 6 ofertas que cumplan las condiciones. Se deberían de borrar las 6
    @isTest
    static void test_DeleteAllOffersFisica()
    {
        List<Account> newAccountF = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_LEAD, 1);
        
        newAccountF[0].FirstName='Prueba';
        newAccountF[0].LastName='DeleteAll';
        newAccountF[0].Type='F';
        newAccountF[0].RecordTypeId=LeadRecordTypeId;
        insert newAccountF;

       // create new 6 offers
       List<Opportunity> newOffersFDelete = TestDataFactory.generateOpportunitiesForEachAccount(newAccountF, 'ZE', OFFER_STAGE_NEW,System.today().addDays(10), 6);
       
       newOffersFDelete[0].CommercialStructureCode__c='6100';
       newOffersFDelete[1].CommercialStructureCode__c='6800';
       newOffersFDelete[2].CommercialStructureCode__c='6800';
       newOffersFDelete[3].CommercialStructureCode__c='6200';
       newOffersFDelete[4].CommercialStructureCode__c='6300';
       newOffersFDelete[5].CommercialStructureCode__c='6250';

       insert newOffersFDelete;

        List<Opportunity> ofertasDias = [Select id,CreatedDate,CommercialStructureCode__c from Opportunity where id in: newOffersFDelete];
        Datetime fecha2 = Datetime.now().addYears(-3);
    
        List<Opportunity> nombreOfertasBorradasFisicas = new List<Opportunity>();

        nombreOfertasBorradasFisicas.add(ofertasDias[0]);
        nombreOfertasBorradasFisicas.add(ofertasDias[1]);
        nombreOfertasBorradasFisicas.add(ofertasDias[2]);
        nombreOfertasBorradasFisicas.add(ofertasDias[3]);
        nombreOfertasBorradasFisicas.add(ofertasDias[4]);
        nombreOfertasBorradasFisicas.add(ofertasDias[5]);

        Test.setCreatedDate(ofertasDias[0].Id, fecha2);
        Test.setCreatedDate(ofertasDias[1].Id, fecha2);
        Test.setCreatedDate(ofertasDias[2].Id, fecha2);
        Test.setCreatedDate(ofertasDias[3].Id, fecha2);
        Test.setCreatedDate(ofertasDias[4].Id, fecha2);
        Test.setCreatedDate(ofertasDias[5].Id, fecha2);
        
        test.startTest();
        Batch_DeleteOfferGDPR batchDeleteOfferGdpr=new Batch_DeleteOfferGDPR();
        Database.executeBatch(batchDeleteOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(44, oppListNew.size());

        for(Opportunity oppborrado: nombreOfertasBorradasFisicas)
        {
            system.assertEquals(false, oppListNew.contains(oppborrado));
        }
    }

    // Métod del test en el que añadimos una cuenta juridica, con 6 ofertas que cumplan las condiciones. Se deberían de borrar las 6
    @isTest

    static void test_DeleteAllOffersJuridica()
    {
        List<Account> newAccountJ = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_LEAD, 1);
        newAccountJ[0].FirstName='Prueba';
        newAccountJ[0].LastName='DeleteAll';
        newAccountJ[0].Type='J';
        newAccountJ[0].RecordTypeId=LeadRecordTypeId;
        insert newAccountJ;

       // create new 6 offers
       List<Opportunity> newOffersJDelete = TestDataFactory.generateOpportunitiesForEachAccount(newAccountJ, 'ZE', OFFER_STAGE_NEW,System.today().addDays(10), 6);
       
       newOffersJDelete[0].CommercialStructureCode__c='6100';
       newOffersJDelete[1].CommercialStructureCode__c='6800';
       newOffersJDelete[2].CommercialStructureCode__c='6800';
       newOffersJDelete[3].CommercialStructureCode__c='6200';
       newOffersJDelete[4].CommercialStructureCode__c='6300';
       newOffersJDelete[5].CommercialStructureCode__c='6250';

       insert newOffersJDelete;

        List<Opportunity> ofertas = [Select id,CreatedDate from Opportunity where id in: newOffersJDelete];
        Datetime fecha = Datetime.now().addYears(-6);

        List<Opportunity> nombreOfertasBorradasJuridicas = new List<Opportunity>();

        nombreOfertasBorradasJuridicas.add(ofertas[0]);
        nombreOfertasBorradasJuridicas.add(ofertas[1]);
        nombreOfertasBorradasJuridicas.add(ofertas[2]);
        nombreOfertasBorradasJuridicas.add(ofertas[3]);
        nombreOfertasBorradasJuridicas.add(ofertas[4]);
        nombreOfertasBorradasJuridicas.add(ofertas[5]);

        Test.setCreatedDate(ofertas[0].Id, fecha);
        Test.setCreatedDate(ofertas[1].Id, fecha);
        Test.setCreatedDate(ofertas[2].Id, fecha);
        Test.setCreatedDate(ofertas[3].Id, fecha);
        Test.setCreatedDate(ofertas[4].Id, fecha);
        Test.setCreatedDate(ofertas[5].Id, fecha);

        test.startTest();
        Batch_DeleteOfferGDPR batchDeleteOfferGdpr=new Batch_DeleteOfferGDPR();
        Database.executeBatch(batchDeleteOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(44, oppListNew.size());
        for(Opportunity oppborrado: nombreOfertasBorradasJuridicas)
        {
            system.assertEquals(false, oppListNew.contains(oppborrado));
        }
    }
    @isTest
    static void testBatch_schedule()
    {
        Test.startTest();
        String jobID = system.schedule( 'Delete Offers', '20 30 8 10 2 ?', new Batch_DeleteOfferGDPR() );
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }
}