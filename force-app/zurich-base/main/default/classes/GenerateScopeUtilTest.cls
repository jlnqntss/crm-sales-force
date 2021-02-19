@isTest
private class GenerateScopeUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 50);
        insert accounts;

        // creacion de polizas        
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        for(Policy__c p: policies) {
            p.Scope__c = 'Z';
        }
        insert policies;
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
            //System.debug( 'Entra ' + result.getErrors() );
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

    /**
     * Comprueba que se rellenan los Scope de un objeto a partir del scope que tenga otro objeto referenciado
     * Poner el scope de poliza en el campo scope de siniestro (claim)
     * 
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     * 
     */
    @isTest
    static void test_handleEventsAlternativeSObjects()
    {   
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null];
        System.assertEquals(50, policies.size(), 'Deberia haber 50 polizas con scope');

        // Preparamos los siniestros (claim) sin indicar el scope
        List<Claim__c> claims = new List<Claim__c>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            claims.add(new Claim__c(
                Name= String.valueOf(i + 1).leftPad(9, '0'),
                Policy__c= policies[i].Id
            ));
        }
        
        Test.startTest();
        insert claims;
        Test.stopTest();

        List<Claim__c> claimsUpdated = [SELECT Scope__c FROM Claim__c WHERE Scope__c != null];
        System.assertEquals(50, claimsUpdated.size(), 'No se han generado todas los siniestros con el Ambito correctamente');
    }

    
    /**
     * Comprueba que se produce un error si el objeto (SObject) del cual recuperar el scope no existe
     * 
     * @author nts(agonzalezisasi)
     * @date 19/02/2021
     */
    @isTest
    static void test_handleEventsAlternative_RefObject_ko()
    {
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null LIMIT 1];
        System.assertEquals(1, policies.size(), 'Deberia haber 1 polizas con scope');

        List<GenerateScopeEvent__e> events = new List<GenerateScopeEvent__e>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            events.add(new GenerateScopeEvent__e(
                AccountId__c = policies[i].Id,
                RelatedId__c = 'xxxxx',
                RelatedFieldName__c = 'Scope__c',
                ObjectType__c = 'Claim__c',
                ReferenceObjectName__c = 'InvalidObject__c',
                ReferenceFieldName__c = 'Scope__c'
            ));
        }

        Test.startTest();
        GenerateScopeUtil.handleEventsAlternativeSObjects(events);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'Deberia haber 1 error log');
    }

    
    /**
     * Comprueba que se produce un error si el campo donde recuperar el scope no existe en el objeto
     * referenciado
     * 
     * @author nts(agonzalezisasi)
     * @date 19/02/2021
     */
    @isTest
    static void test_handleEventsAlternative_RefObjectField_ko()
    {
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null LIMIT 1];
        System.assertEquals(1, policies.size(), 'Deberia haber 1 polizas con scope');

        List<GenerateScopeEvent__e> events = new List<GenerateScopeEvent__e>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            events.add(new GenerateScopeEvent__e(
                AccountId__c = policies[i].Id,
                RelatedId__c = 'xxxxx',
                RelatedFieldName__c = 'Scope__c',
                ObjectType__c = 'Claim__c',
                ReferenceObjectName__c = 'Policy__c',
                ReferenceFieldName__c = 'InvalidField__c'
            ));
        }

        Test.startTest();
        GenerateScopeUtil.handleEventsAlternativeSObjects(events);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'Deberia haber 1 error log');
    }

    
    /**
     * Comprueba que se produce un error si el objeto (sobject) destino del scope no existe
     * 
     * @author nts(agonzalezisasi)
     * @date 19/02/2021
     */
    @isTest
    static void test_handleEventsAlternative_RelatedObject_ko()
    {
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null LIMIT 1];
        System.assertEquals(1, policies.size(), 'Deberia haber 1 polizas con scope');

        List<GenerateScopeEvent__e> events = new List<GenerateScopeEvent__e>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            events.add(new GenerateScopeEvent__e(
                AccountId__c = policies[i].Id,
                RelatedId__c = 'xxxxx',
                RelatedFieldName__c = 'Scope__c',
                ObjectType__c = 'InvalidObject__c',
                ReferenceObjectName__c = 'Policy__c',
                ReferenceFieldName__c = 'Scope__c'
            ));
        }

        Test.startTest();
        GenerateScopeUtil.handleEventsAlternativeSObjects(events);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'Deberia haber 1 error log');
    }

    /**
     * Comprueba que se produce un error si el campo donde dejar el scope no existe en el objeto
     * destino
     * 
     * @author nts(agonzalezisasi)
     * @date 19/02/2021
     */
    @isTest
    static void test_handleEventsAlternative_RelatedObjectField_ko()
    {
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null LIMIT 1];
        System.assertEquals(1, policies.size(), 'Deberia haber 1 polizas con scope');

        List<GenerateScopeEvent__e> events = new List<GenerateScopeEvent__e>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            events.add(new GenerateScopeEvent__e(
                AccountId__c = policies[i].Id,
                RelatedId__c = 'xxxxx',
                RelatedFieldName__c = 'InvalidField__c',
                ObjectType__c = 'Claim__c',
                ReferenceObjectName__c = 'Policy__c',
                ReferenceFieldName__c = 'Scope__c'
            ));
        }

        Test.startTest();
        GenerateScopeUtil.handleEventsAlternativeSObjects(events);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'Deberia haber 1 error log');
    }
}
