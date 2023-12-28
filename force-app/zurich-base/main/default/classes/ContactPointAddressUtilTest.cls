@isTest
private class ContactPointAddressUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada vía de contacto de email
     *
     * @author adelgado
     * @date 09/12/2020
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<ContactPointAddress> contactPointAddresses = TestDataFactory.generateContactPointAddressesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointAddresses.size(); i++)
        {
            contactPointAddresses[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointAddresses;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<ContactPointAddress> contactPointAddressesUpdated = [SELECT Scope__c, ScopeId__c FROM ContactPointAddress];

        System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');
        System.assertEquals(20, contactPointAddressesUpdated.size(), 'No se han generado todas las vías de contacto');

        for(ContactPointAddress cpa : contactPointAddressesUpdated)
        {
            System.assert (String.isNotBlank(cpa.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (cpa.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }
}