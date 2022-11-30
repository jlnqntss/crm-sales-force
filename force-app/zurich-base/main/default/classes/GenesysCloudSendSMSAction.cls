public class GenesysCloudSendSMSAction {
  public static final String SPANISH_PHONE_PREFIX = '+34';
  /**
   * Invocable Action que recoge los datos del SMS a enviar en el Flow y los envía a Genesys mediante el API Apex de GenesysCloud
   * Delega la ejecución a GenesysCloud.SMSService.send
   * @param requests Petición de enrutamiento. Formato lista para permitir el bulkificado del flow
   */
  @InvocableMethod(
    label='Send SMS'
    description='Send SMS through Genesys Cloud'
    category='Other'
  )
  public static void sendSMS(List<SendSMSRequest> sendSMSActionRequests) {
    if (sendSMSActionRequests != null && !sendSMSActionRequests.isEmpty()) {
      SendSMSRequest request = sendSMSActionRequests[0];
      if (
        String.isNotBlank(request.senderNumber) &&
        String.isNotBlank(request.toNumber) &&
        String.isNotBlank(request.smsText)
      ) {
        Map<GenesysCloud.SmsData, String> caseIdByGenesysSms = new Map<GenesysCloud.SmsData, String>();
        GenesysCloud.SmsData sms = new GenesysCloud.SmsData();
        sms.fromAddress = request.senderNumber;
        sms.toAddress = request.toNumber.startsWith(SPANISH_PHONE_PREFIX)
          ? request.toNumber
          : SPANISH_PHONE_PREFIX + request.toNumber;
        sms.textBody = request.smsText;
        caseIdByGenesysSms.put(sms, request.relatedCaseId);
        sendAsync(caseIdByGenesysSms);
      } else {
        //Alguno de los campos estaba incompleto
        throw new GenesysCloudSendSMSActionException(
          'Missing fields sending SMS. toNumber: ' +
          request.toNumber +
          ', smsText: ' +
          request.smsText +
          ', genesysSMSNumber: ' +
          request.senderNumber
        );
      }
    }

  }

  /**
   * Devuelve los identificadores de interacción dados por Genesys Cloud
   */
  public class SendSMSResponse {
    @InvocableVariable(label='Id de interacción devuelto por Genesys')
    public String interactionId;
  }

  /**
   * La acción debe poder recoger un valor, ownerId , que será el identificador (email)
   * de usuario que debe gestionar el email. Este se pasará a Genesys Cloud como un atributo personalizado SF_OwnerId.
   */
  public class SendSMSRequest {
    @InvocableVariable(
      label='Sender Number'
      description='Número de teléfono desde donde se envía el SMS'
      required=true
    )
    public String senderNumber;
    @InvocableVariable(
      label='To Number'
      description='Número de teléfono al que enviar el SMS'
    )
    public String toNumber;
    @InvocableVariable(label='SMS Text' description='Contenido del SMS')
    public String smsText;
    @InvocableVariable(
      label='Related Case'
      description='Caso al que quedará relacionado el SMS'
    )
    public String relatedCaseId;
  }

  private static void sendAsync(Map<GenesysCloud.SmsData, String> smsMap) {
    GenesysCloud.SMSService.send(
      new List<GenesysCloud.SmsData>(smsMap.keySet()),
      new UpdateSmsMessageCallback(smsMap)
    );
  }

  public class UpdateSmsMessageCallback implements GenesysCloud.IAPICallback {
    Map<GenesysCloud.SmsData, String> smsCaseIdsByGenesysSmsData;

    public UpdateSmsMessageCallback(
      Map<GenesysCloud.SmsData, String> smsCaseIdsByGenesysSmsData
    ) {
      this.smsCaseIdsByGenesysSmsData = smsCaseIdsByGenesysSmsData;
    }

    public void onSuccess(
      List<Object> results,
      List<GenesysCloud.IAPIRequest> requests
    ) {
    }

    public void onError(Exception error) {
      ErrorLogUtil.commitError(error);
    }
  }

  @TestVisible
  class GenesysCloudSendSMSActionException extends Exception {
  }
}
