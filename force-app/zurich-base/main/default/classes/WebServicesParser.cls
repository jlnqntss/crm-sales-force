/**
 * New version of the WebServicesParser, this utility transform Json String to an indicated
 * Salesforce's SObject
 *
 * @author v1 dontalvilla, raespinosa
 * @date 05/05/2017
 * @author raespinosa, dontalvilla, jmartinezpisson
 * @date 13/04/2020
 *
 **/
public with sharing class WebServicesParser
{
    private static Map<String, List<WebServicesControl__mdt>> requiredMetadataMap = new Map<String, List<WebServicesControl__mdt> >();
    private static Map<String, WebServicesControl__mdt> metadataMap = new Map<String, WebServicesControl__mdt>();
    @TestVisible
    private static List<WebServicesControl__mdt> metadataList = new List<WebServicesControl__mdt>();
    private static Schema.SObjectType parentObjectType;
    private static Boolean parented = false;
    private static String relFieldName = '';
    private static Integer nestedLevel = 1;
    private static String parenExtKey = '';
    private static String extKey = '';
    private static Map<String, String> extKeyMap = new Map<String, String>(); // gpacho 2020-05-26

    public static WebParserResult result;

    /**
     *  Wrapper class to return every result data
     **
     *  @author dontalvilla
     *  @change raespinosa 13/04/2020 New object structure
     *  @date 05/05/2017
     **/
    public class WebParserResult
    {
        //public List<SObject> recordsList;

        public Map<String, SObject> recordsMap;
        public Map<String, String> errorMessagesMap;
        public Map<String, List<SObject> > secLvlRecordsMap;
        public Map<String, List<SObject> > thrLvlRecordsMap;
        public String jsonObject;
        public String source;
        public String service;
        public Schema.SObjectType entityType;
        public boolean upsertRequired = false;

        public WebParserResult(String jsonObj, String src, String serv, Schema.SObjectType entType)
        {
            this.jsonObject = jsonObj;
            this.source = src;
            this.service = serv;
            this.entityType = entType;
            recordsMap = new Map<String, SObject>();
            errorMessagesMap = new Map<String, String>();
            secLvlRecordsMap = new Map<String, List<SObject> >();
            thrLvlRecordsMap = new Map<String, List<SObject> >();
        }
    }

    /**
     *  Retrieves Custom metadata type to proccess the Json
     **
     *  @author dontalvilla
     *  @change raespinosa 13/04/2020 Method has been modified to get only the metadata, the Control wrapper was deleted
     *  @date 05/05/2017
     *  @throws none
     *  @where N/A
     **/
    private static void retrieveMetadata()
    {
        if (!Test.isRunningTest() )
        {
            metadataList = new List<WebServicesControl__mdt>(
                [
                    SELECT
                    AttributeName__c,
                    Source__c,
                    ServiceName__c,
                    EntityName__c,
                    FieldName__c,
                    RelatedObjectType__c,
                    Nullable__c,
                    PicklistValues__c,
                    IgnoreErrors__c,
                    Required__c,
                    Object__c,
                    Array__c,
                    PicklistAttributesName__c,
                    External_Id__c,
                    Attachable__c,
                    Duplicate__c,
                    Nested__c
                    FROM WebServicesControl__mdt
                ]
                );
        }

        if (!metadataList.isEmpty() )
        {
            for (WebServicesControl__mdt control : metadataList)
            {
                metadataMap.put(
                    control.Source__c +
                    '*' +
                    control.ServiceName__c +
                    '*' +
                    control.EntityName__c +
                    '*' +
                    control.AttributeName__c,
                    control
                    );
                processMapControls(control);
            }
        }
    }

    /**
     *  Process the json string and retrieves a complete SF Object
     **
     *  @author dontalvilla
     *  @change raespinosa 13/04/2020 New version of the WebServicesParser
     *  @date 05/05/2017
     *  @param record type, json, source and service
     *  @return WebParserResult result object
     *  @throws none
     *  @where N/A
     **/
    public static WebParserResult parseObject(Schema.SObjectType entityType, String jsonObject, String source, String service)
    {
        result = new WebParserResult(jsonObject, source, service, entityType);

        if ( String.isBlank(jsonObject) || String.isBlank(source) ||  String.isBlank(service) || entityType == null )
        {
            result.errorMessagesMap.put('Parameters', Label.EmptyParameters);
            return result;
        }
        List<String> errorMessages;
        try
        {
            List<Object> jsonResults = (List<Object>) JSON.deserializeUntyped(jsonObject);

            retrieveMetadata();
            manageObjectList(jsonResults, errorMessages, entityType);
        }
        catch (JSONException ex)
        {
            result.errorMessagesMap.put('JSON', Label.JsonIncorrecto);
        }

        return result;
    }

    /**
     *  Get a list of records obtained from the JSON and process record by record
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param List<Object> objects
     *  @param List<String> errorMessages
     *  @param SObject record
     *  @where N/A
     *
     *  @change gpacho 2020-05-26 External key handling system updated
     **/
    private static void manageObjectList(List<Object> objects, List<String> errorMessages, Schema.SObjectType entityType)
    {
        for (Object jsonResult : objects)
        {
            //Empty list of error Messages
            errorMessages = new List<String>();
            //Convert Object to record Map
            Map<String, Object> recordMap = (Map<String, Object>) jsonResult;
            manageRecordMap(recordMap, errorMessages, entityType);
        }
    }

    /**
     *  Get a record with Map format and proccess it
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param Map<String, Object> recordMap
     *  @param List<String> errorMessages
     *  @param Schema.SObjectType entityType
     *  @where N/A
     **/
    private static void manageRecordMap(Map<String, Object> recordMap, List<String> errorMessages, Schema.SObjectType entityType)
    {
        SObject record = entityType.newSObject();
        String entityName = entityType.getDescribe().getName();
        WebServicesControl__mdt fieldControl;

        for (String fieldName : recordMap.keySet() )
        {
            
            if (!String.isBlank(fieldName))
            {
                fieldControl = checkFieldProcessing(
                    result.source,
                    result.service,
                    entityType,
                    fieldName
                );

                if (fieldControl != null)
                {
                    Object element = recordMap.get(fieldName);
                    Boolean isString = element instanceof String;
                    Boolean isInteger = element instanceof Integer; // gpacho 2020-06-01
                    Boolean isDouble = element instanceof Double; // gpacho 2020-06-01
                    Boolean isBoolean = element instanceof Boolean; // gpacho 2020-06-10
                    if (
                        fieldControl.Object__c ||
                        !(isString ||
                          isInteger ||
                          isDouble ||
                          isBoolean) // gpacho 2020-06-01
                        )
                    {
                        if (!fieldControl.Nested__c)
                        {
                            if (!fieldControl.Array__c)
                            {
                                processPicklistPairs(
                                    element,
                                    fieldControl,
                                    errorMessages,
                                    record
                                    );
                            }
                            else
                            {
                                List<Object> listMultiPick = (List<Object>) element;
                                if (!listMultiPick.isEmpty() )
                                {
                                    Map<String, Object> mapMultiPick = (Map<String, Object>) listMultiPick.get(0);
                                    if (!mapMultiPick.values().isEmpty() )
                                    {
                                        List<Object> pickPairList = (List<Object>) mapMultiPick.values()
                                                                    .get(0);
                                        for (Object pickPair : pickPairList)
                                        {
                                            processPicklistPairs(
                                                pickPair,
                                                fieldControl,
                                                errorMessages,
                                                record
                                                );
                                        }
                                    }
                                }
                            }
                        }
                        else
                        {
                            nestedLevel++;
                            String actualFieldName = relFieldName;
                            Schema.SObjectType actualType = parentObjectType;

                            relFieldName = fieldControl.FieldName__c;
                            Schema.SObjectType relRecObjType = Schema.getGlobalDescribe()
                                                               .get(fieldControl.RelatedObjectType__c);
                            parentObjectType = record.getSObjectType();
                            //parenExtKey = extKey; // gpacho 2020-05-26
                            if (!fieldControl.Array__c)
                            {
                                //Un solo elemento
                                Map<String, Object> nestedRecord = (Map<String, Object>) element;
                                manageRecordMap(nestedRecord, errorMessages, relRecObjType);
                            }
                            else
                            {
                                List<Object> nestedRecords = (List<Object>) element;
                                manageObjectList(nestedRecords, errorMessages, relRecObjType);
                            }
                            //extKey = parenExtKey; // gpacho 2020-05-26
                            relFieldName = actualFieldName;
                            parentObjectType = actualType;
                            nestedLevel--;
                        }
                    }
                    else
                    {
                        manageRecordGeneration(
                            result,
                            fieldControl,
                            record,
                            element,
                            errorMessages
                        );
                    }
                }
            }
            else
            {
                errorMessages.add('JSON' + ': ' + Label.NombreAtributoVacio);
            }
        }

        if (errorMessages.isEmpty() )
        {
            checkRequiredFields(record, result.source, result.service, errorMessages);
            if (errorMessages.isEmpty() & nestedLevel == 1)
            {
                result.recordsMap.put(extKey, record);
            }
            else if (errorMessages.isEmpty() & nestedLevel == 2)
            {
                if (!parented)
                {
                    String fieldNameAux = getRelatedAttrName(relFieldName);
                    
                    
                    
                    Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                                                               .get(entityName)
                                                               .getDescribe()
                                                               .fields.getMap()
                                                               .get(fieldNameAux)
                                                               .getDescribe();
                    String parentFieldName = relFieldName.substring(
                        relFieldName.indexOf('.') + 1
                        );
                    
                    
                    //setParentRecord(record, fieldDescribe, parentObjectType, parentFieldName, parenExtKey); // gpacho 2020-05-26
                    setParentRecord(
                        record,
                        fieldDescribe,
                        parentObjectType,
                        parentFieldName,
                        extKeyMap.get(parentFieldName)
                        ); // gpacho 2020-05-26
                }
                if (result.secLvlRecordsMap.containsKey(entityName) )
                {
                    result.secLvlRecordsMap.get(entityName).add(record);
                }
                else
                {
                    List<SObject> newRecords = new List<SObject>();
                    newRecords.add(record);
                    result.secLvlRecordsMap.put(entityName, newRecords);
                }
                parented = false;
            }
            else if (errorMessages.isEmpty() & nestedLevel == 3)
            {
                if (!parented)
                {
                    String fieldNameAux = getRelatedAttrName(relFieldName);
                    Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                                                               .get(entityName)
                                                               .getDescribe()
                                                               .fields.getMap()
                                                               .get(fieldNameAux)
                                                               .getDescribe();
                    String parentFieldName = relFieldName.substring(
                        relFieldName.indexOf('.') + 1
                        );
                    //setParentRecord(record, fieldDescribe, parentObjectType, parentFieldName, parenExtKey); // gpacho 2020-05-26
                    setParentRecord(
                        record,
                        fieldDescribe,
                        parentObjectType,
                        parentFieldName,
                        extKeyMap.get(parentFieldName)
                        ); // gpacho 2020-05-26
                }
                if (result.thrLvlRecordsMap.containsKey(entityName) )
                {
                    result.thrLvlRecordsMap.get(entityName).add(record);
                }
                else
                {
                    List<SObject> newRecords = new List<SObject>();
                    newRecords.add(record);
                    result.thrLvlRecordsMap.put(entityName, newRecords);
                }
                parented = false;
            }
            else
            {
                result.errorMessagesMap.put(extKey, getErrorMessage(errorMessages) );
            }
        }
        else
        {
            result.errorMessagesMap.put(extKey, getErrorMessage(errorMessages) );
        }
        errorMessages.clear();
    }

    /**
     * Process a Picklist value. This value can be a String, a pair of id and value, or multiple values
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param Object pickElement
     *  @param WebServicesControl__mdt fieldControl
     *  @param List<String> errorMessages
     *  @param SObject record
     *  @where N/A
     **/
    private static void processPicklistPairs(
        Object pickElement,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages,
        SObject record
        )
    {
        try
        {
            Schema.DescribeFieldResult fieldDescribe = retrieveFieldDescribe(
                fieldControl
                );
            Map<String, String> valuesMap = new Map<String, String>();
            Map<String, Object> mapPick = (Map<String, Object>) pickElement;
            String attrId = '';
            String attrIdSec = '';
            String attrName = '';
            String pickId = '';
            String pickName = '';
            String pickOneId = '';

            if (!String.isBlank(fieldControl.PicklistAttributesName__c) )
            {
                List<String> pickAttrs = fieldControl.PicklistAttributesName__c.split(
                    ';'
                    );
                if (!pickAttrs.isEmpty() )
                {
                    if (pickAttrs.size() == 3)
                    {
                        attrId = pickAttrs.get(0);
                        attrIdSec = pickAttrs.get(1);
                        attrName = pickAttrs.get(2);
                    }
                    else if (pickAttrs.size() == 2)
                    {
                        attrId = pickAttrs.get(0);
                        attrName = pickAttrs.get(1);
                    }
                }
            }
            else
            {
                //TODO:Error al estar los campos en la metadata vacios
            }

            for (String key : mapPick.keySet() )
            {
                if (key.equals(attrId) )
                {
                    if (String.isBlank(attrIdSec) )
                    {
                        pickId = (String) mapPick.get(key);
                    }
                    else
                    {
                        pickOneId = (String) mapPick.get(key);
                    }
                }
                else if (!String.isBlank(attrIdSec) && key.equals(attrIdSec) )
                {
                    pickId = pickOneId + (String) mapPick.get(key);
                }
                else if (key.equals(attrName) )
                {
                    pickName = (String) mapPick.get(key);
                    valuesMap.put(pickName, pickId);
                }
                else
                {
                    //TODO: Añadir mensaje de error
                }

                
                
                String value = null;
                if( fieldDescribe.getPicklistValues() != null && !fieldDescribe.getPicklistValues().isEmpty() )
                {
                    value = checkPicklistValue( valuesMap, errorMessages, fieldControl, fieldDescribe );
                }
                else
                {
                    // Check if there is any value recovered
                    if( valuesMap != null && !valuesMap.keySet().isEmpty() )
                    {
                        // transform set<> intro list<>
                        List<String> keyvalues = new List<String>(valuesMap.keySet() );
                        // Get the first value. There should be only one...
                        value = keyvalues.get(0);
                        if( value != null )
                        {
                            // Truncate the value to the length of the field
                            if( value.length() > fieldDescribe.getLength() && fieldDescribe.getLength() > 0 )
                            {
                                value = value.substring(0, fieldDescribe.getLength() - 1);
                            }
                            // finally check if there are restricted values and if so, filter the value
                            if( fieldControl.PicklistValues__c != null && !fieldControl.PicklistValues__c.contains(keyvalues.get(0) ) )
                            {
                                value = null;
                            }
                        }
                    }
                }
                
                if (!String.isBlank(value) )
                {
                    writeObjectField(record, fieldControl, value, result, errorMessages);
                }
            }
        }
        catch (Exception ex)
        {}
    }

    /**
     * Process a specific value to insert in the record. Check the validity of the value
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param WebParserResult result
     *  @param WebServicesControl__mdt fieldControl
     *  @param SObject record
     *  @param List<String> errorMessages
     *  @return SObject Returns a record with the new value added if it is correct, or and errorMessage if it is wrong
     *  @where N/A
     **/
    private static SObject manageRecordGeneration(WebParserResult result, WebServicesControl__mdt fieldControl, SObject record, Object value, List<String> errorMessages)
    {
        Schema.DescribeFieldResult fieldDescribe;
        String textValue;
        Integer integerValue;
        Double numericValue;
        Date dateValue;
        DateTime dateTimeValue;
        Id idValue;
        Boolean booleanValue;
        Blob fileBody;

        try
        {
            //It validates the value format based on field type
            fieldDescribe = retrieveFieldDescribe(fieldControl);
            switch on fieldDescribe.getSoapType()
            {
                when BOOLEAN {
                    booleanValue = checkBoolean(
                        String.valueOf(value),
                        fieldDescribe,
                        fieldControl,
                        errorMessages
                        ); // gpacho 2020-06-01 (String) value -> String.valueOf(value)

                    if (booleanValue != null)
                    {
                        writeObjectField(
                            record,
                            fieldControl,
                            booleanValue,
                            result,
                            errorMessages
                            );
                    }
                }
                when DATE {
                    if (String.isBlank( (String) value ) )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        dateValue = checkDate(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (dateValue != null)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                dateValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when DATETIME {
                    if (String.isBlank( (String) value ) )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        dateTimeValue = checkDateTime(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (dateTimeValue != null)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                dateTimeValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when DOUBLE {
                    if (
                        String.isBlank(String.valueOf(value) ) // gpacho 2020-06-01
                        )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        numericValue = checkNumeric(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (numericValue != null)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                numericValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when ID {
                    if (String.isBlank( (String) value ) )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        idValue = checkId(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (idValue != null)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                idValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when INTEGER {
                    if (
                        (String.isBlank(String.valueOf(value) ) ) // gpacho 2020-06-01
                        )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        integerValue = checkInteger(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (integerValue != null)
                        {
                            if (fieldControl.External_Id__c)
                            {
                                // gpacho 2020-05-26 start
                                extKeyMap.put(
                                    fieldControl.FieldName__c,
                                    String.valueOf(integerValue)
                                    );
                                //extKey = String.valueOf(integerValue);
                                // gpacho 2020-05-26 end
                            }
                            writeObjectField(
                                record,
                                fieldControl,
                                integerValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when STRING {
                    if (String.isBlank( (String) value ) )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        textValue = checkText(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (!String.isBlank(textValue) )
                        {
                            if (fieldControl.External_Id__c)
                            {
                                // gpacho 2020-05-26 start
                                extKeyMap.put(
                                    fieldControl.FieldName__c,
                                    String.valueOf(textValue)
                                    );
                                //extKey = textValue;
                                // gpacho 2020-05-26 end
                            }

                            if (fieldControl.Attachable__c)
                            {
                                textValue = textValue + '}';
                            }

                            writeObjectField(
                                record,
                                fieldControl,
                                textValue,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                when BASE64BINARY {
                    if (String.isBlank( (String) value ) )
                    {
                        if (fieldControl.Nullable__c)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                null,
                                result,
                                errorMessages
                                );
                        }
                        else
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.AtributoNoAnulable
                                );
                        }
                    }
                    else
                    {
                        fileBody = checkBase64String(
                            value,
                            fieldDescribe,
                            fieldControl,
                            errorMessages
                            );
                        if (fileBody != null)
                        {
                            writeObjectField(
                                record,
                                fieldControl,
                                fileBody,
                                result,
                                errorMessages
                                );
                        }
                    }
                }
                //...Others if necessary
            }
        }
        catch (Exception ex)
        {}
        return record;
    }

    /**
     *  It validates if every required field has been received
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param record(after processing), source, service and result object
     * @return N/A
     *  @throws none
     *  @where at the end of every record processing
     **/
    private static void checkRequiredFields(
        SObject record,
        String source,
        String service,
        List<String> errorMessages
        )
    {
        List<WebServicesControl__mdt> requiredMetadataList = requiredMetadataMap.get(
            source +
            '*' +
            service +
            '*' +
            record.getSobjectType().getDescribe().getName()
            );
        String relFieldName = '';

        if (requiredMetadataList != null && !requiredMetadataList.isEmpty() )
        {
            for (WebServicesControl__mdt control : requiredMetadataList)
            {
                if (control.FieldName__c.contains('.') )
                {
                    relFieldName = getRelatedAttrName(control.FieldName__c);
                    if (record.get(relFieldName) == null)
                    {
                        errorMessages.add(
                            Label.AtributoRequerido +
                            ': ' +
                            control.AttributeName__c
                            );
                    }
                }
                else if (record.get(control.FieldName__c) == null)
                {
                    errorMessages.add(
                        Label.AtributoRequerido +
                        ': ' +
                        control.AttributeName__c
                        );
                }
            }
        }
    }

    /**
     *  It prepares the maps required to process inbound JSONs and generate sample JSONs
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param WebServicesParser control definition
     *  @return void
     *  @throws none
     *  @where Once at the beggining of the parser process
     **/
    private static void processMapControls(WebServicesControl__mdt controlAux)
    {
        List<WebServicesControl__mdt> metadataListAux;
        List<String> sourceListAux = new List<String>();

        if (controlAux.Source__c.contains(';') )
        {
            sourceListAux = controlAux.Source__c.split(',');
        }
        else
        {
            sourceListAux.add(controlAux.Source__c);
        }

        if (!sourceListAux.isEmpty() )
        {
            for (String sourceAux : sourceListAux)
            {
                metadataMap.put(
                    controlAux.Source__c +
                    '*' +
                    controlAux.ServiceName__c +
                    '*' +
                    controlAux.EntityName__c +
                    '*' +
                    controlAux.AttributeName__c,
                    controlAux
                    );
                if (controlAux.Required__c)
                {
                    metadataListAux = requiredMetadataMap.get(
                        controlAux.Source__c +
                        '*' +
                        controlAux.ServiceName__c +
                        '*' +
                        controlAux.EntityName__c
                        );
                    if (metadataListAux == null)
                    {
                        metadataListAux = new List<WebServicesControl__mdt>();
                    }
                    metadataListAux.add(controlAux);
                    requiredMetadataMap.put(
                        controlAux.Source__c +
                        '*' +
                        controlAux.ServiceName__c +
                        '*' +
                        controlAux.EntityName__c,
                        metadataListAux
                        );
                }
            }
        }
    }

    /**
     * Set a unique error Message obtained from a list of errors
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param List<String> errorMessages
     *  @return String A formated error message
     *  @where N/A
     **/
    private static String getErrorMessage(List<String> errorMessages)
    {
        if (errorMessages.size() == 1)
        {
            return errorMessages.get(0);
        }
        else
        {
            String errorMessage = ' ';
            for (String error : errorMessages)
            {
                errorMessage = errorMessage + ' ' + error;
            }
            return errorMessage;
        }
    }

    /**
     *  Inserts string value on a specific field
     *  It takes into account whether the field is a parent record external id or not
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param record to be updated, field details and value to be assigned
     *  @return N/A
     *  @throws none
     *  @where N/A
     **/
    private static void writeObjectField(
        SObject record,
        WebServicesControl__mdt fieldControl,
        Object value,
        WebParserResult result,
        List<String> errorMessages
        )
    {
        String relatedRecordFieldName;
        String fieldNameAux;

        Schema.SObjectType relatedRecordEntityType;
        Schema.DescribeFieldResult fieldDescribe;

        if (!fieldControl.FieldName__c.contains('.') )
        {
            record.put(fieldControl.FieldName__c, value);
        }
        else
        {
            relatedRecordFieldName = fieldControl.FieldName__c.substring(
                fieldControl.FieldName__c.indexOf('.') + 1
                );
            fieldNameAux = getRelatedAttrName(fieldControl.FieldName__c);
            fieldDescribe = Schema.getGlobalDescribe()
                            .get(fieldControl.EntityName__c)
                            .getDescribe()
                            .fields.getMap()
                            .get(fieldNameAux)
                            .getDescribe();

            if (
                fieldControl.RelatedObjectType__c != null &&
                fieldControl.RelatedObjectType__c != ''
                )
            {
                relatedRecordEntityType = Schema.getGlobalDescribe()
                                          .get(fieldControl.RelatedObjectType__c);
            }
            else
            {
                relatedRecordEntityType = fieldDescribe.getReferenceTo()[0];
            }
            setParentRecord(
                record,
                fieldDescribe,
                relatedRecordEntityType,
                relatedRecordFieldName,
                value
                );
        }
    }

    /**
     *  Parent objetcs with provided values
     **
     *  @author raespinosa
     *  @date 18/05/2020
     *  @param SObject record Record to be parented
     *  @param Schema.DescribeFieldResult fieldDescribe Field Describe of the son record to be parented
     *  @param Schema.SObjectType relRecEntityType RecordType of the parent
     *  @param String relRecFieldName Field to relate in the son record
     *  @param Object value Value of the External Id field of the parent
     *  @throws none
     *  @where When the attribute name is required to get his field describre
     **/
    private static void setParentRecord(
        SObject record,
        Schema.DescribeFieldResult fieldDescribe,
        Schema.SObjectType relRecEntityType,
        String relRecFieldName,
        Object value
        )
    {
        
        SObject parentObject;
        parentObject = relRecEntityType.newSObject();
        
        
        
        parentObject.put(relRecFieldName, value);
        record.putSObject(fieldDescribe.getRelationshipName(), parentObject);
        result.upsertRequired = true;
        parented = true;
        
    }

    /**
     *  It returns the real name of the Lookup attribute
     **
     *  @author raespinosa
     *  @date 12/12/2018
     *  @param fieldName The obtained field name from the metadata
     *  @return String The real name of the lookup attribute
     *  @throws none
     *  @where When the attribute name is required to get his field describre
     **/
    private static String getRelatedAttrName(String fieldName)
    {
        String fieldNameAux = fieldName.left(fieldName.indexOf('.') );
        if (fieldNameAux.containsIgnoreCase('__r') )
        {
            fieldNameAux = fieldNameAux.replace('__r', '__c');
        }
        else
        {
            fieldNameAux = fieldNameAux + 'Id';
        }
        return fieldNameAux;
    }

    /**
     *  It validates that a Base64 String value if correct
     **
     *  @author raespinosa
     *  @date 15/01/2019
     *  @param Inbound caller and attribute info
     *  @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Blob checkBase64String(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Blob result;
        try
        {
            String fileValue = (String) value;
            if (String.isBlank(fileValue) )
            {
                result = null;
            }
            else
            {
                result = EncodingUtil.base64Decode(fileValue);
            }
        }
        catch (Exception e)
        {
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.ArchivoNoValido
                    );
            }
        }
        return result;
    }

    /**
     *  It validates that a boolean value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @change 16/04/2020 raespinosa Change the logic to check de Boolean validity
     *  @param Inbound caller and attribute info
     *  @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Boolean checkBoolean(
        String value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Boolean result;

        if (!String.isBlank(value) )
        {
            switch on value.toLowerCase()
            {
                when 'true', 'si', 'sí', 'verdadero', '1', 'yes' {
                    result = true;
                }
                when 'false', 'no', 'falso', '0' {
                    result = false;
                }
                when else
                {
                    if (!fieldControl.IgnoreErrors__c)
                    {
                        errorMessages.add(
                            fieldControl.AttributeName__c +
                            ': ' +
                            Label.BooleanoNoValido
                            );
                    }
                }
            }
        }
        return result;
    }

    /**
     *  It validates that a check value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Date checkDate(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Date result;

        try
        {
            if (String.isBlank( (String) value ) )
            {
                result = null;
            }
            else
            {
                result = Date.valueOf( (String) value );
            }
        }
        catch (Exception ex)
        {
            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.FechaNovalida
                    );
            }
        }
        return result;
    }

    /**
     *  It validates that a date time value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static DateTime checkDateTime(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        DateTime result;

        try
        {
            if (String.isBlank( (String) value ) )
            {
                result = null;
            }
            else
            {
                result = DateTime.valueOf( (String) value );
            }
        }
        catch (Exception ex)
        {
            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.FechaHoraNoValido
                    );
            }
        }
        return result;
    }

    /**
     *  It validates that a numeric value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Double checkNumeric(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Double result;
        Boolean error = false;

        try
        {
            Decimal decValue = Decimal.valueOf(String.valueOf(value) ); // gpacho 2020-06-01
            // There can be Double or Integer fields ("Integer" custom fields are actually Double anyway)
            result = decValue;
            if (decValue.precision() > fieldDescribe.getPrecision() )
            {
                error = true;
                result = null;
                //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                if (!fieldControl.IgnoreErrors__c)
                {
                    errorMessages.add(
                        fieldControl.AttributeName__c +
                        ': ' +
                        Label.PrecisionDobleNoValida +
                        ' - ' +
                        String.valueOf(fieldDescribe.getLength() )
                        );
                }
            }
            else
            {
                if (decValue.scale() > fieldDescribe.getScale() )
                {
                    error = true;
                    result = null;
                    //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                    if (!fieldControl.IgnoreErrors__c)
                    {
                        errorMessages.add(
                            fieldControl.AttributeName__c +
                            ': ' +
                            Label.EscalaNumeroNoValida +
                            ' - ' +
                            fieldDescribe.getScale()
                            );
                    }
                }
            }
        }
        catch (Exception ex)
        {
            result = null;
            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.ErrorDeParseo +
                    ' - ' +
                    ex.getMessage()
                    );
            }
        }

        return result;
    }

    /**
     *  It validates that a Id value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Id checkId(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Id result;

        try
        {
            if (String.isBlank( (String) value ) )
            {
                result = null;
            }
            else
            {
                result = (Id) value;
            }
        }
        catch (Exception ex)
        {
            result = null;
            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.IdNoValido +
                    ' - ' +
                    value
                    );
            }
        }
        return result;
    }

    /**
     *  It validates that a integer value if correct
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static Integer checkInteger(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        Integer result;

        try
        {
            Decimal decValue = Decimal.valueOf( (String) value );

            if (decValue.precision() > fieldDescribe.getDigits() )
            {
                result = null;
                //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                if (!fieldControl.IgnoreErrors__c)
                {
                    errorMessages.add(
                        fieldControl.AttributeName__c +
                        ': ' +
                        Label.PrecisionNumeroNoValida +
                        ' - ' +
                        fieldDescribe.getDigits()
                        );
                }
            }
            else
            {
                result = Integer.valueOf( (String) value );
            }
        }
        catch (Exception ex)
        {
            result = null;
            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.EnteroNoValido
                    );
            }
        }
        return result;
    }

    /**
     * Check a picklist value obtained from the Json
     **
     *  @author raespinosa
     *  @date 13/04/2020
     *  @param Map<String, String> valuesMap
     *  @param List<String> errorMessages
     *  @param WebServicesControl__mdt fieldControl
     *  @param Schema.DescribeFieldResult fieldDescribe
     *  @return String A valid value of the picklist field is it is a correct value, errorMessage if the value is wrong
     *  @where N/A
     **/
    private static String checkPicklistValue(
        Map<String, String> valuesMap,
        List<String> errorMessages,
        WebServicesControl__mdt fieldControl,
        Schema.DescribeFieldResult fieldDescribe
        )
    {
        String result;

        if (errorMessages.isEmpty() )
        {
            Map<String, String> validValuesMap = new Map<String, String>();
            //If the metadata control specifies which values to accept, it won't check the field Schema
            if (!string.isBlank(fieldControl.PicklistValues__c) )
            {
                List<String> availableValuesList = fieldControl.PicklistValues__c.split(
                    ';'
                    );
                if (fieldControl.Object__c)
                {
                    List<Schema.PicklistEntry> picklistEntriesList = fieldDescribe.getPicklistValues();
                    for (Schema.PicklistEntry entry : picklistEntriesList)
                    {
                        if (availableValuesList.contains(entry.getLabel() ) )
                        {
                            validValuesMap.put(entry.getLabel(), entry.getValue() );
                            validValuesMap.put(entry.getValue(), entry.getLabel() );
                        }
                    }
                }
                else
                {
                    for (String validValue : availableValuesList)
                    {
                        validValuesMap.put(validValue, validValue);
                    }
                }
            }
            else
            {
                List<Schema.PicklistEntry> picklistEntriesList = fieldDescribe.getPicklistValues();
                for (Schema.PicklistEntry entry : picklistEntriesList)
                {
                    validValuesMap.put(entry.getLabel(), entry.getValue() );
                    validValuesMap.put(entry.getValue(), entry.getLabel() );
                }
            }

            if (validValuesMap != null && !validValuesMap.isEmpty() )
            {
                for (String key : valuesMap.keySet() )
                {
                    String valueAux = valuesMap.get(key);

                    if (!validValuesMap.containsKey(valueAux) )
                    {
                        if (!fieldControl.IgnoreErrors__c)
                        {
                            errorMessages.add(
                                fieldControl.AttributeName__c +
                                ': ' +
                                Label.ValorListaNoValido +
                                ': ' +
                                valueAux
                                );
                            result = null;
                        }
                        else
                        {
                            result = key;
                        }
                    }
                    else
                    {
                        result = valueAux;
                    }
                }
            }
            else
            {
                result = null;
            }
        }
        else
        {
            result = null;
        }

        return result;
    }

    /**
     *  It validates that a text value if correct
     ** Aquí se verifica el valor del picklist
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     * @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static String checkText(
        Object value,
        Schema.DescribeFieldResult fieldDescribe,
        WebServicesControl__mdt fieldControl,
        List<String> errorMessages
        )
    {
        String result;
        try
        {
            result = (String) value;
            if (String.isBlank(result) )
            {
                result = null;
            }
            else
            {
                if (result.length() > fieldDescribe.getLength() )
                {
                    //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                    if (!fieldControl.IgnoreErrors__c)
                    {
                        errorMessages.add(
                            fieldControl.AttributeName__c +
                            ': ' +
                            Label.LongitudTextoNoValida +
                            ' - ' +
                            String.valueOf(fieldDescribe.getLength() )
                            );
                        result = null;
                    }
                }
                else
                {
                    if (
                        fieldDescribe.getType() == Schema.DisplayType.Picklist ||
                        fieldDescribe.getType() == Schema.DisplayType.MultiPicklist
                        )
                    {
                        Map<String, String> valuesMap = new Map<String, String>();

                        if (fieldDescribe.getType() == Schema.DisplayType.MultiPicklist)
                        {
                            List<String> valuesList = new List<String>();
                            valuesList = result.split(';');
                            for (String val : valuesList)
                            {
                                valuesMap.put(val, val);
                            }
                        }
                        else
                        {
                            //If it is single Picklist field, the whole text is considered as a single value
                            valuesMap.put(result, result);
                        }

                        checkPicklistValue(
                            valuesMap,
                            errorMessages,
                            fieldControl,
                            fieldDescribe
                            );
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.Email)
                    {
                        Pattern emailPattern = Pattern.compile(
                            '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'
                            );
                        Matcher emailMatcher = emailPattern.matcher(result);
                        if (!emailMatcher.matches() )
                        {
                            result = null;
                            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                            if (!fieldControl.IgnoreErrors__c)
                            {
                                errorMessages.add(
                                    fieldControl.AttributeName__c +
                                    ': ' +
                                    Label.EmailNoValido
                                    );
                            }
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.URL)
                    {
                        Pattern urlPattern = Pattern.compile(
                            '^((http|https)://)??(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9(-|/|=|?)??]+?)+?$'
                            );
                        Matcher urlMatcher = urlPattern.matcher(result);
                        if (!urlMatcher.matches() )
                        {
                            result = null;
                            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                            if (!fieldControl.IgnoreErrors__c)
                            {
                                errorMessages.add(
                                    fieldControl.AttributeName__c +
                                    ': ' +
                                    Label.URLNoValida
                                    );
                            }
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.Phone)
                    {
                        Pattern phonePattern = Pattern.compile('^[+]{0,1}[0-9]*?$');
                        String valueTrimmed = result.replace('(', '');
                        valueTrimmed = valueTrimmed.replace(')', '');
                        valueTrimmed = valueTrimmed.replace(' ', '');
                        valueTrimmed = valueTrimmed.replace('.', '');
                        valueTrimmed = valueTrimmed.replace('\'', '');
                        Matcher phoneMatcher = phonePattern.matcher(valueTrimmed);
                        if (!phoneMatcher.matches() )
                        {
                            result = null;
                            //If errors are not ignored for this field, the error message is thrown, else the field is just not included
                            if (!fieldControl.IgnoreErrors__c)
                            {
                                errorMessages.add(
                                    fieldControl.AttributeName__c +
                                    ': ' +
                                    Label.TelefonoNoValido +
                                    ' - ' +
                                    value
                                    );
                            }
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            if (!fieldControl.IgnoreErrors__c)
            {
                errorMessages.add(
                    fieldControl.AttributeName__c +
                    ': ' +
                    Label.ErrorDeParseo +
                    ' - '
                    );
                result = null;
            }
        }
        return result;
    }

    /**
     *  Obtains the Apex field Describe based of field data
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param fieldControl including name, service, method...
     * @return records data structure
     *  @throws none
     *  @where N/A
     **/
    private static Schema.DescribeFieldResult retrieveFieldDescribe(
        WebServicesControl__mdt fieldControl
        )
    {
        Schema.DescribeFieldResult fieldDescribe;

        //ORIGINAL
        if (!fieldControl.FieldName__C.contains('.') )
        {
            fieldDescribe = getFieldDescribe(
                null,
                fieldControl.EntityName__c,
                fieldControl.FieldName__c
                );
        }
        else
        {
            Schema.SObjectType entityType;

            //If it is a related record field
            if (
                fieldControl.RelatedObjectType__c != null &&
                fieldControl.RelatedObjectType__c != ''
                )
            {
                entityType = Schema.getGlobalDescribe()
                             .get(fieldControl.RelatedObjectType__c);
            }
            else
            {
                String fieldNameAux = getRelatedAttrName(fieldControl.FieldName__c);
                fieldDescribe = getFieldDescribe(
                    null,
                    fieldControl.EntityName__c,
                    fieldNameAux
                    );
                List<Schema.sObjectType> entityTypesList = fieldDescribe.getReferenceTo();
                entityType = entityTypesList[0];
            }
            getFieldDescribe(
                entityType,
                fieldControl.EntityName__c,
                fieldControl.FieldName__c.substring(
                    fieldControl.FieldName__c.indexOf('.') + 1
                    )
                );
        }

        return fieldDescribe;
    }

    /**
     *  Obtains the Apex field Describe based of field data
     **
     *  @author raespinosa
     *  @date 17/04/2020
     *  @param Schema.SObjectType entityType Type of the Salesforce Object to obtain the describe
     *  @param String entityName Type of the Salesforce Object to obtain the describe
     *  @param String fieldName Field who want to obtain the describe
     *  @return Schema.DescribeFieldResult The describe of the single field of a SObject type received
     *  @throws none
     *  @where N/A
     **/
    private static Schema.DescribeFieldResult getFieldDescribe(
        Schema.SObjectType entityType,
        String entityName,
        String fieldName
        )
    {
        Map<String, Schema.SObjectField> fieldsMap;
        if (entityType == null)
        {
            entityType = Schema.getGlobalDescribe().get(entityName);
            fieldsMap = entityType.getDescribe().fields.getMap();
            return fieldsMap.get(fieldName).getDescribe();
        }
        else
        {
            fieldsMap = entityType.getDescribe().fields.getMap();
            return fieldsMap.get(fieldName).getDescribe();
        }
    }

    /**
     *  It validates if the onbound attribute must be processed
     **
     *  @author dontalvilla
     *  @date 05/05/2017
     *  @param Inbound caller and attribute info
     *  @return WebServicesParser record definition
     *  @throws none
     *  @where once per each parameter
     **/
    private static WebServicesControl__mdt checkFieldProcessing(
        String source,
        String service,
        Schema.SObjectType entity,
        String attribute
        )
    {
        if (
            string.isBlank(source) ||
            string.isBlank(service) ||
            entity == null ||
            string.isBlank(attribute)
            )
        {
            return null;
        }

        return metadataMap.get(
            source +
            '*' +
            service +
            '*' +
            entity.getDescribe().getName() +
            '*' +
            attribute
            );
    }
}