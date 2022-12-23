@isTest
public with sharing class CreateActaControllerTest {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.generateEvent();
    }

    @isTest
    static void createActa() {
        List<Event> eventList = new List<Event>([SELECT Id FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            Id actaId = CreateActaController.createActa(queryEvent.Id);
            Test.stopTest();

            List<Event> eventListPost = new List<Event>([SELECT Id, Acta__c FROM Event WHERE Id = :queryEvent.Id LIMIT 1]);
 
            System.assertEquals(actaId, eventListPost.get(0).Acta__c, 'Deben tener el mismo id de acta');
        }
    }

    @isTest
    static void createActa_KO() {
        List<Event> eventList = new List<Event>([SELECT Id FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            Event queryEvent = eventList.get(0);
            Test.startTest();
            Id actaId = CreateActaController.createActa(queryEvent.Id);
            try {
               CreateActaController.createActa(queryEvent.Id); // creo el segundo acta donde saltará la excepcion
            } catch (Exception e) {
                System.debug('Excepcion capturada ');
            } 
            
            Test.stopTest();

            List<Acta__c> actaList = new List<Acta__c>([SELECT Id FROM Acta__c ]);
 
            System.assertEquals(1, actaList.size(), 'Deben tener el mismo id de acta');
        }
    }
}
