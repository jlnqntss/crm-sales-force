@isTest
public with sharing class EventSelectorTest {
    
    @TestSetup
    static void makeData(){
        Event e = TestDataFactory.generateEvent();
        Acta__c acta = TestDataFactory.generateActa(e);    
    }

    @isTest
    static void getEventAndAttendees() {

        List<Event> eventList = new List<Event>([SELECT Id, Subject FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            List<Event> resultList = EventSelector.getEventAndAttendees(queryEvent.Id);
            Test.stopTest();
 
            System.assertEquals(queryEvent.Subject, resultList.get(0).Subject, 'Deben tener el mismo subject');
        }        
    }


    @isTest
    static void getActaFromEvent() {

        List<Event> eventList = new List<Event>([SELECT Id, Subject, Acta__r.Name FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            List<Event> resultList = EventSelector.getActaFromEvent(queryEvent.Id);
            Test.stopTest();
            
            System.assertEquals(queryEvent.Acta__r.Name, resultList.get(0).Acta__r.Name, 'Debe encontrar el mismo registro');
        }        
    }


    @isTest
    static void getActaTemplateData() {

        List<Event> eventList = new List<Event>([SELECT Id, Subject FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            List<Event> resultList = EventSelector.getActaTemplateData(queryEvent.Id);
            Test.stopTest();
 
            System.assertEquals(queryEvent.Subject, resultList.get(0).Subject, 'Deben tener el mismo subject');
        }        
    }
}
