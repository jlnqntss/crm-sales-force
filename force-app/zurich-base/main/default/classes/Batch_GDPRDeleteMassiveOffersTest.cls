/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 26/10/2023
 * @last modified by  : jgallaga
**/
@isTest
public class Batch_GDPRDeleteMassiveOffersTest
{
    @TestSetup
    static void makeData()
    {

        // QUEDA CREAR OFERTAS PARA LOS TIPOS DE DEFAULT
        Integer numFAccounts = 0;
        Integer numJAccounts = 0;

        Map<String,Integer> numTypeAccounts = getHowManyAccountOfEachType(Batch_GDPRDeleteMassiveOffers.INTERNAL_ESTRUCTURE.keySet());

        System.debug('Primer grupo ' + numTypeAccounts);

        numFAccounts = numFAccounts + numTypeAccounts.get('F');
        numJAccounts = numJAccounts + numTypeAccounts.get('J');

        numTypeAccounts = getHowManyAccountOfEachType(Batch_GDPRDeleteMassiveOffers.DEFAULT_ESTRUCTURE.keySet());

        System.debug('Segundo grupo ' + numTypeAccounts);

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

        System.debug('J Account ' + jAccounts);
        System.debug('F ACcount ' + fAccounts);

        insert accountsForTest;

        createTestOffersToDelete(Batch_GDPRDeleteMassiveOffers.INTERNAL_ESTRUCTURE, jAccounts, fAccounts);
        createTestOffersToDelete(Batch_GDPRDeleteMassiveOffers.DEFAULT_ESTRUCTURE, jAccounts, fAccounts);
    }

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

        for(Opportunity testOpportunity : [SELECT Account.Type, CommercialStructureCode__c, LegalEntity__c FROM Opportunity])
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
    private static void test()
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
}