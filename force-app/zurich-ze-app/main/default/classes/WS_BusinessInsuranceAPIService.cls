/**
 * Clase que implementa el Web Service REST que servirá de API para los Web Services relacionados con Zurich Empresas
 *
 * @author rlopez
 * @date 30/10/2020
 */
@RestResource(urlMapping='/ze/*/*')
global without sharing class WS_BusinessInsuranceAPIService extends WS_BaseAPIService {
    /**
     * Metodo Post que recibe la información del formulario web y procesa dicha información
     * en función del paso en el que se encuentre
     * @author rlopez
     * @date 30/10/2020
     *
     * @change 21/04/2021 - nts (agonzalezisasi) - Se traslada al final la traza de la peticion para que informe tambien del resultado del proceso
     */
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        // Para la traza de la peticion, inicialmente presuponemos que ira bien
        String requestResultType = 'warning';
        String requestResult = 'OK.200';
        String requestResultErrorMessage;
        String requestResultErrorStackTrace;

        Savepoint sp = Database.setSavepoint();
        try
        {

            validateRequest();

            String resource = WS_BaseAPIService.resource;
            Integer version = WS_BaseAPIService.version;
            String vendor = WS_BaseAPIService.vendor;

            BusinessInsuranceRaterService.version = version;
            String requestInformation = request.requestBody.toString();

            switch on resource {
                when 'offers' {
                    Map<String, Object> requestInformationJSON = (Map<String, Object>) JSON.deserializeUntyped(
                        requestInformation
                    );

                    //Recuperamos los metadatos que contengan ese LastStep
                    BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(
                        (String) requestInformationJSON.get(BusinessInsuranceRaterService.LASTSTEP_FIELD)
                    );

                    //Creamos el objeto utilizando los wrappers
                    BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
                        requestInformation,
                        BusinessInsuranceRaterService.Request.class
                    );

                    BusinessInsuranceRaterService.validateReceivedInformation();
                    // Se comprueban los datos de la solicitud para descartar las pruebas del bot.
                    BusinessInsuranceRaterService.processFormData(requestInformationObject);

                    response.responseBody = Blob.valueOf('{"status":"success", "sfId":"", "errors":[]}');
                    response.statusCode = 200;
                }
                when 'interactions' {
                    //Deserializar la request en formato CallMeBack
                    BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
                        requestInformation,
                        BusinessInsuranceCallbackService.CallMeBack.class
                    );
                    String callMeBackId='';
                    //Validar que llegan todos los campos necesarios
                    BusinessInsuranceCallbackService.validateRequiredFields(deserializedRequest);
                    // Se comprueban los datos de la solicitud para descartar las pruebas del bot.
                    if (!BusinessInsuranceCallbackService.isBotTestingExecution(deserializedRequest))
                    {
                        //Insertar un Contact Request que entrará en el Process Builder
                        callMeBackId = BusinessInsuranceCallbackService.insertCallMeBack(deserializedRequest);
                    }
                    response.responseBody = Blob.valueOf('{"status":"success", "sfId":"'+callMeBackId+'", "errors":[]}');
                    response.statusCode = 200;
                }
                when else 
                {
                    // else code
                }
            }
        }
        catch (WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            ErrorResponseZE errorFormat = new ErrorResponseZE(apiError);
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
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = dmlError.getMessage();
            requestResultErrorStackTrace = dmlError.getStackTraceString();
        }
        catch (BusinessInsuranceRaterService.BusinessInsuranceRaterServiceException serviceException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(serviceException.statusCode, serviceException.getMessage(), false);
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = serviceException.getMessage();
            requestResultErrorStackTrace = serviceException.getStackTraceString();
        }
        catch (BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException serviceException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(serviceException.statusCode, serviceException.getMessage(), false);
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
            
            // informaremos del error en la traza de la peticion
            requestResultErrorMessage = serviceException.getMessage();
            requestResultErrorStackTrace = serviceException.getStackTraceString();
        }
        catch (JSONException jsonException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_JSON_KO, jsonException.getMessage(), false);
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
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
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
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
            ErrorLogUtil.commitError(requestResultType, 'New webform request: ' + requestResult, 'WS_BusinessInsuranceAPIService', stackTraceText);
        }
    }

    public class ErrorResponseZE {
        public String status {get; set;}
        public String sfId {get; set;}
        public List<ErrorResponseZE_Error> errors {get; set;}

        public ErrorResponseZE(WS_BaseAPIService.ApiException error)
        {
            this.status = 'error';
            this.sfId = null;

            ErrorResponseZE_Error formattedError = new ErrorResponseZE_Error();
            formattedError.message = error.message;
            formattedError.errorCode = error.statusCode;
            this.errors = new List<ErrorResponseZE_Error>{formattedError};
        }
    }

    public class ErrorResponseZE_Error {
        public String message {get; set;}
        public String errorCode {get; set;}
    }
}
