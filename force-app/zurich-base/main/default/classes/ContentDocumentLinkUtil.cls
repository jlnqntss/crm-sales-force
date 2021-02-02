/**
 *
 * @author rlopez
 * @date 26/01/2021
 */
public without sharing class ContentDocumentLinkUtil
{
    public static Integer CASE_FIELDS_CSV_INDEX = 0;
    public static Integer FROM_ADDRESS_CSV_INDEX = 1;
    public static Integer TO_ADDRESS_CSV_INDEX = 2;

    public static String csvSeparator = ';';

    public static List<String> caseFieldsList = new List<String>();

    public static Boolean isActiveTrigger = false;
    public static String documentTitle = 'HEGEO-CLASIFICACION';
    public static String fileExtension = 'csv';

    public static Map<String, Map<String, String>> caseTypesMapping = new Map<String, Map<String, String>>();
    public static List<String> caseRecordTypeNames = new List<String>{};

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
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c
            FROM Robot_Hegeo_Setting__mdt
        ];

        if(!robotHegeoSettings.isEmpty())
        {
            CASE_FIELDS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).CaseFieldsIndex__c);
            FROM_ADDRESS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).FromAddressIndex__c);
            TO_ADDRESS_CSV_INDEX = Integer.valueOf(robotHegeoSettings.get(0).ToAddressIndex__c);

            csvSeparator = robotHegeoSettings.get(0).Separator__c;

            if(robotHegeoSettings.get(0).CaseFields__c != null)
            {
                caseFieldsList = robotHegeoSettings.get(0).CaseFields__c.split(',');   
            }

            if(robotHegeoSettings.get(0).CaseRecordTypeNames__c != null)
            {
                caseRecordTypeNames = robotHegeoSettings.get(0).CaseRecordTypeNames__c.split(',');
            }

            isActiveTrigger = robotHegeoSettings.get(0).isActive__c;
            documentTitle = robotHegeoSettings.get(0).DocumentTitle__c;
            fileExtension = robotHegeoSettings.get(0).FileExtension__c;
        }

        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = [
            SELECT Id, Level__c, SourceValue__c, SalesforceValue__c
            FROM Robot_Hegeo_Field_Mapping__mdt
        ];

        if(!robotHegeoFieldsMapping.isEmpty())
        {
            for(Robot_Hegeo_Field_Mapping__mdt fieldMapping: robotHegeoFieldsMapping)
            {
                Map<String, String> valuesMap = new Map<String, String>();
                if(caseTypesMapping.containsKey(fieldMapping.Level__c))
                {
                    valuesMap = caseTypesMapping.get(fieldMapping.Level__c);
                }
                
                valuesMap.put(fieldMapping.SourceValue__c, fieldMapping.SalesforceValue__c);
                caseTypesMapping.put(fieldMapping.Level__c, valuesMap);
            }

            System.debug('caseTypesMapping: ' + caseTypesMapping);
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
        System.debug(newList);

        initSettings();

        if(isActiveTrigger)
        {
            Map<Id, ContentDocumentLink> linkedEntityToDocumentMap = new Map<Id, ContentDocumentLink>();

            for(ContentDocumentLink docLink: newList)
            {
                linkedEntityToDocumentMap.put(docLink.LinkedEntityId, docLink);
            }

            //Recuperamos los emails en los que hemos recibido los documentos adjuntos
            Set<Id> caseRecordTypeIds = new Set<Id>();
            for(String recordTypeName: caseRecordTypeNames)
            {
                caseRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId());
            }
            relatedEmailMessages = new Map<Id, EmailMessage>(
                [SELECT Id, Subject, CreatedDate, ParentId FROM EmailMessage WHERE Id IN: linkedEntityToDocumentMap.keySet() AND Parent.RecordTypeId IN: caseRecordTypeIds]
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
                    WHERE Title =: documentTitle AND FileExtension =: fileExtension AND Id IN: contentDocumentIds
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
        //Solo procesamos si hemos encontrado información relacionada con el ContentDocument
        if( contentDocumentInformationMap.containsKey(docInformation.Id) && contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion != null 
            && contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion.VersionData != null )
        {
            if(relatedEmailMessages.containsKey(docInformation.LinkedEntityId))
            {
                //1. Actualizamos fromAddress y toAddress del EmailMessage
                EmailMessage relatedEmail = relatedEmailMessages.get(docInformation.LinkedEntityId);

                //Recuperamos los datos del csv y dividimos por cada línea que contiene el documento
                String csvAsString = contentDocumentInformationMap.get(docInformation.Id).LatestPublishedVersion.VersionData.toString();
                List<String> csvFileLines = csvAsString.split('\n');

                String fromAddress = '';
                String toAddress = '';

                //Si existen más de 2 líneas (0: tipificación del caso, 1: from, 2: to)
                if(csvFileLines.size() > 2)
                {
                    //Extraemos el email fromAddress
                    if(String.isNotBlank(csvFileLines.get(FROM_ADDRESS_CSV_INDEX)))
                    {
                        String fromAddressFromCSV = csvFileLines.get(FROM_ADDRESS_CSV_INDEX).trim();
                        if(fromAddressFromCSV.contains('<'))
                        {
                            fromAddress = fromAddressFromCSV.substring(0,fromAddressFromCSV.length()-1).substringAfter('<');
                        }
                        else
                        {
                            fromAddress = fromAddressFromCSV;
                        }
                    }

                    //Extraemos el email toAddress
                    if(String.isNotBlank(csvFileLines.get(TO_ADDRESS_CSV_INDEX)))
                    {
                        String toAddressToCSV = csvFileLines.get(TO_ADDRESS_CSV_INDEX).trim();
                        if(toAddressToCSV.contains('<'))
                        {
                            toAddress = toAddressToCSV.substring(0,toAddressToCSV.length()-1).substringAfter('<');
                        }
                        else 
                        {
                            toAddress = toAddressToCSV;
                        }
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
                        //Dividimos la información de la tipificación del caso por el separador configurado
                        List<String> types = csvFileLines.get(CASE_FIELDS_CSV_INDEX).trim().split(csvSeparator);

                        System.debug('types: ' + types);
                        System.debug('types.size(): ' + types.size());
                        System.debug('types.isEmpty(): ' + types.isEmpty());

                        if (!types.isEmpty()) 
                        {
                            //Incluimos el Id del caso para deserializar
                            Map<String, String> caseFieldsMap = new Map<String, String>{
                                'Id' => relatedCases.get(relatedEmail.ParentId).Id
                            };

                            //Recorremos la lista ordenada de campos a tipificar, 
                            //así podemos acceder directamente por posición al valor recibido
                            for(Integer i=0; i<caseFieldsList.size(); i++)
                            {
                                //Este if controla que no falle la ejecución si recibimos menos valores de los esperados
                                //o si el valor viene vacio
                                if(i<types.size() && String.isNotBlank(types.get(i)))
                                {
                                    String value = types.get(i);
                                    
                                    //Sí el campo que estamos iterando corresponde con alguno de los campos
                                    //de tipificación (Type, Subtype o TypeN3), necesitamos "traducir" el valor recibido
                                    if(caseTypesMapping.containsKey(caseFieldsList.get(i)))
                                    {
                                        if(caseTypesMapping.get(caseFieldsList.get(i)).containsKey(value))
                                        {
                                            value = caseTypesMapping.get(caseFieldsList.get(i)).get(value);
                                            System.debug('types.get('+i+'): ' + value);
                                            caseFieldsMap.put(caseFieldsList.get(i), value);
                                        }
                                        else
                                        {
                                            //Si hemos llegado a este punto, hemos recibido un valor en el CSV
                                            //que no se corresponde con ninguno de los esperados y no se puede traducir
                                            ErrorLogUtil.commitError(
                                                'warning',
                                                String.format(Label.RobotHegeoInvalidType, new List<String>{value, caseFieldsList.get(i)}),
                                                'ContentDocumentLinkUtil'
                                            );
                                        }
                                    }
                                    else
                                    {
                                        //En este caso no hace falta traducir el valor y se incluye directamente
                                        System.debug('types.get('+i+'): ' + value);
                                        caseFieldsMap.put(caseFieldsList.get(i), value);
                                    }
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