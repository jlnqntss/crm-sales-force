/**
 * Test the methods in the PreferenceCentreZController class
 * 
 * This class started as a copy of the class Test_PreferenceCentreController developer for Klinc
 * 
 * @author nts (agonzalezisasi)
 * @date 09-16-2020
 * 
 */
@isTest
public class Test_PreferenceCentreZEController
{
    /**
     * Test the update of the scope when the user opted out of email
     * 
     * @author nts (agonzalezisasi)
     * @date 17/12/2020
     */
    @isTest
    static void test_processRequest_ok()
    {
        String hashid = '123456';

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);
        insert accounts;
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        scopes[0].HashedId__c = hashid;
        insert scopes;

        test.startTest();
        PreferenceCentreZEController.processRequest(hashid, true);
        test.stopTest();

        
        scopes = [SELECT Id, HasOptedOutOfEmail__c FROM Scope__c WHERE HashedId__c = :hashid];
        System.assertNotEquals(true, scopes.isEmpty(), 'There should be 1 scope');
        System.assertEquals(true, scopes[0].HasOptedOutOfEmail__c, 'The Opted Out of Email should be true');
    }

    /**
     * Test the update of the scope when the user opted out of email
     * 
     * @author nts (agonzalezisasi)
     * @date 17/12/2020
     */
    @isTest
    static void test_processRequest_ko()
    {
        test.startTest();
        PreferenceCentreZEController.processRequest('', true);
        test.stopTest();
    }

    /**
     * Test the labels json for the lwc page
     * 
     * @author nts (agonzalezisasi)
     * @date 17/12/2020
     */
    @isTest
    static void test_getLabels()
    {
        Test.startTest();
        String labels = PreferenceCentreZEController.getLabels();
        Test.stopTest();

        System.assertNotEquals(null, labels, 'The labels should not be null');
        System.assertNotEquals('', labels, 'The labels should not be empty');
    }

    /**
     * Test the getLogoUrl for an Scope. No assert is included to avoid errors in the class
     * if there are no logos in the static resources
     * 
     * @author nts (agonzalezisasi)
     * @date 03/02/2021
     */
    @isTest
    static void test_getLogoUrl()
    {
        string resource_url = null;
        Test.startTest();
        resource_url = PreferenceCentreZEController.getLogoUrl('ZE');
        Test.stopTest();

        // not checking the assert to avoid errors if the static resources dont exist
        //System.assertNotEquals(null, resource_url, 'The resource url should not be null');
        //System.assertEquals(true, resource_url.contains(PreferenceCentreController.ZURICH_LOGO_RESOURCE));
    }
}