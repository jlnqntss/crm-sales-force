
/**
 * Clase controladora del LWC ZRMRecibos
 *
 * @author fpalomo
 * @date 13/06/2024
 */
public with sharing class ZRMRecibosContadorTotalesController
{
    @AuraEnabled
    public static Integer getData()
    {
        String errorMessage;

        try {
            // Invocar servicio web
            GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response = (new WS_GetReturnedReceiptsCount()).callWebService();

            // Obtener los datos de la respuesta y devolver resultado
            if (response == null)
            {
                errorMessage = System.Label.ZRM_Recibos_WS_Error;
                throw new HandledException(errorMessage);
            }

            return response.numeroRecibosDevueltos;

        } catch (Exception e) {
            errorMessage = String.isNotEmpty(errorMessage) ? errorMessage : System.Label.ZRM_Recibos_LWC_Error;
            throw new AuraHandledException(errorMessage);
        }
    }
}