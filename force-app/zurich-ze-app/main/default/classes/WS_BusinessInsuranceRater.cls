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
      String requestInformation = '{\n\"TimeStamp\":\"2020-04-28T12:23:00\",\n\"WebEmail\":true,\n\"WebPhone\":\"600666000\",\n\"SessionId\":\"xxxxx\",\n\"BusinessCode\":\"3200011531\",\n\"LastStep\":\"CRM-01\",\n\"Status\":\"Activo\",\n\"Manager\":{\n\"FirstName\":\"ManagerFirstName\",\n\"LastName\":\"ManagerLastName\",\n\"Email\":\"manageremail@manager.com\",\n\"Phone\":\"123456789\"\n},\n\"AccountInformation\":{\n\"FirstName\":\"Nombre\",\n\"LastName\":\"Apellidos\",\n\"Family\":\"10\",\n\"CommercialActivity\":\"101100\",\n\"AnnualRevenue\":\"200000.10\",\n\"NumberOfEmployees\":\"150\",\n\"TradeName\":\"Nombre comercial\",\n\"CompanyName\":\"Nombre Compañía\",\n\"NationalIdentifier\":\"B111111111\"\n},\n\"Offers\":[\n{\n\"QuoteNumberINFO\":\"456789456\",\n\"QuoteNumberJRE\":\"5555555\",\n\"PolicyNumber\":\"654654654\",\n\"OperationCode\":\"P1\",\n\"BusinessCode\":\"3200011531\",\n\"EffectiveDate\":\"2020-09-28\",\n\"CommercialPC\":\"00001\",\n\"TechnicalPC\":\"00526\",\n\"PaymentType\":\"A\",\n\"PaymentTypeSucc\":\"A\",\n\"PaymentChannel\":\"CC\",\n\"PaymentChannelSucc\":\"CC\",\n\"Language\":\"ES\",\n\"BuildingCapital\":\"120000\",\n\"ContentCapital\":\"12000\",\n\"GeneralLiabilityLimit\":\"12000\",\n\"NetPremium\":\"12000\",\n\"ValidationErrors\":\"\",\n\"OfferRiskInformation\":{\n\"PropertyStreetType\":\"VI\",\n\"PropertyStreet\":\"Via Augusta\",\n\"PropertyStreetNumber\":\"12\",\n\"PropertyAdditionalInfo\":\"\",\n\"PropertyPostalCode\":\"08006\",\n\"PropertyCity\":\"Barcelona\",\n\"PropertyState\":\"8\",\n\"PropertyCountry\":\"ESP\",\n\"YearOfConstruction\":\"1960\",\n\"Ownership\":\"P\",\n\"InsuredType\":\"I\",\n\"BuildingType\":\"I\",\n\"Height\":\"AL\",\n\"RiskFactor01\":\"0001\",\n\"RiskFactor02\":\"\",\n\"RiskFactor03\":\"\",\n\"RiskFactor04\":\"\",\n\"RiskFactor05\":\"\",\n\"RiskFactor06\":\"\",\n\"RiskFactor07\":\"\",\n\"RiskFactor08\":\"0039\",\n\"RiskFactor09\":\"\",\n\"Area\":\"50\",\n\"LockType\":true,\n\"SecurityDoor\":false,\n\"BulletproofDoor\":false,\n\"ConnectedAlarm\":false,\n\"FireHydrant\":false,\n\"Surveillance\":false,\n\"SmokeDetector\":false,\n\"Sprayer\":false,\n\"FireExtinguisher\":true,\n\"TypeOfWindows\":\"2\",\n\"Strongbox\":\"N\"\n}\n}\n]\n}';

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

          System.debug('requiredFieldsSet:');
          System.debug(requiredFieldsSet);

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
