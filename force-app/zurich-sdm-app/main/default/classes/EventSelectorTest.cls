@isTest
public with sharing class EventSelectorTest {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.generateEvent();
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
}
