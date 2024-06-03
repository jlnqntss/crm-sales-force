/**
 * Clase encargada de encapsular los campos para una peticion de envio de informacion a canal unico
 * a traves de ESB. Contiene metodos para la construccion de la peticion de tipo SOAP
 *
 * @author mario.navarro@seidor.com
 * @date 21/03/2024
 * @see https://zurichspain.atlassian.net/wiki/spaces/OCS/pages/2673770514/Servicio+env+o+a+Canal+nico#CanalUnicoUpdateVsegTicketRequest
 */
public with sharing class CanalUnicoUpdateVsegTicketRequest
{
    public CanalUnicoTicket ticket;

    //Para la validacion del campo event
    private static Set<String> availableEventValues
    {
        get
        {
            if (availableEventValues == null)
            {
                List<ZdaCuRequestAvailableEventValues__mdt> availableList = ZdaCuRequestAvailableEventValues__mdt.getAll().values();
                availableEventValues = new Set<String>();
                for (ZdaCuRequestAvailableEventValues__mdt availableValue : availableList)
                {
                    availableEventValues.add(availableValue.Value__c);
                }
            }
            return availableEventValues;
        }
        set;
    }
    //Para la validacion del campo ticketStatus
    private static Set<String> availableTicketStatusValues
    {
        get
        {
            if (availableTicketStatusValues == null)
            {
                List<ZdaCuReqAvailableTicketStatusValues__mdt> availableList = ZdaCuReqAvailableTicketStatusValues__mdt.getAll().values();
                availableTicketStatusValues = new Set<String>();
                for (ZdaCuReqAvailableTicketStatusValues__mdt availableValue : availableList)
                {
                    availableTicketStatusValues.add(availableValue.Value__c);
                }
            }
            return availableTicketStatusValues;
        }
        set;
    }
    //Para la validacion del campo ticketSubStatus
    private static Set<String> availableTicketSubStatusValues
    {
        get
        {
            if (availableTicketSubStatusValues == null)
            {
                List<ZdaCuReqAvailTicketSubStatusValues__mdt> availableList = ZdaCuReqAvailTicketSubStatusValues__mdt.getAll().values();
                availableTicketSubStatusValues = new Set<String>();
                for (ZdaCuReqAvailTicketSubStatusValues__mdt availableValue : availableList)
                {
                    availableTicketSubStatusValues.add(availableValue.Value__c);
                }
            }
            return availableTicketSubStatusValues;
        }
        set;
    }
    //Para la validacion del campo CanalUnicoQuote.paymentType
    private static Set<String> availablePaymentTypeValues
    {
        get
        {
            if (availablePaymentTypeValues == null)
            {
                List<ZdaCuReqAvailPaymentTypeValues__mdt> availableList = ZdaCuReqAvailPaymentTypeValues__mdt.getAll().values();
                availablePaymentTypeValues = new Set<String>();
                for (ZdaCuReqAvailPaymentTypeValues__mdt availableValue : availableList)
                {
                    availablePaymentTypeValues.add(availableValue.Value__c);
                }
            }
            return availablePaymentTypeValues;
        }
        set;
    }
    //Para la validacion del campo eventReason del ticket NO DEL QUOTE
    private static Set<String> availableTicketEventReasonValues
    {
        get
        {
            if (availableTicketEventReasonValues == null)
            {
                List<ZdaCuReqAvailableEventReasonValues__mdt> availableList = ZdaCuReqAvailableEventReasonValues__mdt.getAll().values();
                availableTicketEventReasonValues = new Set<String>();
                for (ZdaCuReqAvailableEventReasonValues__mdt availableValue : availableList)
                {
                    availableTicketEventReasonValues.add(availableValue.Value__c);
                }
            }
            return availableTicketEventReasonValues;
        }
        set;
    }

    //Placeholders para los labels de error
    private static final String FIELD_VALUE_PLACEHOLDER = '#fieldValue#';
    private static final String FIELD_NAME_PLACEHOLDER = '#fieldName#';
    private static final String STR_NULL = 'NULL';

    //Nombres de los campos que se validan
    private static final String FIELD_EVENT = 'event';
    private static final String FIELD_TICKET_STATUS = 'ticketStatus';
    private static final String FIELD_TICKET_SUBSTATUS = 'ticketSubStatus';
    private static final String FIELD_TICKET_EVENT_REASON = 'eventReason';
    private static final String FIELD_PAYMENT_TYPE = 'paymentType';
    private static final String FIELD_DURATION = 'duration';
    private static final String FIELD_ANUAL_NET_PREMIUM = 'anualNetPremium';
    private static final String FIELD_TOTAL_ANUAL_RECEIPT = 'totalAnualReceipt';

    /**
     * Valida el valor de un campo contra la lista de valores validos. En caso de no estar informado
     * o no estar informado con unos de los valores validos posibles, se lanza una IllegalArgumentException
     *
     * @author mario.navarro@seidor.com
     * @date 24/05/2024
     * @param fieldValue valor que contiene el campo a validar
     * @param fieldValidValues Set de strings que contiene los valores validos para el campo
     * @param fieldName nombre del campo que se valida
     */
    private static void validateField(String fieldValue, Set<String> fieldValidValues, String fieldName)
    {
        if ( fieldValue == null || !fieldValidValues.contains(fieldValue) )
        {
            throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace( FIELD_VALUE_PLACEHOLDER, (fieldValue != null ? fieldValue : STR_NULL) ).replace(FIELD_NAME_PLACEHOLDER, fieldName) );
        }
    }

    /**
     * Construye un elemento que contiene una lista de elementos
     *
     * @author mario.navarro@seidor.com
     * @date 24/05/2024
     * @param elemsToBuild lista de elementos a construir
     * @param containerElementName Set de strings que contiene los valores validos para el campo
     * @return el xml construido
     */
    private static String buildElementList(List<IUpdateVsegTicketRequestElem> elemsToBuild, String containerElementName)
    {
        String elem = '';
        if ( !elemsToBuild.isEmpty() )
        {
            elem += '<v1:'+containerElementName+'>';
            for (IUpdateVsegTicketRequestElem elemToBuild: elemsToBuild)
            {
                elem += elemToBuild.buildRequest();
            }
            elem += '</v1:'+containerElementName+'>';
        }

        return elem;
    }

    /**
     * Interfaz para los elementos que componen una peticion al servicio del ESB
     * para comunicarse con Canal unico
     * 
     * @author mario.navarro@seidor.com
     * @date 24/05/2024
     */
    private interface IUpdateVsegTicketRequestElem
    {
        /**
         * Se encarga de construir el cuerpo del xml del elemento en cuestion
         */
        String buildRequest();
    }

    /**
     * Construye el cuerpo de la peticion
     *
     * @author mario.navarro@seidor.com
     * @date 21/03/2024
     * @return retorna el string que contiene el cuerpo de la peticion SOAP
     */
    public String buildRequest()
    {
        String req = '<v1:updateVsegTicketRequest>';
        if (ticket != null)
        {
            req += ticket.buildRequest();
        }
        req += '</v1:updateVsegTicketRequest>';
        return req;
    }

    /**
     * Encapsula los campos del elemento ticket de la peticion
     *
     * @author mario.navarro@seidor.com
     * @date 21/03/2024
     */
    public class CanalUnicoTicket implements IUpdateVsegTicketRequestElem
    {
        /**
         * Identificador del ticket en Canal único
         *
         * Tamaño maximo: 20
         */
        public String ticketId
        {
            get
            {
                return ticketId != null ? ticketId : '';
            }
            set;
        }
        /**
         * Identificador del ticket en SF
         */
        public String externalTicketId
        {
            get
            {
                return externalTicketId != null ? externalTicketId : '';
            }
            set;
        }
        /**
         * Acción que se realiza sobre el ticket. Campo obligatorio. Posibles valores:
         * 1 - Inicio del trámite
         * 2 - Finalización del trámite
         * 3 - Desestimación del trámite
         * 4 - Petición información
         * 5 - Notificación a oficina
         * 6 - Información nueva fecha prevista de cierre
         * 7 - Respuesta a un contactar
         * 8 - Actualización de etapa/sub estado
         * 9 - Mover departamento
         * 10 - Envío documentación
         * 11 - Derivado a Especialista
         */
        public String event;
        /**
         * Estado en el que se encuentra el ticket. Por defecto al crear un ticket nuevo en Canal único, queda guardado como pendiente. Campo obligatorio. Posibles valores:
         * 1 - Pendiente
         * 2 - En tramitación
         * 3 – Tramitado / Finalizado
         * 4 - Desestimado
         * 5 - Pendiente Información
         */
        public String ticketStatus;
        /**
         * Para cada estado se definirán N subestados. En caso de no poder informar el subestado, se informará el siguiente subStatusDesc. Campo obligatorio. Posibles valores:
         * 0 - Sin sub estado
         * 1 - En especialista
         */
        public String ticketSubStatus;
        /**
         * Campo libre para informar la descripción o comentarios del subestado
         *
         * Tamaño maximo: 1000
         */
        public String subStatusDesc
        {
            get
            {
                return subStatusDesc != null ? subStatusDesc : '';
            }
            set;
        }
        /**
         * Técnico que está gestionando el ticket en Hegeo
         *
         * Tamaño maximo: 50
         */
        public String agent
        {
            get
            {
                return agent != null ? agent : '';
            }
            set;
        }
        /**
         * Fecha del evento o cambio de situación. Campo obligatorio
         *
         * Formato: YYYY/MM/dd HH:mm:ss
         */
        public DateTime eventDate = DateTime.now();
        /**
         * Motivo del cambio de situación. Posibles valores:
         * 1 - MFPOtros
         * 2 - MRPOtros
         * 3 - MPI_PetInfo
         */
        public String eventReason;
        /**
         * Descripción del evento o cambio de situación
         *
         * Tamaño máximo: Se ha probado con 10k caracteres y ha funcionado bien, se desconoce el maximo real, puesto que en
         * la documentacion nos indican que el maximo es 1k
         */
        public String eventDesc
        {
            get
            {
                return eventDesc != null ? eventDesc : '';
            }
            set;
        }
        /**
         * Fecha prevista de cierre del ticket
         *
         * Formato: YYYY/MM/dd HH:mm:ss
         */
        public DateTime estimatedEndDate = DateTime.now().addDays(1);
        /**
         * Comentario interno entre primeros niveles de BO
         *
         * Tamaño máximo: Se ha probado con 10k caracteres y ha funcionado bien, se desconoce el maximo real, puesto que en
         * la documentacion nos indican que el maximo es 1k
         */
        public String comments
        {
            get
            {
                return comments != null ? comments : '';
            }
            set;
        }
        /**
         * Lista de cotizaciones. No se enviará nada
         */
        public List<IUpdateVsegTicketRequestElem> quotesList
        {
            get
            {
                return quotesList != null ? quotesList : new List<CanalUnicoQuote>();
            }
            set;
        }
        /**
         * Lista de documentos adjuntos
         */
        public List<IUpdateVsegTicketRequestElem> documentList
        {
            get
            {
                return documentList != null ? documentList : new List<CanalUnicoDocument>();
            }
            set;
        }

        /**
         * Construye el cuerpo de la peticion para el elemento ticket
         *
         * @author mario.navarro@seidor.com
         * @date 21/03/2024
         * @return retorna el string que contiene el cuerpo de la peticion SOAP
         * @throws IllegalArgumentException en caso de que alguno de los campos obligatorios no este informado o su valor no sea valido
         */
        public String buildRequest()
        {
            //Checkeamos campos obligatorios (o invalidos), en caso de faltar alguno, lanzamos excepcion
            validateField(event, availableEventValues, FIELD_EVENT);
            validateField(ticketStatus, availableTicketStatusValues, FIELD_TICKET_STATUS);
            validateField(ticketSubStatus, availableTicketSubStatusValues, FIELD_TICKET_SUBSTATUS);
            
            if ( eventReason != null && !availableTicketEventReasonValues.contains(eventReason) )
            {
                //Si el eventReason esta informado se comprueba que su valor sea valido
                throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace( FIELD_VALUE_PLACEHOLDER, eventReason ).replace(FIELD_NAME_PLACEHOLDER, FIELD_TICKET_EVENT_REASON) );
            }
            String req = '<v1:ticket>';
            req += '<v1:ticketId>' + ticketId + '</v1:ticketId>';
            req += '<v1:externalTicketId>' + externalTicketId + '</v1:externalTicketId>';
            req += '<v1:event>' + event + '</v1:event>';
            req += '<v1:ticketStatus>' + ticketStatus + '</v1:ticketStatus>';
            req += '<v1:ticketSubStatus>' + ticketSubStatus + '</v1:ticketSubStatus>';
            req += '<v1:subStatusDesc>' + subStatusDesc + '</v1:subStatusDesc>';
            req += '<v1:agent>' + agent + '</v1:agent>';
            req += '<v1:eventDate>' + eventDate.format(TicketingHegeoUtil.DATE_TIME_FORMATTER) + '</v1:eventDate>';
            req += '<v1:eventReason>' + (eventReason != null ? eventReason.toString() : '') + '</v1:eventReason>';
            req += '<v1:eventDesc>' + eventDesc + '</v1:eventDesc>';
            req += '<v1:estimatedEndDate>' + estimatedEndDate.format(TicketingHegeoUtil.DATE_TIME_FORMATTER) + '</v1:estimatedEndDate>';
            req += '<v1:comments>' + comments + '</v1:comments>';
            
            req += buildElementList(quotesList, 'quotesList');
            req += buildElementList(documentList, 'documentList');
            
            req += '</v1:ticket>';
            return req;
        }

    }

    public class CanalUnicoQuote implements IUpdateVsegTicketRequestElem
    {
        /**
         * Identificador de la cotización en Hegeo
         */
        public String externalQuoteId
        {
            get
            {
                return externalQuoteId != null ? externalQuoteId : '';
            }
            set;
        }
        /**
         * Alias de la compañía. Por defecto: 'ZURICH'
         *
         * Tamaño máximo: 10
         */
        public String company
        {
            get
            {
                return company != null ? company : '';
            }
            set;
        }
        /**
         * Código de producto
         *
         * Tamaño máximo: 20
         */
        public String modality
        {
            get
            {
                return modality != null ? modality : '';
            }
            set;
        }
        /**
         * Forma de pago asociada a la cotización. Posibles valores:
         * 0 - Única
         * 1 - Anual
         * 2 - Semestral
         * 3 - Cuatrimestral
         * 4 - Trimestral
         * 6 – Bimestral
         * 12 - Mensual
         */
        public String paymentType
        {
            get
            {
                return paymentType != null ? paymentType : '';
            }
            set;
        }
        /**
         * Duración de la póliza. Campo obligatorio
         */
        public DateTime duration;
        /**
         * Valor de la prima neta anual. Campo obligatorio
         */
        public Decimal anualNetPremium;
        /**
         * Valor de la prima total anual. Campo obligatorio
         */
        public Decimal totalAnualReceipt;
        /**
         * Comentarios asociados a la cotización.
         *
         * Tamaño máximo: 1000
         */
        public String comments
        {
            get
            {
                return comments != null ? comments : '';
            }
            set;
        }
        /**
         *
         */
        public String eventReason
        {
            get
            {
                return eventReason != null ? eventReason : '';
            }
            set;
        }
        /**
         *
         */
        public String eventDesc
        {
            get
            {
                return eventDesc != null ? eventDesc : '';
            }
            set;
        }
        /**
         * Lista de documentos adjuntos a la cotización
         */
        public List<IUpdateVsegTicketRequestElem> documentList
        {
            get
            {
                return documentList != null ? documentList : new List<CanalUnicoDocument>();
            }
            set;
        }

        /**
         * Construye el cuerpo de la peticion para el elemento CanalUnicoQuote
         *
         * @author mario.navarro@seidor.com
         * @date 21/03/2024
         * @return retorna el string que contiene el cuerpo de la peticion SOAP
         * @throws IllegalArgumentException en caso de que alguno de los campos obligatorios no este informado
         */
        public String buildRequest()
        {
            //Checkeamos campos obligatorios, en caso de faltar alguno, lanzamos excepcion
            if (duration == null)
            {
                throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace(FIELD_VALUE_PLACEHOLDER, STR_NULL).replace(FIELD_NAME_PLACEHOLDER, FIELD_DURATION) );
            }
            if (anualNetPremium == null)
            {
                throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace(FIELD_VALUE_PLACEHOLDER, STR_NULL).replace(FIELD_NAME_PLACEHOLDER, FIELD_ANUAL_NET_PREMIUM) );
            }
            if (totalAnualReceipt == null)
            {
                throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace(FIELD_VALUE_PLACEHOLDER, STR_NULL).replace(FIELD_NAME_PLACEHOLDER, FIELD_TOTAL_ANUAL_RECEIPT) );
            }
            if ( String.isNotBlank(paymentType) && !availablePaymentTypeValues.contains(paymentType) )
            {
                throw new IllegalArgumentException( Label.ZDAVsegTicketRequestFieldValidationError.replace(FIELD_VALUE_PLACEHOLDER, paymentType).replace(FIELD_NAME_PLACEHOLDER, FIELD_PAYMENT_TYPE) );
            }
            String req = '<v1:quote>';
            req += '<v1:externalQuoteId>' + externalQuoteId + '</v1:externalQuoteId>';
            req += '<v1:company>' + company + '</v1:company>';
            req += '<v1:modality>' + modality + '</v1:modality>';
            req += '<v1:paymentType>' + paymentType + '</v1:paymentType>';
            req += '<v1:duration>' + duration.format(TicketingHegeoUtil.DATE_TIME_FORMATTER) + '</v1:duration>';
            req += '<v1:anualNetPremium>' + anualNetPremium + '</v1:anualNetPremium>'; //ojo formato
            req += '<v1:totalAnualReceipt>' + totalAnualReceipt + '</v1:totalAnualReceipt>'; //ojo formato
            req += '<v1:comments>' + comments + '</v1:comments>';
            req += '<v1:eventReason>' + eventReason + '</v1:eventReason>';
            req += '<v1:eventDesc>' + eventDesc + '</v1:eventDesc>';

            req += buildElementList(documentList, 'documentList');
            
            req += '</v1:quote>';
            return req;
        }
    }

    public class CanalUnicoDocument implements IUpdateVsegTicketRequestElem
    {
        public String documentCode
        {
            get
            {
                return documentCode != null ? documentCode : '';
            }
            set;
        }
        public CanalUnicoAttachedDocument attachedDocument = new CanalUnicoAttachedDocument();

        /**
         * Construye el cuerpo de la peticion para el elemento CanalUnicoDocument
         *
         * @author mario.navarro@seidor.com
         * @date 21/03/2024
         * @return retorna el string que contiene el cuerpo de la peticion SOAP
         */
        public String buildRequest()
        {
            String req = '<v1:document>';
            req += '<v1:documentCode>' + documentCode + '</v1:documentCode>';
            req += attachedDocument.buildRequest();
            req += '</v1:document>';
            return req;
        }
    }

    public class CanalUnicoAttachedDocument implements IUpdateVsegTicketRequestElem
    {
        public String fileName
        {
            get
            {
                return fileName != null ? fileName : '';
            }
            set;
        }
        public String mimeType
        {
            get
            {
                return mimeType != null ? mimeType : '';
            }
            set;
        }
        public String data
        {
            get
            {
                return data != null ? data : '';
            }
            set;
        }
        public String encoding
        {
            get
            {
                return encoding != null ? encoding : '';
            }
            set;
        }

        /**
         * Construye el cuerpo de la peticion para el elemento CanalUnicoAttachedDocument
         *
         * @author mario.navarro@seidor.com
         * @date 21/03/2024
         * @return retorna el string que contiene el cuerpo de la peticion SOAP
         */
        public String buildRequest()
        {
            String req = '<v1:attachedDocument>';
            req += '<v1:fileName>' + fileName + '</v1:fileName>';
            req += '<v1:mimeType>' + mimeType + '</v1:mimeType>';
            req += '<v1:data>' + data + '</v1:data>';
            req += '<v1:encoding>' + encoding + '</v1:encoding>';
            req += '</v1:attachedDocument>';
            return req;
        }
    }
}