/**
 * Clase para consultar el servicio web GetReturnedReceiptsList que devuelve los recibos del usuario logueado
 *
 * @author dmunoz
 * @date 29/05/2024
 */
public with sharing class WS_GetReturnedReceiptsList
{
    private static final String CLASS_NAME = 'WS_GetReturnedReceiptsList'; 

    /**
     * Método principal que realiza la consulta al servicio web
     *
     * @author dmunoz
     * @date 29/05/2024
     * 
     * @param invocationType debe ser "DiaAnterior" o "Acumulados"
     *
     * @return ZRMReciboListResponse devuelve la respuesta del servicio web 
     */
    public GetReturnedReceiptsWSUtils.ZRMReciboListResponse callWebService(Integer pageNumber, Integer pageSize, String invocationType)
    {
        String level = ErrorLogUtil.ERROR_LEVEL_WARNING;
        String message = 'OK.200';
        String requestBody = '';

        try
        {
            // Crear objeto request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:WS_GetReturnedReceiptsListSyncOperation');
            request.setMethod('POST');
            request.setTimeout(120000);

            // añado la cabecera y la autenticación
            request = GetReturnedReceiptsWSUtils.setAuthenticationHeader(request);
            
            // Crear request
            GetReturnedReceiptsWSUtils.ZRMReciboRequest zrmReciboRequest = GetReturnedReceiptsWSUtils.createRequest(pageNumber, pageSize, invocationType);
            requestBody = JSON.serialize(zrmReciboRequest);
            request.setBody(requestBody);
            
            // Enviar request
            HttpResponse response = http.send(request);
            
            // Verificar el estado de la respuesta
            if (response.getStatusCode() == 200)
            {
                // Deserializar la respuesta JSON en un objeto ZRMReciboListResponse
                GetReturnedReceiptsWSUtils.ZRMReciboListResponse result = (GetReturnedReceiptsWSUtils.ZRMReciboListResponse) JSON.deserialize(response.getBody(), GetReturnedReceiptsWSUtils.ZRMReciboListResponse.class);
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