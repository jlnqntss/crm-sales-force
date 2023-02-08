public with sharing class GeneratePDFActaController {

    @AuraEnabled
    public static String checkActaExists(String eventId){
        try {
            String result = '';
            List<Event> events = EventSelector.getActaFromEvent(eventId);

            if (!events.isEmpty()) {
                Event e = events.get(0);
                if (String.isNotEmpty(e.Acta__c)) {
                    result = e.Acta__r.Name;
                }
            } else {
                throw new HandledException(System.Label.SDM_Acta_NoActaErrorToastMessage);
            }                    
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}