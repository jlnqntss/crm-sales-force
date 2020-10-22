@RestResource(urlMapping='/v1/genesys-cloud/interactions/init/*')
global without sharing class WS_GenesysCloudInteractions {
  /**
   * Entrada de petición de Genesys
   * @author nescudero
   * @date 21/10/2020
   */
  @HttpPost
  global static void init(WrapperReq ReqBody) {
    RestResponse res = RestContext.response;
    WrapperResponse response;
    WrapperBadResponse badResponse;

    //1º Comprobación de campos obligatorios
    if (
      ReqBody.interactionType == null ||
      ReqBody.fromId == null ||
      ReqBody.toId == null
    ) {
      badResponse = new WrapperBadResponse(
        'BAD_REQUEST',
        'Faltan campos obligatorios en la petición.'
      ); //TODO: crear label para esto
      res.responseBody = Blob.valueOf(JSON.serialize(badResponse));
      res.statusCode = 400;
    } else {
      Savepoint sp = Database.setSavepoint();

      try {
        String screenPopRecordId;
        String callLogId;
        String bestAgentId;

        //1º Crear una Task
        callLogId = GenesysCloudInteractionManagementService.createOnqueueInteraction();

        //2º Encontrar al contacto y su último registro creado (ya sea opportunity o case)

        //3º Identificar el Owner de dicho registro

        //4º Devolver una respuesta bien
        response = new WrapperResponse(
          screenPopRecordId,
          callLogId,
          bestAgentId
        );
        res.responseBody = Blob.valueOf(JSON.serialize(response));
        res.statusCode = 201;
      } catch (Exception e) {
        Database.rollback(sp);
        badResponse = new WrapperBadResponse(
          'INTERNAL_SERVER_ERROR',
          '[MessageError: ' +
          e.getMessage() +
          '] [StackTrace: ' +
          e.getStackTraceString() +
          ']'
        ); //TODO: label
        res.responseBody = Blob.valueOf(JSON.serialize(badResponse));
        res.statusCode = 500;
      }
    }
  }

  global class WrapperResponse {
    public String screenPopRecordId { get; set; }
    public String callLogId { get; set; }
    public String bestAgentId { get; set; }

    public WrapperResponse(
      String screenPopRecordId,
      String callLogId,
      String bestAgentId
    ) {
      this.screenPopRecordId = screenPopRecordId;
      this.callLogId = callLogId;
      this.bestAgentId = bestAgentId;
    }
  }

  global class WrapperBadResponse {
    public String errorCode { get; set; }
    public String message { get; set; }

    public WrapperBadResponse(String errorCode, String message) {
      this.errorCode = errorCode;
      this.message = message;
    }
  }

  global class WrapperReq {
    public String interaction { get; set; }
    public String interactionType { get; set; }
    public String fromId { get; set; }
    public String toId { get; set; }
    public String queueId { get; set; }
    public String lookFor { get; set; }
  }
}
