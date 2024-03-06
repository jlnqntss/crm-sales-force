/**
 * @description       : Clase de test para la clase AccountsSelector
 * @author            :
 * @group             :
 * @last modified on  : 08-22-2023
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class AccountsSelectorTest
{
    public static final String SET_ERROR_MSG            =   'Set should contains the record Id';
    public static final String EMPTY_TEXT_MSG           =   'List shouldnt be empty';
    public static final String NEMP_TEXT_MSG            =   'List should be empty';
    public static final String ACC_ERROR_MSG            =   'There should be Accounts';
    public static final String INTERMEDIARY_EMAIL       =   'intermediary01@invalid.com';
    public static final String INTERMEDIARY_EMAIL_FIELD =   'MainEmail__c';
    public static final String MESSAGE_DEBERIA_HABER_CUENTAS = 'Deberia haber cuentas';
    public static final String INTERMEDIARY_NIF         =   '01234567A';
    public static final String INTERMEDIARY_NIF_FIELD   =   'NationalId__c';
    public static final String INTERMEDIARY_STATUS_FIELD   =   'Status__c';

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
        intermediaryAccounts[0].put(INTERMEDIARY_STATUS_FIELD, '001');
        intermediaryAccounts[0].put(INTERMEDIARY_NIF_FIELD, INTERMEDIARY_NIF);

        insert intermediaryAccounts;

        //Jerarquía y códigos para la parte de visibilidad
        intermediaryAccounts[0].IntermediaryWithUser__c = intermediaryAccounts[1].Id;
        for (Integer i=2; i < intermediaryAccounts.size(); i++)
        {
            intermediaryAccounts[i].ParentId = intermediaryAccounts[0].Id;
        }
        update intermediaryAccounts;

        //Agrupations
        List<Account> agrupations = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_AGRUPATION, 1
            );
        insert agrupations;

        for (Integer i=2; i < intermediaryAccounts.size(); i++)
        {
            intermediaryAccounts[i].IntermediaryGroup__c = agrupations[0].Id;
        }
        update intermediaryAccounts;
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
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>( new AccountsSelector().selectById(recordIds) );

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
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>( new AccountsSelector().selectById(recordIds) );

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
        List<Policy__c> policiesSelected = [SELECT InfoPolicyNumber__c FROM Policy__c WHERE PolicyHolder__c IN : accountIds];
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
        List<Opportunity> quotesSelected = [SELECT InfoQuoteNumber__c FROM Opportunity WHERE AccountId IN : accountIds];
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

        List<Account> selectedAccounts = new AccountsSelector().selectById( new Set<Id>() );

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

        Map<Id, Account> selectedAccountsById = new Map<Id, Account>( new AccountsSelector().selectById(accountIds) );

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

    @isTest
    static void test_findIntermediariesByParentId()
    {
        AccountsSelector accSel = new AccountsSelector();

        List<Account> agrupations = [SELECT Id FROM Account WHERE RecordTypeId = : accSel.rtAgrupationId];
        System.assertEquals(1, agrupations.size(), 'Deberia haber 1 agrupacion');

        List<Account> accounts = [SELECT ParentId FROM Account WHERE RecordTypeId = : accSel.rtIntermediaryId LIMIT 4];
        System.assert (!accounts.isEmpty(), MESSAGE_DEBERIA_HABER_CUENTAS);

        for (Account account : accounts)
        {
            account.ParentId = agrupations.get(0).Id;
        }

        update accounts;

        Test.startTest();
        List<Account> intermediaries = accSel.findIntermediariesByParentId(new Set<Id> {agrupations.get(0).Id});
        Test.stopTest();

        System.assert (!intermediaries.isEmpty(), 'Debería haber intermediarios');
        System.assertEquals(accounts.size(), intermediaries.size(), 'Debería haber ' + accounts.size() + ' intermediarios.');
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
            INTERMEDIARY_EMAIL, new Set<String> {INTERMEDIARY_EMAIL_FIELD}
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
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordTypeId = : accSel.rtIntermediaryId];
        System.assertEquals(false, accounts.isEmpty(), MESSAGE_DEBERIA_HABER_CUENTAS);

        Set<String> fields = new Set<String> {'Name'};

        Test.startTest();
        accounts = accSel.findWithFields(accounts, fields);
        Test.stopTest();

        System.assertEquals(false, accounts.isEmpty(), MESSAGE_DEBERIA_HABER_CUENTAS);
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

        List<Account> agrupations = [SELECT Id FROM Account WHERE RecordTypeId = : accSel.rtAgrupationId];
        System.assertEquals(1, agrupations.size(), 'Deberia haber 1 agrupacion');

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(
            agrupations, ContactsSelector.RT_NAME_CONTACT, 1
            );
        insert contacts;

        // Se recupera el id del recordtype de agrupacion de mediadores si no se ha hecho ya
        Query subquery = new Query( Contact.getSObjectType() );
        subquery.selectField(Contact.AccountId);
        subquery.addConditionIn(Contact.Id, contacts);

        Test.startTest();
        List<Account> checkAgrupations = new AccountsSelector().findAgrupationsBySubquery(subquery);
        Test.stopTest();

        System.assertEquals(1, checkAgrupations.size(), 'Deberia encontrar 1 agrupacion');
    }

    /**
     * Test del método que recupera los clientes en base al cif y la fecha de creación
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     */
    @IsTest
    static void test_findByCIFAndCreationDate()
    {
        AccountsSelector accSel = new AccountsSelector();
        String cif = '11223344';
        Account customer = [SELECT Id, NationalId__c FROM Account WHERE RecordTypeId = : accSel.rtCustomerId LIMIT 1];
        customer.NationalId__c = cif;
        update customer;

        Test.startTest();
        List<Account> accountsfound = new AccountsSelector().findByCIFAndCreationDate(new List<String> {cif}, '1');
        Test.stopTest();

        System.assertEquals(1, accountsfound.size(), 'Deberia encontrar 1 cliente');
    }

    /**
     * Test del método que recupera las cuentas intermediario activas(status 001 o 002)
     * @author lrodriguez6@seidor.es
     * @date 09/02/2023
     */
    @IsTest
    static void test_findAccountsIntermediaryRatio()
    {
        AccountsSelector accSel = new AccountsSelector();

        List<Account> accountsIntermediary = [SELECT Id FROM Account WHERE RecordTypeId = : accSel.rtAccountIntermediaryId ];
        accountsIntermediary[0].Status__c='001';
        accountsIntermediary[1].Status__c='002';

        update accountsIntermediary;

        Test.startTest();
        String query = new AccountsSelector().getQueryStringAccountIntermediaryRatio();
        List<Account> matchedAccountRecords = (List<Account>) Database.query(query);
        Test.stopTest();

        System.assertEquals(2, matchedAccountRecords.size(), 'Deberia encontrar 2 cuentas');
    }


    /**
     * Test del método que recupera cuentas de mediador por codigo de afiliación
     * @author dmunoz
     * @date 26/06/2023
     */
    @IsTest
    static void test_findAccountByBusinessCode()
    {
        AccountsSelector accSel = new AccountsSelector();

        List<Account> accountsQuery = [SELECT Id, INFOBusinessCode__c FROM Account LIMIT 1];

        if ( !accountsQuery.isEmpty() )
        {
            List<String> affiliationCodeList = new List<String>();
            affiliationCodeList.add(accountsQuery.get(0).INFOBusinessCode__c);

            List<Account> result = accSel.findAccountByBusinessCode(affiliationCodeList);

            System.assertEquals(true, !result.isEmpty(), 'Debe tener resultados');

        }

    }

    /**
     * Test del método que recupera las cuentas filtradas por record type name
     * @author aberuete
     * @date 02/06/2023
     */
    @IsTest
    static void test_setRecordType()
    {
        List<Account> allAccountsList = [Select id from Account];
        System.assertEquals(21, allAccountsList.size(), 'El número de cuentas totales no es correcto');
        Map<Id,Account> mapAccountsById = new Map<Id,Account> (allAccountsList);

        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setRecordType(new List<String> {'Customer'});
        List<Account> matchedRecords = accountsSelector.selectById( mapAccountsById.keySet() );
        Test.stopTest();

        System.assertEquals(10, matchedRecords.size(), 'El número de cuentas de Customer no es correcto');
    }

    /**
     * Test del método que recupera las cuentas filtradas por tipo de cuenta
     * @author aberuete
     * @date 06/06/2023
     */
    @IsTest
    static void test_setTypeOfAccount()
    {
        List<Account> allAccountsList = [Select id from Account];
        allAccountsList[0].Type = 'F';
        allAccountsList[1].Type = 'J';
        update allAccountsList;
        System.assertEquals(21, allAccountsList.size(), 'El número de cuentas totales no es correcto');
        Map<Id,Account> mapAccountsById = new Map<Id,Account> (allAccountsList);

        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setTypeOfAccount(new List<String> {'F','J'});
        List<Account> matchedRecords = accountsSelector.selectById( mapAccountsById.keySet() );
        Test.stopTest();

        System.assertEquals(2, matchedRecords.size(), 'El número de cuentas de tipo F y J no es correcto');
    }

    /**
     * Test del método que recupera las cuentas filtradas por un conjunto de ids de cuentas, record type name y tipo de cuenta
     * @author aberuete
     * @date 22/08/2023
     */
    @IsTest
    static void test_findByAccountIdsRecordTypeNameAndType()
    {
        Map<Id,Account> accountList = new Map<Id,Account>([Select id from Account]);
        List<Account> accountListCustomer = [Select id,RecordType.DeveloperName,Type from Account where RecordType.DeveloperName = 'Customer'];

        for (Account accountToUpdate : accountListCustomer)
        {
            accountToUpdate.Type = 'J';
        }
        update accountListCustomer;

        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findByAccountIdsRecordTypeNameAndType(new Set<Id>( accountList.keySet() ), new List<String> {'Customer'}, new List<String> {'F','J'});
        Test.stopTest();

        System.assertNotEquals(accountList.size(), accountListAfterQuery.size(), 'El número de cuentas no debería ser el mismo');
        System.assertEquals(10, accountListAfterQuery.size(), 'El número de cuentas de tipo customer debería ser 10');
    }

    /**
     * Test del método que recupera los intermediarios por su código
     * @author jfherrero
     * @date 13/09/2023
     */
    @IsTest
    static void test_findByINFOIntermediaryCode_ok()
    {
        List<Account> accountListIntermediary = [SELECT Id, ParentId, IntermediaryGroup__r.IntermediaryWithUser__c, INFOIntermediaryCode__c FROM Account
                                                 WHERE Account.INFOIntermediaryCode__c != null AND IntermediaryGroup__r.IntermediaryWithUser__c != null];

        List<String> intermediaryCodes = new List<String>();

        for (Account interm : accountListIntermediary)
        {
            intermediaryCodes.add(interm.INFOIntermediaryCode__c);
        }

        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findByINFOIntermediaryCode(intermediaryCodes);
        Test.stopTest();

        System.assertEquals(intermediaryCodes.size(), accountListAfterQuery.size(), 'El número de cuentas recuperadas no coincide');
    }

    /**
     * Test del método que recupera los intermediarios por su código. Contempla la ruta por la que la lista está vacía o nula
     * @author jfherrero
     * @date 13/09/2023
     */
    @IsTest
    static void test_findByINFOIntermediaryCode_null()
    {
        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findByINFOIntermediaryCode( new List<String>() );
        Test.stopTest();

        System.assertEquals(0, accountListAfterQuery.size(), 'El número de cuentas recuperadas debería ser 0');
    }

    /**
     * Test del método que devuelve una Query con cuentas pasa borrar
     * @author jfherrero
     * @date 13/09/2023
     */
    @IsTest
    static void test_getAccountsToDelete()
    {
        String accToDelete = AccountsSelector.getAccountsToDelete();
    }

    @isTest
    static void test_findIntermediariesByNif_ok()
    {

        List<String> listaNIF = new List<String>();
        listaNIF.add(INTERMEDIARY_NIF);

        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findIntermediariesByNIF( listaNIF );
        Test.stopTest();

        System.assertEquals(1, accountListAfterQuery.size(), 'El número de cuentas ha de ser mayor de 0');

    }

    @isTest
    static void test_findIntermediariesByNif_ko()
    {

        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findIntermediariesByNIF( new List<String>() );
        Test.stopTest();

        System.assertEquals(0, accountListAfterQuery.size(), 'El número de cuentas recuperadas debería ser 0');

    }

    @isTest
    static void test_findByNationalIdAndPhoneNumber_ok()
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


        ID idBuscado = null;
        for (Id elementos : recordIds)
        {
            idBuscado = elementos;
            break;
        }

        List<Account> cuenta = [SELECT Id, NationalID__c FROM Account WHERE Id = : idBuscado];
        List<String> dnis = new List<String>();
        dnis.add(cuenta[0].NationalId__c);

        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByNationalIdAndPhoneNumber(dnis, '', telephoneNumberToSearch);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');
    }

    @isTest
    static void test_findByNAtionalIdAndPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(RecordsSelector.Scope.ALL);
        List<Account> matchedRecords = accountsSelector.findByNationalIdAndPhoneNumber( new List<String>(), '', new List<String>() );

        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), NEMP_TEXT_MSG);
    }

    @isTest
    static void test_findIntermediaryGroupByIntermediaryGroupCodes()
    {
        List<Account> agrupacionesData = new List<Account>([SELECT Id, INFOIntermediaryGroupCode__c FROM Account WHERE RecordTypeId = :AccountsSelector.RT_NAME_AGRUPATION AND INFOIntermediaryGroupCode__c != NULL]);
        Set<String> groupCodes = new Set<String>();

        for (Account acc: agrupacionesData) {
            groupCodes.add(acc.INFOIntermediaryGroupCode__c);
        }

        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findIntermediaryGroupByIntermediaryGroupCodes(groupCodes);
        Test.stopTest();

        System.assertEquals(agrupacionesData.size(), accountListAfterQuery.size(), 'El número de cuentas recuperadas debería ser el mismo');

    }

    @isTest
    static void test_findIntermediaryGroupByIntermediaries()
    {
        
        Test.startTest();
        List<Account> accountListAfterQuery = new AccountsSelector().findIntermediaryGroupByIntermediaries(new Set<String>());
        Test.stopTest();

        System.assertEquals(true, accountListAfterQuery != null, 'No puede ser nulo el resultado de la query');

    }
}