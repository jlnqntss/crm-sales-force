/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11-09-2023
 * @last modified by  : mfernandezcarrera
**/
@isTest
public class Batch_GDPRDeleteMassiveOffersTest
{
    @TestSetup
    static void makeData()
    {
        Integer numFAccounts = 0;
        Integer numJAccounts = 0;

        Map<String,Integer> numTypeAccounts = getHowManyAccountOfEachType(Batch_GDPRDeleteMassiveOffers.INTERNAL_ESTRUCTURE.keySet());

        numFAccounts = numFAccounts + numTypeAccounts.get('F');
        numJAccounts = numJAccounts + numTypeAccounts.get('J');

        numTypeAccounts = getHowManyAccountOfEachType(Batch_GDPRDeleteMassiveOffers.DEFAULT_ESTRUCTURE.keySet());

        numFAccounts = numFAccounts + numTypeAccounts.get('F');
        numJAccounts = numJAccounts + numTypeAccounts.get('J');

        List<Account> accountsForTest = TestDataFactory.generateAccounts('001', 'Business Customer', numFAccounts + numJAccounts);

        List<Account> fAccounts = new List<Account>();
        List<Account> jAccounts = new List<Account>();

        Integer jCounter = 0;

        for(Account nextAccount : accountsForTest)
        {
            if(jCounter < numJAccounts)
            {
                nextAccount.Type = 'J';
                jAccounts.add(nextAccount);
                jCounter++;
            }
            else
            {
                nextAccount.Type = 'F';
                fAccounts.add(nextAccount);
            }
        }

        insert accountsForTest;

        createTestOffersToDelete(Batch_GDPRDeleteMassiveOffers.INTERNAL_ESTRUCTURE, jAccounts, fAccounts);
        createTestOffersToDelete(Batch_GDPRDeleteMassiveOffers.DEFAULT_ESTRUCTURE, jAccounts, fAccounts);
    }

    /**
     * @description Test que comprueba que los elementos presentes en los mapas de estructuras
     *              se borran correctamente.
     * @author      jgallaga | 30/10/2023
     */
    private static void createTestOffersToDelete(Map<String,Integer> mapaEstructuras, List<Account> jAccounts, List<Account> fAccounts)
    {
        List<Opportunity> offersForTestToDelete = new List<Opportunity>();

        Boolean isNotDefaultEstructure = false;

        for(String nextEntry : mapaEstructuras.keySet())
        {
            isNotDefaultEstructure = nextEntry.length() > 4;

            Account relatedAccount;
            String accountType = nextEntry.right(1); // Cogemos la letra del tipo de cuenta

            if(accountType == 'J')
            {
                relatedAccount = jAccounts.remove(0); // Cogemos el primer elemento de la lista de cuentas de tipo J y se elimina de la lista de paso
            }
            else
            {
                relatedAccount = fAccounts.remove(0); // Cogemos el primer elemento de la lista de cuentas de tipo F y se elimina de la lista de paso
            }

            // Procedemos a crear la oferta
            Opportunity newOpp = TestDataFactory.generateOpportunitiesForEachAccount(new List<Account>{relatedAccount}, 'General', 'Open', Date.today().addDays(30), 1)[0];

            newOpp.LegalEntity__c = nextEntry.substring(0,3); // -> Desde el indice siendo un array que empieza en 0. Hasta donde quieres -1.
            if(isNotDefaultEstructure)
            {
                newOpp.CommercialStructureCode__c = nextEntry.substring(3,7);  // -> Desde el indice siendo un array que empieza en 0. Hasta donde quieres -1.
            }
            else
            {
                newOpp.CommercialStructureCode__c = '0000';
            }

            offersForTestToDelete.add(newOpp);
        }

        insert offersForTestToDelete;

        List<Opportunity> createdOpportunities;
        if(isNotDefaultEstructure)
        {
            createdOpportunities=[SELECT Account.Type, CommercialStructureCode__c, LegalEntity__c, CreatedDate FROM Opportunity WHERE CommercialStructureCode__c!='0000'];
        }
        else 
        {
            createdOpportunities=[SELECT Account.Type, CommercialStructureCode__c, LegalEntity__c, CreatedDate FROM Opportunity WHERE CommercialStructureCode__c ='0000'];
        }

        for(Opportunity testOpportunity : createdOpportunities)
        {
            String keyValue;
            if(isNotDefaultEstructure)
            {
                keyValue = testOpportunity.LegalEntity__c + testOpportunity.CommercialStructureCode__c + testOpportunity.Account.Type;
            }
            else
            {
                keyValue = testOpportunity.LegalEntity__c + testOpportunity.Account.Type;
            }

            Integer days = mapaEstructuras.get(keyValue);
            Date fakeCreatedDate = Date.today().addDays(-days);

            Test.setCreatedDate(testOpportunity.Id, fakeCreatedDate);
        }
    }

    private static Map<String,Integer> getHowManyAccountOfEachType(Set<String> mapKeySet)
    {
        Map<String,Integer> mapCounter = new Map<String,Integer>{ 'F' => 0, 'J' => 0};

        for(String nextValue : mapKeySet)
        {
            String accountType = nextValue.right(1);
            mapCounter.put(accountType, mapCounter.get(accountType) + 1);
        }

        return mapCounter;
    }


    @isTest
    private static void test_deleteOfferOfEstructureTables()
    {
        Test.startTest();
        for(Opportunity testOpportunity : [SELECT Account.Type, CommercialStructureCode__c, LegalEntity__c, createddate FROM Opportunity])
        {
            System.debug('Opp ' + testOpportunity.Account.Type + ' - Estructura ' + testOpportunity.CommercialStructureCode__c  + ' - Entidad ' + testOpportunity.LegalEntity__c + ' - ' +  testOpportunity.createddate);
        }
        Database.executeBatch(new Batch_GDPRDeleteMassiveOffers());
        Test.stopTest();

        List<Opportunity> deletedOffers = [SELECT Id FROM Opportunity];

        System.debug(deletedOffers.size());

        Assert.isTrue(deletedOffers.isEmpty(), 'No se han borrado las ofertas esperadas');
    }

    @isTest
    // Método del test en el que no se debe de borrar ninfuna oferta ya que no cumplen las condiciones
    static void test_NoDeleteOffers()
    {
        List<Account> accountF = TestDataFactory.generateAccounts('999', 'Business Customer', 1);

        accountF[0].FirstName='Prueba';
        accountF[0].Type='F';
        insert accountF;

       // create new 3 offers
       List<Opportunity> newOffersFNoDelete = TestDataFactory.generateOpportunitiesForEachAccount(accountF, 'General', 'Open',System.today().addDays(10), 3);

       newOffersFNoDelete[0].CommercialStructureCode__c='5500';
       newOffersFNoDelete[1].CommercialStructureCode__c='5501';
       newOffersFNoDelete[2].CommercialStructureCode__c='1997';

       insert newOffersFNoDelete;

        test.startTest();
        Batch_GDPRDeleteMassiveOffers batchDeleteMassiveOfferGdpr=new Batch_GDPRDeleteMassiveOffers();
        Database.executeBatch(batchDeleteMassiveOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(3, oppListNew.size());
    }

    @isTest
    // Método del test en el que no se debe de borrar ninfuna oferta ya que no cumplen las condiciones por las fechas
    static void test_NoDeleteOffersByDate()
    {
        List<Account> accountJ = TestDataFactory.generateAccounts('001', 'Business Customer', 1);

        accountJ[0].FirstName='Prueba';
        accountJ[0].Type='J';
        insert accountJ;

       // create new 3 offers
       List<Opportunity> newOffersJNoDelete = TestDataFactory.generateOpportunitiesForEachAccount(accountJ, 'General', 'Open',System.today().addDays(10), 2);

       newOffersJNoDelete[0].CommercialStructureCode__c='6100';
       newOffersJNoDelete[1].CommercialStructureCode__c='6300';

       insert newOffersJNoDelete;

        test.startTest();
        Batch_GDPRDeleteMassiveOffers batchDeleteMassiveOfferGdpr=new Batch_GDPRDeleteMassiveOffers();
        Database.executeBatch(batchDeleteMassiveOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id FROM Opportunity];
        System.assertEquals(2, oppListNew.size());
    }

    @isTest
    // Método del test en el que no se debe de borrar ninfuna oferta ya que no cumplen las condiciones por las fechas
    static void test_NoDeleteOfferLegalEntity()
    {
        List<Account> accountJ = TestDataFactory.generateAccounts('999', 'Business Customer', 1);

        accountJ[0].FirstName='Prueba';
        accountJ[0].Type='J';
        insert accountJ;

       // create new offer
       List<Opportunity> newOffersJNoDelete = TestDataFactory.generateOpportunitiesForEachAccount(accountJ, 'General', 'Open',System.today().addDays(10), 1);

       newOffersJNoDelete[0].CommercialStructureCode__c='0000';

       insert newOffersJNoDelete;
       List<Opportunity> ofertas = [Select id,CreatedDate from Opportunity where id in: newOffersJNoDelete];
       Datetime fecha = Datetime.now().addYears(-6);
       Test.setCreatedDate(ofertas[0].Id, fecha);

        test.startTest();
        Batch_GDPRDeleteMassiveOffers batchDeleteMassiveOfferGdpr=new Batch_GDPRDeleteMassiveOffers();
        Database.executeBatch(batchDeleteMassiveOfferGdpr);
        test.stopTest();
        List<Opportunity> oppListNew= [SELECT id,createdDate,LegalEntity__c,CommercialStructureCode__c,Account.Type FROM Opportunity];
        System.assertEquals(1, oppListNew.size());
    }
}