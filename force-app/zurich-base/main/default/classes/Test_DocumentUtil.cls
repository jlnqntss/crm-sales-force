/**
 * Clases de test para DocumentUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */

@isTest(SeeAllData = false)
public with sharing class Test_DocumentUtil
{
    /* //Descartado en fase de implementación
       @testSetup
       static void makeData() {

          Account newMaster= new Account(Name='test',CustomerNum__c='3123');
          Account MasterRef=new Account(CustomerNum__c='3123');
          insert  newMaster;

          Order policy = new Order( EffectiveDate=Date.valueOf('1990-01-02'), CustomerNum__c='3123', PolicyNum__c='8989',Status='Sync',
                                   PolicyContractStartDate__c=Date.valueOf('2020-05-02'),LegalEntity__c='GI',
                                   RecordTypeId=SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI));
          policy.Account=MasterRef;
          insert policy;
       }


       @IsTest
       static void test_createEmail()
       {
          IBADocument__c  document=new IBADocument__c (Name='ServiceInfo.pdf', DocumentDate__c=Date.valueOf('2020-01-02'), PolicyNum__c='8989');

          Map<String, Order> mapPolicies = new Map<String, Order>();
          mapPolicies=SystemUtil.PolicySelector();
          List <IBADocument__c> documentsToInsert=new List <IBADocument__c>();

          Test.startTest();

          DocumentUtil.insertDocument(document, mapPolicies, documentsToInsert);
          System.assert(documentsToInsert!=null, 'Test_DocumentUtil: Error al creare Documento de IBA');

          Test.stopTest();

       }


       @IsTest
       static void test_ErrorNoCustomer()
       {
          IBADocument__c  document=new IBADocument__c (Name='ServiceInfo.pdf', DocumentDate__c=Date.valueOf('2020-01-02'), PolicyNum__c='1111');


          Map<String, Order> mapPolicies = new Map<String, Order>();
          mapPolicies=SystemUtil.PolicySelector();
          List <IBADocument__c> documentsToInsert=new List <IBADocument__c>();

          Test.startTest();

          try{
              DocumentUtil.insertDocument(document, mapPolicies, documentsToInsert);

          }Catch(Exception e){
              system.assert(e.getMessage().contains(Label.ErrorIBADocument),'Test_DocumentUtil: Error al crear documento IBA sin cliente existente' );
          }


          Test.stopTest();

       }*/
}