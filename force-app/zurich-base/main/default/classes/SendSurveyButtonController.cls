public without sharing class SendSurveyButtonController
{
    @testvisible
    public static AdminSetupParameter__mdt testListPollPhoneNumber;

    @AuraEnabled
    public static String getTransferPollPhoneNumber()
    {
        String genesysPollNumber = '';
        AdminSetupParameter__mdt settings = AdminSetupParameter__mdt.getInstance('GenesysPollPhoneNumber');
        if( Test.isRunningTest() )
        {
            if( testListPollPhoneNumber.Value__c != null )
            {
                settings = testListPollPhoneNumber;
            }
        }
        if( settings.Value__c != null )
        {
            genesysPollNumber = settings.Value__c;
        }
        else
        {
            ErrorLogUtil.commitError('warning', 'No se ha podido recuperar el número de teléfono de transferencia de encuestas', 'SendSurveyButtonController');
        }

        return genesysPollNumber;
    }

    public class SendSurveyButtonControllerException extends Exception
    {}

    /**
     * 
     * @author jgarciamartinez@nts-solutions.com
     * @date 29/03/2022
     * se crea un método con auraenabled para traernos
     * todas las queries que hemos solicitado con el selector
     */
    @AuraEnabled(cacheable=true)
    public static List<purecloud__PureCloud_Queue__c> getGenesysCloudQueues()
    {
        try 
        {
            return new GenesysQueueSelector().getAllQueues();
        }
        catch (Exception e) 
        {
            throw new AuraException(e.getMessage() + ': No se han recuperado las colas de la BBDD.');
        }      
    }
}