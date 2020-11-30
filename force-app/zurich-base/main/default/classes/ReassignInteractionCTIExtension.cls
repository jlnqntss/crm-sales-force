/**
 * Clase Apex que personaliza el guardado de interacciones de Genesys Cloud para adaptar los procesos de guardado del conector.
 * Para pruebas unitarias, ejecutar el método a través de un Execute Anoyimous serializando un Mapa de mapas a JSON.
 * '{ "interaction" : { "id": "test1"} } ' '{"eventName": "interactionChanged", "interaction" : { "id": "ucid1"},  "callLog": {"CallObject": "ucid1"}}'
 */
global without sharing class ReassignInteractionCTIExtension implements purecloud.CTIExtension.SaveLog
{
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
                else if(interactionTask.type == 'Email')
                {
                    List<EmailMessage> relatedEmailMessages = new EmailMessagesSelector(new Set<String> { 'Id', 'ParentId', 'Status', 'ToIds', 'ActivityId' }).selectByInteractionId(new Set<String> { interactionId });

                    interactionTask.Id = relatedEmailMessages[0].ActivityId;
                    if(relatedEmailMessages[0].ParentId != null)
                    {
                        interactionTask.WhatId = relatedEmailMessages[0].ParentId;
                    }
                }

                interactionTask.Status = 'Asignada';
                interactionTask.CallObject = interactionId;
                interactionTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
                interactionTask.OwnerId = UserInfo.getUserId();

                //Actualizar el CASO relacionado con la TASK
                changeCaseOwnerFromQueueToUser(interactionTask);
            }
            else if(eventName == 'interactionDisconnected')
            {
                interactionTask.Status = 'Cerrada';
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
     * data.eventName: Representa ele vento que lanza la creación/actualización del Call Log
     * @return Tarea generada
     */
    private static Task createTaskFromCallLog(Map<String, Object> callLog)
    {
        Task interactionTask;
        Id taskId;

        if(callLog.containsKey('Id') )
        {
            String id = String.valueOf(callLog.remove('Id') );

            if(id.length() > 10)
            {
                taskId = id;
            }
        }

        interactionTask = (Task) JSON.deserialize(JSON.serialize(callLog), Task.class);

        if(String.isNotBlank(taskId) )
        {
            interactionTask.Id = taskId;
        }

        return interactionTask;
    }

     /**
     * Si la tarea está asociada a un caso y este caso pertenece a una cola, reasignar el caso al usuario actual.
     * @param interactionTask Task recibida
     */
    @TestVisible
    private static void changeCaseOwnerFromQueueToUser(Task interactionTask)
    {
        //Comprobar si es un CASO
        if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == Case.sObjectType)
        {
            List<Case> cases = [SELECT Id, OwnerId, Owner.Type FROM Case WHERE Id = :interactionTask.WhatId];
            if(!cases.isEmpty())
            {
                //Si el propietario es una COLA
                if(cases[0].OwnerId.getSobjectType() == Group.sObjectType) //(cases[0].Owner.Type == 'Queue')
                {
                    //Cambiar el propietario al usuario actual
                    cases[0].OwnerId = UserInfo.getUserId();
                    update cases;
                }
            }
        }
    }
}