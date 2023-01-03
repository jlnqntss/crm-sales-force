public with sharing class CreateActaController {
    
    /**
     * Insertar un acta asociado a un evento 
     * @param eventId: id del evento que lanza la peticion de crear acta
     * @return Id id del acta generado
     * @author dmunoz
     * @date 22/12/2022
     */
    @AuraEnabled
    public static Id createActa(Id eventId){
        try {
            // query evento y sus attendees 
            Event event = getEventData(eventId);

            // comprobar si existe ya un acta
            if (String.isNotEmpty(event.Acta__c)) {
                throw new HandledException(System.Label.SDM_Acta_CheckExist); 
            } 

            // comprobar si el acta lo está creando el organizador (owner) y el evento no es hijo lanza excepcion si no se cumple
            checkCanCreate(event);                       

            // si no existe se crea el objeto acta y se actualiza el evento            
            Id actaId = insertActa(event);
            updateEvent(eventId, actaId);
            

            return actaId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Obtener la información del evento y los asistentes a partir del id de evento recibido 
     * @param eventId: id del evento a consultar
     * @return Event datos del evento consultado
     * @author dmunoz
     * @date 22/12/2022
     */
    private static Event getEventData(Id eventId) {
        List<Event> eventosList = EventSelector.getEventAndAttendees(eventId);
        Event result;

        if (!eventosList.isEmpty()) {
            result = eventosList.get(0);
        }

        return result;
    }

    /**
     * Comprobar que el usuario logueado no esta intentando crear un acta sin ser el propietario del evento padre
     * @param event: evento obtenido de la base de datos     
     * @author dmunoz
     * @date 23/12/2022
     */
    private static void checkCanCreate(Event event) {

        if (event.IsChild) {
            // consulta del usuario que si podría 
            String message = System.Label.SDM_Acta_CheckOwner.replace('{0}', event.CreatedBy.Name);

            throw new HandledException(message);
        } 
    }

    /**
     * Insertar un registro de acta a partir de los datos del evento
     * @param event: evento obtenido de la base de datos     
     * @author dmunoz
     * @date 22/12/2022
     */
    private static Id insertActa(Event event) {
        Acta__c a = new Acta__c();
        a.MeetingObjective__c = event.Subject;
        a.Location__c = event.Location;
        a.Attendees__c = getEventAttendees(event);

        insert a;

        return a.Id;
    }

    /**
     * Asociamos el evento con el nuevo acta
     * @param eventId: id de evento
     * @param actaId: id de acta
     * @author dmunoz
     * @date 22/12/2022
     */
    private static void updateEvent(String eventId, Id actaId) {
        Event e = new Event();
        e.Id = eventId; 
        e.acta__c = actaId;

        update e;
    }

    /**
     * Obtener los nombres de los asistentes invitados del evento
     * @param event: evento obtenido de la base de datos
     * @return Texto con los nombres de los asistentes del evento
     * @author dmunoz
     * @date 22/12/2022
     */
    private static String getEventAttendees(Event event) {
        String result = event.Owner.Name + '\r\n';
        for (EventRelation er: event.EventRelations) {
            result += er.Relation.Name + '\r\n';
        }
        return result;
    }
}
