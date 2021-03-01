public class GenesysCloudSendSMSAction
{
    public static final String SPANISH_PHONE_PREFIX = '+34';
    /**
     * Invocable Action que recoge los datos del SMS a enviar en el Flow y los envía a Genesys mediante el API Apex de GenesysCloud
     * Delega la ejecución a GenesysCloud.SMSService.send
     * @param requests Petición de enrutamiento. Formato lista para permitir el bulkificado del flow
     */
    @InvocableMethod(
        label='Send SMS'
               description='Send SMS through Genesys Cloud'
                            category= 'Other'
        )
    public static void sendSMS(List<SendSMSRequest> sendSMSActionRequests)
    {
        List<SendSMSResponse> results = new List<SendSMSResponse>();

        if( sendSMSActionRequests != null && !sendSMSActionRequests.isEmpty() )
        {
            List<AdminSetupParameter__mdt> settings = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = 'GenesysSmsNumber'];
            String genesysSmsNumber = settings[0].Value__c;

            SendSMSRequest request = sendSMSActionRequests[0];

            if( String.isNotBlank(request.toNumber) && String.isNotBlank(request.SMSText) && String.isNotBlank(genesysSmsNumber) )
            {
                sendAsync( request.toSMS(genesysSmsNumber) );
            }
            else
            {
                //Alguno de los campos estaba incompleto
                throw new GenesysCloudSendSMSActionException('The genesys queue does not exists.');
            }
        }

        //return results;
    }

    /**
     * Devuelve los identificadores de interacción dados por Genesys Cloud
     */
    public class SendSMSResponse
    {
        @InvocableVariable(label='Id de interacción devuelto por Genesys')
        public String interactionId;
    }

    /**
     * La acción debe poder recoger un valor, ownerId , que será el identificador (email)
     * de usuario que debe gestionar el email. Este se pasará a Genesys Cloud como un atributo personalizado SF_OwnerId.
     */
    public class SendSMSRequest
    {
        @InvocableVariable(label = 'To Number' description='Número de teléfono al que enviar el SMS')
        public String toNumber;
        @InvocableVariable(label = 'SMS Text' description='Contenido del SMS')
        public String SMSText;

        /**
         * @return Devuelve un correo en el formato GenesysCloud.Email utilizando los datos dados por el email
         */
        public GenesysCloud.SmsData toSMS(String fromNumber)
        {
            GenesysCloud.SmsData sms = new GenesysCloud.SmsData();

            sms.toAddress = addPrefixToPhone(this.toNumber);
            sms.fromAddress = fromNumber;
            sms.textBody = this.SMSText;

            return sms;
        }

        private String addPrefixToPhone(String phone)
        {
            if( !phone.startsWith('+') )
            {
                return SPANISH_PHONE_PREFIX + phone;
            }
            else
            {
                return phone;
            }
        }
    }

    private static void sendAsync( GenesysCloud.SmsData sms )
    {
        Map<GenesysCloud.SmsData, String> smsMessageIdsByGenesysSmsData = new Map<GenesysCloud.SmsData, String>();
        smsMessageIdsByGenesysSmsData.put(sms, 'xxx');
        // GenesysCloud.UpdateSmsMessageCallback retorno = new GenesysCloud.UpdateSmsMessageCallback(smsMessageIdsByGenesysSmsData);
        GenesysCloud.SMSService.send(new List<GenesysCloud.SmsData> {sms}, null );
    }

    private class UpdateSmsMessageCallback implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.SmsData, String> smsMessageIdsByGenesysSmsData;

        public UpdateSmsMessageCallback(Map<GenesysCloud.SmsData, String> smsMessageIdsByGenesysSmsData)
        {
            this.smsMessageIdsByGenesysSmsData = smsMessageIdsByGenesysSmsData;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            System.debug('----------------- callback.onSucess');
            // List<EmailMessage> smsMessages = new List<EmailMessage>();

            for(Object result : results)
            {
                GenesysCloud.SmsData sms = (GenesysCloud.SmsData) result;
                System.debug(sms);
                Id relatedSmsMessageId = smsMessageIdsByGenesysSmsData.get(sms);
                System.debug('relatedSmsMessageId: ' + relatedSmsMessageId);

                // if(String.isNotEmpty(relatedSmsMessageId) ) {
                // emailMessages.add(new EmailMessage(
                //     Id = relatedSmsMessageId,
                //     GenesysInteractionId__c = sms.interactionId
                // ));
                // }
            }

            // update emailMessages;
        }

        public void onError(Exception error)
        {
            ErrorLogUtil.commitError(error);
        }
    }

    @TestVisible
    class GenesysCloudSendSMSActionException extends Exception
    {}
}