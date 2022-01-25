/**
 * Test for the class CallRecordingController
 * 
 * @author nts (agonzalezisasi)
 * @date 12/04/2021
 */
@isTest
public class CallRecordingControllerTest
{
    /**
     * Test the recovering of the recording number from the configuration
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_getRecordingPhoneNumber_ok()
    {
        Test.startTest();
        String recordingPhoneResult = CallRecordingController.getRecordingPhoneNumber();
        Test.stopTest();

        System.assertNotEquals(null, recordingPhoneResult, 'No se ha configurado un teléfono para las grabaciones');  
    }
}