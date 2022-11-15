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
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Product2> products = TestDataFactory.generateProducts(10);
        insert products;

        //Insertamos Campañas de Zurich Empresas
        List<Campaign> businessInsuranceCampaigns = TestDataFactory.generateCampaigns('001', 6);
        businessInsuranceCampaigns.get(0).Name = 'ZE_App Submitted Leads';
        businessInsuranceCampaigns.get(1).Name = 'ZE_Legit Leads';
        businessInsuranceCampaigns.get(2).Name = 'ZE_Quoted Leads';
        businessInsuranceCampaigns.get(3).Name = 'ZEO_App Submitted Leads';
        businessInsuranceCampaigns.get(4).Name = 'ZEO_Legit Leads';
        businessInsuranceCampaigns.get(5).Name = 'ZEO_Quoted Leads';
        insert businessInsuranceCampaigns;

        //Insertamos las colas de Genesys correspondientes
        List<purecloud__PureCloud_Queue__c> genesysCloudQueues = TestDataFactory.generateGenesysQueues(2);
        genesysCloudQueues.get(0).Name = 'Voz_ZurichEmpresas';
        genesysCloudQueues.get(1).Name = 'Voz_ZurichEmpresas_Orange';
        insert genesysCloudQueues;
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
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-04', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        //Comprobamos que se ha actualizado el Scope correctamente
        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {existingAccounts.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesByAccount)
        {
            scopeIds.add(scope.Id);
        }

        //Comprobamos que los ContactPoints se han creado/actualizado correctamente
        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailFromJSON);
        System.assertEquals(1, contactPointEmails.size(), 'There should be 1 Contact Point Email');
        System.assertEquals(true, contactPointEmails.get(0).IsPrimary, 'IsPrimary should be true');

        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, requestInformationObject.webPhone);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        //Comprobamos que se han generado las ofertas correctamente
        List<Opportunity> offersCreated = [SELECT Id, StageName FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        Set<Id> offersIds = new Set<Id>();
        for(Opportunity offer: offersCreated)
        {
            offersIds.add(offer.Id);
            System.assertEquals('App Submitted', offer.StageName, 'StageName should be App Submitted');
        }

        //Comprobamos que se han generado los objetos asegurados
        List<Asset> risks = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(false, risks.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), risks.size(), 'There should be the same insured objects than offers');

        //Comprobamos que no se ha generado póliza
        List<Policy__c> policies = new PoliciesSelector().selectByOpportunityName(offersIds);
        System.assertEquals(true, policies.isEmpty(), 'List should be empty');

        //Comprobamos que se ha generado un Contact Request
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest WHERE WhatId IN: offersIds];
        System.assertEquals(false, contactRequests.isEmpty(), 'List should NOT be empty');

        //Comprobamos que se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZE_App Submitted Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {existingAccounts.get(0).PersonContactId});
        System.assertEquals(false, campaignMembers.isEmpty(), 'List should NOT be empty');
    }

    /**
     * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-03
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_processFormData_CRM03_ok()
    {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-03', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Account> createdAccount = [SELECT Id, PersonContactId FROM Account WHERE FirstName =: requestInformationObject.accountInformation.firstName AND LastName =: requestInformationObject.accountInformation.lastName];
        System.assertEquals(false, createdAccount.isEmpty(), 'List should NOT be empty');

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {createdAccount.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, requestInformationObject.webPhone);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c, StageName FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        Set<Id> offersIds = new Set<Id>();
        for(Opportunity offer: offersCreated)
        {
            offersIds.add(offer.Id);
            System.assertEquals('App Submitted', offer.StageName, 'StageName should be App Submitted');
            System.assertEquals(true, productIds.contains(offer.ProductId__c), 'Set should contain product id');
        }

        //Comprobamos que no se han generado objetos asegurados
        List<Asset> risks = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(true, risks.isEmpty(), 'List should NOT be empty');

        //Comprobamos que no se ha generado póliza
        List<Policy__c> policies = new PoliciesSelector().selectByOpportunityName(offersIds);
        System.assertEquals(true, policies.isEmpty(), 'List should be empty');

        //Comprobamos que se ha generado un Contact Request
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest WHERE WhatId IN: offersIds];
        System.assertEquals(false, contactRequests.isEmpty(), 'List should NOT be empty');

        //Comprobamos que se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZE_App Submitted Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {createdAccount.get(0).PersonContactId});
        System.assertEquals(false, campaignMembers.isEmpty(), 'List should NOT be empty');
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
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
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
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, requestInformationObject.webPhone);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        for(Opportunity offer: offersCreated)
        {
            System.assertEquals(true, productIds.contains(offer.ProductId__c), 'Set should contain product id');
        }

        List<Asset> risksCreated = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(false, risksCreated.isEmpty(), 'List should NOT be empty');
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

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);

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
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, requestInformationObject.webPhone);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        for(Opportunity offer: offersCreated)
        {
            System.assertEquals(true, productIds.contains(offer.ProductId__c), 'Set should contain product id');
        }

        List<Asset> risksCreated = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(false, risksCreated.isEmpty(), 'List should NOT be empty');

        List<BusinessInsuranceRaterService.Offer> offersReceived = requestInformationObject.offers;
        Set<String> policyNumbers = new Set<String>();
        for(BusinessInsuranceRaterService.Offer offer: offersReceived)
        {
            if( String.isNotBlank(offer.policyNumber) )
            {
                policyNumbers.add(offer.policyNumber);
            }
        }

        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.InfoPolicyNumber__c, 
                Policy__c.OpportunityName__c
            }
        );
        List<Policy__c> policiesCreated = policiesSelector.selectByHolderAndNumber(existingAccounts.get(0).Id, policyNumbers);
        System.assertEquals(false, policiesCreated.isEmpty(), 'List should NOT be empty');

        for(Policy__c policy: policiesCreated)
        {
            System.assertEquals(true, policyNumbers.contains(policy.InfoPolicyNumber__c), 'Set should contain InfoPolicyNumber__c');
            System.assertEquals(true, String.isNotBlank(policy.OpportunityName__c), 'OpportunityName__c has been filled from Flow');
        }

        //Comprobamos que se ha creado la relación entre las pólizas y el manager
        List<Relationship__c> relationsCreated = [SELECT Id FROM Relationship__c WHERE PolicyId__c IN: policiesCreated];
        System.assertEquals(false, relationsCreated.isEmpty(), 'List should NOT be empty');

        //Comprobamos que en este paso no se ha generado un miembro de campaña
        List<CampaignMember> campaignMembers = [SELECT Id FROM CampaignMember WHERE ContactId =: existingAccounts.get(0).PersonContactId];
        System.assertEquals(true, campaignMembers.isEmpty(), 'List should be empty');
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

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-01', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        Map<String, Object> accountInformation = (Map<String, Object>) jsonInformation.get('accountInformation');
        accountInformation.remove('lastName');
        jsonInformation.put('accountInformation', accountInformation);

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
            System.assertEquals(true, ex.getMessage().contains('The following fields are missing'), 'Error message should contain \'The following fields are missing\'');
        }
        Test.stopTest();
    }

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos cuando llega un BusinessCode incorrecto
     **
     * @author rlopez
     * @date 11/12/2020
     */
    @isTest
    static void test_processFormData_invalid_businessCode_ko()
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

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-01', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, '11111111', existingProducts);

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
            System.assertEquals(true, ex.getMessage().contains('Invalid businessCode received'), 'Error message should contain \'Invalid businessCode received\'');
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
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON( 'CRM-02', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, new List<Product2>() );

        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Account> createdAccount = [SELECT Id, PersonContactId FROM Account WHERE FirstName =: requestInformationObject.accountInformation.firstName AND LastName =: requestInformationObject.accountInformation.lastName];
        System.assertEquals(false, createdAccount.isEmpty(), 'There should be a new Account');

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {createdAccount.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(true, String.isBlank(scopesByAccount.get(0).PrimaryPhone__c), 'Phone should be empty');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, requestInformationObject.webPhone);
        System.assertEquals(true, contactPointPhones.isEmpty(), 'There should be 1 Contact Point Phone');

        //Comprobamos que se crea el ContactRequest
        List<ContactRequest> contactRequestsCreated = [SELECT Id FROM ContactRequest WHERE WhoId =: createdAccount.get(0).PersonContactId];
        System.assertEquals(false, contactRequestsCreated.isEmpty(), 'List should not be empty');

        //Comprobamos que NO se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZE_Legit Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {createdAccount.get(0).PersonContactId});
        System.assertEquals(true, campaignMembers.isEmpty(), 'List should be empty');
    }

    /**
     * Método que comprueba que si no hay productos relacionados con la oferta no se genera el miembro de campaña
     **
     * @author rlopez
     * @date 29/12/2020
     */
    @isTest
    static void test_allEmptyProducts_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        //Modificamos el CommercialPC para que no encuentre los productos, no cree relación
        //producto-oferta y, por este motivo, no cree el miembro de campaña
        List<BusinessInsuranceRaterService.Offer> offersToCreate = requestInformationObject.offers;
        for(Integer i=0; i < offersToCreate.size(); i++)
        {
            offersToCreate.get(i).commercialPC = String.valueOf(i);
        }

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {existingAccounts.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        for(Opportunity offer: offersCreated)
        {
            System.assertEquals(true, String.isBlank(offer.ProductId__c), 'Relation should be empty');
        }

        List<Asset> risksCreated = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(false, risksCreated.isEmpty(), 'List should NOT be empty');

        //Comprobamos que se crea el ContactRequest
        List<ContactRequest> contactRequestsCreated = [SELECT Id FROM ContactRequest WHERE WhoId =: existingAccounts.get(0).PersonContactId];
        System.assertEquals(false, contactRequestsCreated.isEmpty(), 'List should not be empty');

        //Comprobamos que se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZE_Quoted Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {existingAccounts.get(0).PersonContactId});
        System.assertEquals(true, campaignMembers.isEmpty(), 'Products not found during execution, list should be empty');
    }

    /**
     * Método que si solo hay un producto, de varios, que tiene relación con la oferta
     * si se genera el miembro de campaña
     **
     * @author rlopez
     * @date 29/12/2020
     */
    @isTest
    static void test_oneEmptyProduct_ok()
    {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c, GenesysCloudQueueName__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZEO'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-03', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        //Modificamos el CommercialPC de un producto para que no cree relación
        //producto-oferta. Como son más de 1, sí creará el miembro de campaña
        List<BusinessInsuranceRaterService.Offer> offersToCreate = requestInformationObject.offers;
        System.assertEquals(false, offersToCreate.isEmpty(), 'List should NOT be empty');
        offersToCreate.get(0).commercialPC = '0';

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Account> createdAccount = [SELECT Id, PersonContactId FROM Account WHERE FirstName =: requestInformationObject.accountInformation.firstName AND LastName =: requestInformationObject.accountInformation.lastName];
        System.assertEquals(false, createdAccount.isEmpty(), 'List should NOT be empty');

        List<Scope__c> scopesByAccount = new ScopesSelector(
            new Set<String> {'Id', 'Scope__c', 'PrimaryEmail__c', 'PrimaryPhone__c'}
            ).selectByAccountId(new Set<Id> {createdAccount.get(0).Id});
        System.assertEquals(1, scopesByAccount.size(), 'There should be 1 scope for the customer');
        System.assertEquals(scopeSettingsList.get(0).Scope__c, scopesByAccount.get(0).Scope__c, 'Scope__c should be the same');
        System.assertEquals(emailFromJSON, scopesByAccount.get(0).PrimaryEmail__c, 'Email should be the same');
        System.assertEquals(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON, scopesByAccount.get(0).PrimaryPhone__c, 'Phone should be the same');

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
            ).selectByScopeIdAndTelephoneNumber(scopeIds, BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + phoneFromJSON);
        System.assertEquals(1, contactPointPhones.size(), 'There should be 1 Contact Point Phone');
        System.assertEquals(true, contactPointPhones.get(0).IsPrimary, 'IsPrimary should be true');

        List<Opportunity> offersCreated = [SELECT Id, ProductId__c, StageName FROM Opportunity];
        System.assertEquals(false, offersCreated.isEmpty(), 'List should NOT be empty');
        System.assertEquals(requestInformationObject.offers.size(), offersCreated.size(), 'There should be the same opportunities than offers');

        Set<Id> offersIds = new Set<Id>();
        for(Opportunity offer: offersCreated)
        {
            offersIds.add(offer.Id);
            System.assertEquals('App Submitted', offer.StageName, 'StageName should be App Submitted');
        }

        //Comprobamos que no se han generado objetos asegurados
        List<Asset> risks = [SELECT Id FROM Asset WHERE OfferId__c IN: offersCreated];
        System.assertEquals(true, risks.isEmpty(), 'List should be empty');

        //Comprobamos que no se ha generado póliza
        List<Policy__c> policies = new PoliciesSelector().selectByOpportunityName(offersIds);
        System.assertEquals(true, policies.isEmpty(), 'List should be empty');

        //Comprobamos que se ha generado un Contact Request
        List<ContactRequest> contactRequests = [SELECT Id, GenesysCloudQueueId__c FROM ContactRequest WHERE WhatId IN: offersIds];
        System.assertEquals(false, contactRequests.isEmpty(), 'List should NOT be empty');
        System.assertEquals(true, contactRequests.get(0).GenesysCloudQueueId__c != null, 'Genesys Cloud Queue relation is not empty');

        List<purecloud__PureCloud_Queue__c> genesysQueue = [SELECT Id, Name FROM purecloud__PureCloud_Queue__c WHERE Id =: contactRequests.get(0).GenesysCloudQueueId__c];
        System.assertEquals(false, genesysQueue.isEmpty(), 'List should NOT be empty');
        System.assertEquals(scopeSettingsList.get(0).GenesysCloudQueueName__c, genesysQueue.get(0).Name, 'Queue name is the same');

        //Comprobamos que se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZEO_App Submitted Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {createdAccount.get(0).PersonContactId});
        System.assertEquals(false, campaignMembers.isEmpty(), 'List should NOT be empty');
    }    

    /**
     * Método que comprueba si al pasar una fecha fuera del horario de atención
     * se genera el ContactRequest con la siguiente hora hábil
     **
     * @author rlopez
     * @date 13/01/2021
     */
    @isTest
    static void test_processFormData_CRM03_within_businessHours_ok()
    {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts)
        {
            productIds.add(product.Id);
        }

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-03', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);

        //Modificamos la fecha de bestTimeFrom para que sea una fecha no válida
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime notWithinDatetime = System.now();
        while(BusinessHours.isWithin(businessHoursList.get(0).Id, notWithinDatetime) )
        {
            notWithinDatetime = notWithinDatetime.addDays(1);
        }

        jsonInformation.put('bestTimeFrom', TestDataFactory.datetimeToISOString(notWithinDatetime) );

        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        List<Account> createdAccount = [SELECT Id, PersonContactId FROM Account WHERE FirstName =: requestInformationObject.accountInformation.firstName AND LastName =: requestInformationObject.accountInformation.lastName];
        System.assertEquals(false, createdAccount.isEmpty(), 'List should NOT be empty');

        //Comprobamos que se ha generado un Contact Request
        //con PreferredContactDatetime distinto al bestTimeFrom solicitado
        List<ContactRequest> contactRequests = [SELECT Id, PreferredContactDatetime__c FROM ContactRequest WHERE WhoId =: createdAccount.get(0).PersonContactId];
        System.assertEquals(false, contactRequests.isEmpty(), 'List should NOT be empty');
        System.assertEquals(true, contactRequests.get(0).PreferredContactDatetime__c != notWithinDatetime, 'Datetime are different');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, contactRequests.get(0).PreferredContactDatetime__c), 'Datetime is within ZE Business Hours');
    }

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

    /**
     * Método que comprueba que NO se recuperan correctamente los metadatos cuando se solicita un paso inexistente en el formulario
     */
    @isTest
    static void test_addPrefixToPhone_ok()
    {
        String phone = '666123456';

        Test.startTest();
        String phoneWithPrefix = BusinessInsuranceRaterService.addPrefixToPhone(phone);
        Test.stopTest();

        System.assertEquals(
            true,
            phoneWithPrefix.startsWith(BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX),
            'Phone should start with ' + BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX
            );
    }

    /**
     * Método que comprueba que NO se recuperan correctamente los metadatos cuando se solicita un paso inexistente en el formulario
     */
    @isTest
    static void test_addPrefixToPhone_already_specified_ok()
    {
        String phone = '+34666123456';

        Test.startTest();
        String phoneWithPrefix = BusinessInsuranceRaterService.addPrefixToPhone(phone);
        Test.stopTest();

        //Para comprobar que si el número de teléfono ya tiene prefijo, hacemos un split del teléfono
        //utilizando el prefijo y debería dividir el string en 2
        System.assertEquals(
            true,
            phoneWithPrefix.split('\\' + BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX).size() < 3,
            BusinessInsuranceRaterService.SPANISH_PHONE_PREFIX + ' should appear once'
            );
    }

    /**
     * Paso CRM-01. Desde el flow ZECreateLead no se quiere crear ContactRequest
     */
    @isTest
    static void test_processFormData_CRM01_FromFlowZECreateLead_ok()
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

        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-01', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        //Desde el Flow ZECreateLead no se quiere crear ContactRequest
        jsonInformation.put('doNotCreateCallback', true);

        Test.startTest();
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        //Comprobamos que se ha generado un Contact Request
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest];
        System.assertEquals(true, contactRequests.isEmpty(), 'Desde el Flow ZECreateLead no se quiere crear ContactRequest');
    }

    /**
     * CallMeBack. Al completarse la contratacion comprobamos que se cancela un callmeback previo
     */
    @isTest
    static void test_callmeback_complete_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        String managerEmailFromJSON = 'manager@fakeemail.com.invalid';
        String managerPhoneFromJSON = '987654321';

        // Account
        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        // Productos
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts) {
            productIds.add(product.Id);
        }

        // Configuracion Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        // Formulario (json) CRM-08
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );

        // Cambiamos el estado a Completado
        jsonInformation.put('status', 'Completado');

        //Modificamos Manager antes de procesar información
        Map<String, Object> managerInformation = (Map<String, Object>) jsonInformation.get('manager');
        managerInformation.put('email', managerEmailFromJSON);
        managerInformation.put('phone', managerPhoneFromJSON);

        BusinessInsuranceRaterService.Request requestInformationObject = 
            (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                JSON.serialize(jsonInformation),
                BusinessInsuranceRaterService.Request.class
            );

        // Creamos CallMeBack (ContactRequest) para que se cancelen
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(
            existingAccounts[0].PersonContactId, 1
        );
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;

        // Mock Genesys call
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponse(contactReqs[0].GenesysInteractionId__c);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();

        // Comprobamos que el callmeback (ContactRequest) se ha cancelado
        List<ContactRequest> foundContactReqs = [SELECT Id FROM ContactRequest WHERE Status = 'Cancelled'];
        System.assertEquals(1, foundContactReqs.size(), 'Deberia haber un ContactRequest cancelado');
    }

    /**
     * CallMeBack. Al completarse la contratacion comprobamos que falla al cancelar un callmeback previo
     */
    @isTest
    static void test_callmeback_complete_ko()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        String managerEmailFromJSON = 'manager@fakeemail.com.invalid';
        String managerPhoneFromJSON = '987654321';

        // Account
        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        // Productos
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts) {
            productIds.add(product.Id);
        }

        // Configuracion Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        // Formulario (json) CRM-08
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );

        // Cambiamos el estado a Completado
        jsonInformation.put('status', 'Completado');

        //Modificamos Manager antes de procesar información
        Map<String, Object> managerInformation = (Map<String, Object>) jsonInformation.get('manager');
        managerInformation.put('email', managerEmailFromJSON);
        managerInformation.put('phone', managerPhoneFromJSON);

        BusinessInsuranceRaterService.Request requestInformationObject = 
            (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                JSON.serialize(jsonInformation),
                BusinessInsuranceRaterService.Request.class
            );

        // Creamos CallMeBack (ContactRequest) para que se cancelen
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(
            existingAccounts[0].PersonContactId, 1
        );
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;

        // Mock Genesys call con resultado de error
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponseError(contactReqs[0].GenesysInteractionId__c);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();
        
        // Comprobamos que se ha generado un error
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'Deberia haber un Error Log');
    }

    /**
     * CallMeBack. Sin estar completado, comprobamos que si viene un estado mas prioritario en el formulario
     * que el callmeback actualmente programado, se cancela este ultimo y se crea uno nuevo
     */
    @isTest
    static void test_callmeback_priority()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        String managerEmailFromJSON = 'manager@fakeemail.com.invalid';
        String managerPhoneFromJSON = '987654321';

        // Account
        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        // Productos
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts) {
            productIds.add(product.Id);
        }

        // Configuracion Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        // Formulario (json) CRM-07
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );

        // Cambiamos el estado a Telefonico (de mas prioridad)
        jsonInformation.put('status', 'Telefonico');

        //Modificamos Manager antes de procesar información
        Map<String, Object> managerInformation = (Map<String, Object>) jsonInformation.get('manager');
        managerInformation.put('email', managerEmailFromJSON);
        managerInformation.put('phone', managerPhoneFromJSON);

        BusinessInsuranceRaterService.Request requestInformationObject = 
            (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                JSON.serialize(jsonInformation),
                BusinessInsuranceRaterService.Request.class
            );

        // Creamos CallMeBack (ContactRequest) con estado New (menos prioritario)
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(
            existingAccounts[0].PersonContactId, 1
        );
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;

        // Mock Genesys call con resultado de error
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponse(contactReqs[0].GenesysInteractionId__c);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();
        
        // Comprobamos que el callmeback (ContactRequest) se ha cancelado
        List<ContactRequest> foundContactReqs = [
            SELECT Id FROM ContactRequest WHERE Id = :contactReqs[0].Id AND Status = 'Cancelled'
        ];
        System.assertEquals(1, foundContactReqs.size(), 'Deberia haber un ContactRequest cancelado');
        // Comprobamos que hay un callmeback nuevo
        foundContactReqs = [SELECT Id FROM ContactRequest WHERE Id != :contactReqs[0].Id];
        System.assertEquals(1, foundContactReqs.size(), 'Deberia haber un ContactRequest adicional nuevo');
    }

    /**
     * CallMeBack. Sin estar completado, comprobamos que si viene un estado mas prioritario en el formulario
     * que el callmeback actualmente programado, se cancela este ultimo y se crea uno nuevo
     */
    @isTest
    static void test_callmeback_closerInTime()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        String managerEmailFromJSON = 'manager@fakeemail.com.invalid';
        String managerPhoneFromJSON = '987654321';

        // Account
        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        // Productos
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        Set<Id> productIds = new Set<Id>();
        for(Product2 product: existingProducts) {
            productIds.add(product.Id);
        }

        // Configuracion Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        // Formulario (json) CRM-07
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );

        // Ponemos el estado Abandono
        jsonInformation.put('status', 'Abandono');
        // Lo ponemos como mas cercano en el tiempo. 
        // fix: Se añaden 5 minutos para que si tarda, se tenga en cuenta en la query
        jsonInformation.put('bestTimeFrom', System.now().addMinutes(5));

        //Modificamos Manager antes de procesar información
        Map<String, Object> managerInformation = (Map<String, Object>) jsonInformation.get('manager');
        managerInformation.put('email', managerEmailFromJSON);
        managerInformation.put('phone', managerPhoneFromJSON);

        BusinessInsuranceRaterService.Request requestInformationObject = 
            (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                JSON.serialize(jsonInformation),
                BusinessInsuranceRaterService.Request.class
            );

        // Creamos CallMeBack (ContactRequest) con estado Abandoned y para dentro de 15 minutos
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(
            existingAccounts[0].PersonContactId, 1
        );
        contactReqs[0].Status = 'Abandoned';
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;

        // Mock Genesys call con resultado de error
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addCallbackCancelMockResponse(contactReqs[0].GenesysInteractionId__c);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        Test.stopTest();
        
        // Comprobamos que el callmeback (ContactRequest) se ha cancelado
        List<ContactRequest> foundContactReqs = [
            SELECT Id FROM ContactRequest WHERE Id = :contactReqs[0].Id AND Status = 'Cancelled'
        ];
        System.assertEquals(1, foundContactReqs.size(), 'Deberia haber un ContactRequest cancelado');
        // Comprobamos que hay un callmeback nuevo
        foundContactReqs = [SELECT Id FROM ContactRequest WHERE Id != :contactReqs[0].Id];
        System.assertEquals(1, foundContactReqs.size(), 'Deberia haber un ContactRequest adicional nuevo');
    }

    @isTest
    static void test_offer_update()
    {
        // Account
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        // Products
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        // Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        // CRM-04
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-04', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        
        Test.startTest();

        //CRM-04 -> CRM-05
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-05', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );        
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        //CRM-05 -> CRM-06
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-06', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );        
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        //CRM-06 -> CRM-07
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-07', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );        
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        //CRM-04 -> CRM-08
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );        
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        //CRM-08 -> CRM-08
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, existingProducts
        );
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );        
        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        Test.stopTest();

        // Comprobar que solo hay una oferta, con una poliza, un riesgo y una relacion
        List<Opportunity> offers = [
            SELECT Id, (SELECT id FROM Insured_Objects__r), (SELECT id FROM Policies__r)
            FROM Opportunity];
        System.assertEquals(1, offers.size(), 'There should only be 1 offer');
        System.assertEquals(1, offers[0].Insured_Objects__r.size(), 'There should only be 1 Insured Object');
        System.assertEquals(1, offers[0].Policies__r.size(), 'Theres should only be 1 Policy');
    }

    @isTest
    static void test_offer_delete()
    {
        // Account
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c, PersonContactId FROM Account WHERE NationalId__c != null AND RecordTypeId =: personAccountRecordTypeId];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');


        // Products
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];

        // Scope
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt WHERE Scope__c = 'ZE'
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        List<Opportunity> offerOther = TestDataFactory.generateOpportunitiesForEachAccount(
            new List<Account>{existingAccounts.get(0)}, 'ZE', 'Quoted', System.today().addDays(10), 1
        );
        offerOther[0].InfoQuoteNumber__c = '000000111';
        insert offerOther;

        // CRM-05 - se inserta una oferta
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-05', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );
        BusinessInsuranceRaterService.processFormData(requestInformationObject);
        
        Test.startTest();

        // CRM-06 - cambiamos para que la oferta tenga otro codigo y asi se borre la oferta 
        // anteriormente insertada
        jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON(
            'CRM-06', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, 
            scopeSettingsList.get(0).BusinessCode__c, existingProducts);
        requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            JSON.serialize(jsonInformation),
            BusinessInsuranceRaterService.Request.class
            );
        requestInformationObject.offers[0].quoteNumberINFO = '456789000';
        requestInformationObject.offers[0].policyNumber = '000000333';

        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        Test.stopTest();

        // Comprobamos que quedan 2 ofertas. 1 de otra cosa y otra del CRM-06. La del CRM-05 se elimina
        // por estar en la misma sesion pero ya no aparecer en el formulario
        List<Opportunity> offers = [
            SELECT Id, InfoQuoteNumber__c
            FROM Opportunity WHERE InfoQuoteNumber__c IN ('456789456','456789000','000000111')
            ORDER BY CreatedDate DESC];
        System.assertEquals(2, offers.size(), 'There should be 2 offers');
        System.assertEquals(
            requestInformationObject.offers[0].quoteNumberINFO, offers[0].InfoQuoteNumber__c, 
            'The quote number should be the new one');
        System.assertEquals(
                offerOther[0].InfoQuoteNumber__c, offers[1].InfoQuoteNumber__c, 
                'The quote number should be ' + offerOther[0].InfoQuoteNumber__c);
    }
}