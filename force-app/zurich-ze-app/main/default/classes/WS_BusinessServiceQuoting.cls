/**
 * Clase que implementa el Web Service REST a consumir por el formulario web de Zurich Empresas
 *
 * @author rlopez
 * @date 15/10/2020
 */
@RestResource(urlMapping='/*/ze/services/quotes/*')
global with sharing class WS_BusinessServiceQuoting {
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
        paramsURIList.get(1) != null &&
        !Pattern.matches(REGEXP_URI, paramsURIList.get(1))
      ) {
        doPostResponse = new Response(
          'error',
          null,
          INVALID_URI_MESSAGE,
          '400'
        );
        throw new WS_BusinessServiceQuotingException(INVALID_URI_MESSAGE);
      }

      doPostResponse = new Response('success', null, null, null);
    } catch (WS_BusinessServiceQuotingException ex) {
      if (doPostResponse == null) {
        doPostResponse = new Response('error', null, ex.getMessage(), '500');
      }
    }

    return doPostResponse;
  }

  /**
   * Clase interna que representa una solicitud recibida desde el formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class Request {
    public String TimeStamp { get; set; }
    public String WebEmail { get; set; }
    public String WebPhone { get; set; }
    public String SessionId { get; set; }
    public String BusinessCode { get; set; }
    public String LastStep { get; set; }
    public String Status { get; set; }
    public String BestTimeFrom { get; set; }
    public String BestTimeUntil { get; set; }
    public AccountInformation Cuenta { get; set; }
    public List<Offer> Ofertas { get; set; }
  }

  /**
   * Clase interna que representa la información de una cuenta, recibida en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class AccountInformation {
    public String FirstName { get; set; }
    public String LastName { get; set; }
    public String Family { get; set; }
    public String CommercialActivity { get; set; }
    public Double AnnualRevenue { get; set; }
    public Integer NumberOfEmployees { get; set; }
    public String TradeName { get; set; }
    public String CompanyName { get; set; }
    public String NationalIdentifier { get; set; }
  }

  /**
   * Clase interna que representa la información de las ofertas, recibidas en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class Offer {
    public String QuoteNumberINFO { get; set; }
    public String QuoteNumberJRE { get; set; }
    public String PolicyNumber { get; set; }
    public String OperationCode { get; set; }
    public String BusinessCode { get; set; }
    public Date EffectiveDate { get; set; }
    public String CommercialPC { get; set; }
    public String TechnicalPC { get; set; }
    public String PaymentType { get; set; }
    public String PaymentTypeSucc { get; set; }
    public String PaymentChannel { get; set; }
    public String PaymentChannelSucc { get; set; }
    public String Language { get; set; }
    public Double BuildingCapital { get; set; }
    public Double ContentCapital { get; set; }
    public Double GeneralLiabilityLimit { get; set; }
    public Double NetPremium { get; set; }
    public String ValidationErrors { get; set; }
    public OfferRiskInformation Riesgo { get; set; }
  }

  /**
   * Clase interna que representa la información del riesgo de una oferta, recibida en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  global class OfferRiskInformation {
    public String PropertyStreetType { get; set; }
    public String PropertyStreet { get; set; }
    public String PropertyStreetNumber { get; set; }
    public String PropertyAdditionalInfo { get; set; }
    public String PropertyPostalCode { get; set; }
    public String PropertyCity { get; set; }
    public String PropertyState { get; set; }
    public String PropertyCountry { get; set; }
    public Integer YearOfConstruction { get; set; }
    public String Ownership { get; set; }
    public String InsuredType { get; set; }
    public String BuildingType { get; set; }
    public String Height { get; set; }
    public String RiskFactor01 { get; set; }
    public String RiskFactor02 { get; set; }
    public String RiskFactor03 { get; set; }
    public String RiskFactor04 { get; set; }
    public String RiskFactor05 { get; set; }
    public String RiskFactor06 { get; set; }
    public String RiskFactor07 { get; set; }
    public String RiskFactor08 { get; set; }
    public String RiskFactor09 { get; set; }
    public String Area { get; set; }
    public Boolean LockType { get; set; }
    public Boolean SecurityDoor { get; set; }
    public Boolean BulletproofDoor { get; set; }
    public Boolean ConnectedAlarm { get; set; }
    public Boolean FireHydrant { get; set; }
    public Boolean Surveillance { get; set; }
    public Boolean SmokeDetector { get; set; }
    public Boolean Sprayer { get; set; }
    public Boolean FireExtinguisher { get; set; }
    public String TypeOfWindows { get; set; }
    public String Strongbox { get; set; }
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

  class WS_BusinessServiceQuotingException extends Exception {
  }
}
