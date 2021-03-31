/**
 *
 */
public with sharing class GenesysCloudLightningController
{
    private final static String GENESYS_CLOUD_NAMED_CREDENTIAL = 'GenesysCloud';
    /**
     * Verifica si el usuario está autorizado en la Named Credential de usuario de Genesys Cloud
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    @AuraEnabled
    public static Boolean isAuthorized()
    {
        List<ExternalDataUserAuth> userAuths = [SELECT Id FROM ExternalDataUserAuth WHERE ExternalDataSourceId IN (SELECT Id FROM NamedCredential WHERE DeveloperName = :GENESYS_CLOUD_NAMED_CREDENTIAL)  AND UserId = :UserInfo.getUserId()];

        return userAuths.isEmpty();
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
     * @param  uuiData   Texto a enviar como datos de la llamada. Viajarán como UUI y como la clave uuiData dentro del Participant de Genesys Cloud
     */
    @AuraEnabled
    public static void conferenceTo(String toAddress, String uuiData)
    {
        try
        {
            GenesysCloud.CallsService.conferenceTo(toAddress, uuiData);
        }
        catch(Exception error)
        {
            throw new AuraHandledException(error.getMessage() );
        }
    }
}
