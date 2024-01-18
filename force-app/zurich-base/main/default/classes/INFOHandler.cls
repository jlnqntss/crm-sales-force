/**
 * Clase handler de INFO
 * Procesa las external request cuyo origen sea INFO con la ayuda de la clase Transformer
 **
 * @author adelgado
 * @date 13/10/2020
 */
public with sharing class INFOHandler implements ISystem
{
    // Si se da un Insured Object, guardara los valores del picklist ObjectType__c que representan las equivalencias
    // entre el codigo de objeto (INFO) y el campo Name en Salesforce
    private static Map<String, String> mapInsuredObjectTypeToName = null;
    // Guardara las equivalencias configuradas en los metadatos entre el Origen INFO.
    // Para cada Entidad se guarda una pareja de valores de equivalencia entre el origen y SF
    // Por ejemplo para Insured Object (Asset), a partir del ObjectType determina el RecordType
    private static Map<String, Map<String, String>> mapEquivalencesByEntity = null;
    @testvisible
    private static Map<String, Map<String, String>> mapEquivalencesByEntityTest = null;

    public static final String HANDLER_ORIGIN = 'INFO';

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
    public static final String NOTE = 'NOTE';
    public static final String SPECIAL_CONDITION = 'SPECIAL_CONDITION';
    public static final String INTERMEDIARY_KPI = 'INTERMEDIARY_KPI';
    public static final String ACCOUNT_KPI = 'ACCOUNT_KPI';
    public static final String POLICY_KPI = 'POLICY_KPI';
    public static final String SOBJECT_CASE = 'Case';
    public static final String INTERMEDIARY_HIERARCHY = 'INTERMEDIARY_HIERARCHY';
    public static final String INTERMEDIARY_GROUP = 'INTERMEDIARY_GROUP';

    public static final List<String> PRIORITY_ENTITIES =  new List<String>{NOTE};
    public static final String PriorityEntitiesToString = '(\''+ String.join(PRIORITY_ENTITIES, '\',\'') + '\')';

    private static final String NOTE_CASE_ORIGIN = 'NoteINFO';
    private static final String NOTE_CASE_SOURCE_AREA = 'Mediator';

    private class INFOHandlerException extends Exception {}

    /**
     * Obtiene la información necesaria para poder procesar las external request pendientes
     **
     * @author adelgado
     * @date 13/10/2020
     * @param externalRequestList Lista de external request que deben ser procesadas
     * @return void
     * @throws
     * @where ExternalJobQueueBatch
     * @change 15/05/2023 - aberuete - Extraer la función a clase Util
     */
    public static void prepare(Transformer infoTransformer, List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.prepareExternalRequestToProcess(infoTransformer, HANDLER_ORIGIN);
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

        // 0 - Recorrer las external request para hacer la consulta de medidores en caso que lleguen mensajes de INTERMEDIARY_HIERARCHY
        Map<String, Map<String, Account>> intermediaryAndGroupQueryMap = ExternalRequestHandlerUtil.getIntermediaryData(externalRequestList); // keys: Intermediary, IntermediaryGroup
        // 1 - Recorrer todas las external request recibidas
        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            try
            {
                // 1.1 - Comprobar si el contenido de la solicitud está en formato JSON
                if (externalRequest.ContentFormat__c == 'JSON' && String.isNotBlank(externalRequest.Payload__c))
                {
                    // 1.1.1 - Realizar las transformaciones necesarias en base a la entidad de INFO
                    processExternalRequestByEntity(externalRequest, intermediaryAndGroupQueryMap);
                }
                else
                {
                    // 1.1.2 - El formato recibido no está soportado
                    ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha recibido información correcta del registro en INFO', false);
                }
            }
            catch (Exception e)
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', e.getMessage() + '\n' + e.getStackTraceString(), false);
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
     * @change 15/05/2023 - aberuete - Extraer la función a clase Util
     */
    public static void persists(List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.persistExternalRequest ('INFOHandler');
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
     * @change 15/05/2023 - aberuete - Extraer la función a clase Util
     */
    public static void manageResult(Id jobId, List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.manageResultExternalRequest (jobId, externalRequestList, 'INFOHandler');
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
     * @change 15/05/2023 - aberuete - Refactorizar el método
     * @change 12/07/2023 - jonandersanjuan - Se agregan nuevas entidades ACCOUNT_KPI y POLICY_KPI
     */
    private static void processExternalRequestByEntity(ExternalRequest__c externalRequest, Map<String, Map<String, Account>> intermediaryAndGroupQueryMap)
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
                processAccount (recordValuesMap, externalRequest);
            }
            // Vía de contacto
            when 'CONTACT_POINT'
            {
                processContactPoint (recordValuesMap, externalRequest);
            }
            //Producto
            when 'PRODUCT'
            {
                Product2 prodRecord = (Product2) ExternalRequestHandlerUtil.tf.transform(PRODUCT, 'Product2', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, PRODUCT, 'Product2', prodRecord);
            }
            // Oferta
            when 'QUOTE'
            {
                Opportunity quoteRecord = (Opportunity) ExternalRequestHandlerUtil.tf.transform(QUOTE, 'Opportunity', recordValuesMap);
                quoteRecord.isUpdatedFromINFO__c = true; // arcortazar - nts (29/03/2022): fix-ZE-1289
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, QUOTE, 'Opportunity', quoteRecord);
            }
            // Opción oferta
            when 'QUOTE_OPTION'
            {
                Quote optionRecord = (Quote) ExternalRequestHandlerUtil.tf.transform(QUOTE_OPTION, 'Quote', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, QUOTE_OPTION, 'Quote', optionRecord);
            }
            // Póliza
            when 'POLICY'
            {
                Policy__c policyRecord = (Policy__c) ExternalRequestHandlerUtil.tf.transform(POLICY, 'Policy__c', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, POLICY, 'Policy__c', policyRecord);
            }
            // Objeto asegurado
            when 'INSURED_OBJECT'
            {
                processInsuredObject (recordValuesMap, externalRequest);
            }
            // Siniestro
            when 'CLAIM'
            {
                Claim__c claimRecord = (Claim__c) ExternalRequestHandlerUtil.tf.transform(CLAIM, 'Claim__c', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, CLAIM, 'Claim__c', claimRecord);
            }
            // Rol póliza
            when 'POLICY_RELATIONSHIP'
            {
                Relationship__c polRelRecord = (Relationship__c) ExternalRequestHandlerUtil.tf.transform(POLICY_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                polRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, POLICY_RELATIONSHIP, 'Relationship__c', polRelRecord);
            }
            // Rol oferta
            when 'QUOTE_RELATIONSHIP'
            {
                Relationship__c quoRelRecord = (Relationship__c) ExternalRequestHandlerUtil.tf.transform(QUOTE_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                quoRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Offer').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, QUOTE_RELATIONSHIP, 'Relationship__c', quoRelRecord);
            }
            // Rol siniestro
            when 'CLAIM_RELATIONSHIP'
            {
                Relationship__c claimRelRecord = (Relationship__c) ExternalRequestHandlerUtil.tf.transform(CLAIM_RELATIONSHIP, 'Relationship__c', recordValuesMap);
                claimRelRecord.RecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Claim').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, CLAIM_RELATIONSHIP, 'Relationship__c', claimRelRecord);
            }
            // Partner
            when 'PARTNER'
            {
                Account partnerRecord = (Account) ExternalRequestHandlerUtil.tf.transform(PARTNER, 'Account', recordValuesMap);
                partnerRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PartnerOCS').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, PARTNER, 'Account', partnerRecord);
            }
            // Mediador
            when 'INTERMEDIARY'
            {
                Account intermRecord = (Account) ExternalRequestHandlerUtil.tf.transform(INTERMEDIARY, 'Account', recordValuesMap);
                intermRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, INTERMEDIARY, 'Account', intermRecord);
            }
            // INTERMEDIARY_GROUP
            when 'INTERMEDIARY_GROUP'
            {
                Account intermediaryGroup = (Account) ExternalRequestHandlerUtil.tf.transform(INTERMEDIARY_GROUP, 'Account', recordValuesMap);
                intermediaryGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AgrupacionMediador').getRecordTypeId();
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, INTERMEDIARY_GROUP, 'Account', intermediaryGroup); 
            }
            // INTERMEDIARY_HIERARCHY
            when 'INTERMEDIARY_HIERARCHY'
            {
                Account intermediaryHierarchy = (Account) ExternalRequestHandlerUtil.tf.transform(INTERMEDIARY_HIERARCHY, 'Account', recordValuesMap);
                ExternalRequestHandlerUtil.processIntermediaryHierarchy(externalRequest, INTERMEDIARY_HIERARCHY, intermediaryHierarchy, intermediaryAndGroupQueryMap);                
            }
            // Note
            when 'NOTE'
            {
                processNoteToCase (recordValuesMap, externalRequest);
            }
            when 'SPECIAL_CONDITION'
            {
                Special_Condition__c specialConditionRecord = (Special_Condition__c) ExternalRequestHandlerUtil.tf.transform(SPECIAL_CONDITION, 'Special_Condition__c', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, SPECIAL_CONDITION, 'Special_Condition__c', specialConditionRecord);
            }
            when 'INTERMEDIARY_KPI'
            {
                KPI__c intermediaryKpiRecord = (KPI__c) ExternalRequestHandlerUtil.tf.transform(INTERMEDIARY_KPI, 'KPI__c', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, INTERMEDIARY_KPI, 'KPI__c', intermediaryKpiRecord);
            }
            // Account KPIs
            when 'ACCOUNT_KPI'
            {
                Account accountRecord = (Account) ExternalRequestHandlerUtil.tf.transform(ACCOUNT_KPI, 'Account', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, ACCOUNT_KPI, 'Account', accountRecord);
            }
            // Policy KPIs
            when 'POLICY_KPI'
            {
                Policy__c policyRecord = (Policy__c) ExternalRequestHandlerUtil.tf.transform(POLICY_KPI, 'Policy__c', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, POLICY_KPI, 'Policy__c', policyRecord);
            }            
            when else
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha encontrado la entidad indicada', false);
            }
        }
    }

    /**
     * Recupera las equivalencias configuradas en los metadatos para una Entidad
     *
     * @author nts (agonzalezisasi)
     * @date 24/02/2021
     * @param {String} nombre del origen de los datos
     * @param {String} nombre de la entidad en el origen
     * @param {String} valor clave en la entidad de origen
     * @return {Strig} valor equivalente para utilizar en Salesforce
     */
    private static String getEquivalence(String origin, String entity, String originKey)
    {
        String result = '';
        if( mapEquivalencesByEntity == null ) 
        {
            mapEquivalencesByEntity = new Map<String, Map<String, String>>();
        }

        if( !mapEquivalencesByEntity.containsKey(entity) ) 
        {
            
            List<TransformerEquivalences__mdt> settigs = [
                SELECT Id, OriginKey__c, Value__c
                FROM TransformerEquivalences__mdt
                WHERE Origin__c = :origin AND OriginEntity__c = :entity
            ];

            for(TransformerEquivalences__mdt te: settigs) 
            {
                if( mapEquivalencesByEntity.containsKey(entity) ) 
                {
                    mapEquivalencesByEntity.get(entity).put(te.OriginKey__c, te.Value__c);
                } 
                else 
                {
                    mapEquivalencesByEntity.put(entity, new Map<String, String>{
                        te.OriginKey__c => te.Value__c
                    });
                }
            }
        }

        if( Test.isRunningTest() && mapEquivalencesByEntityTest != null ) 
        {
            mapEquivalencesByEntity = mapEquivalencesByEntityTest;
        }

        if( mapEquivalencesByEntity.containsKey(entity) && mapEquivalencesByEntity.get(entity).containsKey(originKey) ) 
        {
            result = mapEquivalencesByEntity.get(entity).get(originKey);
        }
        
        return result;
    }

    /**
     * Procesar la entidad ACCOUNT al objeto account de salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param ExternalRequest__c externalRequest : External request que debe ser procesada
     */
    private static void processAccount (Map<String, Object> recordValuesMap, ExternalRequest__c externalRequest)
    {
        if (recordValuesMap.containsKey('CLIENTE_TIPO_PERSONA') )
        {
            // Persona física
            if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA') ).equalsIgnoreCase('F'))
            {
                Account accountRecord = (Account) ExternalRequestHandlerUtil.tf.transform(ACCOUNT, 'Account', recordValuesMap);
                accountRecord.FirstName = getFirstAndLastName (recordValuesMap)[0];
                accountRecord.LastName = getFirstAndLastName (recordValuesMap)[1];
                accountRecord.LegalEntity__pc = getLegalEntity (recordValuesMap);
                // 30.04.2021 - nts (agonzalezisasi) - ocs 1729 visibilidad GDRP
                accountRecord.LegalEntity__c = accountRecord.LegalEntity__pc;
                accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, ACCOUNT, 'Account', accountRecord);
            }
            // Persona jurídica
            else if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA') ).equalsIgnoreCase('J'))
            {
                //Cuenta
                Account accountRecord = (Account) ExternalRequestHandlerUtil.tf.transform(ACCOUNT, 'Account', recordValuesMap);
                accountRecord.Name = getFirstAndLastName (recordValuesMap)[0] + ' ' + getFirstAndLastName (recordValuesMap)[1];
                accountRecord.LegalEntity__c = getLegalEntity (recordValuesMap);
                accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();

                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, ACCOUNT, 'Account', accountRecord);

                //Contacto
                Contact contactRecord = (Contact) ExternalRequestHandlerUtil.tf.transform(ACCOUNT, 'Contact', recordValuesMap);
                
                contactRecord.FirstName = getFirstAndLastName (recordValuesMap)[0];
                contactRecord.LastName = getFirstAndLastName (recordValuesMap)[1];
                contactRecord.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();

                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, ACCOUNT, 'Contact', contactRecord);
            }
            else
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha podido identificar el tipo de cliente', false);
            }
        } 
    }

     /**
     * Método que obtiene el nombre y apellidos dependiendo del contenido del mapa recordValuesMap
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     */
    @testvisible
    private static List<String> getFirstAndLastName (Map<String, Object> recordValuesMap)
    {
        String firstName = recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null;
        String lastName = (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1'): null) + ' ' +
                                (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);   
        return new List<String>{firstName,lastName};
    }

    /**
     * Método que obtiene la entidad legal dependiendo del contenido del mapa recordValuesMap
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     */
    @testvisible
    private static String getLegalEntity (Map<String, Object> recordValuesMap)
    {
        return recordValuesMap.containsKey('CLIENTE_ENTIDAD_LEGAL') ? (String) recordValuesMap.get('CLIENTE_ENTIDAD_LEGAL') : null; 
    }

    /**
     * Procesar la entidad CONTACT_POINT al objeto ContactPointAddress,ContactPointPhone o ContactPointEmail de salesforce 
     * en función del contenido del mapa recordValuesMap
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param ExternalRequest__c externalRequest : External request que debe ser procesada
     */
    @testvisible
    private static void processContactPoint (Map<String, Object> recordValuesMap, ExternalRequest__c externalRequest)
    {
        if (recordValuesMap.containsKey('TIPO_DOMICILIO'))
        {
            // Vía de contacto postal (A, B, P)
            if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('A') ||
                ((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('B') ||
                ((String) recordValuesMap.get('TIPO_DOMICILIO') ).equalsIgnoreCase('P'))
            {
                ContactPointAddress cpaRecord = (ContactPointAddress) ExternalRequestHandlerUtil.tf.transform(CONTACT_POINT, 'ContactPointAddress', recordValuesMap);
                cpaRecord.Street = String.join
                (
                    new List<String>
                    {
                        cpaRecord.StreetType__c,
                        cpaRecord.Street,
                        cpaRecord.StreetNumber__c,
                        cpaRecord.OtherInfo__c
                    }
                    , ' '
                );
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointAddress', cpaRecord);
            }
            else if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('T'))
            {
                //  Vía de contacto telefónico (T)
                ContactPointPhone cppRecord = (ContactPointPhone) ExternalRequestHandlerUtil.tf.transform(CONTACT_POINT, 'ContactPointPhone', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointPhone', cppRecord);
            }
            else if (((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('E'))
            {
                // Vía de contacto email (E)
                ContactPointEmail cpeRecord = (ContactPointEmail) ExternalRequestHandlerUtil.tf.transform(CONTACT_POINT, 'ContactPointEmail', recordValuesMap);
                ExternalRequestHandlerUtil.addRecordToMap(externalRequest, CONTACT_POINT, 'ContactPointEmail', cpeRecord);
            }
            else
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha podido identificar el tipo de vía de contacto', false);
            }
        }  
    }

    /**
     * Procesar la entidad INSURED_OBJECT al objeto asset de salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param ExternalRequest__c externalRequest : External request que debe ser procesada
     */
    @testvisible
    private static void processInsuredObject (Map<String, Object> recordValuesMap, ExternalRequest__c externalRequest)
    {
        Asset insObjRecord = (Asset) ExternalRequestHandlerUtil.tf.transform(INSURED_OBJECT, 'Asset', recordValuesMap);
                
        // Recuperamos la etiqueta con el nombre a partir del codigo de tipo de objeto
        if( mapInsuredObjectTypeToName == null ) 
        {
            mapInsuredObjectTypeToName = new Map<String, String>();

            Schema.DescribeFieldResult fieldResult = Asset.ObjectType__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry p : ple) 
            {
                mapInsuredObjectTypeToName.put(p.getValue(), p.getLabel());
            }
        }
        insObjRecord.Name = insObjRecord.ObjectType__c.trim();
        
        if( mapInsuredObjectTypeToName.containsKey(insObjRecord.Name) ) 
        {
            insObjRecord.Name = mapInsuredObjectTypeToName.get(insObjRecord.Name);
        }
        
        // Recuperamos de la configuracion la equivalencia entre el ObjectType y su record type en Salesforce
        String recordTypeDevName = getEquivalence(HANDLER_ORIGIN, 'INSURED_OBJECT', insObjRecord.ObjectType__c.trim());
                
        if( String.isBlank(recordTypeDevName) ) 
        {
            throw new INFOHandlerException('RecordType equivalence not found for the following Object Type: ' + insObjRecord.ObjectType__c.trim());
        }

        insObjRecord.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        ExternalRequestHandlerUtil.addRecordToMap(externalRequest, INSURED_OBJECT, 'Asset', insObjRecord);
    }

    /**
     * Procesar la entidad NOTE al objeto caso de salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param ExternalRequest__c externalRequest : External request que debe ser procesada
     * @change 21/12/2023 - aberuete - Añadir en el campo descripción el usuario creador de la nota
     */
    @testvisible
    private static void processNoteToCase (Map<String, Object> recordValuesMap, ExternalRequest__c externalRequest)
    {
         
        // Normal transformation of fields
        Case caseRecord = (Case) ExternalRequestHandlerUtil.tf.transform(NOTE, SOBJECT_CASE, recordValuesMap);
        // Assign the Case Origin to "Nota INFO"
        caseRecord.Origin = NOTE_CASE_ORIGIN;
        // Assign the Case Source Area to "Mediator"
        caseRecord.SourceArea__c = NOTE_CASE_SOURCE_AREA;

        String descriptionCase = getDescriptionForCase (recordValuesMap);

        if (String.isNotBlank(descriptionCase))
        {
            caseRecord.Description = descriptionCase;
        }

        //Tipo de NOTA INFO
        //Se utiliza el método getEquivalence para comprobar si el tipo de Nota INFO es RBCO/RBNW/SINO
        //En este caso el RecordType del nuevo caso generado es automáticamente OCS
        String valorNotaInfo = getEquivalence(HANDLER_ORIGIN,NOTE,(String)recordValuesMap.get('note_cod_agrupacion_TA'));

        if(String.isNotBlank(valorNotaInfo))
        {
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(valorNotaInfo).getRecordTypeId();
        }
        else 
        {
            // Recuperamos de la configuracion la equivalencia entre el ObjectType y su record type en Salesforce
            String recordTypeDevName = getEquivalence(HANDLER_ORIGIN,NOTE,caseRecord.HegeoProductGroupCode__c.trim());

            if( String.isBlank(recordTypeDevName) ) 
            {
                //En caso de no encontrar equivalencia se establece el caso tendrá RecordType OCS
                caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
            }
            else 
            {
                caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
            }
        }

        // Get the Type, Subytype and TypeN3 from the HEGEO fields metadata configuration
        caseRecord = ExternalRequestHandlerUtil.fillTypificationIntoCase (recordValuesMap, 'NOTE_DESC_TIPO_ENVIO', 'NOTE_DESC_SUBTIPO', caseRecord);

        ExternalRequestHandlerUtil.addRecordToMap(externalRequest, NOTE, SOBJECT_CASE, caseRecord);
    }

    /**
     * Obtener la descripción del caso y añadir el usuario creador de la nota
     **
     * @author aberuete
     * @date 21/12/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     */
    private static String getDescriptionForCase (Map<String, Object> recordValuesMap)
    {
        String descriptionCase; 

        if (recordValuesMap.containsKey('note_texto'))
        {
            descriptionCase = recordValuesMap.get('note_texto') +'\n';  
        }

        if (recordValuesMap.containsKey('note_usuario') && String.isNotBlank((String)recordValuesMap.get('note_usuario')))
        {
            if (String.isNotBlank(descriptionCase))
            {
                descriptionCase = descriptionCase + 'USUARIO CREADOR: ' + recordValuesMap.get('note_usuario');
            }
            else 
            {
                descriptionCase = 'USUARIO CREADOR: ' + recordValuesMap.get('note_usuario');
            }   
        }

        return descriptionCase;
    }
}