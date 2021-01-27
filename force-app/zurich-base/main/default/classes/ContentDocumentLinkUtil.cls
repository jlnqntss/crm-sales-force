/**
 *
 * @author rlopez
 * @date 26/01/2021
 */
public class ContentDocumentLinkUtil
{
    public static final Integer CASE_FIELDS_CSV_INDEX = 0;
    public static final Integer FROM_ADDRESS_CSV_INDEX = 1;
    public static final Integer TO_ADDRESS_CSV_INDEX = 2;

    public static Map<Id, EmailMessage> relatedEmailMessages = new Map<Id, EmailMessage>();
    public static Map<Id, Case> relatedCases = new Map<Id, Case>();
    public static Map<Id, EmailMessage> caseToEmailMap = new Map<Id, EmailMessage>();
    public static Map<Id, ContentDocumentLink> emailToDocumentMap = new Map<Id, ContentDocumentLink>();
    public static Map<Id, EmailMessage> documentToEmailMap = new Map<Id, EmailMessage>();

    public static Map<Id,ContentDocumentLink> contentDocumentInformationMap = new Map<Id,ContentDocumentLink>();

    public static List<EmailMessage> emailMessagesToUpdate = new List<EmailMessage>();
    public static List<Case> casesToUpdate = new List<Case>();
    /**
     * Método que recupera los EmailMessages en los que viene adjunto el documento
     *
     * @author rlopez
     * @date 26/01/2021
     */
    public static void getRelatedEmailMessages(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap)
    {
        Map<Id, ContentDocumentLink> linkedEntityToDocumentMap = new Map<Id, ContentDocumentLink>();

        for(ContentDocumentLink docLink: newList)
        {
            linkedEntityToDocumentMap.put(docLink.LinkedEntityId, docLink);
        }

        //Recuperamos los emails en los que hemos recibido los documentos adjuntos
        relatedEmailMessages = new Map<Id, EmailMessage>(
            [SELECT Id, Subject, CreatedDate, ParentId FROM EmailMessage WHERE Id IN: linkedEntityToDocumentMap.keySet()]
        );

        if(!relatedEmailMessages.isEmpty())
        {
            Set<Id> contentDocumentIds = new Set<Id>();
            for(EmailMessage relatedEmail: relatedEmailMessages.values())
            {
                if(linkedEntityToDocumentMap.containsKey(relatedEmail.Id))
                {
                    //Es Email
                    emailToDocumentMap.put(relatedEmail.Id, linkedEntityToDocumentMap.get(relatedEmail.Id));
                    caseToEmailMap.put(relatedEmail.ParentId, relatedEmail);

                    documentToEmailMap.put(linkedEntityToDocumentMap.get(relatedEmail.Id).Id, relatedEmail);

                    contentDocumentIds.add(linkedEntityToDocumentMap.get(relatedEmail.Id).ContentDocumentId);
                }
            }

            /*List<ContentVersion> contentVersionList = [SELECT Id, Title, VersionData, ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId IN: contentDocumentIds];// AND Title = 'HEGEO-CLASIFICACION'
            LatestPublishedVersionId AND ContentDocument.Title = 'HEGEO-CLASIFICACION'*/ 

            contentDocumentInformationMap = new Map<Id,ContentDocumentLink>(
                [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FirstPublishLocationId FROM ContentDocumentLink WHERE ContentDocumentId IN: contentDocumentIds]
            );

            relatedCases = new Map<Id, Case>(
                [SELECT Id FROM Case WHERE Id IN: caseToEmailMap.keySet()]
            );
        }
    }

    public static void setFromAndToEmailAddresses(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap)
    {
        for(ContentDocumentLink docLink: newList)
        {
            if(contentDocumentInformationMap.containsKey(docLink.Id))
            {
                setEmailAddresses(docLink);
            }
        }
    }

    private static void setEmailAddresses(ContentDocumentLink docInformation)
    {
        if(relatedEmailMessages.containsKey(docInformation.LinkedEntityId))
        {
            EmailMessage relatedEmail = relatedEmailMessages.get(docInformation.LinkedEntityId);

            String csvAsString = contentDocumentInformationMap.get(docInformation.Id).ContentDocument.LatestPublishedVersion.VersionData.toString();
            List<String> csvFileLines = csvAsString.split('\n');
            /*for(Integer i=0; i < csvFileLines.size(); i++){
                System.debug('csvFileLines' + i + ': ' + csvFileLines[i]);
            }*/

            String fromAddress = '';
            String toAddress = '';

            if(String.isNotBlank(csvFileLines.get(FROM_ADDRESS_CSV_INDEX)))
            {
                String fromAddressFromCSV = csvFileLines.get(FROM_ADDRESS_CSV_INDEX).trim();
                fromAddress = fromAddressFromCSV.substring(0,fromAddressFromCSV.length()-1).substringAfter('<');
            }

            if(String.isNotBlank(csvFileLines.get(TO_ADDRESS_CSV_INDEX)))
            {
                String toAddressFromCSV = csvFileLines.get(TO_ADDRESS_CSV_INDEX).trim();
                toAddress = toAddressFromCSV.substring(0,toAddressFromCSV.length()-1).substringAfter('<');
            }

            if(String.isNotBlank(fromAddress))
            {
                relatedEmail.FromAddress = fromAddress;
            }

            if(String.isNotBlank(toAddress))
            {
                relatedEmail.ToAddress = toAddress;
            }

            if(relatedEmail.FromAddress != fromAddress || relatedEmail.ToAddress != toAddress)
            {
                emailMessagesToUpdate.add(relatedEmail);
            }

            if(relatedEmail.ParentId != null && relatedCases.containsKey(relatedEmail.ParentId))
            {
                Case relatedCase = relatedCases.get(relatedEmail.ParentId);
                //TODO: Modificar campos del caso
                List<String> types = csvFileLines.get(CASE_FIELDS_CSV_INDEX).trim().split(',');
                if(String.isNotBlank(types.get(0)))
                {
                    relatedCase.Type = types.get(0);
                }

                casesToUpdate.add(relatedCase);
            }
        }
    }

    public static void updateRelatedRecords()
    {
        if(!emailMessagesToUpdate.isEmpty())
        {
            update emailMessagesToUpdate;
        }

        if(!casesToUpdate.isEmpty())
        {
            update casesToUpdate;
        }
    }
}