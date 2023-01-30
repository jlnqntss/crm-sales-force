@isTest
public with sharing class GeneratePDFActaControllerTest {
    @TestSetup
    static void makeData(){
        Event e = TestDataFactory.generateEvent();
        Acta__c acta = TestDataFactory.generateActa(e);
    }


    @isTest static void checkActaExists() {
        List<Event> eventList = new List<Event>([SELECT Id, Acta__r.Name FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            String nombreActa = GeneratePDFActaController.checkActaExists(queryEvent.Id);
            Test.stopTest();
 
            System.assertEquals(queryEvent.Acta__r.Name, nombreActa, 'Deben coincidir el nombre del acta');
        }        
    } 
    
    @isTest static void checkActaExists_KO() {
        List<Event> eventList = new List<Event>([SELECT Id, Acta__r.Name FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            
            try {
                List<Event> eventToDelete = new List<Event>([SELECT Id FROM Event WHERE Id = :queryEvent.Id]);
                delete eventToDelete; // borro para que no lo encuentre

                Test.startTest();
                String nombreActa = GeneratePDFActaController.checkActaExists(queryEvent.Id);
                Test.stopTest(); 
            
            } catch (Exception e) {
                System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Se debe recibir un aura handled exception');
            }            
        }        
    }  
}