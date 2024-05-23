/**
 * Clase de utilidades para el servicio de comunicacion con el ESB de Banc Sabadell
 * 
 * @author mario.navarro@seidor.com
 * @date 05/04/2024
 */
public with sharing class TicketingHegeoUtil
{
    //formateador para las fechas que se envian por el servicio
    public static final String DATE_TIME_FORMATTER = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
    private static final String STATUS_PENDIENTE = 'Pendiente';
    private static final String STATUS_TRAMITACION = 'EnTramitacion';
    private static final String STATUS_CERRADO = 'TramitadoFinalizado';
    private static final String STATUS_PENDIENTE_INFO = 'PendienteInformacion';
    private static final String SUBSTATUS_SIN = 'SinSubestado';
    private static final String SUBSTATUS_ESPECIALISTA = 'EnEspecialista';
    private static final String STR_PENDIENTE_DE = 'Pendiente de ';

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
        switch on c.Status
        {
            when  'Nuevo'
            {
                //Pendiente
                request.ticket.ticketStatus = ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_PENDIENTE)?.Value__c;
            }
            when  'Asignado', 'Respondido'
            {
                //En tramitacion
                request.ticket.ticketStatus = ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_TRAMITACION)?.Value__c;
            }
            when  'Cerrado'
            {
                //De momento no podemos mirar motivos de cierre, estan por definir
                //Cerrado (no hay desestimado por el momento)
                request.ticket.ticketStatus = ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_CERRADO)?.Value__c;
            }
            when else
            {
                //Pendiente informacion (Pendiente soporte o supervisor)
                request.ticket.ticketStatus = ZdaCuReqAvailableTicketStatusValues__mdt.getInstance(STATUS_PENDIENTE_INFO)?.Value__c;
                if (c.PendingBy__c == CaseUtil.PENDING_BY_SUPPORT || c.PendingBy__c == CaseUtil.PENDING_BY_SUPERVISOR)
                {
                    request.ticket.ticketSubStatus = ZdaCuReqAvailTicketSubStatusValues__mdt.getInstance(SUBSTATUS_ESPECIALISTA)?.Value__c;
                }
                request.ticket.subStatusDesc = STR_PENDIENTE_DE+c.PendingBy__c;
            }
        }
        
    }
}