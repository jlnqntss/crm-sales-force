@isTest
public class SendSurveyButtonControllerTest
{
    @isTest
    static void test_getTransferPollPhoneNumber_ok()
    {
        List<PermissionSetAssignment> usuarios = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Consulta_Datos'];
        User u = [Select Id FROM User WHERE Id = :usuarios.get(0).AssigneeId];
        SendSurveyButtonController.testListPollPhoneNumber = 
            new AdminSetupParameter__mdt(
                Label='TestMetadataPollNumber',
                DeveloperName='TestMetadataPollNumber',
                KeyName__c='TestMetadataPollNumber',
                Value__c='+34999999999',
                Description__c='TestDescription'
            );
        System.runAs(u)
        {
            Test.startTest();
            String pollPhoneNumberResult = SendSurveyButtonController.getTransferPollPhoneNumber();
            Test.stopTest();            
        }

        System.assertEquals(SendSurveyButtonController.testListPollPhoneNumber.Value__c, pollPhoneNumberResult, 'PhoneNumber is the same');
    }
    
    @TestSetup
        static void makeData()
        {
            List<purecloud__PureCloud_Queue__c> testingGenesysQueues = TestDataFactory.generateGenesysQueues(5);
            testingGenesysQueues[1].IsSurveyable__c = true;
            insert testingGenesysQueues;
        }

    @IsTest
    static void test_getAllQueues_ok()
    {
        List<purecloud__PureCloud_Queue__c> totalQueues = [SELECT Id, Name, IsSurveyable__c FROM purecloud__PureCloud_Queue__c];
    
        Test.startTest();
        List<purecloud__PureCloud_Queue__c> selectedQueues = SendSurveyButtonController.getGenesysCloudQueues();
        Test.stopTest();
    
        System.assertEquals(totalQueues.size(), selectedQueues.size(), 'No hay las colas esperadas');

    }
}