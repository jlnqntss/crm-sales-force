/**
 * Clases de test para BusinessInsuranceRaterService
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class BusinessInsuranceRaterServiceTest
{
    static final String REQUEST_URI = '/ze/v1/offers/';
    static final String INVALID_REQUEST_URI = '/ze/va/offers/';

    @TestSetup
    static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Product2> products = TestDataFactory.generateProducts(10);
        insert products;
        /*List<Scope__c> insertedScopes = [SELECT Id, AccountId__c, Scope__c, AccountId__r.Name FROM Scope__c WHERE Id IN: scopes];

           List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromScopes(insertedScopes, 10);
           insert contactPointEmails;*/
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-04
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM04_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-04', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {existingAccounts.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals('ZE', scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesByAccount)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailFromJSON);
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 Contact Point Email');
        System.assertEquals(true, contactPointEmails.get(0).IsPrimary, 'IsPrimary should be true');

        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id FROM Opportunity];
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-04
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM03_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-03', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Account> createdAccount = [SELECT Id FROM Account WHERE FirstName =: requestInformationObject.accountInformation.firstName AND LastName =: requestInformationObject.accountInformation.lastName];
        System.assertEquals(false, createdAccount.isEmpty(), 'List should NOT be empty');

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {createdAccount.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals('ZE', scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesByAccount)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailFromJSON);
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 Contact Point Email');
        System.assertEquals(true, contactPointEmails.get(0).IsPrimary, 'IsPrimary should be true');

        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c FROM Opportunity];
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        for(Opportunity offer: offersCreated)
        {
            System.assertEquals(true, productIds.contains(offer.ProductId__c), 'Set should contain product id');
        }
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-07
     **
     * @author rlopez
     * @date 01/12/2020
     */
    @isTest
    static void test_processFormData_CRM07_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {existingAccounts.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals('ZE', scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesByAccount)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailFromJSON);
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 Contact Point Email');
        System.assertEquals(true, contactPointEmails.get(0).IsPrimary, 'IsPrimary should be true');

        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id FROM Opportunity];
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-08
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM08_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        String managerEmailFromJSON = 'manager@fakeemail.com.invalid';
        String managerPhoneFromJSON = '987654321';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);

        //Modificamos Manager antes de procesar información
        Map<String, Object> managerInformation = (Map<String, Object>) jsonInformation.get('manager');
        managerInformation.put('email', managerEmailFromJSON);
        managerInformation.put('phone', managerPhoneFromJSON);

        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {existingAccounts.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals('ZE', scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesByAccount)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailFromJSON);
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 Contact Point Email');
        System.assertEquals(true, contactPointEmails.get(0).IsPrimary, 'IsPrimary should be true');

        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id FROM Opportunity];
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');
    }

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-01
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM01_ko()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-01', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);
        jsonInformation.remove('webEmail');

        Test.startTest();
        try
        {
            BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                JSON.serialize(jsonInformation),
                BusinessInsuranceRaterService.Request.class
                );
            BusinessInsuranceRaterService.processFormData(requestInformationObject);
        }
        catch (Exception ex)
        {
            System.debug( ex.getMessage() );
            System.debug( ex.getStackTraceString() );
            System.assertEquals(true, ex.getMessage().contains('The following fields are missing'), 'Error message should contain \'The following fields are missing\'');
        }
        Test.stopTest();
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-02
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM02_ok()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-02
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM02_ko()
    {}

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-03
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM01_ok()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-03
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM03_ko()
    {}

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-04
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM0_ok()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-04
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM04_ko()
    {}

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-05
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM05_ok()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-05
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM05_ko()
    {}

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-06
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM06_ok()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-06
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM06_ko()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-07
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM07_ko()
    {}

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-08
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM08_ko()
    {}

    /**
     * Método que comprueba que se recuperan correctamente los metadatos cuando se solicita un paso existente en el formulario
     */
    @isTest
    static void test_getRequiredFieldsFromMetadata_ok()
    {
        String validFormStep = 'CRM-01';

        Test.startTest();
        BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(validFormStep);
        Test.stopTest();

        System.assertEquals(
            false,
            BusinessInsuranceRaterService.stepMetadataList.isEmpty(),
            'The list shouldnt be empty'
            );
        System.assertEquals(
            false,
            BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
            'The set shouldnt be empty'
            );
    }

    /**
     * Método que comprueba que NO se recuperan correctamente los metadatos cuando se solicita un paso inexistente en el formulario
     */
    @isTest
    static void test_getRequiredFieldsFromMetadata_ko()
    {
        String validFormStep = 'CRM-AA';

        Test.startTest();
        BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(validFormStep);
        Test.stopTest();

        System.assertEquals(
            false,
            BusinessInsuranceRaterService.stepMetadataList.isEmpty(),
            'Metadata list shouldnt be empty, all fields are retrieved'
            );
        System.assertEquals(
            true,
            BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
            'The set should be empty, as the step doesnt exists'
            );
    }
}
