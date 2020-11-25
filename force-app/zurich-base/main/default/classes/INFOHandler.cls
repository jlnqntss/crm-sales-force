/**
 * Clase handler de INFO
 * Procesa las external request cuyo origen sea INFO con la ayuda de la clase Transformer
 **
 * @author adelgado
 * @date 13/10/2020
 */
public class INFOHandler implements ISystem
{
    @testVisible
    private static Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToUpsertByEntity = new Map<String, Map<String, Map<sObject, ExternalRequest__c>>>();
    @testVisible
    private static Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToDeleteByEntity = new Map<String, Map<String, Map<sObject, ExternalRequest__c>>>();
    @testVisible
    private static List<ExternalRequest__c> externalRequestResultList = new List<ExternalRequest__c>();

    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    // CUSTOM METATDATA
    @testVisible
    private static Transformer tf;
    @testVisible
    private static Map<String, Map<String, String>> externalIdByEntity = new Map<String, Map<String, String>>();
    @testVisible
    private static Integer maxRetries;

    public static final String ACCOUNT = 'ACCOUNT';
    public static final String CONTACT_POINT = 'CONTACT_POINT';
    public static final String PRODUCT = 'PRODUCT';
    public static final String QUOTE = 'QUOTE';
    public static final String QUOTE_OPTION = 'QUOTE_OPTION';
    public static final String POLICY = 'POLICY';
    public static final String INSURED_OBJECT = 'INSURED_OBJECT';
    public static final String CLAIM = 'CLAIM';
    public static final String QUOTE_RELATIONSHIP = 'QUOTE_RELATIONSHIP';
    public static final String POLICY_RELATIONSHIP = 'POLICY_RELATIONSHIP';
    public static final String CLAIM_RELATIONSHIP = 'CLAIM_RELATIONSHIP';
    public static final String PARTNER = 'PARTNER';
    public static final String INTERMEDIARY = 'INTERMEDIARY';

    // Orden de DML sobre entidades
    private static List<String> entityOrder = new List<String> 
    {
        ACCOUNT, // 1
        PARTNER, // 2       
        INTERMEDIARY, // 3
        CONTACT_POINT, // 4
        PRODUCT, // 5
        QUOTE, // 6
        QUOTE_OPTION, // 7
        POLICY, // 8
        INSURED_OBJECT, // 9
        CLAIM, // 10
        QUOTE_RELATIONSHIP, // 11
        POLICY_RELATIONSHIP, // 12
        CLAIM_RELATIONSHIP // 13
    };

    /**
     * Obtiene la información necesaria para poder procesar las external request pendientes
     **
     * @author adelgado
     * @date 13/10/2020
     * @param externalRequestList Lista de external request que deben ser procesadas
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     */
    public static void prepare(Transformer INFOTransformer, List<ExternalRequest__c> externalRequestList)
    {
        // 1 - Obtener el tranformer a utilizar
        tf = INFOTransformer;

        // 2 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
        recordsToUpsertByEntity = tf.initRequestsMapBySettings();
        recordsToDeleteByEntity = tf.initRequestsMapBySettings();

        // 3 - Obtener identificadores externos por cada entidad
        for (ExternalIdField__mdt externalId : new ExternalIdFieldsSelector
            (new List<Schema.SObjectField> {ExternalIdField__mdt.OriginEntity__c, ExternalIdField__mdt.SalesforceEntity__c, ExternalIdField__mdt.ExternalId__c}
            ).selectByOrigin(new Set<String> {Transformer.ORIGIN_NAME_INFO}) )
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
        ).selectByOrigin(new Set<String> {Transformer.ORIGIN_NAME_INFO}).get(0).Retries__c;
    }

    /**
     * Realiza las transformaciones necesarias para procesar las external request recibidas y convertirlas en objetos de Salesforce
     **
     * @author adelgado
     * @date 13/10/2020
     * @param externalRequestList Lista de external request que deben ser procesadas
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     */
    public static void process(List<ExternalRequest__c> externalRequestList)
    {
        // 1 - Recorrer todas las external request recibidas
        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            try
            {
                // 1.1 - Comprobar si el contenido de la solicitud está en formato JSON
                if (externalRequest.ContentFormat__c == 'JSON' && String.isNotBlank(externalRequest.Payload__c))
                {
                    // 1.1.1 - Realizar las transformaciones necesarias en base a la entidad de INFO
                    processExternalRequestByEntity(externalRequest);
                }
                else
                {
                    // 1.1.2 - El formato recibido no está soportado
                    setExternalRequest(externalRequest, true, 'KO', 'No se ha recibido información correcta del registro en INFO', false);
                }
            }
            catch (Exception e)
            {
                System.debug('[INFOHandler] process() - ' + e.getMessage());
                setExternalRequest(externalRequest, true, 'KO', e.getMessage() + '\n' + e.getStackTraceString(), false);
                //ErrorLogUtil.commitError(e, 'INFOHandler', 'process');
            }
        }
    }

    /**
     * Realiza las operaciones DML sobre la BBDD y actualiza la información de las external request procesadas
     **
     * @author adelgado
     * @date 13/10/2020
     * @param externalRequestList Lista de external request que deben ser procesadas
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     */
    public static void persists(List<ExternalRequest__c> externalRequestList)
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
            System.debug('[INFOHandler] persists() - ' + e.getMessage());
            ErrorLogUtil.commitError(e, 'INFOHandler', 'persists');
        }
    }

    /**
     * Actualiza las external request procesadas con el resultado obtenido en las operaciones DML
     **
     * @author adelgado
     * @date 13/10/2020
     * @param jobId Id del job que se está ejecutando
     * @param externalRequestList Lista de external request que deben ser procesadas
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     */
    public static void manageResult(Id jobId, List<ExternalRequest__c> externalRequestList)
    {
        List<ExternalRequestErrorEvent__e> erErrorEventList = new List<ExternalRequestErrorEvent__e>();

        try
        {
            if ( externalRequestResultList != null && !externalRequestResultList.isEmpty() )
            {
                // 1 - Actualizar las external request con el resultado
                Database.SaveResult[] resultList = Database.update(externalRequestResultList,false);

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
                        System.debug('[INFOHandler] manageResult() - ' + e.getMessage());
                        ErrorLogUtil.commitError(e, 'INFOHandler', 'manageResult');
                    }
                }

                // 3 - Publicar external request erróneas
                if ( !erErrorEventList.isEmpty() )
                {
                    List<Database.SaveResult> results = EventBus.publish(erErrorEventList);
                }
            }
        }
        catch ( Exception e )
        {
            System.debug('[INFOHandler] manageResult() - ' + e.getMessage());
            ErrorLogUtil.commitError(e, 'INFOHandler', 'manageResult');
        }
    }

    /**
     * Convertir JSON de INFO a registro de Salesforce en base a la entidad recibida
     **
     * @author adelgado
     * @date 13/10/2020
     * @param externalRequest External request que debe ser procesada
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     */
    private static void processExternalRequestByEntity(ExternalRequest__c externalRequest)
    {
        // 1 - Transformar el contenido del JSON a una estructura Map
        Map<String, Object> recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(externalRequest.Payload__c);

        // 2 - Convertir a mayúsculas todas las claves del mapa de campos de INFO
        for ( String field : recordValuesMap.keySet() )
        {
            recordValuesMap.put(field.toUpperCase(), recordValuesMap.get(field));
        }

        // 3 - Realizar las transformaciones necesarias en base a la entidad de INFO
        switch on externalRequest.Entity__c.toUpperCase()
        {
            // Persona
            when 'ACCOUNT' 
            {
                if (recordValuesMap.containsKey('CLIENTE_TIPO_PERSONA') )
                {
                    // Persona física
                    if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA') ).equalsIgnoreCase('F'))
                    {
                        Account accountRecord = (Account) tf.transform(ACCOUNT, 'Account', recordValuesMap);
                        accountRecord.FirstName = recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null;
                        accountRecord.LastName = (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1'): null) + ' ' +
                                                    (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                        accountRecord.LegalEntity__pc = recordValuesMap.containsKey('CLIENTE_ENTIDAD_LEGAL') ? (String) recordValuesMap.get('CLIENTE_ENTIDAD_LEGAL') : null;
                        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

                        addRecordToMap(externalRequest, ACCOUNT, 'Account', accountRecord);                                  
                    }
                    // Persona jurídica
                    else if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA') ).equalsIgnoreCase('J'))
                    {
                        //Cuenta
                        Account accountRecord = (Account) tf.transform(ACCOUNT, 'Account', recordValuesMap);
                        accountRecord.Name = (recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null) + ' ' +
                                                (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1') : null) + ' ' +
                                                (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                        accountRecord.LegalEntity__c = recordValuesMap.containsKey('CLIENTE_ENTIDAD_LEGAL') ? (String) recordValuesMap.get('CLIENTE_ENTIDAD_LEGAL') : null;
                        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();

                        addRecordToMap(externalRequest, ACCOUNT, 'Account', accountRecord); 
                        
                        //Contacto
                        Contact contactRecord = (Contact) tf.transform(ACCOUNT, 'Contact', recordValuesMap);
                        contactRecord.FirstName = recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE'): null;
                        contactRecord.LastName = (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1') : null) + ' ' +
                                                    (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                        contactRecord.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();

                        addRecordToMap(externalRequest, ACCOUNT, 'Contact', contactRecord); 
                    }
                    else
                    {
                        setExternalRequest(externalRequest, true, 'KO', 'No se ha podido identificar el tipo de cliente', false);
                    }
                }
            }
            // Vía de contacto
            when 'CONTACT_POINT' 
            {
                if (recordValuesMap.containsKey('TIPO_DOMICILIO'))
                {
                    // Vía de contacto postal (A, B, P)
                    if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('A') ||
                        ((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('B') ||
                        ((String) recordValuesMap.get('TIPO_DOMICILIO') ).equalsIgnoreCase('P'))
                    {
                        ContactPointAddress cpaRecord = (ContactPointAddress) tf.transform(CONTACT_POINT, 'ContactPointAddress', recordValuesMap);
                        addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointAddress', cpaRecord); 
                    }
                    else if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('T'))
                    {
                        //  Vía de contacto telefónico (T)
                        ContactPointPhone cppRecord = (ContactPointPhone) tf.transform(CONTACT_POINT, 'ContactPointPhone', recordValuesMap);
                        addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointPhone', cppRecord); 
                    }
                    else if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('E'))
                    {
                        // Vía de contacto email (E)
                        ContactPointEmail cpeRecord = (ContactPointEmail) tf.transform(CONTACT_POINT, 'ContactPointEmail', recordValuesMap);
                        addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointEmail', cpeRecord); 
                    }
                    else
                    {
                        setExternalRequest(externalRequest, true, 'KO', 'No se ha podido identificar el tipo de vía de contacto', false);
                    }
                }
            }
            //Producto
            when 'PRODUCT' 
            {
                Product2 prodRecord = (Product2) tf.transform(PRODUCT, 'Product2', recordValuesMap);
                addRecordToMap(externalRequest, PRODUCT, 'Product2', prodRecord); 
            }
            // Oferta
            when 'QUOTE' 
            {
                Opportunity quoteRecord = (Opportunity) tf.transform(QUOTE, 'Opportunity', recordValuesMap);
                addRecordToMap(externalRequest, QUOTE, 'Opportunity', quoteRecord); 
            }
            // Opción oferta
            when 'QUOTE_OPTION' 
            {
                Quote optionRecord = (Quote) tf.transform(QUOTE_OPTION, 'Quote', recordValuesMap);
                addRecordToMap(externalRequest, QUOTE_OPTION, 'Quote', optionRecord); 
            }
            // Póliza
            when 'POLICY' 
            {
                Policy__c policyRecord = (Policy__c) tf.transform(POLICY, 'Policy__c', recordValuesMap);
                addRecordToMap(externalRequest, POLICY, 'Policy__c', policyRecord); 
            }
            // Objeto asegurado
            when 'INSURED_OBJECT' 
            {
                Asset insObjRecord = (Asset) tf.transform(INSURED_OBJECT, 'Asset', recordValuesMap);
                insObjRecord.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(insObjRecord.ObjectType__c.trim()).getRecordTypeId();
                addRecordToMap(externalRequest, INSURED_OBJECT, 'Asset', insObjRecord); 
            }
            // Siniestro
            when 'CLAIM' 
            {
                Claim__c claimRecord = (Claim__c) tf.transform(CLAIM, 'Claim__c', recordValuesMap);
                addRecordToMap(externalRequest, CLAIM, 'Claim__c', claimRecord);
            }
            // Rol póliza
            when 'POLICY_RELATIONSHIP' 
            {
                Relationship__c polRelRecord = (Relationship__c) tf.transform(POLICY_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                polRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
                addRecordToMap(externalRequest, POLICY_RELATIONSHIP, 'Relationship__c', polRelRecord);
            }
            // Rol oferta
            when 'QUOTE_RELATIONSHIP' 
            {
                Relationship__c quoRelRecord = (Relationship__c) tf.transform(QUOTE_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                quoRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Offer').getRecordTypeId();
                addRecordToMap(externalRequest, QUOTE_RELATIONSHIP, 'Relationship__c', quoRelRecord);
            }
            // Rol siniestro
            when 'CLAIM_RELATIONSHIP' 
            {
                Relationship__c claimRelRecord = (Relationship__c) tf.transform(CLAIM_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                claimRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Claim').getRecordTypeId();
                addRecordToMap(externalRequest, CLAIM_RELATIONSHIP, 'Relationship__c', claimRelRecord);
            }
            // Partner
            when 'PARTNER' 
            {
                Account partnerRecord = (Account) tf.transform(PARTNER, 'Account', recordValuesMap);
                partnerRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
                addRecordToMap(externalRequest, PARTNER, 'Account', partnerRecord);
            }
            // Mediador
            when 'INTERMEDIARY' 
            {
                Account intermRecord = (Account) tf.transform(INTERMEDIARY, 'Account', recordValuesMap);
                intermRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
                addRecordToMap(externalRequest, INTERMEDIARY, 'Account', intermRecord);
            }
            when else
            {
                setExternalRequest(externalRequest, true, 'KO', 'No se ha encontrado la entidad indicada', false);
            }
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
     */
    private static void persistRecords(String action, Map<String, Map<String, Map<sObject, ExternalRequest__c>>> recordsToPersist)
    {
        List<sObject> recordList;
        List<ExternalRequest__c> externalRequestList;
        ExternalRequest__c extReq;

        // 1 - Realizar las operaciones DML sobre los registros generados y actualizar external request con resultado
        for ( String entity : entityOrder )
        {
            if ( recordsToPersist.containsKey(entity) )
            {
                for ( String objectName : recordsToPersist.get(entity).keySet() )
                {
                    if ( !recordsToPersist.get(entity).get(objectName).isEmpty() )
                    {
                        Schema.SObjectField externalIdField = globalDescribe.get(objectName).getDescribe().fields.getMap().get(externalIdByEntity.get(entity).get(objectName));

                        recordList = new List<sObject>(recordsToPersist.get(entity).get(objectName).keySet());
                        externalRequestList = recordsToPersist.get(entity).get(objectName).values();

                        if(action == 'UPSERT')
                        {
                            Database.UpsertResult[] resultList = Database.upsert(recordList, externalIdField, false);
                            
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
                        else if(action == 'DELETE')
                        {
                            Set<Object> externalIdValues = new Set<Object>();

                            for(sObject sObj : recordList)
                            {
                                externalIdValues.add(sObj.get(externalIdField));
                            }
                            
                            Database.DeleteResult[] resultList = Database.delete(new RecordsSelector(globalDescribe.get(objectName)).selectByExternalId(externalIdField, externalIdValues));

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
     */
    private static void setExternalRequest(ExternalRequest__c externalRequest, Boolean processed, String processResult, String error, Boolean sumRetry)
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

            // 3 - Si se marca la external request como procesada se indica la fecha de procesamiento
            if(processed)
            {
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
     */
    private static void addRecordToMap(ExternalRequest__c externalRequest, String entity, String sObjectType, sObject record)
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

}