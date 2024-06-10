/**
 * Clase de utilidades para el servicio de comunicacion con el ESB de Banc Sabadell
 * 
 * @author mario.navarro@seidor.com
 * @date 05/04/2024
 */
public with sharing class TicketingHegeoUtil
{
    //formateador para las fechas que se envian por el servicio
    public static final String DATE_TIME_FORMATTER
    {
        get
        {
            if (DATE_TIME_FORMATTER == null)
            {
                List<ZDAUpdateRequestTimeFormat__mdt> availableList = ZDAUpdateRequestTimeFormat__mdt.getAll().values();
                DATE_TIME_FORMATTER = availableList[0].Format__c;
                
            }
            return DATE_TIME_FORMATTER;
        }
        set;
    }

    private static final String STATUS_PENDIENTE = 'Pendiente';
    private static final String STATUS_TRAMITACION = 'EnTramitacion';
    private static final String STATUS_CERRADO = 'TramitadoFinalizado';
    private static final String STATUS_PENDIENTE_INFO = 'PendienteInformacion';
    private static final String SUBSTATUS_SIN = 'SinSubestado';
    private static final String SUBSTATUS_ESPECIALISTA = 'EnEspecialista';
    private static final String STR_PENDIENTE_DE = 'Pendiente de ';
    private static final String EVENT_INICIO_TRAMITE = 'InicioTramite';
    private static final String EVENT_REASON_OTROS = 'MRPOtros';

    private static final Map<String, String> caseStatusCuStatusRelationship = new Map<String, String>
    {
        CaseUtil.CASE_NUEVO => ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_PENDIENTE)?.Value__c,
        CaseUtil.CASE_ASIGNADO => ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_TRAMITACION)?.Value__c,
        CaseUtil.CASE_RESPONDIDO => ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_TRAMITACION)?.Value__c,
        CaseUtil.estadoCerrado => ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_CERRADO)?.Value__c
    };

    //Relacion entre los ficheros admitidos para los envios y su extension. Necesario
    //para adjuntarlo en el campo mimeType para los ficheros adjuntos
    public static final Map<String, String> MIME_TYPE_EXTENSIONS
    {
        get
        {
            if (MIME_TYPE_EXTENSIONS == null)
            {
                List<FileMimeType__mdt> fileMimeList = FileMimeType__mdt.getAll().values();
                MIME_TYPE_EXTENSIONS = new Map<String, String>();
                for (FileMimeType__mdt fileMime : fileMimeList)
                {
                    if (fileMime.AllowedInZDA__c)
                    {
                        MIME_TYPE_EXTENSIONS.put(fileMime.Label, fileMime.MimeType__c);
                    }
                }
            }
            return MIME_TYPE_EXTENSIONS;
        }
        set;
    }

    /**
     * Establece los campos ticketStatus, ticketSubStatus y subStatusDesc del objeto request en funcion
     * del estado proporcionado por el caso.
     * PRECONDICION: El objeto request y el request.ticket deben estar inicializados
     * 
     * El campo ticketStatus puede tener los siguientes valores:
     * 1 - Pendiente
     * 2 - En tramitacion
     * 3 – Tramitado / Finalizado
     * 4 - Desestimado
     * 5 - Pendiente Informacion
     * 
     * Y el campo substatus:
     * 0 - Sin sub estado
     * 1 - En especialista
     * 
     * Para el caso de ZDA tenemos los siguientes status:
     * A - Nuevo
     * B - Asignado
     * C - Cerrado
     * D - Pendiente (con pending by: )
     * E - Respondido
     * F - Cerrado sin respuesta (solo aplica a los casos recibidos via email, que no realizaran llamadas a ESB)
     * 
     * La relacion entre los estados de SF y la que enviemos sera la siguiente:
     * Nuevo ==> Pendiente
     * Asignado ==> En tramitacion
     * Cerrado ==> Segun el motivo de cierre, sera 'Tramitado / Finalizado' o Desestimado
     * Respondido ==> En tramitacion
     * 
     * @author mario.navarro@seidor.com
     * @date 05/04/2024
     * @param request Objeto request al que setear los campos ticketStatus y ticketSubStatus
     * @param c Objeto caso a partir del cual se informaran los campos en el objeto request
     */
    public static void setStatusSubstatusByCase(CanalUnicoUpdateVsegTicketRequest request, Case c)
    {
        request.ticket.ticketSubStatus = ZdaCuReqAvailTicketSubStatusValues__mdt.getInstance(SUBSTATUS_SIN)?.Value__c;
        request.ticket.ticketStatus = caseStatusCuStatusRelationship.get(c.Status);
        if (request.ticket.ticketStatus == null)
        {
            //Pendiente informacion (Pendiente soporte o supervisor)
            request.ticket.ticketStatus = ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_PENDIENTE_INFO)?.Value__c;
            if (c.PendingBy__c == CaseUtil.CASE_PENDIENTE_SOPORTE || c.PendingBy__c == CaseUtil.CASE_PENDIENTE_SUPERVISOR)
            {
                request.ticket.ticketSubStatus = ZdaCuReqAvailTicketSubStatusValues__mdt.getInstance(SUBSTATUS_ESPECIALISTA)?.Value__c;
            }
            request.ticket.subStatusDesc = STR_PENDIENTE_DE+c.PendingBy__c;
        }
        
    }

    /**
     * Envia una peticion para a canal unico conforme el status de un caso ha
     * cambiado a Asignado (En tramite para ellos)
     * 
     * @author mario.navarro@seidor.com
     * @date 30/05/2024
     * @param relatedCase caso relacionado con la peticion a enviar
     * @return CanalUnicoUpdateVsegTicketRequest objeto request construido
     */
    @future(callout=true)
    public static void sendRequestStatusChangeToAssigned(Id relatedCaseId)
    {
        Case relatedCase = new CasesSelector().getByIdWithZDAInfo(relatedCaseId);
        CanalUnicoUpdateVsegTicketRequest calloutRequest = createBaseRequestByCase(relatedCase);
        calloutRequest.ticket.event = ZdaCuRequestAvailableEventValues__mdt.getInstance(EVENT_INICIO_TRAMITE)?.Value__c;

        TicketingHegeoService.updateVsegTicket(calloutRequest);
    }

    /**
     * Crea una peticion para enviar a canal unico con los que se rellenan a partir de la informacion
     * del caso relacionado. A ESTE OBJETO AUN FALTARA POR INFORMAR EL CAMPO calloutRequest.ticket.event
     * 
     * @author mario.navarro@seidor.com
     * @date 30/05/2024
     * @param relatedCase caso relacionado con la peticion a enviar
     * @return CanalUnicoUpdateVsegTicketRequest objeto request construido
     */
    public static CanalUnicoUpdateVsegTicketRequest createBaseRequestByCase(Case relatedCase)
    {
        CanalUnicoUpdateVsegTicketRequest calloutRequest = new CanalUnicoUpdateVsegTicketRequest();
        calloutRequest.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        calloutRequest.ticket.ticketId = relatedCase.CuTicketId__c;
        calloutRequest.ticket.externalTicketId = '' + relatedCase.CaseNumber;
        setStatusSubstatusByCase(calloutRequest, relatedCase);
        calloutRequest.ticket.agent = relatedCase.Owner.Name;
        calloutRequest.ticket.eventReason = ZdaCuReqAvailableEventReasonValues__mdt.getInstance(EVENT_REASON_OTROS)?.Value__c;

        return calloutRequest;
    }
}