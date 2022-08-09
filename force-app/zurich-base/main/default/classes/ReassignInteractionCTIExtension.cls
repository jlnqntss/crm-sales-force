/**
 * Clase Apex que personaliza el guardado de interacciones de Genesys Cloud para adaptar los procesos de guardado del conector.
 * Para pruebas unitarias, ejecutar el método a través de un Execute Anoyimous serializando un Mapa de mapas a JSON.
 * '{ "interaction" : { "id": "test1"} } ' '{"eventName": "interactionChanged", "interaction" : { "id": "ucid1"},  "callLog": {"CallObject": "ucid1"}}'
 */
global without sharing class ReassignInteractionCTIExtension implements purecloud.CTIExtension.SaveLog
{
    private final static String TASK_SUBTYPE_CALL       = 'Call';
    private final static String TASK_SUBTYPE_EMAIL      = 'Email';
    private final static String TASK_STATUS_ASSIGNED    = 'Asignada';
    private final static String TASK_STATUS_CLOSED      = 'Cerrada';
    private final static String TASK_RECORDTYPE_ID_INTERACTION = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();

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
            Map<String, Object> deserializedEventData = (Map<String, Object>) JSON.deserializeUntyped(data);

            Task interactionTask = createTaskFromCallLog( (Map<String, Object>) deserializedEventData.get('callLog') );

            manageInteractionEvents(interactionTask, deserializedEventData);

            changeOwnerFromQueueToUser(interactionTask); // Se hace update del registro relacionado a la llamada

            upsert interactionTask;

            return interactionTask.Id;
        }
        catch (Exception interactionError)
        {
            Database.rollback(sp);
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_CRITICAL, interactionError.getMessage(), 'ReassignInteractionCTIExtension', interactionError.getStackTraceString() + ' Payload: ' + data);
        }

        return null;
    }

    /**
     * @author      jgallaga
     * @date        05/08/2022
     * @description A partir del tipo de evento, se gestiona la interacción de la forma adecuada
     * @param       Task - La interacción relacionada con el evento
     * @param       Map<String,Obejct> - Mapa con la información del evento
     */
    private static void manageInteractionEvents(Task interactionTask, Map<String, Object> eventData)
    {
        String eventName = (String) eventData.get('eventName');

        if(String.isBlank(eventName))
        {
            return;
        }

        if(eventName == 'interactionChanged' && String.isEmpty(interactionTask.Id))
        {
            Map<String, Object> interaction = (Map<String, Object>) eventData.get('interaction');
            eventOnInteractionChanged(interactionTask, interaction);
        }
        else if(eventName == 'interactionDisconnected')
        {
            eventOnInteractionDisconnected(interactionTask);
        }
    }

    /**
     * @author      jgallaga
     * @date        05/08/2022
     * @description Se comprueba si la interacción existe ya en el sistema de una gestión anterior.
     *              Dependiendo de si existe o no, se comprueba el tupo de interacción para relacionar la tarea con el registro
     *              correspondiente.
     *              Finalmente se asigna el estado y posesion de la tarea al usuario que ha provocado el evento.
     * @param       Task - La interacción relacionada con el evento
     * @param       Map<String,Obejct> - Mapa con la información del evento
     */
    private static void eventOnInteractionChanged(Task interactionTask, Map<String, Object> eventInteractionData)
    {
        String interactionId = eventInteractionData.containsKey('id') ? (String) eventInteractionData.get('id') : null;

        List<Task> existingInteractionTasks = ActivitySelector.selectTasksByCallObjectIdentifier(interactionId);

        if(!existingInteractionTasks.isEmpty() )
        {
            interactionTask.Id      = existingInteractionTasks[0].Id;
            interactionTask.WhatId  = existingInteractionTasks[0].WhatId;
            interactionTask.WhoId   = existingInteractionTasks[0].WhoId;
        }
        else if(interactionTask.type == TASK_SUBTYPE_EMAIL)
        {
            List<EmailMessage> relatedEmailMessages = new EmailMessagesSelector(new Set<String> { 'Id', 'ParentId', 'Status', 'ToIds', 'ActivityId' }).selectByInteractionId(new Set<String> { interactionId });

            if(!relatedEmailMessages.isEmpty() && relatedEmailMessages[0].ActivityId != null)
            {
                interactionTask.Id = relatedEmailMessages[0].ActivityId;

                if(relatedEmailMessages[0].ParentId != null)
                {
                    interactionTask.WhatId = relatedEmailMessages[0].ParentId;
                }
            }
            else
            {
                interactionTask.TaskSubtype = TASK_SUBTYPE_EMAIL;
            }
        }
        else if(interactionTask.type == TASK_SUBTYPE_CALL)
        {
            interactionTask.TaskSubtype = TASK_SUBTYPE_CALL;
        }

        interactionTask.Status      = TASK_STATUS_ASSIGNED;
        interactionTask.CallObject  = interactionId;
        interactionTask.OwnerId     = UserInfo.getUserId();
    }

        /**
     * @author      jgallaga
     * @date        05/08/2022
     * @description Al finalizar una interacción, el estado de la tarea pasa a cerrada.
     * @param       Task - La interacción relacionada con el evento
     * ***
     * Modificaciones
     * ***
     * @date    05/08/20222
     * @author  jgallaga
     * @description
     *          Se añade que en el cierre de la interacción, se asigne como propietario de la tarea al usuario que esta ejecutando la acción
     */
    private static void eventOnInteractionDisconnected(Task interactionTask)
    {
        interactionTask.Status  = TASK_STATUS_CLOSED;
        interactionTask.OwnerId = UserInfo.getUserId();
    }

    /**
     * Crea la tarea solventando las deficiencias en el formato de Genesys con respecto al Id.
     * Asigna siempre el Tipo de registro Interaction
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
        String idField = 'id', wahtIdField = 'whatid', whoIdField = 'whoid';

        for (String key : callLog.keySet())
        {
            String field = key.toLowerCase();

            if(field == idField)
            {
                taskId = parseId(callLog.remove(key));
            }

            if(field == wahtIdField)
            {
                whatId = parseId(callLog.remove(key));
            }

            if(field == whoIdField)
            {
                whoId = parseId(callLog.remove(key));
            }
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


        interactionTask.RecordTypeId = TASK_RECORDTYPE_ID_INTERACTION;

        return interactionTask;
    }

    /**
     * Parsea un Id de un Object
     *
     * @author jmartinezpisson
     * @date 17/11/2020
     * @param {Object} idToParse Id a tratar
     * @return {Id} Id parseado. null si el valor no era un Id.
     * @modification 5/7/2021 error de MALFORMED ID, ahora se comprueba
     * si es un ID de SF o no
     * @modification 26/7/2021 error Cannot locate Apex Type for ID
     */
    private static Id parseId(Object idToParse)
    {
        Pattern pattern15 = Pattern.compile('([a-zA-Z0-9]{15})');
        Pattern pattern18 = Pattern.compile('([a-zA-Z0-9]{18})');

        String strId = String.valueOf(idToParse);

        try
        {//Errores a evitar: Invalid id y Cannot locate Apex Type for ID
            Id checkSObjectFromId = Id.valueOf(strId);
            checkSObjectFromId.getsObjectType();
        }
        catch(Exception ex)
        {
            return null;
        }

        Matcher match15 = pattern15.matcher( strId );
        Matcher match18 = pattern18.matcher( strId );

        if(match15.matches() || match18.matches())
        {
            //Si es de 18 comprobar el checksum
            if(match18.matches())
            {
                String id15 = strId.substring(0,16);
                String idChecksumCalculated = sfdc15To18(id15);
                //Si coincide el cálculo del Checksum con el ID, bien
                if(idChecksumCalculated == strId)
                {
                    return strId;
                }
                return null;
            }
            return strId;
        }

        return null;
    }

    /**
     * Si la tarea está asociada a un caso y este caso pertenece a una cola, reasignar el caso al usuario actual.
     * @param interactionTask Task recibida
     * @last modified on  : 09/08/2022
     * @last modified by  : jgallaga
     */
    @TestVisible
    private static void changeOwnerFromQueueToUser(Task interactionTask)
    {
        if(interactionTask == null || String.isBlank(interactionTask.WhatId))
        {
            return;
        }

        try
        {
            //Comprobar si es un CASO
            if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == Case.sObjectType)
            {
                Set<String> idsCasos = new Set<String>();
                idsCasos.add(interactionTask.WhatId);

                List<Case> cases = new CasesSelector().findById(idsCasos);

                if(!cases.isEmpty() )
                {
                    //Si el propietario es una COLA
                    // arcortazar - nts: fix-OCS-2682: Hacemos que asignme el usuario si es Owner es una cola o el usuario Integrator
                    if(cases[0].OwnerId.getSobjectType() == Group.sObjectType || cases[0].Owner.Profile.Name == Label.IntegratorUser) //(cases[0].Owner.Type == 'Queue')
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
                List<Opportunity> offers = new OpportunitiesSelector().findById(interactionTask.WhatId);
                if(!offers.isEmpty() )
                {
                    List<Opportunity> totalOffers = new List<Opportunity>();

                    // Sería aqui donde tendríamos que cambiar el Owner de la oferta para que siempre pasase:
                    totalOffers.addAll(offers);

                    //Si el cliente de la oferta tiene más ofertas que también están asignadas a Integrator, cambiarlas todas de owner
                    if(offers[0].AccountId != null && offers[0].ScopeId__c != null)
                    {
                        // Luego ya buscamos el resto de ofertas asociadas a la misma Account y Scope para comprobar si alguna tiene como Owner el Integrator
                        Id accountId = offers[0].AccountId;
                        Id scopeId = offers[0].ScopeId__c;
                        List<Opportunity> extraOffers = new List<Opportunity>();
                        extraOffers = new OpportunitiesSelector().findByAccountIdAndScopeAndNotId(interactionTask.WhatId, accountId, scopeId);
                        if(!extraOffers.isEmpty() )
                        {
                            totalOffers.addAll(extraOffers);
                        }
                    }

                    //Si el Owner es el Integrador hay que cambiarlo
                    // arcortazar - 31/01/2022: Y si la oferta no es de test
                    for(Opportunity offer: totalOffers)
                    {
                        if(offer.OwnerId != null && offer.Owner.Profile.Name == 'Integrator' && offer.IsTest__c == false)
                        {
                            //Cambiar el propietario al usuario actual
                            offer.OwnerId = UserInfo.getUserId();
                            offer.HasBeenReassigned__c = true; //arcortazar - 09/03/2022: [ZE-1327] Indicamos que la oferta ha sido reasignada
                        }
                    }
                    update totalOffers;
                }
            }
        }
        catch(Exception e)
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, e.getMessage(), 'ReassignInteractionCTIExtension', e.getStackTraceString());
        }
    }

    /**
     * Método de ayuda para comprobar si es un ID de SF
     * @date 5/7/2021
     */
    private static String sfdc15To18 (String original15) {
        // This method expects a 15-char valid Salesforce ID, and returns the 18-char equivalent
        Map<String,String> lookup5bin = new Map<String,String>();
        String Piece1 = '';
        String Piece2 = '';
        String Piece3 = '';

        original15 = original15.substring(0,15);

        lookup5bin.put('00000','A'); lookup5bin.put('01000','I'); lookup5bin.put('10000','Q'); lookup5bin.put('11000','Y');
        lookup5bin.put('00001','B'); lookup5bin.put('01001','J'); lookup5bin.put('10001','R'); lookup5bin.put('11001','Z');
        lookup5bin.put('00010','C'); lookup5bin.put('01010','K'); lookup5bin.put('10010','S'); lookup5bin.put('11010','0');
        lookup5bin.put('00011','D'); lookup5bin.put('01011','L'); lookup5bin.put('10011','T'); lookup5bin.put('11011','1');
        lookup5bin.put('00100','E'); lookup5bin.put('01100','M'); lookup5bin.put('10100','U'); lookup5bin.put('11100','2');
        lookup5bin.put('00101','F'); lookup5bin.put('01101','N'); lookup5bin.put('10101','V'); lookup5bin.put('11101','3');
        lookup5bin.put('00110','G'); lookup5bin.put('01110','O'); lookup5bin.put('10110','W'); lookup5bin.put('11110','4');
        lookup5bin.put('00111','H'); lookup5bin.put('01111','P'); lookup5bin.put('10111','X'); lookup5bin.put('11111','5');

        Piece1 = sfdc0Or1(original15.substring(4,5)) +
        sfdc0Or1(original15.substring(3,4)) +
        sfdc0Or1(original15.substring(2,3)) +
        sfdc0Or1(original15.substring(1,2)) +
        sfdc0Or1(original15.substring(0,1));

        Piece2 = sfdc0Or1(original15.substring(9,10)) +
        sfdc0Or1(original15.substring(8,9)) +
        sfdc0Or1(original15.substring(7,8)) +
        sfdc0Or1(original15.substring(6,7)) +
        sfdc0Or1(original15.substring(5,6));

        Piece3 = sfdc0Or1(original15.substring(14,15)) +
        sfdc0Or1(original15.substring(13,14)) +
        sfdc0Or1(original15.substring(12,13)) +
        sfdc0Or1(original15.substring(11,12)) +
        sfdc0Or1(original15.substring(10,11));

        return (original15 + lookup5bin.get(Piece1) + lookup5bin.get(Piece2) + lookup5bin.get(Piece3));
    }

    /**
     * Método de ayuda para comprobar si es un ID de SF
     * @date 5/7/2021
     */
    private static String sfdc0Or1 (String charX) {
        // This method accepts a one-char string and returns '1' if it's between A and Z, otherwise '0'.

        if (charX.compareTo('A') >= 0 && charX.compareTo('A') <= 25 && charX.compareTo('Z') >= -25 && charX.compareTo('Z') <= 0) return '1';
        return '0';
    }
}