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
            result = new List<Event>([SELECT Id, Subject, Location, OwnerId, Owner.Name, Acta__c, (select Relation.Name from EventRelations) FROM event where ID = :eventId]);
        } 

        return result;
    }
}
