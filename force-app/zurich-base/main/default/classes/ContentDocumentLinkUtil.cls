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
    public static List<String> caseTypeFieldsMetadataList = new List<String>();

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
        //Cargamos los settings generales
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, CaseTypeFieldsMetadata__c
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

            if(robotHegeoSettings.get(0).CaseTypeFieldsMetadata__c != null)
            {
                caseTypeFieldsMetadataList = robotHegeoSettings.get(0).CaseTypeFieldsMetadata__c.split(',');
            }

            isActiveTrigger = robotHegeoSettings.get(0).isActive__c;
            documentTitle = robotHegeoSettings.get(0).DocumentTitle__c;
            fileExtension = robotHegeoSettings.get(0).FileExtension__c;
        }

        //Cargamos el mapeo de campos de tipificación del caso
        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = [
            SELECT Id, SourceType__c, SourceSubtype__c, Type__c, Subtype__c, TypeN3__c
            FROM Robot_Hegeo_Field_Mapping__mdt
        ];

        if(!robotHegeoFieldsMapping.isEmpty())
        {
            for(Robot_Hegeo_Field_Mapping__mdt fieldMapping: robotHegeoFieldsMapping)
            {
                Map<String, String> typeValuesMap = new Map<String, String>();
                if(String.isNotBlank(fieldMapping.Type__c))
                {
                    typeValuesMap.put('Type', fieldMapping.Type__c);
                }
                if(String.isNotBlank(fieldMapping.Subtype__c))
                {
                    typeValuesMap.put('Subtype__c', fieldMapping.Subtype__c);
                }
                if(String.isNotBlank(fieldMapping.TypeN3__c))
                {
                    typeValuesMap.put('TypeN3__c', fieldMapping.TypeN3__c);
                }

                caseTypesMapping.put(fieldMapping.SourceType__c + fieldMapping.SourceSubtype__c, typeValuesMap);
            }
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
        if(newList != null && !newList.isEmpty())
        {       
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
    }

    public static void processHegeoCSV(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap)
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

                    if(String.isNotBlank(fromAddress))
                    {
                        relatedEmail.FromAddress = fromAddress;
                    }

                    //Extraemos el email toAddress
                    List<String> toAddressList = new List<String>();
                    if(String.isNotBlank(csvFileLines.get(TO_ADDRESS_CSV_INDEX)))
                    {
                        List<String> toAddressListFromCSV = csvFileLines.get(TO_ADDRESS_CSV_INDEX).split(',');
                        for(String toAddressFromCSV: toAddressListFromCSV)
                        {
                            if(toAddressFromCSV.contains('<'))
                            {
                                toAddressList.add(toAddressFromCSV.trim().substring(0,toAddressFromCSV.length()-1).substringAfter('<'));
                            }
                            else 
                            {
                                toAddressList.add(toAddressFromCSV.trim());
                            }
                        }
                    }

                    if(toAddressList != null && !toAddressList.isEmpty())
                    {
                        relatedEmail.ToAddress = toAddressList.toString();
                    }

                    emailMessagesToUpdate.add(relatedEmail);

                    //2. Actualizamos los campos correspondientes al caso
                    if(relatedEmail.ParentId != null && relatedCases.containsKey(relatedEmail.ParentId))
                    {
                        //Dividimos la información de la tipificación del caso por el separador configurado
                        List<String> types = csvFileLines.get(CASE_FIELDS_CSV_INDEX).trim().split(csvSeparator);

                        if (!types.isEmpty() && types.size() >= caseTypeFieldsMetadataList.size()) 
                        {
                            //Incluimos el Id del caso para deserializar
                            Map<String, String> caseFieldsMap = new Map<String, String>{
                                'Id' => relatedCases.get(relatedEmail.ParentId).Id
                            };

                            //Extraemos la combinación de los tipos de casos (2 primeras posiciones del listado de valores)
                            String typeAndSubtypeCombination = types.get(0) + types.get(1);

                            //caseFieldsMap.putAll(get(typeAndSubtypeCombination))
                            if(caseTypesMapping.containsKey(typeAndSubtypeCombination))
                            {
                                caseFieldsMap.putAll(caseTypesMapping.get(typeAndSubtypeCombination));
                            }
                            else
                            {
                                ErrorLogUtil.commitError(
                                    'warning',
                                    'La combinación de valores '+ typeAndSubtypeCombination +' no existe. EmailMessage Id: ' + relatedEmail.Id,
                                    'ContentDocumentLinkUtil'
                                );    
                            }

                            //Recorremos la lista ordenada de campos a tipificar, 
                            //así podemos acceder directamente por posición al valor recibido
                            for(Integer i=caseTypeFieldsMetadataList.size(); i<caseFieldsList.size(); i++)
                            {
                                //Este if controla que no falle la ejecución si recibimos menos valores de los esperados
                                //o si el valor viene vacio
                                if(i<types.size() && String.isNotBlank(types.get(i)))
                                {
                                    String value = types.get(i);
                                    //En este caso no hace falta traducir el valor y se incluye directamente
                                    caseFieldsMap.put(caseFieldsList.get(i), value);
                                }
                            }

                            casesToUpdate.add((Case) JSON.deserialize(
                                JSON.serialize(caseFieldsMap), Case.class)
                            );
                        }
                        else
                        {
                            ErrorLogUtil.commitError(
                                'warning',
                                'La información correspondiente a la tipificación de los casos está vacia o es menor de lo esperado. EmailMessage Id: ' + relatedEmail.Id,
                                'ContentDocumentLinkUtil'
                            );
                        }
                    }
                    else
                    {
                        ErrorLogUtil.commitError(
                            'warning',
                            'No existe caso relacionado con el email para procesar la información. EmailMessage Id: ' + relatedEmail.Id,
                            'ContentDocumentLinkUtil'
                        );
                    }
                }
                else
                {
                    ErrorLogUtil.commitError(
                        'warning',
                        'El documento adjunto cumplía las condiciones establecidas para ser procesado, pero tiene menos información de la esperada para procesar. EmailMessage Id: ' + relatedEmail.Id,
                        'ContentDocumentLinkUtil'
                    );
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