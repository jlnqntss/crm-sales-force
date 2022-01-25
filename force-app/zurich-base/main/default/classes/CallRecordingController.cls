/**
 * Controller class for the LWC callRecordingButton
 * 
 * @author nts (agonzalezisasi) 
 * @date 12/04/2021
 */
public without sharing class CallRecordingController
{
    @testvisible
    public static List<AdminSetupParameter__mdt> testListRecordingPhoneNumber;

    @AuraEnabled
    public static String getRecordingPhoneNumber()
    {
        String genesysRecordingNumber = '';
        List<AdminSetupParameter__mdt> settings = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = 'GenesysRecordingNumber'];
        if( Test.isRunningTest() ) {
            settings = testListRecordingPhoneNumber;
        }
        if( settings != null && !settings.isEmpty() ) {
            genesysRecordingNumber = settings[0].Value__c;
        } else {
            ErrorLogUtil.commitError('warning', 'No se ha podido recuperar el número de teléfono de grabación de llamadas', 'CallRecordingController');
        }

        return genesysRecordingNumber;
    }
}