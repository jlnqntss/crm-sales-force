@IsTest
public with sharing class RelatedAccountsSelectorTest {
    @IsTest
    static void test_findRelatedAccountsByIdentifier_OK()
    {
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

        List<RelatedAccount__c> retrievedRelations = new RelatedAccountsSelector().findRelatedAccountsByIdentifier('1122334455');
        system.assertEquals(warnings.size(), retrievedRelations.size());
    }
}