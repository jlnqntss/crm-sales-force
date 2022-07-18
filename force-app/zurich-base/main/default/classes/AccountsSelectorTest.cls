@isTest
private with sharing class AccountsSelectorTest
{
    public static final String SET_ERROR_MSG            =   'Set should contains the record Id';
    public static final String EMPTY_TEXT_MSG           =   'List shouldnt be empty';
    public static final String NEMP_TEXT_MSG            =   'List should be empty';
    public static final String ACC_ERROR_MSG            =   'There should be Accounts';
    public static final String INTERMEDIARY_EMAIL       =   'intermediary01@invalid.com';
    public static final String INTERMEDIARY_EMAIL_FIELD =   'MainEmail__c';

    @TestSetup
    public static void createScenario()
    {
        //Zurich Empresas
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        //Intermediary-> NO tienen ContactPointPhones!!!
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts('001', 'Intermediary', 10);
        intermediaryAccounts[0].put(INTERMEDIARY_EMAIL_FIELD, INTERMEDIARY_EMAIL);
        insert intermediaryAccounts;

        List<Account> agrupations = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_AGRUPATION, 1
        );
        insert agrupations;
    }

    @isTest
    static void test_findByNationalId_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId LIMIT 1];
        System.assertEquals(1, accountsToSearch.size(), 'There should be 1 Account');

        String nationalId = accountsToSearch.get(0).NationalId__c;

        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ZE);
        accountsSelector.setlegalEntity(RecordsSelector.LegalEntity.GI);
        List<Account> matchedRecords = accountsSelector.findByNationalId(new List<String> { nationalId }, 'N');

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByNationalId_notFound()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguna de las cuentas existentes
        String nationalId = 'A';

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ZE);
        accountsSelector.setlegalEntity(RecordsSelector.LegalEntity.GI);
        List<Account> matchedRecords = accountsSelector.findByNationalId(new List<String> { nationalId }, 'N');

        Test.stopTest();

        // Then
        System.assertEquals(true, matchedRecords.isEmpty(), 'The list should be empty');
    }

    @isTest
    static void test_findByNationalId_emptyNationalIdType()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguna de las cuentas existentes
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId LIMIT 1];
        System.assertEquals(1, accountsToSearch.size(), 'There should be 1 Account');

        String nationalId = accountsToSearch.get(0).NationalId__c;

        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ZE);
        accountsSelector.setlegalEntity(RecordsSelector.LegalEntity.GI);
        List<Account> matchedRecords = accountsSelector.findByNationalId(new List<String> { nationalId }, '');

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByNationalId_matchedRecords_bulk()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        List<Account> accountsToSearch = [SELECT Id, NationalId__c FROM Account];
        System.assertEquals(true, accountsToSearch.size() > 1, 'There should be more than 1 Account');

        List<String> listDNI = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            listDNI.add(account.NationalId__c);
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ZE);
        accountsSelector.setlegalEntity(RecordsSelector.LegalEntity.GI);
        List<Account> matchedRecords = accountsSelector.findByNationalId(listDNI, 'N');

        Test.stopTest();

        // Then
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByPhoneNumber_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> telephoneNumberToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c, TelephoneNumber FROM ContactPointPhone])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            telephoneNumberToSearch.add(contactPoint.TelephoneNumber);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByPhoneNumber(telephoneNumberToSearch);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds));

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByPhoneNumber( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findByEmail_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> emailsToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            emailsToSearch.add(contactPoint.EmailAddress);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByEmail(emailsToSearch);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds) );

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByEmail_ko()
    {
        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByEmail( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findByPolicyNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, ACC_ERROR_MSG);
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las pólizas que hay
        List<String> policyNumbers = new List<String>();
        List<Policy__c> policiesSelected = [SELECT InfoPolicyNumber__c FROM Policy__c WHERE PolicyHolder__c IN :accountIds];
        for(Policy__c policy: policiesSelected)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByPolicyNumber(policyNumbers);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByPolicyNumber_ko()
    {
        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByPolicyNumber( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findByQuoteNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, ACC_ERROR_MSG);
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las ofertas que hay
        List<String> quoteNumbers = new List<String>();
        List<Opportunity> quotesSelected = [SELECT InfoQuoteNumber__c FROM Opportunity WHERE AccountId IN :accountIds];
        for(Opportunity quote: quotesSelected)
        {
            if( !String.isBlank(quote.InfoQuoteNumber__c) )
            {
                quoteNumbers.add(quote.InfoQuoteNumber__c);
            }
        }

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByQuoteNumber(quoteNumbers);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByQuoteNumber_ko()
    {
        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByQuoteNumber( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findByIntermediaryPhoneNumber_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, Phone, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, ACC_ERROR_MSG);
        Set<Id> accountIds = new Set<Id>();
        List<String> phoneNumbers = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            phoneNumbers.add(account.Phone);
        }
        Test.setFixedSearchResults( new List<Id>(accountIds) );

        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().findByIntermediaryPhoneNumber(phoneNumbers);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByIntermediaryPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().findByIntermediaryPhoneNumber( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findByIntermediaryCode_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, INFOIntermediaryCode__c, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, ACC_ERROR_MSG);
        Set<Id> accountIds = new Set<Id>();
        List<String> codes = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            codes.add(account.INFOIntermediaryCode__c);
        }

        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().findByIntermediaryCode(codes);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), EMPTY_TEXT_MSG );

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), SET_ERROR_MSG);
        }
    }

    @isTest
    static void test_findByIntermediaryCode_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().findByIntermediaryCode( new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    /**
     * Test findByIdsAndScope method
     *
     * @author NTS (agonzalezisasi)
     * @date 10/12/2020
     */
    @isTest
    static void test_findByIdsAndScope_ok()
    {
        // Include Personal Accounts Test - 10/12/2020 - NTS (agonzalezisasi)
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 2);
        insert accounts;
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 3);
        insert scopes;

        Test.startTest();
        Set<Id> ids = new Set<Id> {accounts[0].Id, accounts[1].Id};
        AccountsSelector accountSel = new AccountsSelector();
        List<Account> result = accountSel.findByIdsAndScope(ids, new List<String> {'ZE', 'ZEO'});
        Test.stopTest();

        
        System.assertEquals(2, result.size(), 'There should be 2 accounts');
        System.assertEquals(3, result[0].Scope__r.size(), 'There should be 3 scopes for the first account');
        System.assertEquals(3, result[1].Scope__r.size(), 'There should be 3 scopes for the second account');
    }

    @isTest
    static void test_selectById_ko()
    {
        Test.startTest();

        List<Account> selectedAccounts = new AccountsSelector().selectById(new Set<Id>());

        Test.stopTest();

        System.assertEquals(true, selectedAccounts.isEmpty(), 'Se debería recibir una lista vacía');
    }

    @isTest
    static void test_selectById_ok()
    {
        // When
        Set<Id> accountIds = new Map<Id, Account>( [SELECT Id FROM Account] ).keySet();

        // Test
        Test.startTest();

        Map<Id, Account> selectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(accountIds));

        Test.stopTest();

        // Then
        System.assertEquals(true, !selectedAccountsById.isEmpty(), 'Se debería recibir una lista no vacía');
        System.assertEquals(accountIds.size(), selectedAccountsById.keySet().size(), 'Se debería recibir el mismo número de cuentas');
        System.assertEquals(true, selectedAccountsById.keySet().containsAll(accountIds), 'No contiene todos los ids de cuenta');
    }


    @isTest
    static void test_findAgrupatedIntermediries()
    {
        List<Account> acList = [SELECT Id, NationalID__c FROM Account WHERE RecordType.DeveloperName='Intermediary' ];

        Test.startTest();
        List<Account> agrupated = new AccountsSelector().findAgrupatedIntermediaries(acList);
        Test.stopTest();

        System.assertEquals(false, agrupated.isEmpty(), 'Deberia haber cuentas de Agrupacion de Intermediarios');
    }

    /**
     * Test del metodo que busca un email en los campos dados
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     */
    @isTest
    static void test_findIntermediariesByEmailInFields()
    {
        Test.startTest();
        List<Account> intermediaries = new AccountsSelector().findIntermediariesByEmailInFields(
            INTERMEDIARY_EMAIL, new Set<String>{INTERMEDIARY_EMAIL_FIELD}
        );
        Test.stopTest();

        System.assertEquals(1, intermediaries.size(), 'Deberia haber 1 Mediador');
    }

    /**
     * Test del metodo que busca un email en los campos dados
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     */
    @isTest
    static void test_findWithFields()
    {
        AccountsSelector accSel = new AccountsSelector();
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordTypeId = :accSel.rtIntermediaryId];
        System.assertEquals(false, accounts.isEmpty(), 'Deberia haber cuentas');

        Set<String> fields = new Set<String>{'Name'};

        Test.startTest();
        accounts = accSel.findWithFields(accounts, fields);
        Test.stopTest();

        System.assertEquals(false, accounts.isEmpty(), 'Deberia haber cuentas');
        System.assertEquals(true, String.isNotBlank(accounts[0].Name), 'El nombre de la cuenta no deberia estar vacio');
    }

    /**
     * Test del metodo que recupera las agrupaciones de mediadores
     * por una subquery con los ids de las cuentas
     *
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     */
    @isTest
    static void test_findAgrupationsBySubquery()
    {
        AccountsSelector accSel = new AccountsSelector();
        
        List<Account> agrupations = [SELECT Id FROM Account WHERE RecordTypeId = :accSel.rtAgrupationId];
        System.assertEquals(1, agrupations.size(), 'Deberia haber 1 agrupacion');

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(
            agrupations, ContactsSelector.RT_NAME_CONTACT, 1
        );
        insert contacts;

        // Se recupera el id del recordtype de agrupacion de mediadores si no se ha hecho ya
        Query subquery = new Query(Contact.getSObjectType());
        subquery.selectField(Contact.AccountId);
        subquery.addConditionIn(Contact.Id, contacts);

        Test.startTest();
        List<Account> checkAgrupations = new AccountsSelector().findAgrupationsBySubquery(subquery);
        Test.stopTest();

        System.assertEquals(1, checkAgrupations.size(), 'Deberia encontrar 1 agrupacion');
    }

}