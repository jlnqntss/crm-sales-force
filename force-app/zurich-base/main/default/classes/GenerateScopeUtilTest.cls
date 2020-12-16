@isTest
private class GenerateScopeUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 50);
        insert accounts;
    }

    @isTest
    static void test_generateScopeEvents()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointPhones.size(); i++)
        {
            contactPointPhones[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        Database.SaveResult[] results = GenerateScopeUtil.generateScopeEvents('ParentId', null, contactPointPhones);
        Test.stopTest();

        System.assert (!results.isEmpty(), 'No se han publicado correctamente los eventos');

        for(Database.SaveResult result : results)
        {
            System.debug( 'Entra ' + result.getErrors() );
            System.assert (result.isSuccess(), 'No se ha publicado correctamente el evento');
        }
    }

    /**
     * Comprobar que no se generan mas ámbitos de los necesarios ni se duplican si ya existe
     * @author adelgado
     * @date 04/12/2020
     * @param events Eventos a procesar
     **/
    @isTest
    static void test_handleEvents_scopeExists()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Scope__c> scopes = new List<Scope__c>();
        for(Account account : accounts)
        {
            scopes.add
            (
                new Scope__c(Name = 'General', Scope__c = 'Z', AccountId__c = account.Id)
            );
        }
        insert scopes;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointPhones.size(); i++)
        {
            contactPointPhones[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointPhones;
        Test.stopTest();

        List<Scope__c> scopesAfter = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<ContactPointPhone> contactPointPhonesUpdated = [SELECT Scope__c, ScopeId__c FROM ContactPointPhone];

        System.assertEquals(50, scopesAfter.size(), 'No se han generado todos los ámbitos necesarios');

        for(ContactPointPhone cpe : contactPointPhonesUpdated)
        {
            System.assert (String.isNotBlank(cpe.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (cpe.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

    /**
     * Comprobar que se generan los ambitos correctamente si no existen
     * @author adelgado
     * @date 04/12/2020
     * @param events Eventos a procesar
     **/
    @isTest
    static void test_handleEvents_scopeNoExists()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);

        for(Integer i = 0; i < contactPointPhones.size(); i++)
        {
            contactPointPhones[i].INFOContactPointNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert contactPointPhones;
        Test.stopTest();

        List<Scope__c> scopesAfter = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<ContactPointPhone> contactPointPhonesUpdated = [SELECT Scope__c, ScopeId__c FROM ContactPointPhone];

        System.assertEquals(50, scopesAfter.size(), 'No se han generado todos los ámbitos necesarios');

        for(ContactPointPhone cpe : contactPointPhonesUpdated)
        {
            System.assert (String.isNotBlank(cpe.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (cpe.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }
}
