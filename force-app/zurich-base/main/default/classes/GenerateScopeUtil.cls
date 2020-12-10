public class GenerateScopeUtil
{
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
            for(Integer i = 0; i < 200; i++)
            {
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
                        BusinessCode__c = String.isNotBlank(businessCodeField) ? (String) record.get(businessCodeField) : null
                    )
                );
            }

            return EventBus.publish(generateScopeEvents);

        }
        catch (Exception e)
        {
            if (EventBus.TriggerContext.currentContext().retries < 9)
            {
                throw new EventBus.RetryableException( e.getMessage() );
            }
            else
            {
                ErrorLogUtil.commitError(e, 'GenerateScopeUtil', 'generateScopeEvents');
            }
        }

        return null;

    }

    /**
     * Procesar los eventos recibidos para generar el scope correspondiente a cada registro
     * @author adelgado
     * @date 04/12/2020
     * @param events Eventos a procesar
     **/
    private static void handleEvents(List<GenerateScopeEvent__e> events)
    {
        List<SObject> sobjectsToUpdate = new List<SObject>();

        Map<String, Scope_Setting__mdt> scopeSettingsByCode = new Map<String, Scope_Setting__mdt>();
        List<Scope__c> scopesToInsert = new List<Scope__c>();
        Map<String, List<Scope__c> > scopesByAccountId = new Map<String, List<Scope__c> >();
        Map<String, Map<String, Scope__c> > scopesByAccountIdAndType = new Map<String, Map<String, Scope__c> >();
        Map<String, Scope__c> scopesByObject = new Map<String, Scope__c>();

        Set<Id> accountIds = new Set<Id>();

        String scopePicklistValue;
        String scopeNameValue;
        Scope__c scopeToAssign;

        try
        {
            // 1 - Recuperar metadatos con la configuración de scopes
            for( Scope_Setting__mdt scopeSetting : new ScopeSettingsSelector().selectAll() )
            {
                scopeSettingsByCode.put(scopeSetting.BusinessCode__c, scopeSetting);
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
                if( String.isNotBlank(event.BusinessCode__c) )
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

                // 4.3 - Instanciar un objeto del tipo recibido en el evento y asignarle el campo RelatedId__c
                SObject record = Schema.getGlobalDescribe().get(event.ObjectType__c).newSObject();
                record.Id = event.RelatedId__c;

                // 4.4 - Especificar el valor de la picklist de scope
                record.put('Scope__c', scopePicklistValue);

                // 4.5 - Si se ha recibido uan cuenta, se genera (si no existe) y se asigna el scope correspondiente al registro
                if( String.isNotBlank(event.AccountId__c) )
                {
                    scopeToAssign = null;

                    // 4.5.1 - Comprobar si la cuenta ya tiene generado el scope necesario
                    for( Scope__c scope : scopesByAccountId.get(event.AccountId__c) )
                    {
                        if(scope.Scope__c == scopePicklistValue)
                        {
                            scopeToAssign = scope;
                            break;
                        }
                    }

                    // 4.5.2 - Si no se ha econtrado el scope, se genera
                    if(scopeToAssign == null)
                    {
                        // 4.5.3 - Comprobar si el scope está pendiente de ser insertado porque ya se ha generado para otro registro
                        if( scopesByAccountIdAndType.containsKey(event.AccountId__c) && scopesByAccountIdAndType.get(event.AccountId__c).containsKey(scopePicklistValue) )
                        {
                            scopeToAssign = scopesByAccountIdAndType.get(event.AccountId__c).get(scopePicklistValue);
                        }
                        // 4.5.4 - Si no se ha econtrado el scope y no se ha generado anteriormente, se genera el scope con los datos necesarios
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

                // 4.6 - Añadir el SObject a la lista de SObjects a actualizar
                sobjectsToUpdate.add(record);
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
                update sobjectsToUpdate;
            }

        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'GenerateScopeUtil', 'generateScopeEvents');
        }

    }
}