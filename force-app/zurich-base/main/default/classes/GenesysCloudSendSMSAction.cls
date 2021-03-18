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

            if( String.isNotBlank(request.toNumber) && String.isNotBlank(request.smsText) && String.isNotBlank(genesysSmsNumber) )
            {
                Map<GenesysCloud.SmsData, String> caseIdByGenesysSms = new Map<GenesysCloud.SmsData, String>();
                GenesysCloud.SmsData currentSms = request.toSMS(genesysSmsNumber);
                caseIdByGenesysSms.put(currentSms, request.relatedCaseId);
                sendAsync( caseIdByGenesysSms );
            }
            else
            {
                //Alguno de los campos estaba incompleto
                throw new GenesysCloudSendSMSActionException(
                          'Missing fields sending SMS. toNumber: ' + request.toNumber + ', smsText: ' + request.smsText + ', genesysSMSNumber: ' + genesysSmsNumber
                          );
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
        public String smsText;
        @InvocableVariable(label = 'Related Case' description='Caso al que quedará relacionado el SMS')
        public String relatedCaseId;

        /**
         * @return Devuelve un correo en el formato GenesysCloud.Email utilizando los datos dados por el email
         */
        public GenesysCloud.SmsData toSMS(String fromNumber)
        {
            GenesysCloud.SmsData sms = new GenesysCloud.SmsData();

            sms.toAddress = addPrefixToPhone(this.toNumber);
            sms.fromAddress = fromNumber;
            sms.textBody = this.smsText;

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

    private static void sendAsync( Map<GenesysCloud.SmsData, String> smsMap )
    {
        GenesysCloud.SMSService.send( new List<GenesysCloud.SmsData> ( smsMap.keySet() ), new UpdateSmsMessageCallback(smsMap) );
    }

    public class UpdateSmsMessageCallback implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.SmsData, String> smsCaseIdsByGenesysSmsData;

        public UpdateSmsMessageCallback(Map<GenesysCloud.SmsData, String> smsCaseIdsByGenesysSmsData)
        {
            this.smsCaseIdsByGenesysSmsData = smsCaseIdsByGenesysSmsData;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            System.debug('----------------- callback.onSucess');
            List<Task> smsTasks = new List<Task>();

            for(Object result : results)
            {
                GenesysCloud.SmsData sms = (GenesysCloud.SmsData) result;
                System.debug(sms);
                Id relatedSmsCaseId = smsCaseIdsByGenesysSmsData.get(sms);
                System.debug('relatedCaseId: ' + relatedSmsCaseId);

                // if(String.isNotEmpty(relatedSmsMessageId) ) {
                // emailMessages.add(new EmailMessage(
                //     Id = relatedSmsMessageId,
                //     GenesysInteractionId__c = sms.interactionId
                // ));
                // }

                smsTasks.add(
                    new Task(
                        CallType = 'Outbound',
                        Channel__c = 'Phone',
                        CallObject = sms.smsId,
                        Description = sms.textBody,
                        OwnerId = UserInfo.getUserId(),
                        PhoneNumber__c = sms.toAddress,
                        Priority = 'Normal',
                        Status = 'Cerrada',
                        Subject = Label.solicitudDocumentacionSms,
                        Type = 'Other',
                        WhatId = relatedSmsCaseId
                        )
                    );
            }

            insert smsTasks;
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