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
        GenesysCloudLightningController.testExternalDataUserAuth = new ExternalDataUserAuth();

        Test.startTest();
        Boolean isAuthorized = GenesysCloudLightningController.isAuthorized();
        Test.stopTest();

        System.assertEquals(false, isAuthorized, 'Should be authorized');
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
        String toAddress = '+349999999';
        String conversationId = '9d720887-910f-402d-b102-946c2c273992';
        Map<String, String> attributes = new Map<String, String>{
            'parentConversationId' => conversationId
        };

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addActiveConversationsMockResponse(conversationId);
        responsesMock.addParticipantMockResponse(conversationId);
        responsesMock.addUUIDMockResponse();
        responsesMock.addConsultMockResponse();
        Test.setMock(HttpCalloutMock.class, responsesMock);
        

        Test.startTest();
        GenesysCloudLightningController.conferenceTo(toAddress, attributes, true);
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
        String toAddress = '+349999999';
        String conversationId = '9d720887-910f-402d-b102-946c2c273992';
        Map<String, String> attributes = new Map<String, String>{
            'parentConversationId' => conversationId
        };
        
        String exceptionError;
        Test.startTest();
        try {
            GenesysCloudLightningController.conferenceTo(toAddress, attributes, true);
        } catch(Exception ex ) {
            exceptionError = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(false, String.isBlank(exceptionError), 'There should be an exception');
    }

    /**
     * A positive Test of a conference to a phone number
     * 
     * @author nts (agonzalezisasi) 
     * @date 12/04/2021
     */
    @isTest
    static void test_getActiveCalls_ok()
    {
        String conversationId = '9d720887-910f-402d-b102-946c2c273992';

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addActiveConversationsMockResponse(conversationId);
        Test.setMock(HttpCalloutMock.class, responsesMock);

        Test.startTest();
        GenesysCloud.Call[] activeCalls = GenesysCloudLightningController.getActiveCalls();
        Test.stopTest();

        // Then
        System.assertEquals(1, activeCalls.size(), 'No se han devuelto llamadas');
        System.assertEquals(conversationId, activeCalls[0].id, 'No se han devuelto llamadas');
    }

    /**
     * A negative Test of a conference to a phone number
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_getActiveCalls_ko()
    {
        String conversationId = '9d720887-910f-402d-b102-946c2c273992';

        // Mock
        GenesysCloudConversationsAPIMock responsesMock = new GenesysCloudConversationsAPIMock();
        responsesMock.addRawMockResponse(
            'api/v2/conversations/calls',
            new GenesysCloudConversationsAPIMock.APIResponse(
                404,
                new Map<String, Object> {
                    'message' => 'Not Found'
                }
            )
        );
        Test.setMock(HttpCalloutMock.class, responsesMock);

        String exceptionError;

        Test.startTest();
        try {
            GenesysCloud.Call[] activeCalls = GenesysCloudLightningController.getActiveCalls();
        } catch(Exception ex ) {
            exceptionError = ex.getMessage();
        }
        Test.stopTest();

        // Then
        System.assertNotEquals(null, exceptionError, 'There should be an exception');
    }
}
