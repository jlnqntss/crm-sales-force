/**
 * Clase para generar los escenarios de pruebas de los test
 **
 * @author nts
 * @date 13/10/2020
 */
@isTest
public class TestDataFactory {
  /*
        Tip: Obtener elementos random

        // Get random number between 0 and 10 Apex
        Integer randomNumber = Integer.valueof((Math.random() * 10));
        System.debug('randomNumber  is'+randomNumber);

        // Get random number between 0 and 100 Apex
        Integer randomNumber = Integer.valueof((Math.random() * 100));
        System.debug('randomNumber is'+randomNumber);

        // Get random Boolean value Apex
        Integer randomNumber = Integer.valueof((math.random() * 10));
        Boolean randomBoolean = Math.mod(randomNumber,2) == 0 ? true : false;
        System.debug('randomBoolean is'+randomBoolean);

        // Get random String from list of strings Apex
        List<String> availableValues = new List<String>{'Red','Green','Blue','White','Black'};
        Integer listSize = availableValues.size() - 1;
        Integer randomNumber = Integer.valueof((Math.random() * listSize));
        String randomString= availableValues[randomNumber];
        System.debug('randomString is'+randomString);
    */

  /**
   * Obtener estructura json del sistema de origen INFO para registros de entidad Persona
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author xsobera
   * @date 14/10/2020
   */
  public static List<Map<String, Object>> getINFOCustomerJson(
    Integer totalItems
  ) {
    return buildINFOCustomerJson(totalItems, null);
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Persona del tipo indicado
   **
   * @param Integer numero de elementos a generar
   * @param String tipo elemento a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author xsobera
   * @date 14/10/2020
   */
  public static List<Map<String, Object>> getINFOCustomerJson(
    Integer totalItems,
    String customerType
  ) {
    if (
      String.isBlank(customerType) ||
      (!customerType.equalsIgnoreCase('F') &&
      !customerType.equalsIgnoreCase('J'))
    ) {
      throw new TestException('incorrect value for customerType parameter');
    }
    return buildINFOCustomerJson(totalItems, customerType);
  }

  private static List<Map<String, Object>> buildINFOCustomerJson(
    Integer totalItems,
    String customerType
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    List<String> languages = new List<String>{
      'AL',
      'CA',
      'EN',
      'ES',
      'FR',
      'NL'
    };

    List<String> docTypes = new List<String>{
      'N',
      'R',
      'C',
      'S',
      'P',
      'E',
      'X'
    };

    List<String> personType = new List<String>{ 'F', 'J' };

    List<String> flagType = new List<String>{ 'S', 'N', null };

    List<String> letters = new List<String>{
      'X',
      'S',
      'P',
      'L',
      'A',
      'T',
      'J',
      'E',
      'B',
      'D',
      'W',
      'N',
      'V',
      'Y',
      'R',
      'Q',
      'M'
    };

    List<String> businessUnits = new List<String>{
      '000',
      '001',
      '002',
      '003',
      '004',
      '005',
      '006',
      '007',
      '008',
      '999'
    };

    List<String> commercialActivities = new List<String>{ // cno y cnae aleatorios
      '02300',
      '02310',
      '02311',
      '02312',
      '02313',
      '02314',
      '02319',
      '02320',
      '02331',
      '02332',
      '02340',
      '02341',
      '02342',
      '02343',
      '02344',
      '02349',
      '02350',
      '02351',
      '02352',
      '02360',
      '02361',
      '1139',
      '1210',
      '1220',
      '1311',
      '1312',
      '1319',
      '1320',
      '1401',
      '1402',
      '1403',
      '1404',
      '1405',
      '1406',
      '1409',
      '1510',
      '1520'
    };

    List<Integer> years = new List<Integer>{
      1980,
      1981,
      1982,
      1983,
      1984,
      1985,
      1986,
      1987,
      1988,
      1989,
      1990,
      1991,
      1992,
      1993,
      1994,
      1995,
      1996,
      1997,
      1998,
      1999,
      2000,
      2001,
      2002,
      2003
    };
    List<Integer> months = new List<Integer>{
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    };
    List<Integer> days = new List<Integer>{
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28
    };

    Map<String, Object> jsonMap = new Map<String, Object>();
    Date auxDate;
    for (Integer i = 0; i < totalItems; i++) {
      auxDate = Date.newInstance(
        years[Integer.valueof((Math.random() * years.size() - 1))],
        months[Integer.valueof((Math.random() * months.size() - 1))],
        days[Integer.valueof((Math.random() * days.size() - 1))]
      );
      /* REGISTRO PERSONA */
      jsonElementsList.add(
        new Map<String, Object>{
          'cliente_cod_filiacion' => customerType + String.valueOf(i + 1).leftPad(9, '0'), // string
          'cliente_nombre' => 'Name_' + String.valueOf(i + 1), // string
          'cliente_apellido1' => 'Surname_1_' + String.valueOf(i + 1), // string
          'cliente_apellido2' => 'Surname_2_' + String.valueOf(i + 1), // string
          'cliente_nif_tipo' => docTypes[
            Integer.valueof((Math.random() * docTypes.size() - 1)) // String -> N, R, C, S (9 digitos)  P, E, X (12 digitos)
          ],
          'cliente_id_fiscal_codigo' => String.valueOf(
            Integer.valueof((Math.random() * 99999999))
          ) + letters[Integer.valueof((Math.random() * letters.size() - 1))], // String -> de 9 a 12 digitos
          'cliente_clase_persona' => String.isNotBlank(customerType)
            ? customerType
            : personType[
                Integer.valueof((Math.random() * personType.size() - 1)) // String -> 'F' o 'J'
              ],
          'cliente_valor' => String.valueOf(
            Integer.valueof((Math.random() * 6)) + 1
          ), // String -> valor cliente de 1 al 7
          'cliente_fecha_nac' => String.valueOf(auxDate.year()) +
          '-' +
          String.valueOf(auxDate.month()).leftPad(2, '0') +
          '-' +
          String.valueOf(auxDate.day()).leftPad(2, '0'), // Fecha nacimiento o constitución -> 'YYYY-MM-DD'
          'cliente_idioma' => languages[
            Integer.valueof((Math.random() * languages.size() - 1)) // Idioma correspondencia
          ],
          'cliente_entidad_legal' => businessUnits[
            Integer.valueof((Math.random() * businessUnits.size() - 1)) // Entidad Legal
          ],
          'cliente_codigo_cnae_cno' => commercialActivities[
            Integer.valueof((Math.random() * commercialActivities.size() - 1)) // cno o cnae
          ],
          'cliente_restringido' => flagType[
            Integer.valueof((Math.random() * flagType.size() - 1)) // checkbox -> 'S': true, sino false
          ],
          'cliente_morosidad' => flagType[
            Integer.valueof((Math.random() * flagType.size() - 1)) // checkbox -> 'S': true, sino false
          ],
          'cliente_registro_mizurich' => flagType[
            Integer.valueof((Math.random() * flagType.size() - 1)) // checkbox -> 'S': true, sino false
          ],
          'cliente_bloqueo_gdpr' => flagType[
            Integer.valueof((Math.random() * flagType.size() - 1)) // checkbox -> 'S': true, sino false
          ]
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Vía de contacto del tipo indicado
   **
   * @param Integer numero de elementos a generar
   * @param String tipo elemento a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 15/10/2020
   */
  public static List<Map<String, Object>> getINFOContactPointJson(
    Integer totalItems,
    String contactPointType
  ) {
    if (
      String.isBlank(contactPointType) ||
      (!contactPointType.equalsIgnoreCase('A') &&
      !contactPointType.equalsIgnoreCase('B') &&
      !contactPointType.equalsIgnoreCase('E') &&
      !contactPointType.equalsIgnoreCase('P') &&
      !contactPointType.equalsIgnoreCase('T'))
    ) {
      throw new TestException('incorrect value for contactPointType parameter');
    }
    return buildINFOCustomerJson(totalItems, contactPointType);
  }

  private static List<Map<String, Object>> buildINFOContactPointJson(
    Integer totalItems,
    String contactPointType
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    List<String> homeType = new List<String>{ 'F', 'H', 'R', 'T' };

    List<String> streetType = new List<String>{
      'CL',
      'CM',
      'CO',
      'CR',
      'CS',
      'CT',
      'CU',
      'DS',
      'ED'
    };

    List<String> flagType = new List<String>{ 'S', 'N', null };

    List<String> phoneType = new List<String>{ 'FA', 'MO', 'TL' };

    List<Integer> years = new List<Integer>{
      1980,
      1981,
      1982,
      1983,
      1984,
      1985,
      1986,
      1987,
      1988,
      1989,
      1990,
      1991,
      1992,
      1993,
      1994,
      1995,
      1996,
      1997,
      1998,
      1999,
      2000,
      2001,
      2002,
      2003
    };
    List<Integer> months = new List<Integer>{
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    };
    List<Integer> days = new List<Integer>{
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28
    };

    Map<String, Object> jsonMap = new Map<String, Object>();
    Date auxDate;

    if (
      contactPointType.equalsIgnoreCase('A') ||
      !contactPointType.equalsIgnoreCase('B') ||
      !contactPointType.equalsIgnoreCase('P')
    ) {
      for (Integer i = 0; i < totalItems; i++) {
        auxDate = Date.newInstance(
          years[Integer.valueof((Math.random() * years.size() - 1))],
          months[Integer.valueof((Math.random() * months.size() - 1))],
          days[Integer.valueof((Math.random() * days.size() - 1))]
        );

        /* REGISTRO VIA DE CONTACTO POSTAL*/
        jsonElementsList.add(
          new Map<String, Object>{
            'id_unico_via_contacto' => String.valueOf(i + 1).leftPad(10, '0'),  
            'cliente_cod_filiacion' => String.valueOf(i + 1).leftPad(10, '0'), // string
            'cod_secuencial_domicilio' => String.valueOf(i + 1),
            'tipo_domicilio' => contactPointType,
            'clase_domicilio' => homeType[
              Integer.valueof((Math.random() * homeType.size() - 1)) // clase domicilio,
            ],
            'tipo_via' => streetType[
              Integer.valueof((Math.random() * streetType.size() - 1)) // clase domicilio,,
            ],
            'descripcion_dom' => 'Street_' + String.valueOf(i + 1), // dirección
            'num_via' => String.valueOf(Integer.valueof((Math.random() * 6)) + 1), // número vía
            'via_info_adicional' => String.valueOf(
              Integer.valueof((Math.random() * 6)) + 1
            ),
            'poblacion' => 'City_' + String.valueOf(i + 1), // población
            'cod_poblacion_ine' => String.valueOf(
              Math.round((Math.random() * (900000000) + 100000000))
            ),
            'provincia' => 'State_' + String.valueOf(i + 1), // provincia
            'codigo_postal' => String.valueOf(
              Math.round((Math.random() * (90000) + 10000))
            ),
            'pais_codigo' => 'ESP', // país
            'indicador_domicilio_principal' => flagType[
              Integer.valueof((Math.random() * flagType.size() - 1)) // checkbox -> 'S': true, sino false,
            ],
            'tipo_comunicacion' => '',
            'numero_prefijo_pais' => '',
            'numero_tel' => '',
            'numero_extension_tel' => '',
            'fecha_alta' => String.valueOf(auxDate.year()) +
            '-' +
            String.valueOf(auxDate.month()).leftPad(2, '0') +
            '-' +
            String.valueOf(auxDate.day()).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
          }
        );
      }
    } else if (contactPointType.equalsIgnoreCase('T')) {
      for (Integer i = 0; i < totalItems; i++) {
        auxDate = Date.newInstance(
          years[Integer.valueof((Math.random() * years.size() - 1))],
          months[Integer.valueof((Math.random() * months.size() - 1))],
          days[Integer.valueof((Math.random() * days.size() - 1))]
        );

        /* REGISTRO VIA DE CONTACTO TELEFÓNICO */
        jsonElementsList.add(
          new Map<String, Object>{
            'id_unico_via_contacto' => String.valueOf(i + 1).leftPad(10, '0'),
            'cliente_cod_filiacion' => String.valueOf(i + 1).leftPad(10, '0'), // string
            'cod_secuencial_domicilio' => String.valueOf(i + 1),
            'tipo_domicilio' => contactPointType,
            'clase_domicilio' => '',
            'tipo_via' => '',
            'descripcion_dom' => '',
            'num_via' => '',
            'via_info_adicional' => '',
            'poblacion' => '',
            'cod_poblacion_ine' => '',
            'provincia' => '',
            'codigo_postal' => '',
            'pais_codigo' => '',
            'indicador_domicilio_principal' => '',
            'tipo_comunicacion' => phoneType[
              Integer.valueof((Math.random() * phoneType.size() - 1)) // checkbox -> 'S': true, sino false,,
            ],
            'numero_prefijo_pais' => String.valueOf(
              Math.round((Math.random() * (90) + 10))
            ),
            'numero_tel' => String.valueOf(
              Math.round((Math.random() * (900000000) + 100000000))
            ),
            'numero_extension_tel' => '',
            'fecha_alta' => String.valueOf(auxDate.year()) +
            '-' +
            String.valueOf(auxDate.month()).leftPad(2, '0') +
            '-' +
            String.valueOf(auxDate.day()).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
          }
        );
      }
    } else if (contactPointType.equalsIgnoreCase('E')) {
      for (Integer i = 0; i < totalItems; i++) {
        auxDate = Date.newInstance(
          years[Integer.valueof((Math.random() * years.size() - 1))],
          months[Integer.valueof((Math.random() * months.size() - 1))],
          days[Integer.valueof((Math.random() * days.size() - 1))]
        );

        /* REGISTRO VIA DE CONTACTO EMAIL*/
        jsonElementsList.add(
          new Map<String, Object>{
            'id_unico_via_contacto' => String.valueOf(i + 1).leftPad(10, '0'),
            'cliente_cod_filiacion' => String.valueOf(i + 1).leftPad(10, '0'), // string
            'cod_secuencial_domicilio' => String.valueOf(i + 1),
            'tipo_domicilio' => contactPointType,
            'clase_domicilio' => '',
            'tipo_via' => '',
            'email' => 'email' +
            String.valueOf(i + 1) +
            '@fake.com', // dirección email
            'num_via' => '',
            'via_info_adicional' => '',
            'poblacion' => '',
            'cod_poblacion_ine' => '',
            'provincia' => '',
            'codigo_postal' => '',
            'pais_codigo' => '',
            'pais_desc' => '',
            'indicador_domicilio_principal' => '',
            'tipo_comunicacion' => '',
            'numero_prefijo_pais' => '',
            'numero_tel' => '',
            'numero_extension_tel' => '',
            'fecha_alta' => String.valueOf(auxDate.year()) +
            '-' +
            String.valueOf(auxDate.month()).leftPad(2, '0') +
            '-' +
            String.valueOf(auxDate.day()).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
          }
        );
      }
    }

    return jsonElementsList;
  }

  public static List<ExternalRequest__c> generateExternalRequest(String origin, String type, Integer numRecords)
  {
    List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

    switch on type.toUpperCase() 
    {
      // Persona física
      when 'NATURAL_ACCOUNT'
      {
        for(Map<String, Object> payload : getINFOCustomerJson(numRecords, 'F'))
        {
          externalRequestList.add
          (
            new ExternalRequest__c
            (
              Origin__c = origin,
              Entity__c = 'ACCOUNT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Persona jurídica
      when 'LEGAL_ACCOUNT'
      {
        for(Map<String, Object> payload : getINFOCustomerJson(numRecords, 'J'))
        {
          externalRequestList.add
          (
            new ExternalRequest__c
            (
              Origin__c = origin,
              Entity__c = 'ACCOUNT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Vía de contacto 
      when 'CONTACT_POINT_ADDRESS'
      {
        for(Map<String, Object> payload : getINFOContactPointJson(numRecords, 'P'))
        {
          externalRequestList.add
          (
            new ExternalRequest__c
            (
              Origin__c = origin,
              Entity__c = 'CONTACT_POINT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Vía de contacto 
      when 'CONTACT_POINT_PHONE'
      {
        for(Map<String, Object> payload : getINFOContactPointJson(numRecords, 'T'))
        {
          externalRequestList.add
          (
            new ExternalRequest__c
            (
              Origin__c = origin,
              Entity__c = 'CONTACT_POINT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Vía de contacto 
      when 'CONTACT_POINT_EMAIL'
      {
        for(Map<String, Object> payload : getINFOContactPointJson(numRecords, 'E'))
        {
          externalRequestList.add
          (
            new ExternalRequest__c
            (
              Origin__c = origin,
              Entity__c = 'CONTACT_POINT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
    }

      return externalRequestList;

  }

  public class TestException extends Exception {
  }
}