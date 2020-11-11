/**
 * Clase parser que transforma un origen de datos en objetos Salesforce dada una configuración
 **
 * @author xsobera
 * @date 13/10/2020
 */
public class Transformer
{
    public static final String ORIGIN_NAME_INFO = 'INFO';
    private static Set<String> validOrigins = new Set<String> { ORIGIN_NAME_INFO };

    // Cache de validaciones y transformaciones del mapeo campos
    private static Map<String, List<String>> targetFieldsCache = new Map<String, List<String>>();
    private static Map<String, Boolean> lookupsValidationCache = new Map<String, Boolean>();
    private static Map<String, ParentRelationDefinition> lookupsDefinitionCache = new Map<String, ParentRelationDefinition>();

    class ParentRelationDefinition
    {
        public String childFieldName;
        public String parentObjectName;
        public String parentExternalFieldName;

        public ParentRelationDefinition(String childFieldName, String parentObjectName, String parentExternalFieldName)
        {
            this.childFieldName = childFieldName;
            this.parentObjectName = parentObjectName;
            this.parentExternalFieldName = parentExternalFieldName;
        }
    }

    // Mapa y Clase "ObjectDefinition" para cachear los métodos "getDescribe" y solo se llamen una sola vez
    private static Map<String, ObjectDefinition> objectDefinitionByName = new Map<String, ObjectDefinition>();
    private static Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

    class ObjectDefinition
    {
        private String objectName;
        public Schema.SObjectType getSObjectType()
        {
            return globalDescribeMap.get(this.objectName);
        }

        Map<String, Schema.DescribeSObjectResult> descResultMap = new Map<String, Schema.DescribeSObjectResult>();
        Map<String, Map<String, Schema.SObjectField>> fieldsByObjectMap = new Map<String, Map<String, Schema.SObjectField>>();
        Map<String, Map<String, Schema.DisplayType>> fieldTypeByObjectAndField = new Map<String, Map<String, Schema.DisplayType>>();

        ObjectDefinition(String objectName)
        {
            if(!globalDescribeMap.containsKey(objectName))
            {
                throw new TransformerException('There are not any object in Salesforce with these name. sObject: ' + objectName );
            }
            this.objectName = objectName;
        }

        /**
         * Método para obtener los campos de un objeto Salesforce y cachear su información
         **
         * @return Map<String, Schema.SObjectField> mapa listado de campos del objeto indicado constructor
         * @author xsobera
         * @date 05/11/2020
         */
        public Map<String, Schema.SObjectField> getObjectFields()
        {
            // Obtenemos la información de los campos del objeto Salesforce destino
            Schema.DescribeSObjectResult descResult;
            if ( !descResultMap.containsKey(this.objectName) )
            {
                descResult = Schema.describeSObjects(new List<String> { objectName })[0];
                descResultMap.put(objectName, descResult);
            }
            descResult = descResultMap.get(objectName);

            if( !fieldsByObjectMap.containsKey(this.objectName))
            {
                fieldsByObjectMap.put(this.objectName, descResult.fields.getMap());
            }

            return fieldsByObjectMap.get(this.objectName);
        }

        /**
         * Método para obtener el tipo de un campo Salesforce del objeto establecido en constructor y cachear la información
         **
         * @param String sfFieldName nombre campo
         * @return Schema.DisplayType tipo de datos para el campo indicado
         * @throws TransformerException excepción especifica durante el proceso de transformación del registro
         * @author xsobera
         * @date 05/11/2020
         */
        public Schema.DisplayType getFieldType(String sfFieldName) // cachear
        {
            if(!fieldTypeByObjectAndField.containsKey(this.objectName) || !fieldTypeByObjectAndField.get(this.objectName).containsKey(sfFieldName))
            {
                // Validar que el campo indicado en metadata existe en el objeto de salesforce
                Map<String, Schema.SObjectField> objectFields = this.getObjectFields();
                if ( objectFields.containsKey(sfFieldName.toLowerCase()) )
                {
                    // Obteniendo detalles del campo: ' + sfFieldName
                    Schema.SObjectField sfFieldObj = objectFields.get(sfFieldName.toLowerCase());
                    Schema.DisplayType fieldDisplayType = sfFieldObj.getDescribe().getType();
                    if(fieldTypeByObjectAndField.get(this.objectName) == null)
                    {
                        fieldTypeByObjectAndField.put(this.objectName, new Map<String, Schema.DisplayType>());
                    }
                    fieldTypeByObjectAndField.get(this.objectName).put(sfFieldName, fieldDisplayType);
                }
                else
                {
                    throw new TransformerException('There are not any field with these name in the salesforce object. sObject: ' + this.objectName + ' Field: ' + sfFieldName );
                }
            }

            return fieldTypeByObjectAndField.get(this.objectName).get(sfFieldName);
        }
    }

    private Map<String, Map<String, Map<String, String>>> mappingsByObject {
        get {
            if (mappingsByObject == null)
            {
                // Inicializar mapeo objeto Salesforce => campo origen -> campo destino
                mappingsByObject = new Map<String, Map<String, Map<String, String>>>();
            }
            return mappingsByObject;
        }
        set;
    }

    private List<Transformer__mdt> settings;
    public List<Transformer__mdt> getSettings()
    {
        return this.settings;
    }
    private String origin;
    public String getOrigin()
    {
        return this.origin;
    }
    private Map<String, Object> unmappedValues {
        get {
            if (unmappedValues == null)
            {
                // Inicializar mapa para devolver los campos no mapeados
                unmappedValues = new Map<String, Object>();
            }
            return unmappedValues;
        }
        set;
    }
    public Map<String, Object> getUnmappedValues()
    {
        return unmappedValues;
    }

    public Map<String, Map<String, Map<sObject, ExternalRequest__c>>> initRequestsMapBySettings()
    {
        Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsByEntityAndObject = new Map<String, Map<String, Map<sObject, ExternalRequest__c>>>();

        // 2 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
        for (Transformer__mdt setting : this.settings)
        {
            if (!recordsByEntityAndObject.containsKey(setting.OriginEntity__c) )
            {
                recordsByEntityAndObject.put(setting.OriginEntity__c, new Map<String, Map<sObject, ExternalRequest__c>>());
            }

            recordsByEntityAndObject.get(setting.OriginEntity__c).put(setting.SalesforceEntity__c, new Map<sObject, ExternalRequest__c>());
        }

        return recordsByEntityAndObject;
    }

    public Transformer(String originSystem)
    {
        if (String.isBlank(originSystem) || !validOrigins.contains(originSystem) )
        {
            throw new TransformerException(
                      'There are not established a valid origin system for the Transformer'
                      );
        }
        this.origin = originSystem;
        this.settings =  TransformerSelector.selectMetadataByOrigin(originSystem);

        if (settings == null || settings.isEmpty() )
        {
            throw new TransformerException(
                      'There are not metadata configuration for selected origin: ' +
                      this.origin
                      );
        }

        // Inicializar mapeo campos según metadatos
        for (Transformer__mdt setting : this.settings)
        {
          if (!mappingsByObject.containsKey(setting.OriginEntity__c) )
          {
            mappingsByObject.put(setting.OriginEntity__c, new Map<String, Map<String, String>>());
          }

          if (!mappingsByObject.get(setting.OriginEntity__c).containsKey(setting.SalesforceEntity__c) )
          {
            mappingsByObject.get(setting.OriginEntity__c).put(setting.SalesforceEntity__c, new Map<String, String>());
          }

          mappingsByObject.get(setting.OriginEntity__c).get(setting.SalesforceEntity__c).put(setting.OriginField__c.toLowerCase(), setting.SalesforceField__c);
          mappingsByObject.get(setting.OriginEntity__c).get(setting.SalesforceEntity__c).put(setting.OriginField__c.toUpperCase(), setting.SalesforceField__c);
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
    public sObject transform( String entity, String objectName, Map<String, Object> originRecordMap )
    {
        // Obtenemos la información de los campos del objeto Salesforce destino
        if( !objectDefinitionByName.containsKey(objectName))
        {
            objectDefinitionByName.put(objectName, new ObjectDefinition(objectName));
        }

        Map<String, String> mappingByOriginField = mappingsByObject.get(entity).get(objectName);
        SObject record = objectDefinitionByName.get(objectName).getSObjectType().newSObject();

        String sfFieldNameConfig;
        String originRecordFieldUppercased;
        List<String> currentTargetFields;
        String sfFieldName;
        for (String originRecordField : originRecordMap.keySet())
        {
            originRecordFieldUppercased = originRecordField.toUpperCase(); // cachear la transformación
            if (mappingByOriginField.containsKey(originRecordFieldUppercased))
            {
                sfFieldNameConfig = mappingByOriginField.get( originRecordFieldUppercased );
                // comprobar que hay un campo sf definido en el metadato
                if ( String.isNotBlank(sfFieldNameConfig) )
                {
                    currentTargetFields = getTargetFields(sfFieldNameConfig);
                    for (Integer i = 0; i < currentTargetFields.size(); i++)
                    {
                        sfFieldName = currentTargetFields[i];
                        // comprobar que si es lookup
                        if ( !isLookupRelationship(sfFieldName) )
                        {
                            // Fill value
                            fillFieldValue( record, sfFieldName, (String) originRecordMap.get(originRecordField) );
                        }
                        else
                        {
                            // Fill lookup
                            buildParentRelationship( record, sfFieldName, (String) originRecordMap.get(originRecordField) );
                        }
                    } // fin loop getTargetFields()
                }
                else
                {
                    // Sí hay configuración para el campo origen pero no se ha definido
                    // un campo sf de destino en el metadato (vacío o nulo) => Guardar en unmappedValues
                    unmappedValues.put( originRecordField, originRecordMap.get(originRecordField) );
                }
            }
            else
            {
                // No se ha especificado ninguna configuración para el campo origen xxx => Guardar en unmappedValues
                unmappedValues.put( originRecordField, originRecordMap.get(originRecordField) );
            }
        }

        return record;
    }

    /**
     * Método que parsea un string en boolean de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en boolean, por ejemplo: S, Y, 1 ...
     * @param String origen configurado en el Transformer
     * @return Boolean
     *
     * @author xsobera
     * @date 13/10/2020
     */
    @TestVisible
    private static Boolean parseBooleanField(String strValue, string origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                Boolean booleanValue = false;
                if ( String.isNotBlank(strValue) )
                {
                  if( strValue.equalsIgnoreCase('S'))
                  {
                    booleanValue = true;
                  }
                  else
                  {
                    booleanValue = Boolean.valueOf(strValue);
                  }
                }
                return booleanValue;
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseBooleanField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que parsea un string en Date de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en Date, por ejemplo: 'YYYY-MM-DD' ...
     * @param String origen configurado en el Transformer
     * @return Date
     *
     * @author xsobera
     * @date 20/10/2020
     */
    @TestVisible
    private static Date parseDateField(String strValue, String origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                if ( String.isNotBlank(strValue) )
                {
                    return Date.valueOf(strValue);
                }
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseDateField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que parsea un string en Datetime de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en Datetime, por ejemplo: YYYY-MM-DD HH:MM:SS
     * @param String origen configurado en el Transformer
     * @return Datetime
     *
     * @author xsobera
     * @date 20/10/2020
     */
    @TestVisible
    private static Datetime parseDatetimeField(String strValue, String origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                if ( String.isNotBlank(strValue) )
                {
                    return Datetime.valueOf(strValue);
                }
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseDatetimeField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que parsea un string en texto de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en String , por ejemplo: 'hola'
     * @param String origen configurado en el Transformer
     * @return String
     *
     * @author xsobera
     * @date 21/10/2020
     */
    @TestVisible
    private static String parseStringField(String strValue, String origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                if ( String.isNotBlank(strValue) )
                {
                    return strValue;
                }
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseStringField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que parsea un string en Double de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en Double, por ejemplo: '0000.00' ...
     * @param String origen configurado en el Transformer
     * @return Double
     *
     * @author xsobera
     * @date 26/10/2020
     */
    @TestVisible
    private static Double parseDoubleField(String strValue, String origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                if ( String.isNotBlank(strValue) )
                {
                    return Double.valueOf(strValue );
                }
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseDoubleField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que parsea un string en Integer de acuerdo con las indicaciones
     * de formato del sistema origen
     **
     * @param String valor a transformar en Integer, por ejemplo: '0000' ...
     * @param String origen configurado en el Transformer
     * @return Integer
     *
     * @author xsobera
     * @date 26/10/2020
     */
    @TestVisible
    private static Integer parseIntegerField(String strValue, String origin)
    {
        switch on origin
        {
            when 'INFO'
            {
                if ( String.isNotBlank(strValue) && strValue.isNumeric() )
                {
                    return Integer.valueOf(strValue );
                }
            }
        }

        System.debug(LoggingLevel.WARN, '[Transformer] parseIntegerField() transformación no específicada para origen: ' + origin );
        return null;
    }

    /**
     * Método que comprueba si la configuración de metadatos es lookup
     * Formato targetFieldOfChild:sObjectNameOfParent->externalFieldIdOfParent
     **
     * @param String valor configuración
     * @return Boolean
     *
     * @author xsobera
     * @date 21/10/2020
     */
    @TestVisible
    private static Boolean isLookupRelationship(String configValue)
    {
        if(!lookupsValidationCache.containsKey(configValue))
        {
            lookupsValidationCache.put(configValue,
            (String.isNotBlank(configValue) &&
            configValue.countMatches(':') == 1 &&
            configValue.countMatches('->') == 1));
        }
        return lookupsValidationCache.get(configValue);
    }

    /**
     * Método que rellena el valor dado en origen en el campo configurado
     **
     * @param sObject parentObjectName
     * @param String sfFieldName
     * @param String fieldValue
     *
     * @author xsobera
     * @date 04/11/2020
     */
    private void fillFieldValue( sObject record, String sfFieldName, String fieldValue)
    {
        // Obteniendo tipo del campo: ' + sfFieldName
        Schema.DisplayType fieldDisplayType = objectDefinitionByName.get(String.valueOf(record.getSObjectType())).getFieldType(sfFieldName);
        switch on fieldDisplayType
        {
            when BOOLEAN
            {
                record.put( sfFieldName, parseBooleanField(fieldValue, this.origin) );
            }
            when DATE
            {
                record.put( sfFieldName, parseDateField(fieldValue, this.origin) );
            }
            when DATETIME
            {
                record.put( sfFieldName, parseDatetimeField(fieldValue, this.origin) );
            }
            when CURRENCY, DOUBLE
            {
                record.put( sfFieldName, parseDoubleField(fieldValue, this.origin) );
            }
            when INTEGER
            {
                record.put( sfFieldName, parseIntegerField(fieldValue, this.origin) );
            }
            when else
            {
                // se considera texto el resto de campos
                record.put( sfFieldName, parseStringField(fieldValue, this.origin) );
            }
        }
    }

    /**
     * Método que devuelve establece la relación con el padre según el externalId configurado
     * Formato targetFieldOfChild:sObjectNameOfParent->externalFieldIdOfParent
     **
     * @param sObject parentObjectName
     * @param String configValue
     * @param String fieldValue
     *
     * @author xsobera
     * @date 21/10/2020
     */
    @TestVisible
    private static void buildParentRelationship( sObject record, String configValue, String fieldValue )
    {
        ParentRelationDefinition lookupDef;
        if(!lookupsDefinitionCache.containsKey(configValue))
        {
            // Cachear este split
            String childFieldName;
            String parentObjectName;
            String parentExternalFieldName;
            List<String> aux;
            aux = new List<String>(configValue.split(':') );
            childFieldName = aux[0];
            aux = new List<String>(aux[1].split('->') );
            parentObjectName = aux[0];
            parentExternalFieldName = aux[1];

            lookupsDefinitionCache.put(configValue, new ParentRelationDefinition(childFieldName, parentObjectName, parentExternalFieldName));
        }

        lookupDef = lookupsDefinitionCache.get(configValue);

        // Comprobar que existen los campos en hijo y el objeto padre y su campo
        if( !objectDefinitionByName.containsKey(lookupDef.parentObjectName))
        {
            objectDefinitionByName.put(lookupDef.parentObjectName, new ObjectDefinition(lookupDef.parentObjectName));
        }
        Map<String, Schema.SObjectField> parentObjectFields = objectDefinitionByName.get(lookupDef.parentObjectName).getObjectFields();
        if (parentObjectFields.containsKey(lookupDef.parentExternalFieldName.toLowerCase()))
        {
            if( !objectDefinitionByName.containsKey(String.valueOf(record.getSObjectType())))
            {
                objectDefinitionByName.put(String.valueOf(record.getSObjectType()), new ObjectDefinition(String.valueOf(record.getSObjectType())));
            }
            Map<String, Schema.SObjectField> childObjectFields = objectDefinitionByName.get(String.valueOf(record.getSObjectType())).getObjectFields();
            if (childObjectFields.containsKey(lookupDef.childFieldName.toLowerCase()))
            {
                if (string.isNotBlank(fieldValue))
                {
                    SObject parentObject = objectDefinitionByName.get(lookupDef.parentObjectName).getSObjectType().newSObject();
                    parentObject.put(lookupDef.parentExternalFieldName, fieldValue);

                    String relationName = childObjectFields.get( lookupDef.childFieldName.toLowerCase() ).getDescribe().getRelationshipName();

                    // Establecer la relación
                    record.putSObject(relationName, parentObject);
                }
                else
                {
                    // La relación se establece a null
                    record.put(lookupDef.childFieldName, null);
                }
            }
            else
            {
                // El hijo no contienen un campo con ese nombre
                throw new TransformerException( 'There are not any field with these name in the salesforce child object. sObject: ' + String.valueOf(record.getSObjectType()) + ' Field: ' + lookupDef.childFieldName);
            }
        }
        else
        {
            // El padre no contiene un campo con ese nombre
            throw new TransformerException( 'There are not any field with these name in the salesforce parent object. sObject: ' + lookupDef.parentObjectName + ' Field: ' + lookupDef.parentExternalFieldName );
        }
    }

    /**
     * Método que las configuraciones para cada uno de los campos destino
     * Formato entrada targetField1,targetField2
     **
     * @param String configValue
     * @return List<String> configuraciones para cada campo destino
     *
     * @author xsobera
     * @date 23/10/2020
     */
    @TestVisible
    private static List<String> getTargetFields(String configValue)
    {
        List<String> configValues = new List<String>(); // siempre tiene que devolver una lista instanciada
        if ( String.isNotBlank(configValue) )
        {
            if( targetFieldsCache.containsKey(configValue) ) // comprobar cache
            {
                configValues = targetFieldsCache.get(configValue);
            }
            else
            {
                Set<String> aux = new Set<String>(configValue.split(',') );
                aux.removeAll(new Set<String> { null, '', ' ' });
                configValues.addAll(aux);
                targetFieldsCache.put(configValue, configValues); // cachear la transformación
            }
        }

        return configValues;
    }

    public class TransformerException extends Exception {}
}