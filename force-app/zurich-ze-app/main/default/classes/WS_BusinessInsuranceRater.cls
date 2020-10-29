/**
 * Clase que implementa el Web Service REST a consumir por el formulario web de Zurich Empresas
 *
 * @author rlopez
 * @date 15/10/2020
 */
@RestResource(urlMapping='/ze/*/rates/*')
global with sharing class WS_BusinessInsuranceRater extends WS_BaseAPIService {
  //TODO: Crear custom labels de estas constantes
  static final String INVALID_URI_MESSAGE = 'Invalid URI versioning';
  static final String INVALID_CONTENTTYPE_MESSAGE = 'Invalid Content-Type on request headers';
  /**
   * Metodo Post que recibe la información del formulario web y procesa dicha información
   * en función del paso en el que se encuentre
   * @author rlopez
   * @date 15/10/2020
   */
  @HttpPost
  global static void doPost() {
    RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;
    try {
      response.addHeader('Content-Type', 'application/json');

      //Si la versión no es correcta, lanzamos error
      if (!WS_BaseAPIService.isValidVersion) {
        response.statusCode = 400;
        throw new WS_BaseAPIService.ApiException(
          'INVALID_URI_MESSAGE',
          INVALID_URI_MESSAGE
        );
      }

      //Si la cabecera content-type no es JSON, lanzamos error
      if (!WS_BaseAPIService.isJSONContentType) {
        response.statusCode = 400;
        throw new WS_BaseAPIService.ApiException(
          'BAD_REQUEST',
          INVALID_CONTENTTYPE_MESSAGE
        );
      }

      String resource = WS_BaseAPIService.resource;
      Integer version = WS_BaseAPIService.version;
      String vendor = WS_BaseAPIService.vendor;

      String requestInformation = request.requestBody.toString();

      //TODO: Confirmar si sería mejor sacar el lastStep buscandolo directamente en el string y no haciendo un deserializeUntyped
      Map<String, Object> requestInformationJSON = (Map<String, Object>) JSON.deserializeUntyped(
        requestInformation
      );

      if (!String.isBlank((String) requestInformationJSON.get('LastStep'))) {
        //Recuperamos los metadatos que contengan ese LastStep
        BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(
          (String) requestInformationJSON.get('LastStep')
        );

        //Creamos el objeto utilizando los wrappers
        try {
          BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
            requestInformation,
            BusinessInsuranceRaterService.Request.class
          );

          List<String> fieldsNotFound = BusinessInsuranceRaterService.validateReceivedInformation();
          if (!fieldsNotFound.isEmpty()) {
            response.statusCode = 400;
            throw new WS_BaseAPIService.ApiException(
              'INVALID_FIELD',
              'The following fields are missing in the information received from the web form: ' +
              fieldsNotFound.toString()
            );
          }

          response.statusCode = 200;
        } catch (Exception ex) {
          System.debug('Error deserializing JSON: ' + ex.getMessage());

          response.statusCode = 400;
          throw new WS_BaseAPIService.ApiException(
            'JSON_PARSER_ERROR',
            'Error deserializing JSON'
          );
        }
      } else {
        //Retornamos un error de que no tenemos LastStep
        response.statusCode = 400;
        throw new WS_BaseAPIService.ApiException(
          'INVALID_FIELD',
          'LastStep field missing'
        );
      }
    } catch (WS_BaseAPIService.ApiException exAPI) {
      System.debug('WS_BaseAPIService.ApiException: ' + exAPI.getMessage());
      response.responseBody = Blob.valueOf(JSON.serialize(exAPI));
    } catch (Exception ex) {
      System.debug('Exception: ' + ex.getMessage());

      if (response.statusCode == null) {
        response.statusCode = 500;
      }

      //ErrorLogUtil.commitError(ex);

      WS_BaseAPIService.ApiException exceptionApi = new WS_BaseAPIService.ApiException(
        'INTERNAL_SERVER_ERROR',
        ex.getMessage()
      );
      response.responseBody = Blob.valueOf(JSON.serialize(exceptionApi));
    }
  }
}
