@isTest
public class SendSurveyButtonControllerTest
{
    @isTest
    static void test_getTransferPollPhoneNumber_ok()
    {
        SendSurveyButtonController.testListPollPhoneNumber = new List<AdminSetupParameter__mdt> {
            new AdminSetupParameter__mdt(
                Label='TestMetadataPollNumber',
                DeveloperName='TestMetadataPollNumber',
                KeyName__c='TestMetadataPollNumber',
                Value__c='+34999999999',
                Description__c='TestDescription'
                )
        };

        Test.startTest();
        String pollPhoneNumberResult = SendSurveyButtonController.getTransferPollPhoneNumber();
        Test.stopTest();

        System.assertEquals(SendSurveyButtonController.testListPollPhoneNumber.get(0).Value__c, pollPhoneNumberResult, 'PhoneNumber is the same');
    }
}