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
        CallRecordingController.testListRecordingPhoneNumber = new List<AdminSetupParameter__mdt> {
            new AdminSetupParameter__mdt(
                Label='TestMetadataRecordingNumber',
                DeveloperName='TestMetadataRecordingNumber',
                KeyName__c='TestMetadataRecordingNumber',
                Value__c='+34999999999',
                Description__c='TestDescription'
                )
        };

        Test.startTest();
        String recordingPhoneNumberResult = CallRecordingController.getRecordingPhoneNumber();
        Test.stopTest();

        System.assertEquals(CallRecordingController.testListRecordingPhoneNumber.get(0).Value__c, recordingPhoneNumberResult, 'The phone number should be the same');
    }

    /**
     * Test the error if the recording phone number is not configured
     * 
     * @author nts (agonzalezisasi)
     * @date 12/04/2021
     */
    @isTest
    static void test_getRecordingPhoneNumber_ko()
    {
        CallRecordingController.testListRecordingPhoneNumber = new List<AdminSetupParameter__mdt>();

        Test.startTest();
        String recordingPhoneNumberResult = CallRecordingController.getRecordingPhoneNumber();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'There should be 1 error log');
    }
}