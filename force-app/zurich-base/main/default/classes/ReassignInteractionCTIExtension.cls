/**
 * Clase Apex que personaliza el guardado de interacciones de Genesys Cloud para adaptar los procesos de guardado del conector.
 * Para pruebas unitarias, ejecutar el método a través de un Execute Anoyimous serializando un Mapa de mapas a JSON.
 * '{ "interaction" : { "id": "test1"} } ' '{"eventName": "interactionChanged", "interaction" : { "id": "ucid1"},  "callLog": {"CallObject": "ucid1"}}'
 */
global without sharing class ReassignInteractionCTIExtension implements purecloud.CTIExtension.SaveLog
{
    private final static String TASK_SUBTYPE_CALL = 'Call';
    private final static String TASK_SUBTYPE_EMAIL = 'Email';
    private final static String TASK_STATUS_ASSIGNED = 'Asignada';
    private final static String TASK_STATUS_CLOSED = 'Cerrada';

    /**
     * Identifica una tarea a través del parámetro data.interaction.id y devuelve dicha tarea modificando el usuario Asignado
     * @param data: JSON string con la información de Genesys Cloud
     * data.eventName: Representa ele vento que lanza la creación/actualización del Call Log
     * data.interaction: Representa la interacción de Genesys
     * data.interaction.id: Interaction Id. Debe usarse para buscar la tarea a partir del campo CallObjectIdentifier
     * @return Identificado de la tarea creada/actualizada
     * @author nescudero
     * @date 27/10/2020
     * @consideraciones El parámetro data llega como un JSON que debe ser deserializado mediante JSON.deserialize
     * Enlace a documentación de la interfaz: https://help.mypurecloud.com/articles/use-the-extension-points-to-customize-saving-interaction-logs/
     */
    public static String onSaveLog(String data)
    {
        Savepoint sp = Database.setSavepoint();

        try
        {
            Map<String, Object> deserializedData = (Map<String, Object>) JSON.deserializeUntyped(data);
            Task interactionTask = createTaskFromCallLog( (Map<String, Object>) deserializedData.get('callLog') );
            String eventName = (String) deserializedData.get('eventName');
            String interactionId;
            Id currentWhatId;

            // 1 - Si la tarea de Genesys no cuenta con Id,se busca en el sistema a través del InteractionId
            //     Este proceso solo se produce en la gestión inicial
            if(eventName == 'interactionChanged' && String.isEmpty(interactionTask.Id) )
            {
                Map<String, Object> interaction = (Map<String, Object>) deserializedData.get('interaction');

                if ( interaction.containsKey('id') )
                {
                    interactionId = (String) interaction.get('id');
                }

                List<Task> existingInteractionTasks = ActivitySelector.selectTasksByCallObjectIdentifier(interactionId);

                if(!existingInteractionTasks.isEmpty() )
                {
                    interactionTask.Id = existingInteractionTasks[0].Id;
                    interactionTask.WhatId = existingInteractionTasks[0].WhatId;
                    interactionTask.WhoId = existingInteractionTasks[0].WhoId;
                }
                else if(interactionTask.type == TASK_SUBTYPE_EMAIL)
                {
                    List<EmailMessage> relatedEmailMessages = new EmailMessagesSelector(new Set<String> { 'Id', 'ParentId', 'Status', 'ToIds', 'ActivityId' }).selectByInteractionId(new Set<String> { interactionId });

                    interactionTask.Id = relatedEmailMessages[0].ActivityId;
                    if(relatedEmailMessages[0].ParentId != null)
                    {
                        interactionTask.WhatId = relatedEmailMessages[0].ParentId;
                    }
                    interactionTask.TaskSubtype = TASK_SUBTYPE_EMAIL;
                }
                else if(interactionTask.type == TASK_SUBTYPE_CALL)
                {
                    interactionTask.TaskSubtype = TASK_SUBTYPE_CALL;
                }

                interactionTask.Status = TASK_STATUS_ASSIGNED;
                interactionTask.CallObject = interactionId;
                interactionTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
                interactionTask.OwnerId = UserInfo.getUserId();
            }
            else if(eventName == 'interactionDisconnected')
            {
                interactionTask.Status = TASK_STATUS_CLOSED;
            }

            //Actualizar Owner del registro relacionado en cualquier situación que se tenga whatId
            if(interactionTask.WhatId != null)
            {
                changeOwnerFromQueueToUser(interactionTask);
            }

            upsert interactionTask;

            return interactionTask.Id;
        }
        catch (Exception e)
        {
            Database.rollback(sp);
            ErrorLogUtil.commitError(e);
        }

        return null;
    }

    /**
     * Crea la tarea solventando las deficiencias en el formato de Genesys con respecto al Id.
     *
     * @author jmartinezpisson
     * @date 17/11/2020
     * @param {Map<String, Object>} callLog: Mapa clave-valor con los datos de la tarea
     * @return Tarea generada
     */
    private static Task createTaskFromCallLog(Map<String, Object> callLog)
    {
        Task interactionTask;
        Id taskId, whatId, whoId;

        if(callLog.containsKey('Id') )
        {
            taskId = parseId(callLog.remove('Id') );
        }

        if(callLog.containsKey('WhatId') )
        {
            whatId = parseId(callLog.remove('WhatId') );
        }

        if(callLog.containsKey('WhoId') )
        {
            whoId = parseId(callLog.remove('WhoId') );
        }

        interactionTask = (Task) JSON.deserialize(JSON.serialize(callLog), Task.class);

        if(String.isNotBlank(taskId) )
        {
            interactionTask.Id = taskId;
        }

        if(String.isNotBlank(whatId) )
        {
            interactionTask.WhatId = whatId;
        }

        if(String.isNotBlank(whoId) )
        {
            interactionTask.WhoId = whoId;
        }

        return interactionTask;
    }

    /**
     * Parsea un Id de un Object
     *
     * @author jmartinezpisson
     * @date 17/11/2020
     * @param {Object} idToParse Id a tratar
     * @return {Id} Id parseado. null si el valor no era un Id.
     */
    private static Id parseId(Object idToParse)
    {
        String id = String.valueOf(idToParse);

        return id.length() > 10 ? id : null;
    }

    /**
     * Si la tarea está asociada a un caso y este caso pertenece a una cola, reasignar el caso al usuario actual.
     * @param interactionTask Task recibida
     */
    @TestVisible
    private static void changeOwnerFromQueueToUser(Task interactionTask)
    {
        //Comprobar si es un CASO
        if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == Case.sObjectType)
        {
            List<Case> cases = [SELECT Id, OwnerId, Owner.Type FROM Case WHERE Id = :interactionTask.WhatId];
            if(!cases.isEmpty() )
            {
                //Si el propietario es una COLA
                if(cases[0].OwnerId.getSobjectType() == Group.sObjectType) //(cases[0].Owner.Type == 'Queue')
                {
                    //Cambiar el propietario al usuario actual
                    cases[0].OwnerId = UserInfo.getUserId();
                    update cases;
                }
            }
        }//Comprobar si es un ContactRequest
        else if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == ContactRequest.sObjectType)
        {
            List<ContactRequest> contactrequests = [SELECT Id, OwnerId FROM ContactRequest WHERE Id = :interactionTask.WhatId];
            if(!contactrequests.isEmpty() )
            {
                //Cambiar el propietario al usuario actual siempre
                contactrequests[0].OwnerId = UserInfo.getUserId();
                update contactrequests;
            }
        }//Comprobar si es una Offer
        else if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == Opportunity.sObjectType)
        {
            List<Opportunity> offers = [SELECT Id, AccountId, ScopeId__c, OwnerId, Owner.ProfileId, Owner.Profile.Name FROM Opportunity WHERE Id = :interactionTask.WhatId];
            if(!offers.isEmpty() )
            {
                List<Opportunity> totalOffers = new List<Opportunity>();
                totalOffers.addAll(offers);
                //Si el cliente de la oferta tiene más ofertas que también están asignadas a Integrator, cambiarlas todas de owner
                if(offers[0].AccountId != null && offers[0].ScopeId__c != null)
                {
                    Id accountId = offers[0].AccountId;
                    Id scopeId = offers[0].ScopeId__c;
                    List<Opportunity> extraOffers = new List<Opportunity>();
                    extraOffers = [SELECT Id, OwnerId, Owner.ProfileId, Owner.Profile.Name FROM Opportunity WHERE Id != :interactionTask.WhatId AND AccountId = :accountId AND ScopeId__c = :scopeId];
                    if(!extraOffers.isEmpty() )
                    {
                        totalOffers.addAll(extraOffers);
                    }
                }

                //Si el Owner es el Integrador hay que cambiarlo
                for(Opportunity offer: totalOffers)
                {
                    if(offer.OwnerId != null && offer.Owner.Profile.Name == 'Integrator')
                    {
                        //Cambiar el propietario al usuario actual
                        offer.OwnerId = UserInfo.getUserId();
                    }
                }
                update totalOffers;
            }
        }
    }
}