
/**
 * @description       :
 * @author            : dmunoz
 * @group             :
 * @last modified on  : 16-10-2024
 **/
@isTest
public with sharing class CompetitorsSelectorTest {
    

    @TestSetup
    private static void makeData(){

        // se añade porque se ejecuta un flujo de visibildad para competencias
        TestDataFactory.insertCrossSellingCustomSetting();

        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Competitor__c> competitors = TestDataFactory.generateCompetitors(accounts, 2);
        insert competitors;
    }

    @isTest
    private static void getCompetitorsRelatedWithAccauntIds_OK() {

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Customer' LIMIT 1]);
        List<String> accountsIdsList = new List<String>();

        for (Account account: accounts) {
            accountsIdsList.add(account.Id); 
        }

        Test.startTest();
        CompetitorsSelector selector = new CompetitorsSelector();
        List<Competitor__c> competitorsQueryList = selector.getCompetitorsRelatedWithAccauntIds(accountsIdsList);

        Test.stopTest();
        Assert.isTrue(competitorsQueryList.size() > 0, 'Se deben encontrar registros de competencia');
    }
}