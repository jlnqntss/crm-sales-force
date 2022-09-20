/**
 * @description       : 
 * @author            : arcortazar
 * @group             : 
 * @last modified on  : 09/06/2022
 * @last modified by  : arcortazar
**/
@RestResource(urlMapping = '/identification/*/*') 
global without sharing class WS_ClientIdentificationService extends WS_BaseAPIService
{
    /**
     * Recibe y procesa peticiones POST
     * Identifica el resource, procesa los parámetros y los delega a una segunda clase
     * @author arcortazar
     * @date 13/06/2022
     */
    @HttpPost
    global static void doPost()
    {
        System.debug('++++ WS_ClientIdentificationService.doPost()');

        // Hacemos un 
        Savepoint sp = Database.setSavepoint();

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        String requestResultType = 'warning';
        String requestResult = 'OK.200';
        String requestResultErrorMessage;
        String requestResultErrorStackTrace;

        response.addHeader('Content-Type', 'application/json');

        try
        {
            WS_GenesysAPIService.validateRequest();
            System.debug('++++ WS_GenesysAPIService.validateRequest();: ');
            
            String requestInformation = request.requestBody.toString();
            System.debug('++++ requestInformation: ' + requestInformation);

            switch on WS_BaseAPIService.resource {
                // 1 - POST /people: Procesa la búsqueda de clientes
                when 'people' {

                    // tendremos que validar que tengamos los campos necesarios
                    ClientIdentificationService.Client receivedClient= (ClientIdentificationService.Client) JSON.deserializeStrict(
                        requestInformation,
                        ClientIdentificationService.Client.class
                    );

                    System.debug('++++ receivedClient: ' + receivedClient);
                    
                    ClientIdentificationService.validateReceivedInformation(receivedClient);
                    System.debug('++++ hemos validado: ' + receivedClient);
                    
                    // si es OK, hacemos la identidicación
                    ClientIdentificationService.SearchResult resultado = ClientIdentificationService.processData(receivedClient);

                    // Montamos la respuesta
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(
                        resultado.toString()
                    );
                }
                when else {
                    throw new IntegrationException( 
                        Label.ParseError + 'Unsupported entity type: ' + WS_BaseAPIService.resource
                      );
                }
            }
        }
        catch (WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            ErrorResponse errorFormat = new ErrorResponse(apiError);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = apiError.getMessage();
            requestResultErrorStackTrace = apiError.getStackTraceString();
        }
        catch (DmlException dmlError)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(dmlError, false);
            ErrorResponse errorFormat = new ErrorResponse(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = dmlError.getMessage();
            requestResultErrorStackTrace = dmlError.getStackTraceString();
        }
        catch (JSONException jsonException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_JSON_KO, jsonException.getMessage(), false);
            ErrorResponse errorFormat = new ErrorResponse(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = jsonException.getMessage();
            requestResultErrorStackTrace = jsonException.getStackTraceString();
        }
        catch (Exception genericError)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_GENERIC_KO, genericError.getMessage(), false);
            ErrorResponse errorFormat = new ErrorResponse(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));

            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = genericError.getMessage();
            requestResultErrorStackTrace = genericError.getStackTraceString();
        }
        finally
        {
            // Traza de la peticion con el resultado
            String stackTraceText = request.requestBody?.toString();
            if( String.isNotBlank(requestResultErrorMessage) ) {
                requestResultType = 'error';
                requestResult = 'KO.' + response.statusCode + '.' + requestResultErrorMessage;
                stackTraceText += '\n' + requestResultErrorStackTrace;
            }
            ErrorLogUtil.commitError(requestResultType, 'New webform request: ' + requestResult, 'WS_ClientIdentificationService', stackTraceText);
        }
    }
    
    public class ErrorResponse {
        public String status {get; set;}
        public List<ErrorResponse_Error> errors {get; set;}

        public ErrorResponse(WS_BaseAPIService.ApiException error)
        {
            this.status = 'error';

            ErrorResponse_Error formattedError = new ErrorResponse_Error();
            formattedError.message = error.message;
            formattedError.errorCode = error.statusCode;
            this.errors = new List<ErrorResponse_Error>{formattedError};
        }
    }

    public class ErrorResponse_Error {
        public String message {get; set;}
        public String errorCode {get; set;}
    }

    public class GenesysPeopleServiceException extends Exception {}
}