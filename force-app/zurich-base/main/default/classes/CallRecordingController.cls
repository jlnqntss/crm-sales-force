/**
 * Controller class for the LWC callRecordingButton
 * 
 * @author nts (agonzalezisasi) 
 * @date 12/04/2021
 */
public with sharing class CallRecordingController
{
    @testvisible
    public static AdminSetupParameter__mdt testListRecordingPhoneNumber;

    @AuraEnabled
    public static String getRecordingPhoneNumber()
    {
        String genesysRecordingNumber = '';
        AdminSetupParameter__mdt settings = AdminSetupParameter__mdt.getInstance('GenesysRecordingNumber');
        if( Test.isRunningTest() ) {
            settings = testListRecordingPhoneNumber;
        }
        if( settings != null ) {
            genesysRecordingNumber = settings.Value__c;
        } else {
            ErrorLogUtil.commitError('warning', 'No se ha podido recuperar el número de teléfono de grabación de llamadas', 'CallRecordingController');
        }

        return genesysRecordingNumber;
    }
}