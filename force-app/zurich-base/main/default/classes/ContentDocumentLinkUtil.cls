/**
 *
 * @author rlopez
 * @date 26/01/2021
 */
public with sharing class ContentDocumentLinkUtil
{
    public static List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = null;

    public static List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = null;

    public static Map<String, Robot_Hegeo_Setting__mdt> robotHegeoSettingsMap = new Map<String, Robot_Hegeo_Setting__mdt>();

    public static Map<String, Map<String, String> > caseTypesMapping = new Map<String, Map<String, String> >();
    public static Set<String> caseRecordTypeNames = new Set<String>();
    public static Set<String> documentTitles = new Set<String>();
    public static Set<String> fileExtensions = new Set<String>();

    public static Map<Id, HegeoInformation> mapHegeoInformation = new Map<Id, HegeoInformation>();

    public static List<EmailMessage> emailMessagesToUpdate = new List<EmailMessage>();
    public static List<Case> casesToUpdate = new List<Case>();

    private static void initSettings()
    {
        if( robotHegeoSettings == null ) {

            robotHegeoSettings = [SELECT Id, DeveloperName, CaseFields__c, CaseFieldsIndex__c, Separator__c, FromAddressIndex__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, CaseTypeFieldsMetadata__c, RoutingAddresses__c, CCAddressIndex__c, BCCAddressIndex__c FROM Robot_Hegeo_Setting__mdt];
        }

        if( !robotHegeoSettings.isEmpty() )
        {
            for (Robot_Hegeo_Setting__mdt setting: robotHegeoSettings)
            {
                if (setting.IsActive__c == true)
                {
                    if (setting.RoutingAddresses__c != null)
                    {
                        List<String> routingAddresses = setting.RoutingAddresses__c.split(',');
                        for(String emailAddress: routingAddresses)
                        {
                            robotHegeoSettingsMap.put(emailAddress, setting);
                        }
                    }
                    if(setting.CaseRecordTypeNames__c != null)
                    {
                        caseRecordTypeNames.addAll( setting.CaseRecordTypeNames__c.split(',') );
                    }

                    if( String.isNotBlank(setting.DocumentTitle__c) )
                    {
                        documentTitles.add(setting.DocumentTitle__c);
                    }

                    if( String.isNotBlank(setting.FileExtension__c) )
                    {
                        fileExtensions.add(setting.FileExtension__c);
                    }
                }
            }
        }
        else
        {
            ErrorLogUtil.commitError(
                'warning',
                'No se ha recuperado ningún metadato configurado para el procesamiento de CSV del Robot HEGEO (Robot_Hegeo_Setting__mdt)',
                'ContentDocumentLinkUtil'
                );
        }

        //Cargamos el mapeo de campos de tipificación del caso
        if ( robotHegeoFieldsMapping == null ){
            
            robotHegeoFieldsMapping = Robot_Hegeo_Field_Mapping__mdt.getAll().values();
        }
        
        if( !robotHegeoFieldsMapping.isEmpty() )
        {
            for(Robot_Hegeo_Field_Mapping__mdt fieldMapping: robotHegeoFieldsMapping)
            {
                Map<String, String> typeValuesMap = new Map<String, String>();

                if( String.isNotBlank(fieldMapping.Type__c) )
                {
                    typeValuesMap.put('Type', fieldMapping.Type__c);
                    typeValuesMap.put('RobotTypeN1__c', fieldMapping.Type__c);
                }
                if( String.isNotBlank(fieldMapping.Subtype__c) )
                {
                    typeValuesMap.put('Subtype__c', fieldMapping.Subtype__c);
                    typeValuesMap.put('RobotTypeN2__c', fieldMapping.Subtype__c);
                }
                if( String.isNotBlank(fieldMapping.TypeN3__c) )
                {
                    typeValuesMap.put('TypeN3__c', fieldMapping.TypeN3__c);
                    typeValuesMap.put('RobotTypeN3__c', fieldMapping.TypeN3__c);
                }

                caseTypesMapping.put(fieldMapping.SourceType__c + fieldMapping.SourceSubtype__c, typeValuesMap);
            }
        }
        else
        {
            ErrorLogUtil.commitError(
                'warning',
                'No se ha recuperado ningún metadato configurado para la tipificación de casos del Robot HEGEO (Robot_Hegeo_Field_Mapping__mdt)',
                'ContentDocumentLinkUtil'
                );
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
        if(newList != null && !newList.isEmpty() && oldMap == null)
        {
            initSettings();

            if( !robotHegeoSettingsMap.isEmpty() )
            {
                try
                {
                    //Creamos un mapa de los registros recibidos en newList
                    Map<Id, ContentDocumentLink> linkedEntityToDocumentMap = new Map<Id, ContentDocumentLink>();
                    for(ContentDocumentLink docLink: newList)
                    {
                        linkedEntityToDocumentMap.put(docLink.LinkedEntityId, docLink);
                    }

                    //Recuperamos los emails en los que hemos recibido los documentos adjuntos
                    //Solo para los emails de los buzones y que esten relacionados con un caso del tipo
                    //especificado y con los buzones en los metadatos
                    Set<Id> caseRecordTypeIds = new Set<Id>();
                    for(String recordTypeName: caseRecordTypeNames)
                    {
                        caseRecordTypeIds.add( Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId() );
                    }

                    Map<Id, EmailMessage> relatedEmailMessages = new Map<Id, EmailMessage>(
                        [
                            SELECT Id, Subject, ToAddress, CreatedDate, ParentId, Parent.RecordTypeId, Parent.Industry__c
                            FROM EmailMessage WHERE Id IN: linkedEntityToDocumentMap.keySet()
                            AND Parent.RecordTypeId IN: caseRecordTypeIds AND ToAddress IN: robotHegeoSettingsMap.keySet()
                        ]
                        );

                    if( !relatedEmailMessages.isEmpty() )
                    {
                        //Necesitamos la información de los tipos de registro de caso para almacenar el DeveloperName
                        Map<Id, Schema.RecordTypeInfo> caseRecordTypesById = Schema.SObjectType.Case.getRecordTypeInfosById();

                        //Almacenamos los ids de los documentos relacionados
                        //con ContentDocumentLink y EmailMessage
                        //para recuperar el contenido del CSV
                        Set<Id> contentDocumentIds = new Set<Id>();
                        for(ContentDocumentLink docLink: newList)
                        {
                            if( relatedEmailMessages.containsKey(docLink.LinkedEntityId) )
                            {
                                //Existe email para ContentDocumentLink
                                contentDocumentIds.add(docLink.ContentDocumentId);

                                //Almacenamos toda la información necesaria para procesar los datos
                                EmailMessage relatedEmail = relatedEmailMessages.get(docLink.LinkedEntityId);
                                HegeoInformation hegeoInfo = new HegeoInformation();
                                hegeoInfo.contentDocumentLinkId = docLink.Id;
                                hegeoInfo.contentDocumentId = docLink.ContentDocumentId;
                                hegeoInfo.relatedEmail = relatedEmail;
                                hegeoInfo.relatedCaseRecordTypeName = caseRecordTypesById.get(relatedEmail.Parent.RecordTypeId).getDeveloperName();

                                mapHegeoInformation.put(docLink.Id, hegeoInfo);
                            }
                        }

                        //Recuperamos el contenido del CSV y aprovechamos para filtrar unicamente
                        //por el título y extensión especificados en los metadatos
                        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>(
                            [
                                SELECT Id, Title, FileExtension, LatestPublishedVersion.VersionData
                                FROM ContentDocument
                                WHERE Title IN: documentTitles AND FileExtension IN: fileExtensions AND Id IN: contentDocumentIds
                            ]
                            );

                        //Actualizamos la información almacenada
                        for( Id docLinkId: mapHegeoInformation.keySet() )
                        {
                            HegeoInformation hegeoInfo = mapHegeoInformation.get(docLinkId);
                            if( contentDocuments.containsKey(hegeoInfo.contentDocumentId) )
                            {
                                ContentDocument contentDoc = contentDocuments.get(hegeoInfo.contentDocumentId);
                                hegeoInfo.versionData = contentDoc.LatestPublishedVersion.VersionData.toString();
                                hegeoInfo.documentTitle = contentDoc.Title;
                                hegeoInfo.fileExtension = contentDoc.FileExtension;

                                mapHegeoInformation.put(docLinkId, hegeoInfo);
                            }
                        }
                    }
                }
                catch(Exception ex)
                {
                    ErrorLogUtil.commitError(ex,'ContentDocumentLinkUtil', 'getRelatedEmailMessages');
                }
            }
        }
    }

    public static void processHegeoCSV(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap)
    {
        if(oldMap == null)
        {
            for(ContentDocumentLink docLink: newList)
            {
                if( mapHegeoInformation.containsKey(docLink.Id) )
                {
                    setRelatedEmailMessageAndCase(docLink);
                }
            }
        }
    }

    private static void setRelatedEmailMessageAndCase(ContentDocumentLink docInformation)
    {
        try
        {
            //Validamos si la información cumple con los requerimientos establecidos en los metadatos
            if( mapHegeoInformation.containsKey(docInformation.Id) )
            {
                HegeoInformation relatedHegeoInformation = mapHegeoInformation.get(docInformation.Id);
                List<String> relatedEmailToAddressList = relatedHegeoInformation.relatedEmail.ToAddress.split(',');
                if( !relatedEmailToAddressList.isEmpty() )
                {
                    //Primero, comprobamos y recuperamos la información del buzón correspondiente
                    Robot_Hegeo_Setting__mdt relatedEmailSettings;
                    for(String toAddressEmail: relatedEmailToAddressList)
                    {
                        if( robotHegeoSettingsMap.containsKey(toAddressEmail) )
                        {
                            relatedEmailSettings = robotHegeoSettingsMap.get(toAddressEmail);
                        }
                    }

                    //Existe configuración para el buzón especificado
                    if(relatedEmailSettings != null)
                    {
                        //Comprobamos si el documento cumple con los requisitos de título, extensión y tipo de registro del caso
                        if( relatedHegeoInformation.isValidDocumentTitle(relatedEmailSettings) &&
                            relatedHegeoInformation.isValidFileExtension(relatedEmailSettings) &&
                            relatedHegeoInformation.isValidRecordType(relatedEmailSettings)
                            )
                        {
                            //Inicialiamos variables con datos necesarios para el procesamiento del CSV
                            EmailMessage relatedEmail = relatedHegeoInformation.relatedEmail;

                            String csvSeparator = relatedEmailSettings.Separator__c;
                            Integer fromAddressCSVIndex = Integer.valueOf(relatedEmailSettings.FromAddressIndex__c);
                            Integer toAddressCSVIndex = Integer.valueOf(relatedEmailSettings.ToAddressIndex__c);
                            Integer ccAddressCSVIndex = Integer.valueOf(relatedEmailSettings.CCAddressIndex__c);
                            Integer bccAddressCSVIndex = Integer.valueOf(relatedEmailSettings.BCCAddressIndex__c);
                            String caseFields = relatedEmailSettings.CaseFields__c;

                            List<String> caseTypeFieldsMetadataList = new List<String>();
                            if(relatedEmailSettings.CaseTypeFieldsMetadata__c != null)
                            {
                                caseTypeFieldsMetadataList = relatedEmailSettings.CaseTypeFieldsMetadata__c.split(',');
                            }

                            List<String> caseFieldsList = new List<String>();
                            if(caseFields != null)
                            {
                                caseFieldsList = caseFields.split(',');
                            }

                            //Recuperamos los datos del csv y dividimos por cada línea que contiene el documento
                            List<String> csvFileLines = relatedHegeoInformation.versionData.split('\n');

                            String fromAddress = '';
                            String toAddress = '';

                            //Si existen más de 2 líneas (0: tipificación del caso, 1: from, 2: to)
                            if(csvFileLines.size() > 2)
                            {
                                //Extraemos el email fromAddress
                                if( String.isNotBlank( csvFileLines.get(fromAddressCSVIndex) ) )
                                {
                                    List<String> fromAddressLineValues = csvFileLines.get(fromAddressCSVIndex).split(csvSeparator);
                                    if( fromAddressLineValues != null && !fromAddressLineValues.isEmpty() )
                                    {
                                        String fromAddressFromCSV = fromAddressLineValues.get(0).trim();
                                        if( fromAddressFromCSV.contains('<') )
                                        {
                                            fromAddress = fromAddressFromCSV.substring(0,fromAddressFromCSV.length() - 1).substringAfter('<');
                                        }
                                        else
                                        {
                                            fromAddress = fromAddressFromCSV;
                                        }
                                    }
                                }

                                if( String.isNotBlank(fromAddress) )
                                {
                                    relatedEmail.FromAddress = fromAddress;
                                }

                                //Extraemos el email toAddress
                                List<String> toAddressList = new List<String>();
                                if( String.isNotBlank( csvFileLines.get(toAddressCSVIndex) ) )
                                {
                                    List<String> toAddressLineValues = csvFileLines.get(toAddressCSVIndex).split(csvSeparator);
                                    if( toAddressLineValues != null && !toAddressLineValues.isEmpty() )
                                    {
                                        for(String toAddressFromCSV: toAddressLineValues)
                                        {
                                            // hotfix - ocs-2246 - Salesforce no reconoce el destinatario indicado por el robot tipificador al incluir imap
                                            String trimmedToAddressFromCSV = toAddressFromCSV.trim().toLowerCase().replaceAll('.imap', '');
                                            if( trimmedToAddressFromCSV.contains('<') )
                                            {
                                                toAddressList.add( trimmedToAddressFromCSV.substring(0,trimmedToAddressFromCSV.length() - 1).substringAfter('<') );
                                            }
                                            else
                                            {
                                                toAddressList.add(trimmedToAddressFromCSV);
                                            }
                                        }
                                    }
                                }

                                if( toAddressList != null && !toAddressList.isEmpty() )
                                {
                                    relatedEmail.ToAddress = String.join(toAddressList, ';');
                                }

                                //Extraemos el email ccAddress
                                if (csvFileLines.size() > 3)
                                {
                                    //Existe línea CC Address
                                    List<String> ccAddressList = new List<String>();
                                    if( String.isNotBlank( csvFileLines.get(ccAddressCSVIndex) ) )
                                    {
                                        List<String> ccAddressLineValues = csvFileLines.get(ccAddressCSVIndex).split(csvSeparator);
                                        if( ccAddressLineValues != null && !ccAddressLineValues.isEmpty() )
                                        {
                                            for(String ccAddressFromCSV: ccAddressLineValues)
                                            {
                                                // hotfix - ocs-2411 - Salesforce no reconoce el destinatario indicado por el robot tipificador al incluir imap
                                                String trimmedCcAddressFromCSV = ccAddressFromCSV.trim().toLowerCase().replaceAll('.imap', '');
                                                if( trimmedCcAddressFromCSV.contains('<') )
                                                {
                                                    ccAddressList.add( trimmedCcAddressFromCSV.substring(0,trimmedCcAddressFromCSV.length() - 1).substringAfter('<') );
                                                }
                                                else
                                                {
                                                    ccAddressList.add(trimmedCcAddressFromCSV);
                                                }
                                            }
                                        }
                                    }

                                    if( ccAddressList != null && !ccAddressList.isEmpty() )
                                    {
                                        relatedEmail.ccAddress = String.join(ccAddressList, ';');
                                    }
                                }

                                //Extraemos el email bccAddress
                                if (csvFileLines.size() > 4)
                                {
                                    //Existe línea BCC Address
                                    List<String> bccAddressList = new List<String>();
                                    if( String.isNotBlank( csvFileLines.get(bccAddressCSVIndex) ) )
                                    {
                                        List<String> bccAddressLineValues = csvFileLines.get(bccAddressCSVIndex).split(csvSeparator);
                                        if( bccAddressLineValues != null && !bccAddressLineValues.isEmpty() )
                                        {
                                            for(String bccAddressFromCSV: bccAddressLineValues)
                                            {
                                                String trimmedBccAddressFromCSV = bccAddressFromCSV.trim();
                                                if( trimmedBccAddressFromCSV.contains('<') )
                                                {
                                                    bccAddressList.add( trimmedBccAddressFromCSV.substring(0,trimmedBccAddressFromCSV.length() - 1).substringAfter('<') );
                                                }
                                                else
                                                {
                                                    bccAddressList.add(trimmedBccAddressFromCSV);
                                                }
                                            }
                                        }
                                    }

                                    if( bccAddressList != null && !bccAddressList.isEmpty() )
                                    {
                                        relatedEmail.BccAddress = String.join(bccAddressList, ';');
                                    }
                                }

                                //Actualizamos los campos correspondientes al caso
                                if(relatedEmail.ParentId != null)
                                {
                                    //Dividimos la información de la tipificación del caso por el separador configurado
                                    List<String> types = csvFileLines.get( Integer.valueOf(relatedEmailSettings.CaseFieldsIndex__c) ).trim().split(csvSeparator);
                                    if ( !types.isEmpty() && types.size() >= caseTypeFieldsMetadataList.size() )
                                    {
                                        //Incluimos el Id del caso para deserializar
                                        Map<String, String> caseFieldsMap = new Map<String, String> {
                                            'Id' => relatedEmail.ParentId
                                        };

                                        //Extraemos la combinación de los tipos de casos (2 primeras posiciones del listado de valores)
                                        String typeAndSubtypeCombination = types.get(0) + types.get(1);
                                       
                                        if( caseTypesMapping.containsKey(typeAndSubtypeCombination) )
                                        {
                                            caseFieldsMap.putAll( caseTypesMapping.get(typeAndSubtypeCombination) );
                                        }
                                        else
                                        {
                                            ErrorLogUtil.commitError(
                                                'warning',
                                                'La combinación de valores ' + typeAndSubtypeCombination + ' no existe. EmailMessage Id: ' + relatedEmail.Id,
                                                'ContentDocumentLinkUtil'
                                                );
                                        }

                                        //Recorremos la lista ordenada de campos a tipificar,
                                        //así podemos acceder directamente por posición al valor recibido
                                        for(Integer i=0; i < caseFieldsList.size(); i++)
                                        {
                                            //Este if controla que no falle la ejecución si recibimos menos valores de los esperados,
                                            //si el valor viene vacio o si ya se ha incluido ese campo en el mapa a deserializar
                                            if( i < types.size() && String.isNotBlank( types.get(i) ) && !caseFieldsMap.containsKey( caseFieldsList.get(i) ) )
                                            {
                                                caseFieldsMap.put( caseFieldsList.get(i), types.get(i) );

                                                if(caseFieldsList.get(i) == 'Industry__c')
                                                {
                                                    relatedEmail.Industry__c = types.get(i);
                                                }
                                            }
                                        }
                                       
                                        casesToUpdate.add(
                                            (Case) JSON.deserialize(
                                                JSON.serialize(caseFieldsMap), Case.class
                                                )
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

                                emailMessagesToUpdate.add(relatedEmail);

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
                        else
                        {
                            ErrorLogUtil.commitError(
                                'warning',
                                'El EmailMessage no cumplía los requisitos del metadato para ser procesado: título o extensión del documento adjunto o tipo de registro del caso relacionado. EmailMessage Id: ' + relatedHegeoInformation.relatedEmail.Id,
                                'ContentDocumentLinkUtil'
                                );
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            ErrorLogUtil.commitError(ex, 'ContentDocumentLinkUtil.setRelatedEmailMessageAndCase', docInformation.LinkedEntityId);
        }
    }

    public static void updateRelatedRecords()
    {
        if( !emailMessagesToUpdate.isEmpty() )
        {
            try
            {
                update emailMessagesToUpdate;
            }
            catch(Exception ex)
            {
                ErrorLogUtil.commitError(ex,'ContentDocumentLinkUtil', 'updateRelatedRecords - emailMessagesToUpdate');
            }
        }

        if( !casesToUpdate.isEmpty() )
        {
            try
            {
                update casesToUpdate;
            }
            catch(Exception ex)
            {
                ErrorLogUtil.commitError(ex,'ContentDocumentLinkUtil', 'updateRelatedRecords - casesToUpdate');
            }
        }
    }

    /**
     *
     *
     * @author rlopez
     */
    public class HegeoInformation
    {
        public EmailMessage relatedEmail;
        public String versionData;
        public String documentTitle;
        public String fileExtension;
        public String contentDocumentId;
        public String contentDocumentLinkId;
        public String relatedCaseRecordTypeName;

        public boolean isValidRecordType(Robot_Hegeo_Setting__mdt hegeoSetup)
        {
            return hegeoSetup.CaseRecordTypeNames__c.split(',').contains(this.relatedCaseRecordTypeName);
        }

        public boolean isValidDocumentTitle(Robot_Hegeo_Setting__mdt hegeoSetup)
        {
            return this.documentTitle == hegeoSetup.DocumentTitle__c;
        }

        public boolean isValidFileExtension(Robot_Hegeo_Setting__mdt hegeoSetup)
        {
            return this.fileExtension == hegeoSetup.FileExtension__c;
        }
    }
}