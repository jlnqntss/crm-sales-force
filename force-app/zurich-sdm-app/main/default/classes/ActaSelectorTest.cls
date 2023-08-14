@isTest
public with sharing class ActaSelectorTest {
    @TestSetup
    static void makeData(){
        Event e = TestDataFactory.generateEvent();
        Acta__c acta = TestDataFactory.generateActa(e);      
    }

    @isTest
    static void getDatosActaFromEvent() {

        List<Acta__c> actaList = new List<Acta__c>([SELECT Id, Name FROM Acta__c LIMIT 1]);

        if (!actaList.isEmpty()) {
            Acta__c queryActa = actaList.get(0); 
            Test.startTest();
            List<Acta__c> resultList = ActaSelector.getAccionesTratadasActa(queryActa.Id);
            Test.stopTest();
 
            System.assertEquals(queryActa.Name, resultList.get(0).Name, 'El registro acta debe tener el mismo nombre');
        }        
    }
}