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
     */
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        Savepoint sp = Database.setSavepoint();
        try
        {

            validateRequest();

            String resource = WS_BaseAPIService.resource;
            Integer version = WS_BaseAPIService.version;
            String vendor = WS_BaseAPIService.vendor;

            BusinessInsuranceRaterService.version = version;
            String requestInformation = request.requestBody.toString();

            if(!Test.isRunningTest())
            {
                //Log para registrar el JSON recibido
                ErrorLogUtil.commitError('warning', requestInformation, 'JSON recibido por WS de Zurich Empresas');
            }

            switch on resource {
                when 'offers' {
                    //TODO: Confirmar si sería mejor sacar el lastStep buscandolo directamente en el string y no haciendo un deserializeUntyped
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
                    //Validar que llegan todos los campos necesarios
                    BusinessInsuranceCallbackService.validateRequiredFields(deserializedRequest);
                    //Insertar un Contact Request que entrará en el Process Builder
                    String callMeBackId = BusinessInsuranceCallbackService.insertCallMeBack(deserializedRequest);

                    response.responseBody = Blob.valueOf('{"status":"success", "sfId":"'+callMeBackId+'", "errors":[]}');
                    response.statusCode = 200;
                }
            }
        }
        catch (WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            ErrorResponseZE errorFormat = new ErrorResponseZE(apiError);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
        }
        catch (DmlException dmlError)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(dmlError);
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
        }
        catch (BusinessInsuranceRaterService.BusinessInsuranceRaterServiceException serviceException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(serviceException.statusCode, serviceException.getMessage());
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
        }
        catch (BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException serviceException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(serviceException.statusCode, serviceException.getMessage());
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
        }
        catch (JSONException jsonException)
        {
            Database.rollback(sp);

            response.statusCode = 400;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_JSON_KO, jsonException.getMessage());
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
        }
        catch (Exception genericError)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_GENERIC_KO, genericError.getMessage());
            ErrorResponseZE errorFormat = new ErrorResponseZE(apiException);
            response.responseBody = Blob.valueOf(JSON.serialize(errorFormat));
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
