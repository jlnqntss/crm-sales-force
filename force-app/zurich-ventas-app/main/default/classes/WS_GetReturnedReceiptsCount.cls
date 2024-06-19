/**
 * Clase para consultar el servicio web GetReturnedReceiptsList que devuelve los recibos del usuario logueado
 *
 * @author dmunoz
 * @date 29/05/2024
 */
public with sharing class WS_GetReturnedReceiptsCount
{
    private static final String CLASS_NAME = 'WS_GetReturnedReceiptsCount'; 

    /**
     * Método principal que realiza la consulta al servicio web
     *
     * @author fpalomo
     * @date 13/06/2024
     * 
     * @param invocationType debe ser "DiaAnterior" o "Acumulados"
     *
     * @return ZRMReciboCountResponse devuelve la respuesta del servicio web 
     */
    public GetReturnedReceiptsWSUtils.ZRMReciboCountResponse callWebService()
    {
        String level = ErrorLogUtil.ERROR_LEVEL_WARNING;
        String message = 'OK.200';
        String requestBody = '';

        try
        {
            // Crear objeto request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:WS_GetReturnedReceiptsCountSyncOperation');
            request.setMethod('POST');
            request.setTimeout(120000);

            // añado la cabecera y la autenticación
            request = GetReturnedReceiptsWSUtils.setAuthenticationHeader(request);
            
            // Enviar request
            HttpResponse response = http.send(request);
            
            // Verificar el estado de la respuesta
            if (response.getStatusCode() == 200)
            {
                // Deserializar la respuesta JSON en un objeto GetReturnedReceiptsWSUtils.ZRMReciboCountResponse
                GetReturnedReceiptsWSUtils.ZRMReciboCountResponse result = (GetReturnedReceiptsWSUtils.ZRMReciboCountResponse) JSON.deserialize(response.getBody(), GetReturnedReceiptsWSUtils.ZRMReciboCountResponse.class);
                ErrorLogUtil.commitError(level, message, CLASS_NAME, requestBody); // guardo el ok
                return result;
                
            }
            
            else
            {
                // Manejar respuestas que no sean exitosas
                level = ErrorLogUtil.ERROR_LEVEL_ERROR;
                message = 'KO.' + response.getStatusCode();
                ErrorLogUtil.commitError(level, message, CLASS_NAME, response.getBody()); // guardo la respuesta en caso de error
                return null;
            }
        }

        catch (Exception e)
        {
            level = ErrorLogUtil.ERROR_LEVEL_ERROR;
            message = e.getMessage();
            ErrorLogUtil.commitError(level, message, CLASS_NAME, requestBody); // si hay un error no controlado guardo la request
            return null;
        }
    }
}