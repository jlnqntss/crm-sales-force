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
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10)
    );

    //Personas jurídicas
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'LEGAL_ACCOUNT', 10)
    );

    //Vías de contacto postal
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest(
        'INFO',
        'CONTACT_POINT_ADDRESS',
        10
      )
    );

    //Vías de contacto telefónico
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'CONTACT_POINT_PHONE', 10)
    );

    //Vías de contacto email
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'CONTACT_POINT_EMAIL', 10)
    );

    //Productos
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'PRODUCT', 10)
    );

    //Ofertas
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'QUOTE', 10)
    );

    //Pólizas
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'POLICY', 10)
    );

    //Objetos asegurados
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'INSURED_OBJECT', 10)
    );

    //Roles póliza
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'POLICY_RELATIONSHIP', 10)
    );

    //Roles oferta
    externalRequestList.addAll(
      TestDataFactory.generateExternalRequest('INFO', 'QUOTE_RELATIONSHIP', 10)
    );

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
  static void test_process_OK() {
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
      'No se ha generado correctamente el mapa de registros de account'
    ); // 10 cuentas de personas físicas y 10 de personas jurídicas
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Contact').size(),
      'No se ha generado correctamente el mapa de registros de contact'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('ContactPointAddress').size(),
      'No se ha generado correctamente el mapa de registros de contactPointAddress'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('ContactPointPhone').size(),
      'No se ha generado correctamente el mapa de registros de contactPointPhone'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('ContactPointEmail').size(),
      'No se ha generado correctamente el mapa de registros de contactPointEmail'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Product2').size(),
      'No se ha generado correctamente el mapa de registros de product'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Opportunity').size(),
      'No se ha generado correctamente el mapa de registros de opportunity'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Policy__c').size(),
      'No se ha generado correctamente el mapa de registros de policy'
    );
    System.assertEquals(
      10,
      INFOHandler.recordsToUpsertByObject.get('Asset').size(),
      'No se ha generado correctamente el mapa de registros de asset'
    );
    System.assertEquals(
      20,
      INFOHandler.recordsToUpsertByObject.get('Relationship__c').size(),
      'No se ha generado correctamente el mapa de registros de relationship'
    );
  }

  @isTest
  static void test_process_ERROR_NoEntity() {
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

    for (ExternalRequest__c externalRequest : externalRequestList) {
      externalRequest.Entity__c = 'TTTTTTTTTTTTTT';
    }

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    Test.stopTest();

    System.assertEquals(
      110,
      INFOHandler.externalRequestResultList.size(),
      'No se han marcado como erroneas todas las external request'
    );
  }

  @isTest
  static void test_process_ERROR_NoPayload() {
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

    for (ExternalRequest__c externalRequest : externalRequestList) {
      externalRequest.Payload__c = null;
    }

    Test.startTest();
    INFOHandler.prepare(externalRequestList);
    INFOHandler.process(externalRequestList);
    Test.stopTest();

    System.assertEquals(
      110,
      INFOHandler.externalRequestResultList.size(),
      'No se han marcado como erroneas todas las external request'
    );
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
    List<ContactPointAddress> cpaList = [SELECT Id FROM ContactPointAddress];
    List<ContactPointPhone> cppList = [SELECT Id FROM ContactPointPhone];
    List<ContactPointEmail> cpeList = [SELECT Id FROM ContactPointEmail];
    List<Product2> prodList = [SELECT Id FROM Product2];
    List<Opportunity> oppList = [SELECT Id FROM Opportunity];
    List<Policy__c> policyList = [SELECT Id FROM Policy__c];
    List<Asset> insObjList = [SELECT Id FROM Asset];
    List<Relationship__c> relaList = [SELECT Id FROM Relationship__c];

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
    System.assertEquals(
      10,
      cpaList.size(),
      'No se han insertado todos los registros de contactPointAddress'
    );
    System.assertEquals(
      10,
      cppList.size(),
      'No se han insertado todos los registros de contactPointPhone'
    );
    System.assertEquals(
      10,
      cpeList.size(),
      'No se han insertado todos los registros de contactPointEmail'
    );
    System.assertEquals(
      10,
      prodList.size(),
      'No se han insertado todos los registros de producto'
    );
    System.assertEquals(
      10,
      oppList.size(),
      'No se han insertado todos los registros de oferta'
    );
    System.assertEquals(
      10,
      policyList.size(),
      'No se han insertado todos los registros de póliza'
    );
    System.assertEquals(
      10,
      insObjList.size(),
      'No se han insertado todos los registros de objeto asegurado'
    );
    System.assertEquals(
      20,
      relaList.size(),
      'No se han insertado todos los registros de relaciones'
    );
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
    List<ContactPointAddress> cpaList = [SELECT Id FROM ContactPointAddress];
    List<ContactPointPhone> cppList = [SELECT Id FROM ContactPointPhone];
    List<ContactPointEmail> cpeList = [SELECT Id FROM ContactPointEmail];

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
    List<ExternalRequestError__c> externalRequestErrors = [
      SELECT Id
      FROM ExternalRequestError__c
      WHERE Origin__c = 'INFO'
    ];

    System.assertEquals(
      110,
      externalRequestListUpdated.size(),
      'No se han procesado todas las external request'
    );
    System.assertEquals(
      0,
      externalRequestErrors.size(),
      'Se han insertado external request erróneas en la entidad External Request Error'
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
      110,
      externalRequestListUpdated.size(),
      'No se han procesado todas las external request'
    );
  }
}
