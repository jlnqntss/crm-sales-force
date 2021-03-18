public without sharing class SendSurveyButtonController
{
    @testvisible
    public static List<AdminSetupParameter__mdt> testListPollPhoneNumber;

    @AuraEnabled
    public static String getTransferPollPhoneNumber()
    {
        String genesysPollNumber = '';
        List<AdminSetupParameter__mdt> settings = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = 'GenesysPollPhoneNumber'];
        if( Test.isRunningTest() )
        {
            if( testListPollPhoneNumber != null )
            {
                settings = testListPollPhoneNumber;
            }
        }
        if( settings != null && !settings.isEmpty() )
        {
            genesysPollNumber = settings[0].Value__c;
        }
        else
        {
            ErrorLogUtil.commitError('warning', 'No se ha podido recuperar el número de teléfono de transferencia de encuestas', 'SendSurveyButtonController');
        }

        return genesysPollNumber;
    }

    public class SendSurveyButtonControllerException extends Exception
    {}
}