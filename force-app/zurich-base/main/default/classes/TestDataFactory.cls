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
          'cliente_cod_filiacion' => customerType +
          String.valueOf(i + 1).leftPad(9, '0'), // string
          'cliente_nombre' => 'Name_' + String.valueOf(i + 1), // string
          'cliente_apellido1' => 'Surname_1_' + String.valueOf(i + 1), // string
          'cliente_apellido2' => 'Surname_2_' + String.valueOf(i + 1), // string
          'cliente_nif_tipo' => docTypes[
            Integer.valueof((Math.random() * docTypes.size() - 1)) // String -> N, R, C, S (9 digitos)  P, E, X (12 digitos)
          ],
          'cliente_id_fiscal_codigo' => String.valueOf(
            Integer.valueof((Math.random() * 99999999))
          ) + letters[Integer.valueof((Math.random() * letters.size() - 1))], // String -> de 9 a 12 digitos
          'cliente_tipo_persona' => String.isNotBlank(customerType)
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
    return buildINFOContactPointJson(totalItems, contactPointType);
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

    Date auxDate;

    if (
      contactPointType.equalsIgnoreCase('A') ||
      contactPointType.equalsIgnoreCase('B') ||
      contactPointType.equalsIgnoreCase('P')
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
            'id_unico_via_contacto' => contactPointType +
            String.valueOf(i + 1).leftPad(10, '0'),
            'cliente_cod_filiacion' => 'F' +
            String.valueOf(i + 1).leftPad(9, '0'), // string
            'cod_secuencial_domicilio' => String.valueOf(i + 1),
            'tipo_domicilio' => contactPointType,
            'clase_domicilio' => homeType[
              Integer.valueof((Math.random() * homeType.size() - 1)) // clase domicilio,
            ],
            'tipo_via' => streetType[
              Integer.valueof((Math.random() * streetType.size() - 1)) // clase domicilio,,
            ],
            'descripcion_dom' => 'Street_' + String.valueOf(i + 1), // dirección
            'num_via' => String.valueOf(
              Integer.valueof((Math.random() * 6)) + 1
            ), // número vía
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
            'id_unico_via_contacto' => contactPointType +
            String.valueOf(i + 1).leftPad(10, '0'),
            'cliente_cod_filiacion' => 'F' +
            String.valueOf(i + 1).leftPad(9, '0'), // string
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
            'id_unico_via_contacto' => contactPointType +
            String.valueOf(i + 1).leftPad(10, '0'),
            'cliente_cod_filiacion' => 'F' +
            String.valueOf(i + 1).leftPad(9, '0'), // string
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

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Producto
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<Map<String, Object>> getINFOProductJson(
    Integer totalItems
  ) {
    return buildINFOProductJson(totalItems);
  }

  private static List<Map<String, Object>> buildINFOProductJson(
    Integer totalItems
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    for (Integer i = 0; i < totalItems; i++) {
      /* REGISTRO PRODUCTO*/
      jsonElementsList.add(
        new Map<String, Object>{
          'producto' => String.valueOf(i + 1).leftPad(9, '0'),
          'producto_tecnico' => String.valueOf(i + 1).leftPad(9, '0'),
          'producto_comercial' => String.valueOf(i + 1).leftPad(9, '0'),
          'producto_nombre' => 'Product' + i,
          'producto_descripción' => 'Product' + i,
          'producto_estado' => true
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Póliza
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<Map<String, Object>> getINFOPolicyJson(
    Integer totalItems
  ) {
    return buildINFOPolicyJson(totalItems);
  }

  private static List<Map<String, Object>> buildINFOPolicyJson(
    Integer totalItems
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<String> movementTypes = new List<String>{
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'K',
      'L',
      'M',
      'N',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9'
    };

    List<String> movementReasons = new List<String>{
      'A101',
      'A102',
      'A104',
      'A105',
      'A106',
      'A109',
      'A114',
      'A115',
      'A165',
      'A166',
      'A203',
      'A204'
    };

    List<String> paymentTypes = new List<String>{
      'A',
      'B',
      'C',
      'E',
      'F',
      'M',
      'P',
      'S',
      'T',
      'U',
      'Z'
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

    List<String> status = new List<String>{
      'A',
      'P',
      'S',
      'V',
      '0',
      '1',
      '2',
      '3',
      '4'
    };

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    for (Integer i = 0; i < totalItems; i++) {
      /* REGISTRO PÓLIZA*/
      jsonElementsList.add(
        new Map<String, Object>{
          'poliza_id' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_version' => '01',
          'poliza_movimiento' => movementTypes[
            Integer.valueof((Math.random() * movementTypes.size() - 1))
          ],
          'poliza_movimiento_desc' => 'Test',
          'poliza_motivo_movimiento' => movementReasons[
            Integer.valueof((Math.random() * movementReasons.size() - 1))
          ],
          'poliza_motivo_movimiento_desc' => 'Test',
          'poliza_fecha_inicio' => '',
          'poliza_entidad_legal' => businessUnits[
            Integer.valueof((Math.random() * businessUnits.size() - 1))
          ],
          'poliza_entidad_legal_desc' => 'Test',
          'cliente_cod_filiacion' => 'F' +
          String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_producto' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_producto_tecnico' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_producto_comercial' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_estado' => status[
            Integer.valueof((Math.random() * status.size() - 1))
          ],
          'poliza_estado_desc' => 'Test',
          'poliza_estructura' => 'Test',
          'poliza_negocio' => 'Test',
          'poliza_negocio_desc' => 'Test',
          'poliza_mediador' => '',
          'poliza_fecha_vencimiento' => '',
          'poliza_procedencia_oferta' => '',
          'poliza_forma_pago' => paymentTypes[
            Integer.valueof((Math.random() * paymentTypes.size() - 1))
          ],
          'poliza_forma_pago_desc' => 'Test'
          /*'prima_tecnica' => String.valueOf(Integer.valueof((Math.random() * 6))),
          'prima_suma_recargos_descuentos' => String.valueOf(Integer.valueof((Math.random() * 6))),
          'prima_suma_bonus_malus' => String.valueOf(Integer.valueof((Math.random() * 6))),
          'prima_suma_impuestos' => String.valueOf(Integer.valueof((Math.random() * 6))),
          'prima_total' => String.valueOf(Integer.valueof((Math.random() * 6)))*/
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Objeto Asegurado
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<Map<String, Object>> getINFOInsuredObjectJson(
    Integer totalItems
  ) {
    return buildINFOInsuredObjecttJson(totalItems);
  }

  private static List<Map<String, Object>> buildINFOInsuredObjecttJson(
    Integer totalItems
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<String> objectTypes = new List<String>{
      'Address',
      'Motor',
      'Person',
      'Mobile',
      'Boat',
      'Electronic Device'
    };

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    for (Integer i = 0; i < totalItems; i++) {
      /* REGISTRO OBJETO ASEGURADO*/
      jsonElementsList.add(
        new Map<String, Object>{
          'id_unico_riesgo_asegurado' => String.valueOf(i + 1).leftPad(9, '0'),
          'oferta_id' => '',
          'poliza_id' => '',
          'objeto_tipo' => objectTypes[
            Integer.valueof((Math.random() * objectTypes.size() - 1))
          ],
          'objeto_secuencia' => '',
          'vehiculo_marca' => 'Test',
          'vehiculo_modelo' => 'Test',
          'vehiculo_matricula' => 'Test',
          'tipo_via' => 'Test',
          'tipo_via_desc' => 'Test',
          'descripcion_dom' => 'Test',
          'num_via' => 'Test',
          'via_info_adicional' => 'Test',
          'poblacion' => 'Test',
          'asegurado_nombre' => 'Test',
          'asegurado_apellido_1' => 'Test',
          'asegurado_apellido_2' => 'Test',
          'asegurado_fecha_nacimiento' => '',
          'embarcacion_nombre' => 'Test',
          'embarcacion_matricula' => 'Test',
          'movil_marca' => 'Test',
          'movil_modelo' => 'Test',
          'equipo_electronico_actividad' => 'Test',
          'equipo_electronico_actividad_desc' => 'Test'
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Relación Póliza
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<Map<String, Object>> getINFOPolicyRelationshipJson(
    Integer totalItems
  ) {
    return buildINFOPolicyRelationshipJson(totalItems);
  }

  private static List<Map<String, Object>> buildINFOPolicyRelationshipJson(
    Integer totalItems
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

    List<String> roles = new List<String>{
      'ABG',
      'ABU',
      'ALL',
      'ASC',
      'ASE',
      'ASG',
      'ASR',
      'BEN',
      'BER',
      'BRK',
      'CAI',
      'CAS',
      'CAV',
      'CCN',
      'CCO',
      'CCR',
      'CID',
      'CLG'
    };

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    for (Integer i = 0; i < totalItems; i++) {
      /* REGISTRO RELACIÓN PÓLIZA*/
      jsonElementsList.add(
        new Map<String, Object>{
          'id_unico_rol_poliza' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_id' => String.valueOf(i + 1).leftPad(9, '0'),
          'poliza_rol' => roles[
            Integer.valueof((Math.random() * roles.size() - 1))
          ],
          'poliza_rol_desc' => 'Test',
          'cliente_cod_filiacion' => 'F' + String.valueOf(i + 1).leftPad(9, '0')
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Obtener estructura json del sistema de origen INFO para registros
   * de entidad Oferta
   **
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<Map<String, Object>> getINFOQuoteJson(Integer totalItems) {
    return buildINFOQuoteJson(totalItems);
  }

  private static List<Map<String, Object>> buildINFOQuoteJson(
    Integer totalItems
  ) {
    if (totalItems == null || totalItems < 1) {
      throw new TestException('totalItems must be equal or greater than 1');
    }

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

    List<Map<String, Object>> jsonElementsList = new List<Map<String, Object>>();

    for (Integer i = 0; i < totalItems; i++) {
      /* REGISTRO OFERTA*/
      jsonElementsList.add(
        new Map<String, Object>{
          'oferta_id' => String.valueOf(i + 1).leftPad(9, '0'),
          'oferta_fecha_creacion' => Date.today(),
          'oferta_fecha_validez' => Date.today(),
          'oferta_fecha_efecto' => Date.today(),
          'oferta_entidad_legal' => businessUnits[
            Integer.valueof((Math.random() * businessUnits.size() - 1))
          ],
          'oferta_entidad_legal_desc' => 'Test',
          'cliente_cod_filiacion' => 'F' +
          String.valueOf(i + 1).leftPad(9, '0'),
          'oferta_producto' => String.valueOf(i + 1).leftPad(9, '0'),
          'oferta_producto_tecnico' => 'Test',
          'oferta_producto_comercial' => 'Test',
          'oferta_estado' => 'Test',
          'oferta_estado_desc' => 'Test',
          'oferta_estructura' => 'Test',
          'oferta_negocio' => 'Test',
          'oferta_negocio_desc' => 'Test',
          'oferta_mediador' => '',
          'oferta_fecha_vencimiento' => '',
          'oferta_forma_pago' => '',
          'oferta_forma_pago_desc' => ''
        }
      );
    }

    return jsonElementsList;
  }

  /**
   * Generar registros de ExternalRequest__c a partir de los JSON de prueba
   **
   * @param String Origen
   * @param String Tipo de registro
   * @param Integer numero de elementos a generar
   * @return List<Map<String, Object>> listado de elementos simulando json
   * @author adelgado
   * @date 23/10/2020
   */
  public static List<ExternalRequest__c> generateExternalRequest(
    String origin,
    String type,
    Integer numRecords
  ) {
    List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

    switch on type.toUpperCase() {
      // Persona física
      when 'NATURAL_ACCOUNT' {
        for (
          Map<String, Object> payload : getINFOCustomerJson(numRecords, 'F')
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
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
      when 'LEGAL_ACCOUNT' {
        for (
          Map<String, Object> payload : getINFOCustomerJson(numRecords, 'J')
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
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
      when 'CONTACT_POINT_ADDRESS' {
        for (
          Map<String, Object> payload : getINFOContactPointJson(numRecords, 'P')
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
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
      when 'CONTACT_POINT_PHONE' {
        for (
          Map<String, Object> payload : getINFOContactPointJson(numRecords, 'T')
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
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
      when 'CONTACT_POINT_EMAIL' {
        for (
          Map<String, Object> payload : getINFOContactPointJson(numRecords, 'E')
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'CONTACT_POINT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Producto
      when 'PRODUCT' {
        for (Map<String, Object> payload : getINFOProductJson(numRecords)) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'PRODUCT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Oferta
      when 'QUOTE' {
        for (Map<String, Object> payload : getINFOQuoteJson(numRecords)) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'QUOTE',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Póliza
      when 'POLICY' {
        for (Map<String, Object> payload : getINFOPolicyJson(numRecords)) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'POLICY',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Objeto asegurado
      when 'INSURED_OBJECT' {
        for (
          Map<String, Object> payload : getINFOInsuredObjectJson(numRecords)
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'INSURED_OBJECT',
              Action__c = 'UPSERT',
              Payload__c = JSON.serialize(payload),
              ContentFormat__c = 'JSON'
            )
          );
        }
      }
      // Rol póliza
      when 'POLICY_RELATIONSHIP' {
        for (
          Map<String, Object> payload : getINFOPolicyRelationshipJson(
            numRecords
          )
        ) {
          externalRequestList.add(
            new ExternalRequest__c(
              Origin__c = origin,
              Entity__c = 'POLICY_RELATIONSHIP',
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
