/**
 * Clase de test para la clase INFOHandler
 **
 * @author adelgado
 * @date 15/10/2020
 */
@isTest
private class INFOHandlerTest {
  @TestSetup
  static void makeData() {
    List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

    //Personas físicas
    for (
      Map<String, Object> custJson : TestDataFactory.getINFOCustomerJson(
        10,
        'F'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CUSTOMER',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    //Personas jurídicas
    for (
      Map<String, Object> custJson : TestDataFactory.getINFOCustomerJson(
        10,
        'J'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CUSTOMER',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    //Vías de contacto postal
    for (
      Map<String, Object> custJson : TestDataFactory.getINFOContactPointJson(
        10,
        'P'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CONTACT_POINT',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    //Vías de contacto telefónico
    for (
      Map<String, Object> custJson : TestDataFactory.getINFOContactPointJson(
        10,
        'T'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CONTACT_POINT',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    //Vías de contacto email
    for (
      Map<String, Object> custJson : TestDataFactory.getINFOContactPointJson(
        10,
        'E'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CONTACT_POINT',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    insert externalRequestList;
  }

  @isTest
  static void test_prepare() {
    Set<String> objects = new Set<String>();

    for (Transformer__mdt setting : [
      SELECT SalesforceEntity__c
      FROM Transformer__mdt
      WHERE Origin__c = 'INFO'
    ]) {
      objects.add(setting.SalesforceEntity__c);
    }

    List<ExternalIdField__mdt> externalIdList = [
      SELECT SalesforceEntity__c, ExternalId__c
      FROM ExternalIdField__mdt
      WHERE Origin__c = 'INFO'
    ];
    List<ExternalRequest__c> externalRequestList = [
      SELECT Entity__c, Action__c, Payload__c, ContentFormat__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    Test.stopTest();

    System.assertEquals(
      objects.size(),
      INFOHandler.recordsToUpsertByObject.size(),
      'No se ha generado correctamente el mapa por entidades'
    );
    System.assertEquals(
      externalIdList.size(),
      INFOHandler.externalIdByObject.size(),
      'No se ha generado correctamente el mapa de identificidadores únicos por entidad'
    );
  }

  @isTest
  static void test_process() {
    List<ExternalRequest__c> externalRequestList = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    Test.stopTest();

    System.assertEquals(
      20,
      INFOHandler.recordsToUpsertByObject.get('Account').size(),
      'No se ha generado correctamente el mapa de registros de cuenta'
    ); // 10 cuentas de personas físicas y 10 de personas jurídicas
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Contact').size(),
      'No se ha generado correctamente el mapa de registros de contact'
    );
    //System.assertEquals(10, INFOHandler.recordsToUpsertByObject.get('ContactPointAddress').size(), 'No se ha generado correctamente el mapa de registros de contactPointAddress');
    //System.assertEquals(10, INFOHandler.recordsToUpsertByObject.get('ContactPointPhone').size(), 'No se ha generado correctamente el mapa de registros de contactPointPhone');
    //System.assertEquals(10, INFOHandler.recordsToUpsertByObject.get('ContactPointEmail').size(), 'No se ha generado correctamente el mapa de registros de contactPointEmail');
  }

  @isTest
  static void test_persists_OK() {
    List<ExternalRequest__c> externalRequestList = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    INFOHandler.persists(externalRequestList);
    Test.stopTest();

    List<Account> accountList = [SELECT Id FROM Account];
    List<Contact> contactList = [SELECT Id FROM Contact];
    //List<ContactPointAddress> cpaList = [SELECT Id FROM ContactPointAddress];
    //List<ContactPointPhone> cppList = [SELECT Id FROM ContactPointPhone];
    //List<ContactPointEmail> cpeList = [SELECT Id FROM ContactPointEmail];

    System.assertEquals(
      20,
      accountList.size(),
      'No se han insertado todos los registros de cuenta'
    );
    System.assertEquals(
      20,
      contactList.size(),
      'No se han insertado todos los registros de contacto'
    );
    //System.assertEquals(1, cpaList.size(), 'No se han insertado todos los registros de contactPointAddress');
    //System.assertEquals(1, cppList.size(), 'No se han insertado todos los registros de contactPointPhone');
    //System.assertEquals(1, cpeList.size(), 'No se han insertado todos los registros de contactPointEmail');
  }

  @isTest
  static void test_persists_ERROR() {
    List<ExternalRequest__c> externalRequestList = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    externalRequestList.get(0).Payload__c = null;

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    INFOHandler.persists(externalRequestList);
    Test.stopTest();

    List<Account> accountList = [SELECT Id FROM Account];
    List<Contact> contactList = [SELECT Id FROM Contact];
    //List<ContactPointAddress> cpaList = [SELECT Id FROM ContactPointAddress];
    //List<ContactPointPhone> cppList = [SELECT Id FROM ContactPointPhone];
    //List<ContactPointEmail> cpeList = [SELECT Id FROM ContactPointEmail];

    System.assertEquals(
      19,
      accountList.size(),
      'No se han insertado todos los registros de cuenta'
    );
    System.assertEquals(
      19,
      contactList.size(),
      'No se han insertado todos los registros de contacto'
    );
    //System.assertEquals(1, cpaList.size(), 'No se han insertado todos los registros de contactPointAddress');
    //System.assertEquals(1, cppList.size(), 'No se han insertado todos los registros de contactPointPhone');
    //System.assertEquals(1, cpeList.size(), 'No se han insertado todos los registros de contactPointEmail');
  }

  @isTest
  static void test_manageResult_OK() {
    List<ExternalRequest__c> externalRequestList = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    INFOHandler.persists(externalRequestList);
    INFOHandler.manageResult(null, externalRequestList);
    Test.stopTest();

    List<ExternalRequest__c> externalRequestListUpdated = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO' AND ProcessResult__c != NULL
    ];

    System.assertEquals(
      20,
      externalRequestListUpdated.size(),
      'No se han procesado todas las external request'
    );
  }

  @isTest
  static void test_manageResult_ERROR() {
    List<ExternalRequest__c> externalRequestList = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO'
    ];

    externalRequestList.get(0).Payload__c = null;

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    INFOHandler.persists(externalRequestList);
    INFOHandler.manageResult(null, externalRequestList);
    Test.stopTest();

    List<ExternalRequest__c> externalRequestListUpdated = [
      SELECT
        Entity__c,
        Action__c,
        Payload__c,
        ContentFormat__c,
        NumRetry__c,
        Origin__c
      FROM ExternalRequest__c
      WHERE Origin__c = 'INFO' AND ProcessResult__c != NULL
    ];

    System.assertEquals(
      20,
      externalRequestListUpdated.size(),
      'No se han procesado todas las external request'
    );
  }
}
