public with sharing class EventSelector {
    

    /**Recuperar la información del evento y sus attendees
     * @author nts (dmunoz)
     * @date 23/08/2022
     * 
     * @param {Id} idEvento
     * @return {List<Event>} evento que cumple el filtro 
     */
    public static List<Event> getEventAndAttendees(Id eventId) {
        List<Event> result = new List<Event>();

        if (eventId != null && String.isNotEmpty(eventId)) {
            result = new List<Event>([SELECT Id, Subject, Location, Owner.Name, CreatedBy.Name, IsChild, Acta__c, (select Relation.Name from EventRelations) FROM event where ID = :eventId]);
        } 

        return result;
    }

    /**Recuperar el id acta de un evento
     * @author nts (dmunoz)
     * @date 26/01/2023
     * 
     * @param {Id} idEvento
     * @return {List<Event>} evento que cumple el filtro 
     */
    public static List<Event> getActaFromEvent(Id eventId) {
        List<Event> result = new List<Event>();

        if (eventId != null && String.isNotEmpty(eventId)) {
            result = new List<Event>([SELECT Id, Acta__c, Acta__r.Name FROM event where ID = :eventId]);
        } 

        return result;
    }


    /**Recuperar campos de evento para el pdf de acta los cuales necesitan un tratamiento para mostrarse correctamente
     * @author nts (dmunoz)
     * @date 26/01/2023
     * 
     * @param {Id} idEvento
     * @return {List<Event>} evento que cumple el filtro 
     */
    public static List<Event> getActaTemplateData(Id eventId) {
        List<Event> result = new List<Event>();

        if (eventId != null && String.isNotEmpty(eventId)) {
            result = new List<Event>([SELECT Id, Subject, ActivityDate, ActivityDateTime, EndDate, EndDateTime, toLabel(EventType__c), IsAllDayEvent FROM event where ID = :eventId]);
        } 

        return result;
    }

}
