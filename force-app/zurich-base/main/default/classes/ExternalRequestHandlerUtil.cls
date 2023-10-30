/**
 * @description       : Clase Util que contiene los métodos necesarios para procesar las external request de tipo INFO
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 05-23-2023
 * @last modified by  : aberuete
**/
global with sharing class ExternalRequestHandlerUtil 
{
    
    public static Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToUpsertByEntity = new Map<String, Map<String, Map<sObject, ExternalRequest__c>>>();
    public static Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToDeleteByEntity = new Map<String, Map<String, Map<sObject, ExternalRequest__c>>>();
    public static List<ExternalRequest__c> externalRequestResultList = new List<ExternalRequest__c>();
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    //CUSTOM METADATA
    public static Transformer tf;
    public static Map<String, Map<String, String>> externalIdByEntity = new Map<String, Map<String, String>>();
    public static Map<String, Map<String, Map<String,String>>> mapRobotHegeoFieldsMapping = new Map<String, Map<String, Map<String,String>>> ();
    public static Integer maxRetries;

    // Orden de DML sobre entidades
    public static List<Decimal> entityIndexes = new List<Decimal>();
    public static Map<Decimal, String> entitiesByPrirority = new Map<Decimal, String>();
    public static final String SOBJECT_ACCOUNT = 'Account';
    public static final String SOBJECT_CONTACT = 'Contact';
    public static final String SOBJECT_CONTACT_POINT_ADDRESS = 'ContactPointAddress';
    public static final String SOBJECT_CONTACT_POINT_PHONE = 'ContactPointPhone';
    public static final String SOBJECT_CONTACT_POINT_EMAIL = 'ContactPointEmail';
    public static final String SOBJECT_PRODUCT = 'Product2';
    public static final String SOBJECT_OPPORTUNITY = 'Opportunity';
    public static final String SOBJECT_QUOTE = 'Quote';
    public static final String SOBJECT_POLICY = 'Policy__c';
    public static final String SOBJECT_ASSET = 'Asset';
    public static final String SOBJECT_CLAIM = 'Claim__c';
    public static final String SOBJECT_RELATIONSHIP = 'Relationship__c';
    public static final String SOBJECT_CASE = 'Case';
    public static final String SOBJECT_SPECIAL_CONDITION = 'Special_Condition__c';
    public static final String SOBJECT_KPI = 'KPI__c';

    // Orden de DML sobre SObjects
    private static List<String> sObjectOrder = new List<String>
    {
        SOBJECT_ACCOUNT,
        SOBJECT_CONTACT,
        SOBJECT_KPI,
        SOBJECT_CONTACT_POINT_ADDRESS,
        SOBJECT_CONTACT_POINT_PHONE,
        SOBJECT_CONTACT_POINT_EMAIL,
        SOBJECT_PRODUCT,
        SOBJECT_OPPORTUNITY,
        SOBJECT_QUOTE,
        SOBJECT_POLICY,
        SOBJECT_ASSET,
        SOBJECT_CLAIM,
        SOBJECT_RELATIONSHIP,
        SOBJECT_CASE,
        SOBJECT_SPECIAL_CONDITION
    };

    /**
     * Obtiene la información necesaria para poder procesar las external request pendientes
     **
     * @author aberuete
     * @date 17/05/2023
     * @param Transformer transformerByOrigin : Instancia de la clase que tranforma un origen de datos en objetos Salesforce
     * @param String origin : Origen de la external request
     */
    public static void prepareExternalRequestToProcess(Transformer transformerByOrigin, String origin)
    {
        // 1 - Obtener el tranformer a utilizar
        tf = transformerByOrigin;

        // 2 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
        recordsToUpsertByEntity = tf.initRequestsMapBySettings();
        recordsToDeleteByEntity = tf.initRequestsMapBySettings();

        // 3 - Obtener identificadores externos por cada entidad
        for (ExternalIdField__mdt externalId : new ExternalIdFieldsSelector
            (new List<Schema.SObjectField> {ExternalIdField__mdt.OriginEntity__c, ExternalIdField__mdt.SalesforceEntity__c, ExternalIdField__mdt.ExternalId__c}
            ).selectByOrigin(new Set<String> {origin}) )
        {
            if(!externalIdByEntity.containsKey(externalId.OriginEntity__c))
            {
                externalIdByEntity.put(externalId.OriginEntity__c, new Map<String, String>());
            }
            externalIdByEntity.get(externalId.OriginEntity__c).put(externalId.SalesforceEntity__c, externalId.ExternalId__c);
        }

        // 4 - Obtener el número máximo de reintentos
        maxRetries = (Integer) new ExternalJobQueueBatchesSelector
        (
            new List<Schema.SObjectField> {ExternalJobQueueBatch__mdt.Retries__c}
        ).selectByOrigin(new Set<String> {origin}).get(0).Retries__c;

        // 5 - Cargar mapa con orden de prioridades
        fillEntitiesByPriorityMap();

        // Cargar mapa de tipificaciones 
        fillMapRobotHegeoFieldsMapping ();
    }

    /**
     * Realiza las operaciones DML sobre la BBDD y actualiza la información de las external request procesadas
     **
     * @author aberuete
     * @date 17/05/2023
     * @param String classHandler : Nombre de la clase handler que llama al método
     */
    public static void persistExternalRequest (String classHandler)
    {
        try
        {
            // Upsert
            if ( recordsToUpsertByEntity != null && !recordsToUpsertByEntity.isEmpty() )
            {
                persistRecords('UPSERT', recordsToUpsertByEntity);
            }
            // Delete
            if ( recordsToDeleteByEntity != null && !recordsToDeleteByEntity.isEmpty() )
            {
                persistRecords('DELETE', recordsToDeleteByEntity);
            }

        }
        catch (Exception e)
        {
            
            ErrorLogUtil.commitError(e, classHandler, 'persists');
        }
    }

    /**
     * Actualiza las external request procesadas con el resultado obtenido en las operaciones DML
     **
     * @author aberuete
     * @date 17/05/2023
     * @param jobId Id del job que se está ejecutando
     * @param externalRequestList : Lista de external request que deben ser procesadas
     * @param String classHandler : Nombre de la clase handler que llama al método
     */
    public static void manageResultExternalRequest(Id jobId, List<ExternalRequest__c> externalRequestList, String classHandler)
    {
        List<ExternalRequestErrorEvent__e> erErrorEventList = new List<ExternalRequestErrorEvent__e>();

        try
        {
            if ( externalRequestResultList != null && !externalRequestResultList.isEmpty() )
            {
                // 1 - Actualizar las external request con el resultado
                Database.update(externalRequestResultList,false);

                // 2 - Publicar las external request que no se hayan procesado correctamente
                for ( ExternalRequest__c externalRequest : externalRequestResultList )
                {
                    try
                    {
                        // 2.1 - Solo publicar evento de error si el resultado es 'KO' y se ha superado el número máximo de reintentos
                        if ( externalRequest.Processed__c && externalRequest.ProcessResult__c == 'KO' )
                        {
                            erErrorEventList.add
                            (
                                new ExternalRequestErrorEvent__e
                                (
                                    JobId__c = jobId,
                                    RecordId__c = externalRequest.Id,
                                    Origin__c = externalRequest.Origin__c,
                                    Entity__c = externalRequest.Entity__c,
                                    Action__c = externalRequest.Action__c,
                                    ContentFormat__c = externalRequest.ContentFormat__c,
                                    Payload__c = externalRequest.Payload__c,
                                    Message__c = externalRequest.Error_Log__c,
                                    StackTrace__c = externalRequest.Error_Log__c,
                                    ThrowingTime__c = Datetime.now(),
                                    ExternalRequestCreatedDate__c = externalRequest.CreatedDate
                                )
                            );
                        }
                    }
                    catch ( Exception e )
                    {
                        
                        ErrorLogUtil.commitError(e, classHandler, 'manageResult');
                    }
                }

                // 3 - Publicar external request erróneas
                if ( !erErrorEventList.isEmpty() )
                {
                    EventBus.publish(erErrorEventList);
                }
            }
        }
        catch ( Exception e )
        {
            
            ErrorLogUtil.commitError(e, classHandler, 'manageResult');
        }
    }

    /**
     * Realizar las operaciones DML sobre los registros generados
     **
     * @author adelgado
     * @date 05/11/2020
     * @param action Acción a realizar sobre los registros
     * @param recordsToPersist Mapa con los registros sobre los que realizar las operaciones DML por objeto
     * @return void
     * @change 10/05/2023 - nts (aberuete) - Se mueve el método de la clase INFOhandler a clase Util y se refactoriza
     */
    public static void persistRecords(String action, Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToPersist)
    {
        // 1 - Realizar las operaciones DML sobre los registros generados y actualizar external request con resultado
        for ( Decimal index : entityIndexes )
        {
            String entity = entitiesByPrirority.get(index);
            
            if ( recordsToPersist.containsKey(entity) )
            {
                for ( String objectName : sObjectOrder )
                {
                    persistRecordsUpsertOrDelete (action, recordsToPersist, entity, objectName);
                }
            }
        }
    }

    /**
     * Informar la external request con el resultado del procesamiento
     **
     * @author adelgado
     * @date 05/11/2020
     * @param externalRequest External request que debe ser informada
     * @param processed Indica si se ha procesado la external request
     * @param processResult Resultado del procesamiento de la external request
     * @param error Error que se ha producido al procesar la external request
     * @param sumRetry Indica si hay que sumar un reinteto
     * @return void
     *
     * @change 31/05/2021 - nts (agonzalezisasi) - Al marcar la external request como procesada se cambia tambien el record type
     * @change 20/04/2023 - nts (amiranda) - Se indica la fecha de procesamiento cuando la ER se haya procesado ('KO' inclusive)
     * @change 10/05/2023 - nts (aberuete) - Se mueve el método de la clase INFOhandler a clase Util
     */
    public static void setExternalRequest(ExternalRequest__c externalRequest, Boolean processed, String processResult, String error, Boolean sumRetry)
    {
        if(!externalRequestResultList.contains(externalRequest))
        {
            // 1 - Sumar un reintento a la external request
            if(sumRetry)
            {
                externalRequest.NumRetry__c = externalRequest.NumRetry__c == null ? 1: externalRequest.NumRetry__c + 1;
            }
            
            // 2 - Si se supera el número de reintentos se marca la external request como procesada
            if ( externalRequest.NumRetry__c >= maxRetries )
            {
                externalRequest.Processed__c = true;
            }
            else
            {
                externalRequest.Processed__c = processed;
            }

            if( externalRequest.Processed__c ) 
            {
                Id recordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFOProcessed').getRecordTypeId();
                externalRequest.RecordTypeId = recordTypeId;

                // Si se marca la external request como procesada se indica la fecha de procesamiento
                externalRequest.processedDate__c = Datetime.now();
            }

            externalRequest.ProcessResult__c = processResult;
            externalRequest.Error_Log__c = error;

            externalRequestResultList.add(externalRequest);
        }
    }

    /**
     * Añadir registros generados al mapa correspondiente dependiendo de la acción a realizar UPSERT/DELETE
     **
     * @author adelgado
     * @date 05/11/2020
     * @param externalRequest External request que debe ser añadida al mapa
     * @param sObjectType Objeto de Salesforce
     * @param record Registro generado
     * @return void
     * @change 10/05/2023 - nts (aberuete) - Se mueve el método de la clase INFOhandler a clase Util
     */
    public static void addRecordToMap(ExternalRequest__c externalRequest, String entity, String sObjectType, sObject record)
    {
        if(externalRequest.Action__c.equalsIgnoreCase('UPSERT'))
        {
            recordsToUpsertByEntity.get(entity).get(sObjectType).put(record, externalRequest);
        }
        else if(externalRequest.Action__c.equalsIgnoreCase('DELETE'))
        {
            recordsToDeleteByEntity.get(entity).get(sObjectType).put(record, externalRequest);
        }
    }

    /**
     * Método que rellena el mapa de entidades por prioridad
     **
     * @author aberuete
     * @date 17/05/2023
     */
    public static void fillEntitiesByPriorityMap()
    {
        if(entitiesByPrirority != null && entitiesByPrirority.isEmpty())
        {
            List<EntityOrderMapping__mdt> orderValues = EntityOrderMapping__mdt.getAll().values();

            for(EntityOrderMapping__mdt entity : orderValues)
            {
                entitiesByPrirority.put(entity.Priority__c, entity.Entity__c);
            }

            // Se añáden los índices a una lista ordenada
            entityIndexes.addAll(entitiesByPrirority.keySet());
            entityIndexes.sort();
        }
    }

    /**
     * Método que actualiza el campo index de la external request con la prioridad que tiene la entidad en ser procesada
     **
     * @author aberuete
     * @date 17/05/2023
     * @param List<ExternalRequest__c> erList : Lista de external requests
     */
    public static void setERIndex(List<ExternalRequest__c> erList)
    {
        for(ExternalRequest__c currentER : erList)
        {
            for(Decimal index : entitiesByPrirority.keySet())
            {
                if (entitiesByPrirority.get(index) == currentER.Entity__c)
                {
                    currentER.Index__c = index;
                }
            }
        }
    }

    /**
     * Método que rellena el mapa de tipificaciones
     **
     * @author aberuete
     * @date 17/05/2023
     */
    public static void fillMapRobotHegeoFieldsMapping ()
    {
        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = Robot_Hegeo_Field_Mapping__mdt.getAll().values();
        String sourceType;
        String sourceSubtype;
        Map<String, String> subtypeAndtype3; 
        Map<String, Map<String,String>> mapTipification;

        for (Robot_Hegeo_Field_Mapping__mdt fieldMapping : robotHegeoFieldsMapping)
        {
            sourceType = fieldMapping.SourceType__c; 
            sourceSubtype = fieldMapping.SourceSubtype__c;

            if (sourceType != null || sourceSubtype != null)
            {
                subtypeAndtype3 = new Map<String,String>();
                mapTipification = new Map<String, Map<String,String>> ();
                subtypeAndtype3.put(fieldMapping.Subtype__c,fieldMapping.TypeN3__c);
                mapTipification.put (fieldMapping.Type__c, subtypeAndtype3);
                mapRobotHegeoFieldsMapping.put(sourceType + sourceSubtype,mapTipification);
            } 
        }
    }

    /**
     * Método que obtiene la tipificación del caso y actualiza sus valores
     **
     * @author aberuete
     * @date 17/05/2023
     * @param Map<String, Object> recordValuesMap : Mapa que contiene el valor del json de la external request
     * @param String sourceType : Nombre del campo en el json de la external request correspondiente al valor sourceType del metadato Robot Hegeo Fields Mapping
     * @param String sourceSubtype : Nombre del campo en el json de la external request correspondiente al valor sourceSubtype del metadato Robot Hegeo Fields Mapping
     * @param Case caseRecord : Caso a actualizar
     */
    public static Case fillTypificationIntoCase (Map<String, Object> recordValuesMap, String sourceType, String sourceSubtype, Case caseRecord)
    {
        if( recordValuesMap.containsKey(sourceType) && recordValuesMap.containsKey(sourceSubtype) ) 
        {
            String infoType = (String)recordValuesMap.get(sourceType);
            String infoSubtype = (String)recordValuesMap.get(sourceSubtype);

            Map<String,Map<String,String>> mapTipificacion = mapRobotHegeoFieldsMapping.get(infoType + infoSubtype);
            
            if ( mapTipificacion != null && !mapTipificacion.isEmpty() )
            {
                caseRecord.Type = mapTipificacion.keySet().iterator().next();
                caseRecord.SubType__c = mapTipificacion.values()[0].keySet().iterator().next();
                caseRecord.TypeN3__c = mapTipificacion.values()[0].values()[0];  
            }
        } 
        
        return caseRecord;
    }

    /**
     * Método que obtiene el campo externalId asociado a la entidad y llama a los métodos que realizan las operaciones DML sobre la BBDD
     **
     * @author aberuete
     * @date 17/05/2023
     * @param String action: Indica la acción a realizar Upsert o Delete 
     * @param Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToPersist: Mapa que contiene los registros para realizar las operaciones DML
     * @param String entity : Nombre de la entidad
     * @param String objectName: Nombre del objeto en salesforce
     */
    private static void persistRecordsUpsertOrDelete (String action, Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToPersist, String entity, String objectName)
    {
        List<sObject> recordList;
        List<ExternalRequest__c> externalRequestList;

        if ( recordsToPersist.get(entity).containsKey(objectName) && !recordsToPersist.get(entity).get(objectName).isEmpty() )
        {
            Schema.SObjectField externalIdField = null;
            
            if (externalIdByEntity.get(entity) != null )
            {
                externalIdField = globalDescribe.get(objectName).getDescribe().fields.getMap().get(externalIdByEntity.get(entity).get(objectName));
            }
            
            recordList = new List<sObject>(recordsToPersist.get(entity).get(objectName).keySet());
            externalRequestList = recordsToPersist.get(entity).get(objectName).values();

            //Upsert Record
            persisRecordsUpsert (action, recordList, externalIdField, externalRequestList);

            //Delete Record
            persisRecordsDelete (action, recordList, externalIdField, externalRequestList, objectName);
        }
    }

    /**
     * Método encargado de realizar la operación UPSERT para actualizar o crear los registros de las external request en salesforce
     **
     * @author aberuete
     * @date 17/05/2023
     * @param String action: Indica la acción a realizar Upsert o Delete 
     * @param List<sObject> recordList : Lista de registros a crear o actualizar
     * @param Schema.SObjectField externalIdField : Campo externalId asociado a la entidad utilizado para actualizar el registro
     * @param List<ExternalRequest__c> externalRequestList : Lista de external request
     */
    private static void persisRecordsUpsert (String action,  List<sObject> recordList,  Schema.SObjectField externalIdField, List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequest__c extReq;

        if(action == 'UPSERT')
        {
            Database.UpsertResult[] resultList;

            if (externalIdField != null)
            {
                resultList = Database.upsert(recordList, externalIdField, false);
            }
            else 
            {
                resultList = Database.upsert(recordList, false);  
            }

            for(Integer i = 0; i < externalRequestList.size(); i++)
            {
                extReq = externalRequestList.get(i);

                //Procesamiento correcto
                if ( resultList.get(i).isSuccess() )
                {
                    setExternalRequest(extReq, true, 'OK', null, false);
                }
                
                //Procesamiento incorrecto
                else
                {
                    setExternalRequest(extReq, false, 'KO', string.join(resultList.get(i).getErrors(), '\n'), true);
                }
            }
        }  
    }

    /**
     * Método encargado de realizar la operación DELETE para borrar los registros de las external request en salesforce
     **
     * @author aberuete
     * @date 17/05/2023
     * @param String action: Indica la acción a realizar Upsert o Delete 
     * @param List<sObject> recordList : Lista de registros a borrar
     * @param Schema.SObjectField externalIdField : Campo externalId asociado a la entidad utilizado para borrar el registro
     * @param List<ExternalRequest__c> externalRequestList : Lista de external request
     * @param String objectName : Nombre del objeto en salesforce
     */
    private static void persisRecordsDelete (String action,  List<sObject> recordList,  Schema.SObjectField externalIdField, List<ExternalRequest__c> externalRequestList, String objectName)
    {
        ExternalRequest__c extReq;

        if(action == 'DELETE' && externalIdField != null)
        {
            Set<String> externalIdValues = new Set<String>(); //Query.apex no permite sObject
            
            for(sObject sObj : recordList)
            {
                externalIdValues.add((String) sObj.get(externalIdField));
            }

            Database.DeleteResult[] resultList = Database.delete(new Query(globalDescribe.get(objectName)).addConditionIn(externalIdField, externalIdValues).run());

            for(Integer i = 0; i < externalRequestList.size(); i++)
            {
                extReq = externalRequestList.get(i);

                //Procesamiento correcto
                if ( resultList.get(i).isSuccess() )
                {
                    setExternalRequest(extReq, true, 'OK', null, false);
                }
                
                //Procesamiento incorrecto
                else
                {
                    setExternalRequest(extReq, false, 'KO', string.join(resultList.get(i).getErrors(), '\n'), true);
                }
            }
        }
        else if (externalIdField == null)
        {
            for (ExternalRequest__c extRequest :externalRequestList)
            {
                setExternalRequest(extRequest, true, 'KO', 'No se puede borrar el registro ya que no tiene un campo external id asociado', false); 
            } 
        }
    }

    /**
     * Recorremos todas las external requests para consultar aquellos mediadores que llegan en los mensajes de INTERMEDIARY_HIERARCHY
     **
     * @author dmunoz
     * @date 27/10/2023
     * @param externalRequest External request que debe ser añadida al mapa
     * @param Map account key codigo de mediador
     * @return List<Account>
     */
    public static Map<String, Account> getIntermediaryData(List<ExternalRequest__c> externalRequestList) {
        Map<String, Account> result = new Map<String, Account>();
        List<String> intermediaryCodesList = new List<String>();

        Map<String, Object> recordValuesMap;
        Account intermediaryHierarchy;

        // recorremos todas las external request para obtener la lista de códigos de mediador de los mensajes INTERMEDIARY_HIERARCHY
        for (ExternalRequest__c er: externalRequestList) {
            if ('INTERMEDIARY_HIERARCHY'.equals(er.Entity__c.toUpperCase())) {
                recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(er.Payload__c);
                intermediaryHierarchy = (Account) ExternalRequestHandlerUtil.tf.transform('INTERMEDIARY_HIERARCHY', 'Account', recordValuesMap);
                intermediaryCodesList.add(intermediaryHierarchy.INFOIntermediaryCode__c);
            }
        }

        // una vez hemos obtenido la lista de codigos de mediador, lanzamos la consulta a bd
        List<Account> intermediaryList = (new AccountsSelector()).findByIntermediaryCode(intermediaryCodesList);

        // Convertimos la lista en un map con clave código de mediador INFOIntermediaryCode__c
        for (Account acc: intermediaryList)  {
            result.put(acc.INFOIntermediaryCode__c, acc);
        }

        return result;
    }



    /**
     *Se procesa cada registro de los mensajes procedentes de INFO INTERMEDIARY_HIERARCHY para gestionar la fecha de baja de la relación así como la de la agrupación
     **
     * @author dmunoz
     * @date 25/10/2023
     * @param externalRequest External request que debe ser añadida al mapa
     * @param record Registro generado
     * @return void
     */
    public static void processIntermediaryHierarchy(ExternalRequest__c externalRequest, String entity, Account record, Map<String, Account> intermediaryQueryMap) {

        // compruebo primero si el mediador existe en el sistema
        if (!intermediaryQueryMap.isEmpty() && intermediaryQueryMap.containsKey(record.INFOIntermediaryCode__c)) {

            Account intermediary = intermediaryQueryMap.get(record.INFOIntermediaryCode__c);

            // compruebo primero si existe en el mapa un registro            
            sObject accountFromKeyMap;
            Boolean existeAltaAgrupacionEnMap = false;
    
            for (sObject acc: recordsToUpsertByEntity.get(entity).get('Account').keySet()) {
                if (record.INFOIntermediaryCode__c.equals(acc.get('INFOIntermediaryCode__c'))) {
                    accountFromKeyMap = acc;
                    existeAltaAgrupacionEnMap = acc.get('IntermediaryEndDate__c') == null; // si es nulo true, si no false
                    break;
                }
            }

            // si no existe alta en agrupacion se comprueba las bajas
            record = processEndDate(record, intermediary, existeAltaAgrupacionEnMap);
            
            // guarda en el registro del mapa el registro válido teniendo en cuenta que si es alta se guarda siempre sin tener nada más en cuenta y si es una baja nos quedamos con el de fecha más reciente
            processRecord(record, accountFromKeyMap, externalRequest, existeAltaAgrupacionEnMap, entity);

        } else {
            setExternalRequest(externalRequest, true, 'KO', 'No se ha podido encontrar en BD el mediador con código ' + record.INFOIntermediaryCode__c, false);
        }        
    }

    /**
     * Si no existe alta en agrupacion se comprueba las bajas
     **
     * @author dmunoz
     * @date 25/10/2023
     * @param intermediary mediador buscado en base de datos
     * @param record Registro generado
     * @param existeAltaAgrupacionEnMap existe un alta en el map
     * @return void
     */
    private static Account processEndDate(Account record, Account intermediary, Boolean existeAltaAgrupacionEnMap) {
        if (!existeAltaAgrupacionEnMap && record.get('IntermediaryEndDate__c') != null) { // si llega el mensaje sin fecha de fin es que es un alta, saltamos el registro 
            // si la fecha de baja llega informado y si la agrupacion en bd apunta a la misma agrupacion que el mensaje indica se blanquea la relación entre el mediador y su agrupación
            if (record.IntermediaryEndDate__c != null && intermediary.IntermediaryGroup__r.INFOIntermediaryGroupCode__c.equals(record.IntermediaryGroup__r.INFOIntermediaryGroupCode__c)) {                    
                blankIntermediaryGroup(record);
                
            } else if (intermediary.IntermediaryGroup__r.IntermediaryGroupEndDate__c != null) { // si no está informada se consulta si la agrupación está en baja para blanquearla           
                blankIntermediaryGroup(record);
            } 
        } 
        return record; 
    }

    private static void blankIntermediaryGroup(Account record) {
        record.IntermediaryGroup__c = null;
        record.IntermediaryGroup__r = null; // seteamos el __r a nulo ya que en el transformer añade una referencia como se puede ver en el equals "record.IntermediaryGroup__r.INFOIntermediaryGroupCode__c"
    }

    /**
     * Guarda en el registro del mapa el registro válido teniendo en cuenta que si es alta se guarda siempre sin tener nada más en cuenta y si es una baja nos quedamos con el de fecha más reciente
     **
     * @author dmunoz
     * @date 25/10/2023
     * @param intermediary mediador buscado en base de datos
     * @param accountFromKeyMap sObject de account con el registro a procesar mas adelante en el batch para hacer el upsert
     * @param record Registro generado
     * @param existeAltaAgrupacionEnMap existe un alta en el map
     * @return void
     */
    private static void processRecord(Account record, sObject accountFromKeyMap, ExternalRequest__c externalRequest, Boolean existeAltaAgrupacionEnMap, String entity) {
        if (accountFromKeyMap == null) { // si no hay ningun registro en el mapa lo añado
            addRecordToMap(externalRequest, entity, 'Account', record);

        } else if (accountFromKeyMap != null && record.IntermediaryEndDate__c == null) { // si se trata de un alta reseteamos el registro del mapa, ojo si la agrupacion está en baja se ha reseteado la relación y se actualizará eliminando la relación
            setExternalRequest(recordsToUpsertByEntity.get(entity).get('Account').get(accountFromKeyMap), true, 'OK', 'Se salta este registro por obsoleto', false);
            recordsToUpsertByEntity.get(entity).get('Account').remove(accountFromKeyMap);
            addRecordToMap(externalRequest, entity, 'Account', record);

        } else if (accountFromKeyMap != null && !existeAltaAgrupacionEnMap && record.IntermediaryEndDate__c > Date.valueOf(accountFromKeyMap.get('IntermediaryEndDate__c'))) { // si existe ya un registro y no es un alta y la fecha de fin es anterior a la fecha de baja de la er a procesar se modifica
            recordsToUpsertByEntity.get(entity).get('Account').remove(accountFromKeyMap);
            addRecordToMap(externalRequest, entity, 'Account', record);

        } else { // cualquier otro caso se marca la ER como obsoleta
            setExternalRequest(externalRequest, true, 'OK', 'Se salta este registro por obsoleto', false);
        }
    }
}