/**
 * Clases de test para Transformer usado por las clases de procesamiento de los registros
 * ExternalRequest__c del tipo {ExternalSystemName}Handler.cls y que se encargan de mapear la estructura origen
 * con los objetos Salesforce
 **
 * @author xsobera
 * @date 09/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class TransformerTest {
  @testSetup
  static void makeData() {
  }

  /**
   * Método test que válida la obtención de los metadatos necesarios por origen
   **
   * @author xsobera
   * @date 14/10/2020
   */
  @IsTest
  static void test_getSettings() {
    Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
    List<Transformer__mdt> settings = myTransformer.getSettings();

    System.debug('Metadatos: ' + JSON.serialize(settings));
    System.assertEquals(
      true,
      settings != null && !settings.isEmpty(),
      '[0] No se ha obtenido la configuración de metadatos esperada'
    );
    System.assertEquals(
      true,
      myTransformer.getOrigin().equalsIgnoreCase(Transformer.ORIGIN_NAME_INFO),
      '[1] No se ha establecido el origen adecuado'
    );
    Set<String> objectMapped = myTransformer.initRequestsMapBySettings()
      .keySet();
    System.assertEquals(
      true,
      objectMapped.contains('Account'),
      '[2] La configuración no contiene mapeo para el objeto Cuenta'
    );
    System.assertEquals(
      true,
      objectMapped.contains('Contact'),
      '[3] La configuración no contiene mapeo para el objeto Contacto'
    );

    try {
      Transformer myTransformer2 = new Transformer('BAD');
    } catch (Transformer.TransformerException ex) {
      System.assertEquals(
        'There are not established a valid origin system for the Transformer',
        ex.getMessage(),
        '[4] No se ha lanzado la excepción esperada'
      );
    }
  }

  /**
   * Método test que válida la transformación de los registros INFO de clientes en Cuentas y Contactos Salesforce
   **
   * @author xsobera
   * @date 14/10/2020
   */
  @isTest
  static void test_infoCustomerTransform() {
    List<Map<String, Object>> customersJsonItems = TestDataFactory.getINFOCustomerJson(
      10,
      'F'
    );
    List<Map<String, Object>> companiesJsonItems = TestDataFactory.getINFOCustomerJson(
      10,
      'J'
    );

    List<Account> customersAccounts = new List<Account>();
    List<Account> companiesAccounts = new List<Account>();
    List<Contact> companiesContacts = new List<Contact>();
    Account accountRecord;
    Contact contactRecord;

    // Instanciar el transformer con la configuración de INFO
    Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
    for (Integer i = 0; i < customersJsonItems.size(); i++) {
      accountRecord = (Account) myTransformer.transform(
        Transformer.OBJECT_NAME_ACCOUNT,
        customersJsonItems[i]
      );
      customersAccounts.add(accountRecord);
      System.assertEquals(
        customersJsonItems[i].get('cdfiliac'),
        accountRecord.INFOCustomerNumber__c,
        '[PersonAccount-' +
        String.valueOf(i).leftPad(2, '0') +
        '] No se ha mapeado el External ID correctamente'
      );
    }

    for (Integer i = 0; i < companiesJsonItems.size(); i++) {
      accountRecord = (Account) myTransformer.transform(
        Transformer.OBJECT_NAME_ACCOUNT,
        companiesJsonItems[i]
      );
      companiesAccounts.add(accountRecord);
      System.assertEquals(
        companiesJsonItems[i].get('cdfiliac'),
        accountRecord.INFOCustomerNumber__c,
        '[Account-' +
        String.valueOf(i).leftPad(2, '0') +
        '] No se ha mapeado el External ID correctamente'
      );

      contactRecord = (Contact) myTransformer.transform(
        Transformer.OBJECT_NAME_CONTACT,
        companiesJsonItems[i]
      );
      companiesContacts.add(contactRecord);
      System.assertEquals(
        companiesJsonItems[i].get('cdfiliac'),
        contactRecord.InfoCustomerContactNumber__c,
        '[Contact-' +
        String.valueOf(i).leftPad(2, '0') +
        '] No se ha mapeado el External ID correctamente'
      );
    }

    System.assertEquals(
      customersJsonItems.size(),
      customersAccounts.size(),
      '[0] No se ha obtenido el número de Cuentas Personales esperado'
    );
    System.assertEquals(
      companiesJsonItems.size(),
      companiesAccounts.size(),
      '[1] No se ha obtenido el número de Cuentas esperado'
    );
    System.assertEquals(
      companiesJsonItems.size(),
      companiesContacts.size(),
      '[2] No se ha obtenido el número de Contactos esperado'
    );
  }

  @IsTest
  static void test_getUnmappedValues() {
    // Test para comprobar que obtenemos un mapa con los valores que no están configurados en la metadata
    List<Map<String, Object>> customersJsonItems = TestDataFactory.getINFOCustomerJson(
      1,
      'J'
    );
    customersJsonItems[0].put('unmapped', 'test');

    // Instanciar el transformer con la configuración de INFO
    Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
    myTransformer.transform(
      Transformer.OBJECT_NAME_ACCOUNT,
      customersJsonItems[0]
    );
    Map<String, Object> unmappedValues = myTransformer.getUnmappedValues();

    System.assertEquals(
      'test',
      (String) unmappedValues.get('unmapped'),
      '[0] No se ha obtenido el mapa con los campos no mapeados'
    );
  }
}
