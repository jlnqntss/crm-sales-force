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