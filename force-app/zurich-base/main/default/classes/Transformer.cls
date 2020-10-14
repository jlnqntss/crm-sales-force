/**
 * Clase parser que transforma un origen de datos en objetos Salesforce dada una configuración
 **
 * @author xsobera
 * @date 13/10/2020
 */
public class Transformer
{
    public static final String ORIGIN_NAME_INFO = 'INFO';
    private static Set<String> validOrigins = new Set<String> {
        ORIGIN_NAME_INFO
    };

    public static final String OBJECT_NAME_ACCOUNT = 'Account';
    public static final String OBJECT_NAME_CONTACT = 'Contact';
    public static final String OBJECT_NAME_CONTACT_POINT_ADDRESS = 'ContactPointAddress';
    public static final String OBJECT_NAME_CONTACT_POINT_PHONE = 'ContactPointPhone';
    public static final String OBJECT_NAME_CONTACT_POINT_EMAIL = 'ContactPointEmail';

    private Map<String, Map<String, String>> mappingsByObject
    {
        get {
            if(mappingsByObject == null)
            {
                // Inicializar mapeo objeto Salesforce => campo origen -> campo destino
                mappingsByObject = new Map<String, Map<String, String>>();
            }
            return mappingsByObject;
        }
        set;
    }
    private Map<String, Schema.DescribeSObjectResult> descResultMap
    {
        get {
            if(descResultMap == null)
            {
                // Inicializar información objetos Salesforce
                descResultMap = new Map<String, Schema.DescribeSObjectResult>();
            }
            return descResultMap;
        }
        set;
    }

    private List<Transformer__mdt> settings;
    public List<Transformer__mdt> getSettings() { return this.settings; }
    private String origin;
    public String getOrigin() { return this.origin; }

    public Map<String, Map<sObject, ExternalRequest__c>> initRequestsMapBySettings()
    {
        Map<String, Map<sObject, ExternalRequest__c>> recordsToUpsertByObject = new Map<String, Map<sObject, ExternalRequest__c>>();

        // 2 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
        for(Transformer__mdt setting : this.settings)
        {
            if(!recordsToUpsertByObject.containsKey(setting.SalesforceEntity__c))
            {
                recordsToUpsertByObject.put(setting.SalesforceEntity__c, new Map<sObject, ExternalRequest__c>());
            }
        }

        return recordsToUpsertByObject;
    }

    public Transformer(String originSystem)
    {
        if(String.isBlank(originSystem) || !validOrigins.contains(originSystem))
        {
            throw new TransformerException('There are not established a valid origin system for the Transformer');
        }
        this.origin = originSystem;
        this.settings = new List<Transformer__mdt>([SELECT OriginEntity__c, OriginField__c, SalesforceEntity__c, SalesforceField__c FROM Transformer__mdt WHERE Origin__c =:originSystem]);

        if(settings == null || settings.isEmpty())
        {
            throw new TransformerException('There are not metadata configuration for selected origin: ' + this.origin);
        }

        // Inicializar mapeo campos según metadatos
        for(Transformer__mdt setting : this.settings)
        {
            if(!mappingsByObject.containsKey(setting.SalesforceEntity__c))
            {
                mappingsByObject.put(setting.SalesforceEntity__c, new Map<String, String>());
            }

            mappingsByObject.get(setting.SalesforceEntity__c).put(setting.OriginField__c.toLowerCase(), setting.SalesforceField__c);
            mappingsByObject.get(setting.SalesforceEntity__c).put(setting.OriginField__c.toUpperCase(), setting.SalesforceField__c);
        }
    }

    /**
     * Método que mapea en un objeto Salesforce los datos dados en un Mapa según
     * la configuración establecida en los metadatos personalizados indicados en el constructor
     **
     * @param String objeto Salesforce
     * @param Map<String, Object> datos recibidos en la petición
     * @return sObject objeto SF inicializado con los datos dados en el Mapa
     * @throws TransformerException excepción especifica durante el proceso de transformación del registro
     * @author xsobera
     * @date 13/10/2020
     */
    public sObject transform(String objectName, Map<String, Object> originRecordMap)
    {
        // Obtenemos la información de los campos del objeto Salesforce destino
        Set<String> objectFields = new Set<String>();
        Schema.DescribeSObjectResult descResult;
        System.debug(LoggingLevel.DEBUG, '[Tramsformer] objectName: ' + objectName);
        if(!descResultMap.containsKey(objectName))
        {
            descResult = Schema.describeSObjects(new String[]{objectName})[0];
            descResultMap.put(objectName, descResult);
        }
        else
        {
            descResult = descResultMap.get(objectName);
        }
        objectFields = descResult.fields.getMap().keySet();
        System.debug(LoggingLevel.DEBUG, '[Transformer] objectFields: ' + JSON.serialize(objectFields));

        Map<String, String> mappingByOriginField = mappingsByObject.get(objectName);
        SObject record = Schema.getGlobalDescribe().get(objectName).newSObject();
        String sfFieldName;
        String originFieldValue;
        Schema.SObjectField sfFieldObj;
        Schema.DisplayType fieldDisplayType;
        for(String originRecordField : originRecordMap.keySet())
        {
            if(mappingByOriginField.containsKey(originRecordField.toUpperCase()))
            {
                sfFieldName = mappingByOriginField.get(originRecordField.toUpperCase());
                if(objectFields.contains(sfFieldName.toLowerCase())) // Validar que el campo indicado en metadata existe en el objeto de salesforce
                {
                    originFieldValue = String.valueOf(originRecordMap.get(originRecordField)).trim();
                    if(String.isNotBlank(originFieldValue))
                    {
                        sfFieldObj = (Schema.sObjectField) record.get(sfFieldName);
                        fieldDisplayType = sfFieldObj.getDescribe().getType();
                        switch on fieldDisplayType.name()
                        {
                            when 'Boolean'
                            {
                                record.put(sfFieldName, parseBooleanField(originFieldValue));
                            }
                            when 'Date'
                            {
                                record.put(sfFieldName, Date.parse(originFieldValue));
                            }
                            when 'DateTime'
                            {
                                record.put(sfFieldName, Datetime.parse(originFieldValue));
                            }
                            when else // se considera texto el resto de campos
                            {
                                record.put(sfFieldName, originRecordMap.get(originRecordField));
                            }
                        }
                    }
                    else
                    {
                        record.put(sfFieldName, null);
                    }
                }
                else
                {
                    // El objeto salefsorce xxx no contiene un campo llamado xxxx
                    System.debug(LoggingLevel.ERROR, '[Transformer] No hay ningún campo en el objeto Salesforce con el nombre indicado.\nsObject: ' + objectName + ' \nField: ' + sfFieldName);
                    throw new TransformerException('There are not any field with these name in the salesforce object. \nsObject: ' + objectName + ' \nField: ' + sfFieldName);
                }
            }
            else
            {
                System.debug(LoggingLevel.ERROR, '[Transformer] No hay configuración para los valores solicitados.\n Origen: ' + origin + ' \nsObject: ' + objectName + ' \nField: ' + originRecordField);
                throw new TransformerException('There are not metadata configuration to these values. \n Origin: ' + origin + ' \nsObject: ' + objectName + ' \nField: ' + originRecordField);
            }
        }

        return record;
    }

    /**
     * Método que parsea un string en boolean de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en boolean, por ejemplo: S, Y, 1 ...
     * @return Boolean
     *
     * @author xsobera
     * @date 13/10/2020
     */
    private static Boolean parseBooleanField(String strValue)
    {
        Boolean booleanValue = false;
        if(String.isNotBlank(strValue) && strValue.equalsIgnoreCase('S'))
        {
            booleanValue = true;
        }
        return booleanValue;
    }

    public class TransformerException extends Exception {}
}