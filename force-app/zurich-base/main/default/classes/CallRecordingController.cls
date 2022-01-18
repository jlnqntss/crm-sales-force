/**
 * Controller class for the LWC callRecordingButton
 * 
 * @author nts (agonzalezisasi) 
 * @date 12/04/2021
 */
public with sharing class CallRecordingController
{
    public static final String GENESYS_RECORDING_NUMBER = 'GenesysRecordingNumber';

    /**
     * Método que recupera el metadato con el teléfono de las grabaciones de genesys
     * 
     * @author nts (jjuaristi)
     * @date 13/10/2021
     */
    @AuraEnabled
    public static String getRecordingPhoneNumber()
    {
        return AdminSetupParameter__mdt.getInstance(GENESYS_RECORDING_NUMBER)?.Value__c;
    }
}