/**
 * Clase para gestionar el envio de documentacion a Canal unico
 *
 * @author mario.navarro@seidor.com
 * @date 25/03/2024
 */
public with sharing class SendDocCanalUnicoAction
{

    private static final String UTF_8_ENCODING = 'UTF-8';
    private static final String V_SHARE_TYPE = 'V';
    private static final String ALL_USERS_VISIBILITY = 'AllUsers';
    private static final String KO = 'KO';
    private static final String EVENT_PETICION_INFO = 'PeticionInfo';

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
        List<ContentVersion> fileList = retrieveFiles(contentDocIds);
        //Obtenemos el caso relacionado con el envio de documentacion
        Case relatedCase = new CasesSelector().getByIdWithZDAInfo(caseId);

        //Se construye la peticion
        CanalUnicoUpdateVsegTicketRequest calloutRequest = TicketingHegeoUtil.createBaseRequestByCase(relatedCase);
        calloutRequest.ticket.event = ZdaCuRequestAvailableEventValues__mdt.getInstance(EVENT_PETICION_INFO)?.Value__c; //envio de documentacion, siempre 4
        if ( String.isNotBlank(comments) )
        {
            calloutRequest.ticket.eventDesc = comments;
        }
        //TicketingHegeoUtil.setStatusSubstatusByCase(calloutRequest, relatedCase);
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
                    document.attachedDocument.encoding = UTF_8_ENCODING;
                    attDocList.add(document);

                    //se lincara cada documento enviado con el envio para saber que ficheros se enviaron
                    linksToCreate.add(
                        new ContentDocumentLink(
                            ContentDocumentId = file.ContentDocumentId,
                            LinkedEntityId = sendDocObjectId,
                            ShareType = V_SHARE_TYPE,
                            Visibility = ALL_USERS_VISIBILITY
                            )
                        );
                }
            }
            calloutRequest.ticket.documentList = attDocList;
        }

        String sendResult = TicketingHegeoService.updateVsegTicket(calloutRequest);
        if ( KO.equals(sendResult) )
        {
            sendResult = Label.ZDAVsegTicketRequestError;
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

    /**
     * Metodo que obtiene la lista de ficheros adjuntos del objeto SendDocCUInfo__c, informado en el campo
     * ContentDocIds__c. Este campo esta informado con un valor con la siguiente estructura: [id1,id2,idN].
     * Lo que hacemos es quitar los corchetes y realizar un split por las comas, para obtener de bdd los
     * ficheros
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     * @param contentDocIds string con los identificadores de los ficheros
     * @return lista de objetos a los que pertenecen los ids del string de entrada. Retornara una lista vacia
     * si el campo de entrada esta vacio o con un valor de '[]'
     */
    private static List<ContentVersion> retrieveFiles(String contentDocIds)
    {
        List<ContentVersion> fileList = new List<ContentVersion>();
        if ( String.isNotBlank(contentDocIds) && !'[]'.equals(contentDocIds) )
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

        return fileList;
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