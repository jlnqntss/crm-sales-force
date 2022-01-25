/**
 *
 */
public with sharing class GenesysCloudLightningController
{
    private final static String GENESYS_CLOUD_NAMED_CREDENTIAL = 'GenesysCloud';

    @testvisible
    private static ExternalDataUserAuth testExternalDataUserAuth = null;

    /**
     * Verifica si el usuario está autorizado en la Named Credential de usuario de Genesys Cloud
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    @AuraEnabled
    public static Boolean isAuthorized()
    {
        List<ExternalDataUserAuth> userAuths = [SELECT Id FROM ExternalDataUserAuth WHERE ExternalDataSourceId IN (SELECT Id FROM NamedCredential WHERE DeveloperName = :GENESYS_CLOUD_NAMED_CREDENTIAL)  AND UserId = :UserInfo.getUserId()];

        if( Test.isRunningTest() ) {
            userAuths.add(testExternalDataUserAuth);
        }

        return !userAuths.isEmpty();
    }

    /**
     * Verifica si el usuario está autorizado en la Named Credential de usuario de Genesys Cloud
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    @AuraEnabled
    public static String authorize()
    {

        List<ExternalDataUserAuth> userAuths = [SELECT Id FROM ExternalDataUserAuth WHERE ExternalDataSourceId IN (SELECT Id FROM NamedCredential WHERE DeveloperName = :GENESYS_CLOUD_NAMED_CREDENTIAL)  AND UserId = :UserInfo.getUserId()];

        if(userAuths.isEmpty() )
        {
            return '/' + ExternalDataUserAuth.getSObjectType().getDescribe().getKeyPrefix() + '/e';
        }

        return '/services/auth/xds/GenesysCloud?scope=openid&startURL=%2F' + userAuths[0].Id.to15();
    }

    /**
     * @description Conferencia la llamada en curso del usuario en Genesys Cloud a número identificado
     * @author jmartinezpisson
     * @date 31/03/2021
     * @param  toAddress Número de teléfono destino al que conferenciar
     * @param attributesByName Mapa clave-valor de los atributos a transferir al conferenciado.
     * @param  fallbackToUUI Envía los atributos a través del UUI como valores separados por pipe.
     */
    @AuraEnabled
    public static void conferenceTo(String toAddress, Map<String,String> attributesByName, Boolean fallbackToUUI)
    {
        try
        {
            GenesysCloud.CallsService.conferenceTo(toAddress, attributesByName, fallbackToUUI);
        }
        catch(Exception error)
        {
            throw new AuraHandledException(error.getMessage() );
        }
    }

    /**
     * @description Obtiene las llamadas activas para el usuario logado en Genesys
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    @AuraEnabled
    public static GenesysCloud.Call[] getActiveCalls()
    {
        try
        {
            return GenesysCloud.CallsService.getActive();
        }
        catch(Exception error)
        {
            throw new AuraHandledException(error.getMessage() );
        }
    }

    // #region Funciones para la grabación contractual

    /**
     * @description Iniciar la grabación contractual. Se incluye al participante que realizará la grabación en la llamada.
     * @author rpolvera@nts-solutions.com
     * @date 19/10/2021
     */
    @AuraEnabled
    public static void startRecording(String conversationId)
    {
        try
        {
            GenesysCloud.CallRecorderService.start(conversationId);
        }
        catch(Exception error)
        {
            throw new AuraHandledException(error.getMessage() );
        }
    }

    /**
     * @description Detener la grabación contractual. Se al participante que realizará la grabación de la llamada.
     * @author rpolvera@nts-solutions.com
     * @date 19/10/2021
     */
    @AuraEnabled
    public static void stopRecording(String conversationId)
    {
        try
        {
            GenesysCloud.CallRecorderService.end(conversationId);
        }
        catch(Exception error)
        {
            throw new AuraHandledException(error.getMessage() );
        }
    }
    // #endregion

       /**
     * Cancela un CallBack de Genesys Cloud
     * @author jjuaristi
     * @date 28/10/2021
     */
    @AuraEnabled
    public static GenesysCloud.CallbackCancel cancelCallBack(String interactionID, String contactRequestId)
    {
        GenesysCloud.CallbackCancel callback = new GenesysCloud.CallbackCancel();
         // Creamos la cancelacion del CallMeBack poniendo el id de genesys
         callback.genesysId = interactionID;
 
         // Solicitamos la cancelacion del CallMeBack a Genesys
         return GenesysCloud.CallbacksService.cancel(callback);

    }
}       

