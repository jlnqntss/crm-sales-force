/**
 * Accion invocable que ejecuta la logica de envio de peticiones al ESB de Banc Sabadell para
 * la comunicacion con Canal Unico, para la gestion de los tiquets generados alli y enviados
 * mediante API estandar a Salesforce
 *
 * @author mario.navarro@seidor.com
 * @date 23/04/2024
 */
public with sharing class TicketingHegeoAction
{
    private static Map<Id, List<ContentVersion> > cvByContendDocId;

    @InvocableMethod(
        label='Do callout'
               description='Ejecuta la peticion al ESB para el envio de informacion'
                            category='Other')
    public static List<String> doCallout(List<TicketingHegeoRequest> requestList)
    {
        //primero agrupamos los content document id para buscarlos todos de golpe
        Set<Id> contentDocumentIdToFind = new Set<Id>();
        for (TicketingHegeoRequest req : requestList)
        {
            if ( req.contentDocumentIdList != null && !req.contentDocumentIdList.isEmpty() )
            {
                for (String contentDocId : req.contentDocumentIdList)
                {
                    contentDocumentIdToFind.add(contentDocId);
                }
            }
        }
        List<ContentVersion> foundList = new ContentVersionSelector().findByContentDocumentId(contentDocumentIdToFind);
        cvByContendDocId = (Map<Id, List<ContentVersion> >) CollectionUtil.groupListBy( foundList, ContentVersion.fields.ContentDocumentId.getDescribe().getName() );

        List<String> calloutResultList = new List<String>();
        CanalUnicoUpdateVsegTicketRequest calloutRequest;
        String response;

        for (TicketingHegeoRequest req : requestList)
        {
            calloutRequest = new CanalUnicoUpdateVsegTicketRequest();
            calloutRequest.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
            calloutRequest.ticket.ticketId = '' + req.relatedCase.TicketId__c;
            calloutRequest.ticket.externalTicketId = '' + req.relatedCase.CaseNumber;
            calloutRequest.ticket.event = req.event;
            calloutRequest.ticket.agent = req.relatedCase.Owner.Name;
            calloutRequest.ticket.eventReason = 2; //OBLIGATORIO
            if ( String.isNotBlank(req.comments) )
            {
                calloutRequest.ticket.eventDesc = req.comments;
            }
            calloutRequest.ticket.estimatedEndDate = DateTime.now().addDays(1); //TEMPORAL. POR DEFINIR SLAs
            TicketingHegeoUtil.setStatusSubstatusByCase(calloutRequest, req.relatedCase);
            attachFiles(calloutRequest, req);

            response = TicketingHegeoService.updateVsegTicket(calloutRequest);
            calloutResultList.add(response);
        }

        return calloutResultList;
    }

    /**
     * Adjunta los ficheros que tuviera la peticion al objeto calloutRequest
     *
     * @author mario.navarro@seidor.com
     * @date 23/04/2024
     * @param calloutRequest objeto al que se le adjuntaran los archivos
     * @param req objeto peticion recibida desde el flow que contiene los identificadores de los documentos a adjuntar
     */
    private static void attachFiles(CanalUnicoUpdateVsegTicketRequest calloutRequest, TicketingHegeoRequest req)
    {
        if ( req.contentDocumentIdList == null || req.contentDocumentIdList.isEmpty() )
        {
            return;
        }
        ContentVersion cvToAttach;
        List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument> attDocList = new List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument>();
        CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument document;
        CanalUnicoUpdateVsegTicketRequest.CanalUnicoAttachedDocument attachedDocument;
        String fileMimeType;
        for (String contentDocId : req.contentDocumentIdList)
        {
            if ( cvByContendDocId.containsKey(contentDocId) )
            {
                cvToAttach = cvByContendDocId.get(contentDocId)[0];
                fileMimeType = TicketingHegeoUtil.MIME_TYPE_EXTENSIONS.get(cvToAttach.FileExtension);
                if (fileMimeType != null)
                {
                    //El tipo de fichero a adjuntar debe estar permitido, si no está en ese mapa no se puede adjuntar al no poder obtener
                    //el mime type (imprescindible para que en canal unico se pueda visualizar el fichero)
                    document = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument();
                    document.documentCode = cvToAttach.Title;
                    document.attachedDocument = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoAttachedDocument();
                    document.attachedDocument.fileName = cvToAttach.PathOnClient;
                    document.attachedDocument.mimeType = fileMimeType;
                    document.attachedDocument.data = EncodingUtil.base64Encode(cvToAttach.VersionData);
                    document.attachedDocument.encoding = 'UTF-8';
                    attDocList.add(document);
                }
            }
        }
        calloutRequest.ticket.documentList = attDocList;
    }

    public class TicketingHegeoRequest
    {
        @InvocableVariable(
            label='Related case'
                   description='Caso relacionado con el envio que se va a realizar'
                                required=true)
        public Case relatedCase;
        @InvocableVariable(
            label='Event'
                   description='Tipo de evento. Tipos disponibles en la clase apex: CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket.event'
                                required=true)
        public Integer event;
        @InvocableVariable(
            label='Document list'
                   description='Lista de content document id que adjuntar a la peticion')
        public List<String> contentDocumentIdList;
        @InvocableVariable(
            label='Comments'
                   description='Comentarios a adjuntar en el envio')
        public String comments;
    }

}