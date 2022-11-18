public with sharing class GenerateScopeUtil
{
    private static final String HANDLE_TYPE_SCOPE_ACCOUNT = 'SCOPE_ACCOUNT';
    private static final String HANDLE_TYPE_SCOPE_OTHER = 'SCOPE_OTHER';
    private static final String HANDLE_TYPE_PARTNER_POLICY = 'PARTNER_POLICY';
    private static final String CLASS_NAME = 'GenerateScopeUtil';

    /**
     * Controlar el número de eventos a procesar (200) y marcar cual ha sido el último evento procesado
     * @author adelgado
     * @date 04/12/2020
     * @param events Eventos a procesar
     **/
    public static void handleEventsBatch(List<GenerateScopeEvent__e> events)
    {
        List<GenerateScopeEvent__e> eventsToHandle = new List<GenerateScopeEvent__e>();

        if(events.size() > 200)
        {
            for(Integer i = 0; i < 200; i++) {
                eventsToHandle.add(events[i]);
            }
        }
        else
        {
            eventsToHandle = events;
        }

        if( !events.isEmpty() )
        {
            GenerateScopeUtil.handleEvents(eventsToHandle);

            EventBus.TriggerContext.currentContext().setResumeCheckpoint(eventsToHandle[eventsToHandle.size() - 1].ReplayId);
        }
    }

    /**
     * Generación de GenerateScopeEvent a partir de la información recibida
     * @author adelgado
     * @date 04/12/2020
     * @param accountField Nombre del campo lookup a account
     * @param businessCodeField Nombre del campo que contiene el código de negocio
     * @param records Registros para los que hay que generar el scope
     **/
    public static Database.SaveResult[] generateScopeEvents(String accountField, String businessCodeField, List<SObject> records)
    {
        List<GenerateScopeEvent__e> generateScopeEvents = new List<GenerateScopeEvent__e>();

        try
        {
            for(SObject record : records)
            {
                generateScopeEvents.add
                (
                    new GenerateScopeEvent__e
                    (
                        AccountId__c = String.isNotBlank(accountField) ? (String) record.get(accountField) : null,
                        RelatedId__c = record.Id,
                        ObjectType__c = record.getSObjectType().getDescribe().getName(),
                        BusinessCode__c = String.isNotBlank(businessCodeField) ? (String) record.get(businessCodeField) : null,
                        HandleType__c = HANDLE_TYPE_SCOPE_ACCOUNT
                    )
                );
            }

            return EventBus.publish(generateScopeEvents);

        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME, 'generateScopeEvents');
        }

        return null;

    }

    /**
     * Publica eventos para rellenar el scope de un tipo de objeto a partir del campo de otro
     * tipo de objeto
     * 
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     * 
     * @param {relatedFieldName} Nombre del campo del objeto destino donde se deja el scope
     * @param {referenceIdField} Nombre del campo del objeto destino donde esta el id del objeto referenciado
     * @param {referenceObjectName} Nombre del objeto referenciado para obtener su nombre
     * @param {referenceFieldName} Nombre del campo del objeto referenciado donde esta el scope
     */
    public static Database.SaveResult[] generateScopeEvents(
        String relatedFieldName, String referenceIdField, 
        String referenceObjectName, String referenceFieldName, 
        List<SObject> records)
    {
        List<GenerateScopeEvent__e> generateScopeEvents = new List<GenerateScopeEvent__e>();

        try {
            for(SObject record : records) {
                generateScopeEvents.add (
                    new GenerateScopeEvent__e (
                        AccountId__c = (String)record.get(referenceIdField),
                        RelatedId__c = record.Id,
                        ObjectType__c = record.getSObjectType().getDescribe().getName(),
                        BusinessCode__c = null,
                        ReferenceObjectName__c = referenceObjectName,
                        ReferenceFieldName__c = referenceFieldName,
                        RelatedFieldName__c = relatedFieldName,
                        HandleType__c = HANDLE_TYPE_SCOPE_OTHER
                ));
            }

            return EventBus.publish(generateScopeEvents);

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME, 'generateScopeEvents');
        }

        return null;

    }

    public static Database.SaveResult[] generatePartnerEvents(
        String businessCodeField, String relatedFieldName, 
        String referenceObjectName, String referenceFieldName,
        List<SObject> records)
    {
        List<GenerateScopeEvent__e> generateScopeEvents = new List<GenerateScopeEvent__e>();

        try {
            for(SObject record : records) {
                generateScopeEvents.add (
                    new GenerateScopeEvent__e (
                        RelatedId__c = record.Id,
                        BusinessCode__c = String.isNotBlank(businessCodeField) ? (String) record.get(businessCodeField) : null,
                        ObjectType__c = record.getSObjectType().getDescribe().getName(),
                        ReferenceObjectName__c = referenceObjectName,
                        ReferenceFieldName__c = referenceFieldName,
                        RelatedFieldName__c = relatedFieldName,
                        HandleType__c = HANDLE_TYPE_PARTNER_POLICY
                ));
            }

            return EventBus.publish(generateScopeEvents);

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME, 'generateScopeEvents');
        }

        return null;
    }

    /**
     * Clasifica los eventos entre dos tipos:
     *  - Account: el scope se determina por el businessCode (metadato) y se genera un objeto scope en Account si no lo 
     *             tiene. El objeto scope se liga al objeto original mediante el campo ScopeId__c
     *  - Alternativo: el scope se toma de un objeto pariente relacionado y no se guarda el scopeId
     * 
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     * 
     * @param {List<GenerateScopeEvent__c>} lista de eventos
     */
    private static void handleEvents(List<GenerateScopeEvent__e> events) 
    {
        List<GenerateScopeEvent__e> eventsAccount = new List<GenerateScopeEvent__e>();
        List<GenerateScopeEvent__e> eventsAlternative = new List<GenerateScopeEvent__e>();
        List<GenerateScopeEvent__e> eventsPartner = new List<GenerateScopeEvent__e>();

        for(GenerateScopeEvent__e event : events) {
            if( event.HandleType__c == HANDLE_TYPE_SCOPE_ACCOUNT ) {
                eventsAccount.add(event);
            } else if( event.HandleType__c == HANDLE_TYPE_SCOPE_OTHER ) {
                if( String.isNotBlank(event.AccountId__c))
                    eventsAlternative.add(event);
            } else if( event.HandleType__c == HANDLE_TYPE_PARTNER_POLICY ) {
                eventsPartner.add(event);
            }
        }

        if( !eventsAccount.isEmpty() ) {
            handleEventsAccount(eventsAccount);
        }

        if( !eventsAlternative.isEmpty() ) {
            handleEventsAlternativeSObjects(eventsAlternative);
        }

        if( !eventsPartner.isEmpty() ) {
            handleEventsPartner(eventsPartner);
        }
    }

    /**
     * Procesar los eventos recibidos para generar el scope correspondiente a cada registro
     * @author adelgado
     * @date 04/12/2020
     * @param events Eventos a procesar
     * 
     * @change 15/06/2021 - nts (agonzalezisasi) - fix: para evitar actualizar el mismo objeto
     **/
    private static void handleEventsAccount(List<GenerateScopeEvent__e> events)
    {
        List<SObject> sobjectsToUpdate = new List<SObject>();
        List<ID> listAddedObjects = new List<ID>(); // lista para evitar modificar el mismo objeto

        Map<String, Scope_Setting__mdt> scopeSettingsByCode = new Map<String, Scope_Setting__mdt>();
        List<Scope__c> scopesToInsert = new List<Scope__c>();
        Map<String, List<Scope__c> > scopesByAccountId = new Map<String, List<Scope__c> >();
        Map<String, Map<String, Scope__c> > scopesByAccountIdAndType = new Map<String, Map<String, Scope__c> >();
        Map<String, Scope__c> scopesByObject = new Map<String, Scope__c>();

        Set<Id> accountIds = new Set<Id>();
        Set<String> sObjectsTypes = new Set<String>();

        String scopePicklistValue;
        String scopeNameValue;
        Scope__c scopeToAssign;

        try
        {
            // 1 - Recuperar metadatos con la configuración de scopes (Se tiene en cuenta el entorno)
            ScopeSettingsSelector scopeSettingSelector = new ScopeSettingsSelector();
            for( Scope_Setting__mdt scopeSetting : scopeSettingSelector.selectAll() )
            {
                if(scopeSettingSelector.isSandbox)
                {
                    scopeSettingsByCode.put(scopeSetting.SandboxBusinessCode__c, scopeSetting);
                }
                else
                {
                    scopeSettingsByCode.put(scopeSetting.BusinessCode__c, scopeSetting);
                }
            }

            // 2 - Obtener los ids de las cuentas y generar un mapa con todos ellos para agrupar los scopes que tienen actualmente generados
            for(GenerateScopeEvent__e event : events)
            {
                if( String.isNotBlank(event.AccountId__c) )
                {
                    accountIds.add(event.AccountId__c);
                    scopesByAccountId.put( event.AccountId__c, new List<Scope__c>() );
                }
            }

            // 3 - Obtener los scopes que ya existen de las cuentas recibidas en los eventos
            for( Scope__c scope : new ScopesSelector(new Set<String> {'AccountId__c', 'Scope__c'}).selectByAccountId(accountIds) )
            {
                if( scopesByAccountId.containsKey(scope.AccountId__c) )
                {
                    scopesByAccountId.get(scope.AccountId__c).add(scope);
                }
            }

            // 4 - Recorrer cada uno de los eventos para generar el scope si no existe y actualizar el registro
            for(GenerateScopeEvent__e event : events)
            {
                // 4.1 - Comprobar si se ha recibido el código de negocio para recuperar el scope correspondiente
                if( String.isNotBlank(event.BusinessCode__c) && scopeSettingsByCode.containsKey(event.BusinessCode__c) )
                {
                    scopePicklistValue = scopeSettingsByCode.get(event.BusinessCode__c).Scope__c;
                    scopeNameValue = scopeSettingsByCode.get(event.BusinessCode__c).Scope_Name__c;
                }
                // 4.2 - Si no se ha recibido el código de negocio quiere decir que se asignará al scope general
                else
                {
                    scopePicklistValue = 'Z';
                    scopeNameValue = 'General';
                }

                // 4.3 - Si se trata de una cuenta, únicamente se genera el scope correspondiente
                if(event.ObjectType__c == 'Account')
                {
                    Scope__c newScope = new Scope__c
                                        (
                        Name = scopeNameValue,
                        AccountId__c = event.AccountId__c,
                        Scope__c = scopePicklistValue
                                        );

                    scopesToInsert.add(newScope);

                    if( !scopesByAccountIdAndType.containsKey(event.AccountId__c) )
                    {
                        scopesByAccountIdAndType.put( event.AccountId__c, new Map<String, Scope__c>() );
                    }

                    scopesByAccountIdAndType.get(event.AccountId__c).put(scopePicklistValue, newScope);
                }
                else
                {
                    // 4.4 - Instanciar un objeto del tipo recibido en el evento y asignarle el campo RelatedId__c
                    SObject record = Schema.getGlobalDescribe().get(event.ObjectType__c).newSObject();
                    record.Id = event.RelatedId__c;

                    // 4.5 - Especificar el valor de la picklist de scope
                    record.put('Scope__c', scopePicklistValue);

                    // 4.6 - Si se ha recibido uan cuenta, se genera (si no existe) y se asigna el scope correspondiente al registro
                    if( String.isNotBlank(event.AccountId__c) )
                    {
                        scopeToAssign = null;

                        // 4.6.1 - Comprobar si la cuenta ya tiene generado el scope necesario
                        for( Scope__c scope : scopesByAccountId.get(event.AccountId__c) )
                        {
                            if(scope.Scope__c == scopePicklistValue)
                            {
                                scopeToAssign = scope;
                                break;
                            }
                        }

                        // 4.6.2 - Si no se ha econtrado el scope, se genera
                        if(scopeToAssign == null)
                        {
                            // 4.6.3 - Comprobar si el scope está pendiente de ser insertado porque ya se ha generado para otro registro
                            if( scopesByAccountIdAndType.containsKey(event.AccountId__c) && scopesByAccountIdAndType.get(event.AccountId__c).containsKey(scopePicklistValue) )
                            {
                                scopeToAssign = scopesByAccountIdAndType.get(event.AccountId__c).get(scopePicklistValue);
                            }
                            // 4.6.4 - Si no se ha econtrado el scope y no se ha generado anteriormente, se genera el scope con los datos necesarios
                            else
                            {
                                Scope__c newScope = new Scope__c
                                                    (
                                    Name = scopeNameValue,
                                    AccountId__c = event.AccountId__c,
                                    Scope__c = scopePicklistValue
                                                    );

                                scopeToAssign = newScope;
                                scopesToInsert.add(newScope);

                                if( !scopesByAccountIdAndType.containsKey(event.AccountId__c) )
                                {
                                    scopesByAccountIdAndType.put( event.AccountId__c, new Map<String, Scope__c>() );
                                }

                                scopesByAccountIdAndType.get(event.AccountId__c).put(scopePicklistValue, newScope);
                            }
                        }

                        if(scopeToAssign != null)
                        {
                            scopesByObject.put(record.Id, scopeToAssign);
                        }
                    }

                    // 4.7 - Añadir el SObject a la lista de SObjects a actualizar, sino lo estaba ya
                    // fix: para evitar actualizar el mismo objeto
                    if( !listAddedObjects.contains(record.Id) ) {
                        sobjectsToUpdate.add(record);
                        listAddedObjects.add(record.Id);
                    }
                }

                sObjectsTypes.add(event.ObjectType__c);
            }

            // 5 - Insertar los registros de scope generados
            if( !scopesToInsert.isEmpty() )
            {
                insert scopesToInsert;
            }

            // 6 - Asignar a cada registro el scope correspondiente si este se ha creado en el paso anterior
            for(SObject record :sobjectsToUpdate)
            {
                if( scopesByObject.containsKey(record.Id) )
                {
                    record.put('ScopeId__c', scopesByObject.get(record.Id).Id);
                }
            }

            // 7 - Actualizar los registros
            if( !sobjectsToUpdate.isEmpty() )
            {
                if(sObjectsTypes.size() > 1)
                {
                    sobjectsToUpdate.sort();
                }
                update sobjectsToUpdate;
            }

        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME, 'generateScopeEvents');
        }

    }

    /**
     * Procesar los eventos para recuperar el Scope de un objeto (sobject) referenciado mediante su id.
     * Por ejemplo: poner el scope que tenga la poliza (referenciado) en el objeto claim (relacionado)
     * 
     * @author nts (agonzalezisasi)
     * @date 17/02/2021
     * 
     * @param {List<GenerateScopeEvent__c} lista de eventos
     * 
     * @change 15/06/2021 - nts (agonzalezisasi) - fix: para evitar actualizar el mismo objeto
     */
    @testvisible
    private static void handleEventsAlternativeSObjects(List<GenerateScopeEvent__e> events)
    {
        List<Exception> generatedErrors = new List<Exception>();
        // Para que el proceso sea generico nos guardamos todas las referencias en mapas por el TIPO DE OBJETO
        Map<String, String> mapReferenceObjectNameByObjectType = new Map<String, String>(); // nombre del objeto referenciado
        Map<String, String> mapReferenceObjectFieldByObjectType = new Map<String, String>(); // nombre del campo del objeto referenciado
        Map<String, String> mapRelatedFieldNameByObjectType = new Map<String, String>(); // nombre del campo del objeto destino
        Map<String, Set<Id>> mapReferenceIdsByObjectTypes = new Map<String, Set<Id>>(); // lista de ids del objeto referenciado
        Map<String, Map<Id, SObject>> mapReferenceObjectByObjectTypes = new Map<String, Map<Id, SObject>>(); // lista de objetos referenciados, tras las queries bulk
        Map<String, List<SObject>> mapSObjectsToUpdate = new Map<String, List<SObject>>(); // lista de objetos a actualizar
        List<ID> listAddedObjects = new List<ID>(); // lista que evitara actualizar el mismo objeto en la llamada

        // 1. Clasificamos las listas ids referenciados de los eventos por su tipo de objeto para hacer luego
        // las consultas. Ej: Claim__c => lista de ids de poliza
        for(Integer i=0,j=events.size(); i<j; i++) {
            GenerateScopeEvent__e event = events[i];

            if( String.isNotBlank(event.AccountId__c) && String.isNotBlank(event.ReferenceObjectName__c) &&
                String.isNotBlank(event.ReferenceFieldName__c) && String.isNotBlank(event.RelatedFieldName__c)) {
                // Para cada tipo de objeto (Claim__c, Asset) guardamos la lista de ids a los objetos referenciados (Policy__c, etc.)
                if( mapReferenceIdsByObjectTypes.containsKey(event.ObjectType__c) ) {
                    mapReferenceIdsByObjectTypes.get(event.ObjectType__c).add(event.AccountId__c);
                } else {
                    mapReferenceIdsByObjectTypes.put(event.ObjectType__c, new Set<Id>{event.AccountId__c});
                }
            
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del objeto referenciado (Policy__c, etc.)
                if( !mapReferenceObjectNameByObjectType.containsKey(event.ObjectType__c)) {
                    mapReferenceObjectNameByObjectType.put(event.ObjectType__c, event.ReferenceObjectName__c);
                }
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del campo del objeto referenciado (Scope__c de Policy__c, etc.)
                if( !mapReferenceObjectFieldByObjectType.containsKey(event.ObjectType__c)) {
                    mapReferenceObjectFieldByObjectType.put(event.ObjectType__c, event.ReferenceFieldName__c);
                }
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del campo en ese objeto (Scope__c de Claim__c, etc.)
                if( !mapRelatedFieldNameByObjectType.containsKey(event.ObjectType__c) ) {
                    mapRelatedFieldNameByObjectType.put(event.ObjectType__c, event.RelatedFieldName__c);
                }
            }
        }

        // 2. Por cada Tipo de Objeto, recuperamos la lista de SObjects referenciados y lo clasificamos de nuevo
        // por tipo de objecto. Ej: Claim__c => mapa id de poliza => poliza (con el campo Scope__c)
        for(String objectType: mapReferenceIdsByObjectTypes.keySet()) {
            if( mapReferenceObjectNameByObjectType.containsKey(objectType) && 
                mapReferenceObjectFieldByObjectType.containsKey(objectType) &&
                mapReferenceIdsByObjectTypes.containsKey(objectType) ) {

                try {
                    // A continuacion comprobamos que las referencias a los SObject y sus campos existen.
                    // Lo hacemos aqui para que solo se haga una vez por tipo de Objeto

                    // Comprobamos que el Objeto destino existe
                    if( !Schema.getGlobalDescribe().containsKey(objectType) ) {
                        throw new GenerateScopeException('The Object doesnt exist: ' + objectType);
                    }
                    // Comprobamos que el campo del objeto destino existe
                    String relatedFieldName = mapRelatedFieldNameByObjectType.get(objectType);
                    if( !Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap().containsKey(relatedFieldName) ) {
                        throw new GenerateScopeException('The referenced Field Name doesnt exist: ' + objectType + '.' + relatedFieldName);
                    }
                    
                    // Recuperamos el nombre del objeto referenciado. Ej: para Claim seria Policy__c
                    String refObjectName = mapReferenceObjectNameByObjectType.get(objectType); // Ej. Policy__c
                    if( !Schema.getGlobalDescribe().containsKey(refObjectName) ) {
                        throw new GenerateScopeException('The referenced Object doesnt exist: ' + refObjectName);
                    }
                    // Recuperamos el nombre del campo del objeto referenciado. Ej: para Claim seria Scope__c de Policy__c
                    String refObjectFieldName = mapReferenceObjectFieldByObjectType.get(objectType); // Ej. Scope__c
                    if( !Schema.getGlobalDescribe().get(refObjectName).getDescribe().fields.getMap().containsKey(refObjectFieldName) ) {
                        throw new GenerateScopeException('The referenced Field Name doesnt exist: ' + refObjectName + '.' + refObjectFieldName);
                    }
                    
                    // Pasamos a realizar las consultas
                    // Recuperamos los ids de los eventos
                    Set<Id> ids = mapReferenceIdsByObjectTypes.get(objectType);
                    String query = 'SELECT ' + refObjectFieldName + ' FROM ' + refObjectName + ' WHERE Id IN :ids';
                    List<SObject> lista = Database.query(query);
                    // lo guardamos en un mapa de polizas por id categorizado por ObjectType
                    mapReferenceObjectByObjectTypes.put(objectType, new Map<Id, SObject>(lista));
                } catch( Exception ex ) {
                    generatedErrors.add(ex);
                }
            }
        }

        // 3. Por cada evento, miramos si su id de objeto referenciado existe y tiene Scope
        // Si lo hay, lo añadimos a una lista de objetos a actualizar, clasificados en un mapa por tipo de objeto
        // Ej: Claim__c => lista de Claims(id, Scope__c) a actualizar
        for(Integer i=0,j=events.size(); i<j; i++) {

            GenerateScopeEvent__e event = events[i];
            String objectType = event.ObjectType__c;
            Id parentId = event.AccountId__c;
            SObject obj = null;

            if( mapReferenceObjectByObjectTypes.containsKey(objectType) ) {
                if( mapReferenceObjectByObjectTypes.get(objectType).containsKey(parentId) &&
                    mapRelatedFieldNameByObjectType.containsKey(objectType) &&
                    mapReferenceObjectFieldByObjectType.containsKey(objectType)) 
                {
                    // Recupera el campo a actualizar
                    String relatedFieldName = mapRelatedFieldNameByObjectType.get(objectType); // Ej: Scope__c de Claim__c
                    // Recupera el campo del objeto referenciado
                    String refObjectFieldName = mapReferenceObjectFieldByObjectType.get(objectType);  // Ej: Scope__c de Policy__c
                    // Recupera el objeto referenciado. Ej: Policy__c para los Claims
                    SObject referenceObject = mapReferenceObjectByObjectTypes.get(objectType).get(parentId);

                    // Inicializa un objeto a actualizar del tipo correspondiente. Ej: new Claim__c(Id=xxx,Scope__c=xxxx)
                    obj = (SObject)Type.forName(objectType).newInstance();
                    // establece el campo Id para el update
                    obj.put('Id', event.relatedId__c);
                    // y establece el campo del objeto referenciado al campo correspondiente. Ej: Claim__c.Scope__c = Policy__c.Scope__c
                    obj.put(relatedFieldName, referenceObject.get(refObjectFieldName));
                }
            }

            if( obj != null ) {
                // fix: para evitar actualizar el mismo objeto
                if( !listAddedObjects.contains(obj.Id) ) {
                    if( mapSObjectsToUpdate.containsKey(objectType) ) {
                        mapSObjectsToUpdate.get(objectType).add(obj);
                    } else {
                        mapSObjectsToUpdate.put(objectType, new List<SObject>{obj});
                    }
                    listAddedObjects.add(obj.Id);
                }
            }

        }

        // 4. Por cada tipo de objeto de evento, actualizamos los objetos con el Scope
        List<SObject> listToUpdate = new List<SObject>();
        for( String key: mapSObjectsToUpdate.keySet() ) {
            listToUpdate.addAll(mapSObjectsToUpdate.get(key));
        }
        update listToUpdate;
        if( !generatedErrors.isEmpty() ) {
            for(Integer i=0,j=generatedErrors.size();i<j;i++) {
                ErrorLogUtil.commitError(generatedErrors[i], CLASS_NAME, 'handleEventsAlternativeSObjects');
            }
        }
    }

    /**
     * Procesar los eventos para recuperar el Partner de un objeto (sobject) referenciado mediante su id
     * 
     * @author nts (agonzalezisasi)
     * @date 15/05/2021
     * 
     * @param {List<GenerateScopeEvent__c} lista de eventos
     * 
     * @change 15/06/2021 - nts (agonzalezisasi) - fix: para evitar actualizar el mismo objeto
     */
    @testvisible
    private static void handleEventsPartner(List<GenerateScopeEvent__e> events) 
    {
        
        List<Exception> generatedErrors = new List<Exception>();
        // Para que el proceso sea generico nos guardamos todas las referencias en mapas por el TIPO DE OBJETO
        Map<String, String> mapReferenceObjectNameByObjectType = new Map<String, String>(); // nombre del objeto referenciado
        Map<String, String> mapReferenceObjectFieldByObjectType = new Map<String, String>(); // nombre del campo del objeto referenciado
        Map<String, String> mapRelatedFieldNameByObjectType = new Map<String, String>(); // nombre del campo del objeto destino
        Map<String, Set<String>> mapReferenceIdsByObjectTypes = new Map<String, Set<String>>(); // lista de ids del objeto referenciado
        Map<String, Map<String, ID>> mapReferenceObjectByObjectTypes = new Map<String, Map<String, Id>>(); // lista de objetos referenciados, tras las queries bulk
        Map<String, List<SObject>> mapSObjectsToUpdate = new Map<String, List<SObject>>(); // lista de objetos a actualizar
        List<ID> listAddedObjects = new List<ID>(); // lista que evitara actualizar el mismo objeto en la llamada

        // 1. Clasificamos las listas ids referenciados de los eventos por su tipo de objeto para hacer luego
        // las consultas. Ej: Claim__c => lista de ids de poliza
        for(Integer i=0,j=events.size(); i<j; i++) {
            GenerateScopeEvent__e event = events[i];

            if( String.isNotBlank(event.BusinessCode__c) && String.isNotBlank(event.ReferenceObjectName__c) &&
                String.isNotBlank(event.ReferenceFieldName__c) && String.isNotBlank(event.RelatedFieldName__c)) {
                // Para cada tipo de objeto (Claim__c, Asset) guardamos la lista de ids a los objetos referenciados (Policy__c, etc.)
                if( mapReferenceIdsByObjectTypes.containsKey(event.ObjectType__c) ) {
                    mapReferenceIdsByObjectTypes.get(event.ObjectType__c).add(event.BusinessCode__c);
                } else {
                    mapReferenceIdsByObjectTypes.put(event.ObjectType__c, new Set<String>{event.BusinessCode__c});
                }
            
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del objeto referenciado (Policy__c, etc.)
                if( !mapReferenceObjectNameByObjectType.containsKey(event.ObjectType__c)) {
                    mapReferenceObjectNameByObjectType.put(event.ObjectType__c, event.ReferenceObjectName__c);
                }
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del campo del objeto referenciado (Scope__c de Policy__c, etc.)
                if( !mapReferenceObjectFieldByObjectType.containsKey(event.ObjectType__c)) {
                    mapReferenceObjectFieldByObjectType.put(event.ObjectType__c, event.ReferenceFieldName__c);
                }
                // Para cada tipo de objeto (Claim__c, Asset) guardamos el nombre del campo en ese objeto (Scope__c de Claim__c, etc.)
                if( !mapRelatedFieldNameByObjectType.containsKey(event.ObjectType__c) ) {
                    mapRelatedFieldNameByObjectType.put(event.ObjectType__c, event.RelatedFieldName__c);
                }
            }
        }

        // 2. Por cada Tipo de Objeto, recuperamos la lista de SObjects referenciados y lo clasificamos de nuevo
        // por tipo de objecto. Ej: Claim__c => mapa id de poliza => poliza (con el campo Scope__c)
        for(String objectType: mapReferenceIdsByObjectTypes.keySet()) {
            if( mapReferenceObjectNameByObjectType.containsKey(objectType) && 
                mapReferenceObjectFieldByObjectType.containsKey(objectType) &&
                mapReferenceIdsByObjectTypes.containsKey(objectType) ) {

                try {
                    // A continuacion comprobamos que las referencias a los SObject y sus campos existen.
                    // Lo hacemos aqui para que solo se haga una vez por tipo de Objeto

                    // Comprobamos que el Objeto destino existe
                    if( !Schema.getGlobalDescribe().containsKey(objectType) ) {
                        throw new GenerateScopeException('The Object doesnt exist: ' + objectType);
                    }
                    // Comprobamos que el campo del objeto destino existe
                    String relatedFieldName = mapRelatedFieldNameByObjectType.get(objectType);
                    if( !Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap().containsKey(relatedFieldName) ) {
                        throw new GenerateScopeException('The referenced Field Name doesnt exist: ' + objectType + '.' + relatedFieldName);
                    }
                    
                    // Recuperamos el nombre del objeto referenciado. Ej: para Claim seria Policy__c
                    String refObjectName = mapReferenceObjectNameByObjectType.get(objectType); // Ej. Policy__c
                    if( !Schema.getGlobalDescribe().containsKey(refObjectName) ) {
                        throw new GenerateScopeException('The referenced Object doesnt exist: ' + refObjectName);
                    }
                    // Recuperamos el nombre del campo del objeto referenciado. Ej: para Claim seria Scope__c de Policy__c
                    String refObjectFieldName = mapReferenceObjectFieldByObjectType.get(objectType); // Ej. Scope__c
                    if( !Schema.getGlobalDescribe().get(refObjectName).getDescribe().fields.getMap().containsKey(refObjectFieldName) ) {
                        throw new GenerateScopeException('The referenced Field Name doesnt exist: ' + refObjectName + '.' + refObjectFieldName);
                    }
                    
                    // Pasamos a realizar las consultas
                    // Recuperamos los ids de los eventos
                    Set<String> ids = mapReferenceIdsByObjectTypes.get(objectType);
                    String query = 'SELECT Id, ' + refObjectFieldName + ' FROM ' + refObjectName + ' WHERE ' + refObjectFieldName + ' IN :ids';
                    List<SObject> lista = Database.query(query);

                    // Convertimos la lista en un mapa que nos da el ID a partir del codigo
                    Map<String, ID> mapCodeToId = new Map<String, ID>();
                    for(SObject o: lista) {
                        mapCodeToId.put((String)o.get(refObjectFieldName), (ID)o.get('Id'));
                    }
                    // lo guardamos en un mapa de polizas por id categorizado por ObjectType
                    mapReferenceObjectByObjectTypes.put(objectType, mapCodeToId);
                } catch( Exception ex ) {
                    generatedErrors.add(ex);
                }
            }
        }

        // 3. Por cada evento, miramos si su id de objeto referenciado existe y tiene Scope
        // Si lo hay, lo añadimos a una lista de objetos a actualizar, clasificados en un mapa por tipo de objeto
        // Ej: Claim__c => lista de Claims(id, Scope__c) a actualizar
        for(Integer i=0,j=events.size(); i<j; i++) {

            GenerateScopeEvent__e event = events[i];
            String objectType = event.ObjectType__c;
            String code = event.BusinessCode__c;
            SObject obj = null;

            if( mapReferenceObjectByObjectTypes.containsKey(objectType) ) {
                if( mapReferenceObjectByObjectTypes.get(objectType).containsKey(code) &&
                    mapRelatedFieldNameByObjectType.containsKey(objectType) &&
                    mapReferenceObjectFieldByObjectType.containsKey(objectType)) 
                {
                    // Recupera el campo a actualizar
                    String relatedFieldName = mapRelatedFieldNameByObjectType.get(objectType); // Ej: Scope__c de Claim__c
                    // Recupera el campo del objeto referenciado
                    String refObjectFieldName = mapReferenceObjectFieldByObjectType.get(objectType);  // Ej: Scope__c de Policy__c
                    // Recupera el objeto referenciado. Ej: Policy__c para los Claims
                    ID referenceObjectId = mapReferenceObjectByObjectTypes.get(objectType).get(code);

                    // Inicializa un objeto a actualizar del tipo correspondiente. Ej: new Claim__c(Id=xxx,Scope__c=xxxx)
                    obj = (SObject)Type.forName(objectType).newInstance();
                    // establece el campo Id para el update
                    obj.put('Id', event.relatedId__c);
                    // y establece el campo del objeto referenciado al campo correspondiente. Ej: Claim__c.Scope__c = Policy__c.Scope__c
                    obj.put(relatedFieldName, referenceObjectId);
                }
            }

            if( obj != null ) {
                // fix: para evitar actualizar el mismo objeto
                if( !listAddedObjects.contains(obj.Id) ) {
                    if( mapSObjectsToUpdate.containsKey(objectType) ) {
                        mapSObjectsToUpdate.get(objectType).add(obj);
                    } else {
                        mapSObjectsToUpdate.put(objectType, new List<SObject>{obj});
                    }
                    listAddedObjects.add(obj.Id);
                }
            }

        }

        // 4. Por cada tipo de objeto de evento, actualizamos los objetos con el Scope
        List<SObject> listToUpdate = new List<SObject>();
        for( String key: mapSObjectsToUpdate.keySet() ) {
            listToUpdate.addAll(mapSObjectsToUpdate.get(key));
        }
        update listToUpdate;

        if( !generatedErrors.isEmpty() ) {
            for(Integer i=0,j=generatedErrors.size();i<j;i++) {
                ErrorLogUtil.commitError(generatedErrors[i], CLASS_NAME, 'handleEventsPartner');
            }
        }
    }

    private class GenerateScopeException extends Exception {}
}