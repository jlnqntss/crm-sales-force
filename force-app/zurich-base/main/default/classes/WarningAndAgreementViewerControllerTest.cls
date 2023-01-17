@IsTest
public with sharing class WarningAndAgreementViewerControllerTest {

    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Intermediary', 1);
        for(Account record : accounts){
            record.INFOIntermediaryCode__c = '1122334455';
            record.TerritorialDirection__c =  'DT Madrid';
        }
        insert accounts;

        List<CustomerWarning__c> warnings = new List<CustomerWarning__c>();
        CustomerWarning__c warning = new CustomerWarning__c();
        warning.StartDate__c = System.today();
        warning.Description__c = 'Descripción';
        warnings.add(warning);
        insert(warnings);

        RelatedAccount__c relation = new RelatedAccount__c();
        relation.Warning__c = warning.Id;
        relation.Identifier__c = '1122334455';
        insert(relation); 
        
        List<Special_Condition__c> agreements = new List<Special_Condition__c>();
        Special_Condition__c agreement = new Special_Condition__c();
        agreement.TerritorialDirection__c =  'DT Madrid';
        agreement.Type__c = 'Agreement';
        agreements.add(agreement);
        insert(agreements);
    }

    @IsTest
    static void test_getFields_OK()
    {
        List<WarningAndAgreementViewerController.Field> fields = WarningAndAgreementViewerController.getFields('CustomerWarning__c');

        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get('CustomerWarning__c');
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get('RelatedListFields');
        List<Schema.FieldSetMember> fieldList=  fieldSetObj.getFields(); 

        System.assertEquals(fields.size(), fieldList.size());
    }

    // List<CustomerWarning__c> getWarnings(Account record, String salesforceObject, String recordType)
    @IsTest
    static void test_getWarnings_OK()
    {
        Account account = [SELECT Id, INFOIntermediaryCode__c FROM Account LIMIT 1];
        List<CustomerWarning__c> warnings = WarningAndAgreementViewerController.getWarnings(account, 'CustomerWarning__c', 'Intermediary');

        System.assertEquals(1, warnings.size());
    }

    @IsTest
    static void test_getAgreements_OK()
    {
        Account account = [SELECT Id, INFOIntermediaryCode__c, TerritorialDirection__c FROM Account LIMIT 1];
        List<Special_Condition__c> agreements = WarningAndAgreementViewerController.getAgreements(account, 'Special_Condition__c');

        System.assertEquals(1, agreements.size());
    }

    @IsTest
    static void test_cancelWarnings_OK()
    {
        List<CustomerWarning__c> warnings = [SELECT Id, IsActive__c, EndDate__c FROM CustomerWarning__c];
        WarningAndAgreementViewerController.cancelWarnings(warnings);

        List<CustomerWarning__c> updatedWarnings = [SELECT Id, IsActive__c FROM CustomerWarning__c];
        for(CustomerWarning__c warning : updatedWarnings)
        {
            System.assertEquals(false, warning.IsActive__c);
        }
    }

    @IsTest
    static void test_cancelAgreements_OK()
    {
        List<Special_Condition__c> agreements = [SELECT Id, IsActive__c FROM Special_Condition__c];
        WarningAndAgreementViewerController.cancelAgreements(agreements);

        List<Special_Condition__c> updatedAgreements = [SELECT Id, IsActive__c FROM Special_Condition__c];
        for(Special_Condition__c agreement : updatedAgreements)
        {
            System.assertEquals(false, agreement.IsActive__c);
        }
    }

    @IsTest
    static void test_createRelatedAccount_OK()
    {
        Account account = [SELECT Id, INFOIntermediaryCode__c, TerritorialDirection__c FROM Account LIMIT 1];
        CustomerWarning__c warning = [SELECT Id, IsActive__c, EndDate__c, WarningNumber__c FROM CustomerWarning__c LIMIT 1];

        WarningAndAgreementViewerController.createRelatedAccount(account, warning.WarningNumber__c, 'Intermediary');
        List<RelatedAccount__c> relations = [SELECT Id FROM RelatedAccount__c];
        System.assertEquals(2, relations.size());
    }
}