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
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos cuando el campo WebEmail está vacío
     **
     * @author rlopez
     * @date 11/12/2020
     */
    /*@isTest
       static void test_processFormData_empty_webEmail_ko()
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
        jsonInformation.put('webEmail', '');

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
            System.assertEquals(true, ex.getMessage().contains('WebEmail field is empty'), 'Error message should contain \'WebEmail field is empty\'');
        }
        Test.stopTest();
       }*/

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
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
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
        System.assertEquals(true, risks.isEmpty(), 'List should NOT be empty');

        //Comprobamos que no se ha generado póliza
        List<Policy__c> policies = new PoliciesSelector().selectByOpportunityName(offersIds);
        System.assertEquals(true, policies.isEmpty(), 'List should be empty');

        //Comprobamos que se ha generado un Contact Request
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest WHERE WhatId IN: offersIds];
        System.assertEquals(false, contactRequests.isEmpty(), 'List should NOT be empty');

        //Comprobamos que se ha generado un CampaignMember para el cliente en la campaña correspondiente
        List<Campaign> campaigns = new CampaignsSelector().selectByName(new Set<String> {'ZEO_App Submitted Leads'});
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> campaignMembers = new CampaignMembersSelector(
            new Set<String> {'Id'}
            ).selectByCampaignAndContact(campaigns.get(0).Id, new Set<Id> {createdAccount.get(0).PersonContactId});
        System.assertEquals(false, campaignMembers.isEmpty(), 'List should NOT be empty');
    }

    /**
     * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-03
     **
     * @author rlopez
     * @date 26/10/2020
     */
    @isTest
    static void test_offerNumber_alreadyExists_ko()
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

        BusinessInsuranceRaterService.processFormData(requestInformationObject);

        Test.startTest();
        try
        {
            BusinessInsuranceRaterService.processFormData(requestInformationObject);
        }
        catch (Exception ex)
        {
            System.assertEquals(true, ex.getMessage().contains('DUPLICATE_VALUE'), 'Error message should contain \'DUPLICATE_VALUE\'');
        }
        Test.stopTest();

        //Comprobamos que se ha generado 1 Contact Request
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest];
        System.assertEquals(1, contactRequests.size(), 'There should be just 1 Contact Request');
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

}