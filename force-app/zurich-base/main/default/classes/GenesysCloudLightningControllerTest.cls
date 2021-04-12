/**
 * Test for the class GenesysCloudLightningController
 * 
 * @author nts (agonzalezisasi)
 * @date 12/04/2021
 */
@isTest
public class GenesysCloudLightningControllerTest {
    /**
     * Test the method to check if a user is authorized
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_isAuthorized()
    {
        Test.startTest();
        Boolean isAuthorized = GenesysCloudLightningController.isAuthorized();
        Test.stopTest();

        System.assertEquals(true, isAuthorized, 'Should be authorized');
    }

    /**
     * Test the method that authorize a user
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_authorize()
    {
        Test.startTest();
        String authorize = GenesysCloudLightningController.authorize();
        Test.stopTest();

        System.assertEquals(false, String.isBlank(authorize), 'Should not be empty');
    }

    /**
     * A positive Test of a conference to a phone number
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_conferenceTo_ok()
    {
        Test.startTest();
        GenesysCloudLightningController.conferenceTo(toAddress, uuiData);
        Test.stopTest();

    }

    /**
     * A negative Test of a conference to a phone number
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_conferenceTo_ko()
    {
        String exceptionError;
        Test.startTest();
        try {
            GenesysCloudLightningController.conferenceTo(toAddress, uuiData);
        } catch(Exception ex ) {
            exceptionError = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(false, String.isBlank(exceptionError), 'There should be an exception');
    }
}
