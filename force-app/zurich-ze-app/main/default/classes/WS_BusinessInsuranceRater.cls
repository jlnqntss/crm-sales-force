/**
 * Clase que implementa el Web Service REST a consumir por el formulario web de Zurich Empresas
 *
 * @author rlopez
 * @date 15/10/2020
 */
@RestResource(urlMapping='/ze/*/services/quotes/*')
global with sharing class WS_BusinessInsuranceRater {
  public static Set<String> requiredFieldsMetadataSet = new Set<String>();
  public static Set<String> requiredFieldsSet = new Set<String>();

  static final String INVALID_URI_MESSAGE = 'Invalid URI versioning';
  static final String REGEXP_URI = 'v[0-9]+$';
  /**
   * Metodo Post que recibe la información del formulario web y procesa dicha información
   * en función del paso en el que se encuentre
   * @author rlopez
   * @date 15/10/2020
   */
  @HttpPost
  global static Response doPost() {
    Response doPostResponse;
    try {
      List<String> paramsURIList = RestContext.request.requestURI.split('/');
      if (
        !paramsURIList.isEmpty() &&
        paramsURIList.get(2) != null &&
        !Pattern.matches(REGEXP_URI, paramsURIList.get(2))
      ) {
        doPostResponse = new Response(
          'error',
          null,
          INVALID_URI_MESSAGE,
          '400'
        );
        throw new WS_BusinessInsuranceRaterException(INVALID_URI_MESSAGE);
      }

      /** INIT CODE */
      String requestInformation = RestContext.request.requestBody.toString();

      System.debug('RestContext.request.requestBody');
      System.debug(RestContext.request.requestBody.toString());

      //TODO: Confirmar si sería mejor sacar el lastStep buscandolo directamente en el string y no haciendo un deserializeUntyped
      Map<String, Object> requestInformationJSON = (Map<String, Object>) JSON.deserializeUntyped(
        requestInformation
      );

      if (!String.isBlank((String) requestInformationJSON.get('LastStep'))) {
        //Tenemos LastStep
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
            throw new WS_BusinessInsuranceRaterException(
              'The following fields are missing in the information received from the web form: ' +
              fieldsNotFound.toString()
            );
          }
        } catch (Exception ex) {
          System.debug('Error deserializing JSON');
          System.debug(ex.getMessage());
          //TODO: Lanzar el error correctamente
        }
      } else {
        //Retornamos un error de que no tenemos LastStep
        throw new WS_BusinessInsuranceRaterException(
          'LastStep field is missing'
        );
      }
      /** END CODE */

      doPostResponse = new Response('success', null, null, null);
    } catch (WS_BusinessInsuranceRaterException ex) {
      if (doPostResponse == null) {
        doPostResponse = new Response('error', null, ex.getMessage(), '500');
      }
    }

    return doPostResponse;
  }

  private static void setRequiredFields(String field) {
    if (requiredFieldsMetadataSet.contains(field)) {
      requiredFieldsSet.add(field);
    }
  }

  /**
   * Clase interna que representa la respuesta enviada desde el web service a Zurich,
   * indicando si el procesamiento de la información ha sido satisfactorio o no
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class Response {
    public String status;
    public Id sfId;
    public List<ResponseError> errors;

    public Response(
      String status,
      Id sfId,
      String errorMessage,
      String errorCode
    ) {
      this.status = status;
      this.sfId = sfId;
      this.errors = new List<ResponseError>{
        new ResponseError(errorMessage, errorCode)
      };
    }
  }

  /**
   * Clase interna que representa un error en caso de que se hayan encontrado problemas procesando la información recibida,
   * y que se incluirá en la respuesta enviada desde el web service a Zurich
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class ResponseError {
    public String errorMessage;
    public String errorCode;

    public ResponseError(String errorMessage, String errorCode) {
      this.errorMessage = errorMessage;
      this.errorCode = errorCode;
    }
  }

  class WS_BusinessInsuranceRaterException extends Exception {
  }
}
