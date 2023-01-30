@isTest
public with sharing class TemplateActaPDFControllerTest {

    @TestSetup
    static void makeData(){
        Event e = TestDataFactory.generateEvent();
        Acta__c acta = TestDataFactory.generateActa(e);
    }

    @isTest static void testControllerExtended_download() {

        List<Event> eventList = new List<Event>([SELECT Id, Acta__r.Name, Subject FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            PageReference pageRef = Page.TemplateActaPDF;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', eventList.get(0).Id);
            ApexPages.currentPage().getParameters().put('mode', 'download');

            ApexPages.StandardController sc = new ApexPages.StandardController(eventList.get(0));
            TemplateActaPDFController templateExtension = new TemplateActaPDFController(sc);
            templateExtension.getStartDate();
            templateExtension.getEndDate();
            templateExtension.getEventType();
            templateExtension.getAccionesTratadas();

            System.assertEquals('download', ApexPages.currentPage().getParameters().get('mode'), 'El modo debe ser descarga');
        }
    }

    @isTest static void testControllerExtended_preview() {

        List<Event> eventList = new List<Event>([SELECT Id, Acta__r.Name, Subject FROM Event LIMIT 1]);

        if (!eventList.isEmpty()) {
            PageReference pageRef = Page.TemplateActaPDF;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', eventList.get(0).Id);
            ApexPages.currentPage().getParameters().put('mode', '');

            ApexPages.StandardController sc = new ApexPages.StandardController(eventList.get(0));
            TemplateActaPDFController templateExtension = new TemplateActaPDFController(sc);

            System.assertEquals('', ApexPages.currentPage().getParameters().get('mode'), 'El modo debe estar vacio');
        }
    }
    
}