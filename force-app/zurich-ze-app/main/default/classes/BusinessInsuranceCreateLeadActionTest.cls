@isTest
public class BusinessInsuranceCreateLeadActionTest
{
    @isTest
    static void test_businessInsuranceCreateLeadAction_createLead_ok()
    {
        String businessCode = '3200012491';

        //Preparamos la Request
        List<BusinessInsuranceCreateLeadAction.CreateLeadActionRequest> requests = new List<BusinessInsuranceCreateLeadAction.CreateLeadActionRequest>();
        BusinessInsuranceCreateLeadAction.CreateLeadActionRequest leadInformation = new BusinessInsuranceCreateLeadAction.CreateLeadActionRequest();
        leadInformation.email = 'fakeemail@fakecompany.com.invalid';
        leadInformation.phone = '+34123123123';
        leadInformation.firstName = 'test first name';
        leadInformation.lastName = 'test last name';
        leadInformation.commercialActivity = '101100';
        leadInformation.nationalIdentifier = '12345678U';
        leadInformation.scopeBusinessCode = businessCode;

        requests.add(leadInformation);

        Test.startTest();
        BusinessInsuranceCreateLeadAction.createLead(requests);
        Test.stopTest();

        // Comprobamos que se ha generado correctamente toda la información
        AccountSearchService.Scope accSearchServiceScope = new AccountSearchService.Scope();
        accSearchServiceScope.scope = AccountSearchService.SCOPE_CODE_ZE;
        List<Account> createdLeads = AccountSearchService.findCustomersByDocumentId(new List<String>{leadInformation.nationalIdentifier}, 'N', accSearchServiceScope, '001');
        System.assertEquals(false, createdLeads.isEmpty(), 'List should NOT be empty');

        List<Scope__c> createdScopes = new ScopesSelector().selectByAccountIdAndScope(new Set<Id>{createdLeads.get(0).Id}, AccountSearchService.SCOPE_CODE_ZE);
        System.assertEquals(false, createdScopes.isEmpty(), 'List should NOT be empty');

        List<ContactPointEmail> createdContactPointEmails = new ContactPointEmailsSelector().selectByScopeIdAndEmailAddress(new Set<Id>{createdScopes.get(0).Id}, leadInformation.email);
        System.assertEquals(false, createdContactPointEmails.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> createdContactPointPhones = new ContactPointPhonesSelector().selectByScopeIdAndTelephoneNumber(new Set<Id>{createdScopes.get(0).Id}, leadInformation.phone);
        System.assertEquals(false, createdContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactRequest> createdContactRequests = [SELECT Id FROM ContactRequest];
        System.assertEquals(true, createdContactRequests.isEmpty(), 'Desde el Flow de ZECreateLEad no se quiere crear Contact Request');
    }
}