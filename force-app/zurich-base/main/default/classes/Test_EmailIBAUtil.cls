/**
 * Clases de test para EmailIBAUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */

@isTest(SeeAllData = false)
public with sharing class Test_EmailIBAUtil
{
    /* //Descartado en fase de implementación
       @testSetup
       static void makeData() {

          Contact customer = new Contact(Email='edu@test.com',Birthdate=Date.valueOf('1990-01-01'),FirstName='Edu',LastName='Sanchez',
                                  CustomerNum__c='GI-3123', LegalEntity__c='GI', RecordTypeId=SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI));
          insert customer;
       }


       @IsTest
       static void test_createEmail()
       {
          EmailsIBA__c email=new EmailsIBA__c(SendDate__c=Date.valueOf('2020-01-02'),Subject__c='Test email',
                                                                  CustomerNum__c='3123', LegalEntity__c='GI'  );


          Map<String, Contact> mapContacts = new Map<String, Contact>();
          mapContacts=SystemUtil.ContactsSelector();
          List <EmailsIBA__c> emailsToInsert=new List <EmailsIBA__c>();


          Test.startTest();

          EmailIBAUtil.insertEmailIBA(email, mapContacts, emailsToInsert);
          System.assert(emailsToInsert!=null, 'Test_EmailIBAUtil: Error al crear email IBA');

          Test.stopTest();

       }


       @IsTest
       static void test_ErrorNoCustomer()
       {
          EmailsIBA__c email=new EmailsIBA__c(SendDate__c=Date.valueOf('2020-01-02'),Subject__c='Test email',
                                                                  CustomerNum__c='11111', LegalEntity__c='GI'  );


          Map<String, Contact> mapContacts = new Map<String, Contact>();
          mapContacts=SystemUtil.ContactsSelector();
          List <EmailsIBA__c> emailsToInsert=new List <EmailsIBA__c>();

          Test.startTest();

          try{
              EmailIBAUtil.insertEmailIBA(email, mapContacts, emailsToInsert);

          }Catch(Exception e){
              system.assert(e.getMessage().contains(Label.EmailIBAError),'Test_EmailIBAUtil: Error al crear email IBA sin cliente existente' );
          }


          Test.stopTest();

       }*/
}