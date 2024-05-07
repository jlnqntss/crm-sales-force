/**
 * Clase para gestionar el envio de documentacion a Canal unico
 *
 * @author mario.navarro@seidor.com
 * @date 25/03/2024
 */
public with sharing class SendDocCanalUnicoAction
{

    @InvocableMethod(
        label='Send documentation'
               description='Ejecuta la peticion al ESB para el envio de informacion'
                            category='Other')
    public static void sendDocumentation(List<SendDocCanalUnicoRequest> requestList)
    {
        for (SendDocCanalUnicoRequest req : requestList)
        {
            SendDocCanalUnicoAction.doCallout(req.sendDocObject.Id, req.sendDocObject.CaseId__c, req.sendDocObject.Comments__c, req.sendDocObject.ContentDocIds__c);
        }
    }

    /**
     * Metodo que prepara la peticion de envio de documentacion y realiza la llamada.
     * Se utiliza la anotacion future para poder disponer de mas margen para el envio
     * de documentos (mas ficheros o mas tamaño), ya que de esta manera se dispone del
     * doble de heap (12 MB vs 6 MB en modo sincrono) necesario para poder construir el
     * string que contiene el cuerpo de la peticion
     *
     * @author mario.navarro@seidor.com
     * @date 25/03/2024
     */
    @future(callout=true)
    private static void doCallout(String sendDocObjectId, String caseId, String comments, String contentDocIds)
    {
        List<ContentVersion> fileList = new List<ContentVersion>();
        if ( String.isNotBlank(contentDocIds) )
        {
            //tenemos ficheros adjuntos, los extraemos
            String[] files = contentDocIds.removeStart('[').removeEnd(']').split(',');
            Set<Id> contentDocumentIdToFind = new Set<Id>();
            for (String contentDocId : files)
            {
                contentDocumentIdToFind.add(contentDocId);
            }

            fileList = new ContentVersionSelector().findByContentDocumentId(contentDocumentIdToFind);
        }
        //Obtenemos el caso relacionado con el envio de documentacion
        Case relatedCase = new CasesSelector().getByIdWithZDAInfo(caseId);

        //Se construye la peticion
        CanalUnicoUpdateVsegTicketRequest calloutRequest = new CanalUnicoUpdateVsegTicketRequest();
        calloutRequest.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        calloutRequest.ticket.ticketId = relatedCase.CuTicketId__c;
        calloutRequest.ticket.externalTicketId = '' + relatedCase.CaseNumber;
        calloutRequest.ticket.event = 4; //envio de documentacion, siempre 4
        calloutRequest.ticket.agent = relatedCase.Owner.Name;
        calloutRequest.ticket.eventReason = 2; //OBLIGATORIO
        if ( String.isNotBlank(comments) )
        {
            calloutRequest.ticket.eventDesc = comments;
        }
        calloutRequest.ticket.estimatedEndDate = DateTime.now().addDays(1); //TEMPORAL. POR DEFINIR SLAs
        TicketingHegeoUtil.setStatusSubstatusByCase(calloutRequest, relatedCase);
        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        if ( !fileList.isEmpty() )
        {
            //si hay ficheros a adjuntar, se añaden al objeto request
            String fileMimeType;
            CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument document;
            List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument> attDocList = new List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument>();
            for (ContentVersion file : fileList)
            {
                fileMimeType = TicketingHegeoUtil.MIME_TYPE_EXTENSIONS.get(file.FileExtension);
                if (fileMimeType != null)
                {
                    //El tipo de fichero a adjuntar debe estar permitido, si no está en ese mapa no se puede adjuntar al no poder obtener
                    //el mime type (imprescindible para que en canal unico se pueda visualizar el fichero)
                    document = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument();
                    document.documentCode = file.Title;
                    document.attachedDocument = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoAttachedDocument();
                    document.attachedDocument.fileName = file.PathOnClient;
                    document.attachedDocument.mimeType = fileMimeType;
                    document.attachedDocument.data = EncodingUtil.base64Encode(file.VersionData);
                    document.attachedDocument.encoding = 'UTF-8';
                    attDocList.add(document);

                    //se lincara cada documento enviado con el envio para saber que ficheros se enviaron
                    linksToCreate.add(
                        new ContentDocumentLink(
                            ContentDocumentId = file.ContentDocumentId,
                            LinkedEntityId = sendDocObjectId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                            )
                        );
                }
            }
            calloutRequest.ticket.documentList = attDocList;
        }

        String sendResult = TicketingHegeoService.updateVsegTicket(calloutRequest);
        if ( 'KO'.equals(sendResult) )
        {
            sendResult = 'Se ha producido un error en el envío, consultar log de errores';
        }
        //Actualizar Result__c
        SendDocCUInfo__c sendObj = new SendDocCUInfo__c(
            Id = sendDocObjectId,
            Result__c = sendResult,
            SendDate__c = DateTime.now()
            );
        update sendObj;
        insert linksToCreate;
    }

    public class SendDocCanalUnicoRequest
    {
        @InvocableVariable(
            label='SendObject'
                   description='Objeto que contiene la informacion relativa al envio. Se actualizara con el resultado del callout'
                                required=true)
        public SendDocCUInfo__c sendDocObject;
    }
}