/**
 *
 * @author rlopez
 * @date 26/01/2021
 */
public class ContentDocumentLinkUtil
{
    public static Integer CASE_FIELDS_CSV_INDEX = 0;
    public static Integer FROM_ADDRESS_CSV_INDEX = 1;
    public static Integer TO_ADDRESS_CSV_INDEX = 2;

    public static String SEPARATOR = ',';

    public static List<String> CASE_FIELDS = new List<String>();

    public static Robot_Hegeo_Setting__mdt currentSettings = new Robot_Hegeo_Setting__mdt();

    public static Map<Id, EmailMessage> relatedEmailMessages = new Map<Id, EmailMessage>();
    public static Map<Id, Case> relatedCases = new Map<Id, Case>();
    public static Map<Id, EmailMessage> caseToEmailMap = new Map<Id, EmailMessage>();
    public static Map<Id, ContentDocumentLink> emailToDocumentMap = new Map<Id, ContentDocumentLink>();
    public static Map<Id, EmailMessage> documentToEmailMap = new Map<Id, EmailMessage>();

    public static Map<Id,ContentDocument> contentDocumentInformationMap = new Map<Id,ContentDocument>();

    public static List<EmailMessage> emailMessagesToUpdate = new List<EmailMessage>();
    public static List<Case> casesToUpdate = new List<Case>();

    private static void initSettings()
    {
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c
            FROM Robot_Hegeo_Setting__mdt
        ];

        if(!robotHegeoSettings.isEmpty())
        {
            CASE_FIELDS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).CaseFieldsIndex__c);
            FROM_ADDRESS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).FromAddressIndex__c);
            TO_ADDRESS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).ToAddressIndex__c);

            SEPARATOR = robotHegeoSettings.get(0).Separator__c;

            CASE_FIELDS = robotHegeoSettings.get(0).CaseFields__c.split(SEPARATOR);
        }
    }

    /**
     * Método que recupera los EmailMessages en los que viene adjunto el documento
     *
     * @author rlopez
     * @date 26/01/2021
     */
    public static void getRelatedEmailMessages(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap)
    {
        System.debug('getRelatedEmailMessages');

        initSettings();
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

            /*contentDocumentInformationMap = new Map<Id,ContentDocumentLink>(
                [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.FileExtension, ContentDocument.FileType, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FirstPublishLocationId FROM ContentDocumentLink WHERE ContentDocument.Id IN: contentDocumentIds]
            );*/

            Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([
                SELECT Id, Title, LatestPublishedVersion.VersionData 
                FROM ContentDocument
                WHERE Title = 'HEGEO-CLASIFICACION' AND FileExtension = 'csv' AND Id IN: contentDocumentIds
            ]);

            for(ContentDocumentLink cdl: newList)
            {
                if(contentDocuments.containsKey(cdl.ContentDocumentId))
                {
                    contentDocumentInformationMap.put(cdl.Id, contentDocuments.get(cdl.ContentDocumentId));
                }
            }

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
                setRelatedEmailMessageAndCase(docLink);
            }
        }
    }

    private static void setRelatedEmailMessageAndCase(ContentDocumentLink docInformation)
    {
        
        if(contentDocumentInformationMap.containsKey(docInformation.Id) && contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion != null 
        && contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion.VersionData != null)
        {
            if(relatedEmailMessages.containsKey(docInformation.LinkedEntityId))
            {
                //1. Actualizamos fromAddress y toAddress del EmailMessage
                EmailMessage relatedEmail = relatedEmailMessages.get(docInformation.LinkedEntityId);

                String csvAsString = contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion.VersionData.toString();
                List<String> csvFileLines = csvAsString.split('\n');
                /*for(Integer i=0; i < csvFileLines.size(); i++){
                    System.debug('csvFileLines' + i + ': ' + csvFileLines[i]);
                }*/

                String fromAddress = '';
                String toAddress = '';

                if(csvFileLines.size() > 2)
                {
                    if(String.isNotBlank(csvFileLines.get(FROM_ADDRESS_CSV_INDEX)))
                    {
                        String fromAddressFromCSV = csvFileLines.get(FROM_ADDRESS_CSV_INDEX).trim();
                        if(fromAddressFromCSV.contains('<'))
                        {
                            fromAddress = fromAddressFromCSV.substring(0,fromAddressFromCSV.length()-1).substringAfter('<');
                        }
                        System.debug('from: ' + fromAddress);
                    }

                    if(String.isNotBlank(csvFileLines.get(TO_ADDRESS_CSV_INDEX)))
                    {
                        String toAddressFromCSV = csvFileLines.get(TO_ADDRESS_CSV_INDEX).trim();
                        if(toAddress.contains('<'))
                        {
                            toAddress = toAddressFromCSV.substring(0,toAddressFromCSV.length()-1).substringAfter('<');
                        }
                        System.debug('to: ' + toAddress);
                    }

                    if(String.isNotBlank(fromAddress))
                    {
                        relatedEmail.FromAddress = fromAddress;
                    }

                    if(String.isNotBlank(toAddress))
                    {
                        relatedEmail.ToAddress = toAddress;
                    }

                    emailMessagesToUpdate.add(relatedEmail);

                    //2. Actualizamos los campos correspondientes al caso
                    if(relatedEmail.ParentId != null && relatedCases.containsKey(relatedEmail.ParentId))
                    {
                        Case relatedCase = relatedCases.get(relatedEmail.ParentId);
                        List<String> types = csvFileLines.get(CASE_FIELDS_CSV_INDEX).trim().split(SEPARATOR);

                        System.debug('types: ' + types);
                        System.debug('types.isEmpty(): ' + types.isEmpty());

                        if (!types.isEmpty()) 
                        {
                            Map<String, String> caseFieldsMap = new Map<String, String>{
                                'Id' => relatedCases.get(relatedEmail.ParentId).Id
                            };

                            for(Integer i=0; i<CASE_FIELDS.size(); i++)
                            {
                                if(i<types.size() && String.isNotBlank(types.get(i)))
                                {
                                    System.debug('types.get(i): ' + types.get(i));
                                    caseFieldsMap.put(CASE_FIELDS.get(i), types.get(i));
                                }
                            }

                            System.debug('caseFieldsMap: ' + caseFieldsMap);

                            casesToUpdate.add((Case) JSON.deserialize(
                                JSON.serialize(caseFieldsMap), Case.class)
                            );
                        }
                    }
                }
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