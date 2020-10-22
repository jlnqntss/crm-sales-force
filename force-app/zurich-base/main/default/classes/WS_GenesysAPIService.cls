@RestResource(urlMapping='/genesys-cloud/v1/*')
global without sharing class WS_GenesysAPIService extends WS_BaseAPIService {
  /**
   * Recibe las peticiones POST provenientes de genesys
   * Dependiendo del resource se llamará a una clase u otra de apex
   * De momento solo está implementado 'iteractions'
   * Dependiendo de la función, llamará a un método de GenesysInteractionsSerive u otro
   * De momento solo está implementado 'init'
   * @author nescudero
   * @date 22/10/2020
   */
  @HttpPost
  global static void doPost() {
    RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;

    String resource = WS_BaseAPIService.resource;
    Integer version = WS_BaseAPIService.version;
    String vendor = WS_BaseAPIService.vendor;

    Savepoint sp = Database.setSavepoint();

    try {
      switch on resource {
        when 'interactions' {
          GenesysInteractionsService.version = version;
          if (RestContext.request.requestURI.endsWith('/init')) {
            GenesysInteractionsService.InteractionRequest ir = (GenesysInteractionsService.InteractionRequest) JSON.deserialize(
              request.requestBody.toString(),
              GenesysInteractionsService.InteractionRequest.class
            );
            GenesysInteractionsService.BestAgent ba = GenesysInteractionsService.initInteraction(
              ir
            );
            response.responseBody = Blob.valueOf(JSON.serialize(ba));
            response.statusCode = 201;
          }
        }
      }
    } catch (Exception e) {
      Database.rollback(sp);
      WS_BaseAPIServiceError badResponse = new WS_BaseAPIServiceError(
        e,
        'INTERNAL_SERVER_ERROR',
        e.getMessage(),
        e.getStackTraceString()
      );
      response.responseBody = Blob.valueOf(JSON.serialize(badResponse));
      response.statusCode = 500;
    }
  }
}
