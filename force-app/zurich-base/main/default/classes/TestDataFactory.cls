/**
 * Clase para generar los escenarios de pruebas de los test
 **
 * @author nts
 * @date 13/10/2020
 */
@isTest
public class TestDataFactory
{
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
    public static List<Map<String, Object> > getINFOCustomerJson(Integer totalItems)
    {
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
    public static List<Map<String, Object> > getINFOCustomerJson(Integer totalItems, String customerType)
    {
        if (
            String.isBlank(customerType) ||
            (!customerType.equalsIgnoreCase('F') &&
             !customerType.equalsIgnoreCase('J') )
            )
        {
            throw new TestException('incorrect value for customerType parameter');
        }
        return buildINFOCustomerJson(totalItems, customerType);
    }

    private static List<Map<String, Object> > buildINFOCustomerJson(Integer totalItems, String customerType)
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        List<String> languages = new List<String> {
            'AL',
            'CA',
            'EN',
            'ES',
            'FR',
            'NL'
        };

        List<String> docTypes = new List<String> {
            'N',
            'R',
            'C',
            'S',
            'P',
            'E',
            'X'
        };

        List<String> personType = new List<String> { 'F', 'J' };

        List<String> flagType = new List<String> { 'S', 'N', null };

        List<String> letters = new List<String> {
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

        List<String> businessUnits = new List<String> {
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

        List<String> commercialActivities = new List<String> { // cno y cnae aleatorios
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

        List<Integer> years = new List<Integer> {
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
        List<Integer> months = new List<Integer> {
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
        List<Integer> days = new List<Integer> {
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
        for (Integer i = 0; i < totalItems; i++)
        {
            auxDate = Date.newInstance(
                years[Integer.valueof( (Math.random() * years.size() - 1) )],
                months[Integer.valueof( (Math.random() * months.size() - 1) )],
                days[Integer.valueof( (Math.random() * days.size() - 1) )]
                );
            /* REGISTRO PERSONA */
            jsonElementsList.add(
                new Map<String, Object> {
                'cliente_cod_filiacion' => customerType +
                                          String.valueOf(i + 1).leftPad(9, '0'), // string
                'cliente_nombre' => 'Name_' + String.valueOf(i + 1), // string
                'cliente_apellido1' => 'Surname_1_' + String.valueOf(i + 1), // string
                'cliente_apellido2' => 'Surname_2_' + String.valueOf(i + 1), // string
                'cliente_nif_tipo' => docTypes[
                    Integer.valueof( (Math.random() * docTypes.size() - 1) ) // String -> N, R, C, S (9 digitos)  P, E, X (12 digitos)
                                     ],
                'cliente_id_fiscal_codigo' => String.valueOf(
                    Integer.valueof( (Math.random() * 99999999) )
                    ) + letters[Integer.valueof( (Math.random() * letters.size() - 1) )], // String -> de 9 a 12 digitos
                'cliente_tipo_persona' => String.isNotBlank(customerType)
                                         ? customerType
                                         : personType[
                    Integer.valueof( (Math.random() * personType.size() - 1) ) // String -> 'F' o 'J'
                                         ],
                'cliente_valor' => String.valueOf(
                    Integer.valueof( (Math.random() * 6) ) + 1
                    ), // String -> valor cliente de 1 al 7
                'cliente_fecha_nac' => String.valueOf(auxDate.year() ) +
                                      '-' +
                                      String.valueOf(auxDate.month() ).leftPad(2, '0') +
                                      '-' +
                                      String.valueOf(auxDate.day() ).leftPad(2, '0'), // Fecha nacimiento o constitución -> 'YYYY-MM-DD'
                'cliente_idioma' => languages[
                    Integer.valueof( (Math.random() * languages.size() - 1) ) // Idioma correspondencia
                                   ],
                'cliente_entidad_legal' => businessUnits[
                    Integer.valueof( (Math.random() * businessUnits.size() - 1) ) // Entidad Legal
                                          ],
                'cliente_codigo_cnae_cno' => commercialActivities[
                    Integer.valueof( (Math.random() * commercialActivities.size() - 1) ) // cno o cnae
                                            ],
                'cliente_restringido' => flagType[
                    Integer.valueof( (Math.random() * flagType.size() - 1) ) // checkbox -> 'S': true, sino false
                                        ],
                'cliente_morosidad' => flagType[
                    Integer.valueof( (Math.random() * flagType.size() - 1) ) // checkbox -> 'S': true, sino false
                                      ],
                'cliente_registro_mizurich' => flagType[
                    Integer.valueof( (Math.random() * flagType.size() - 1) ) // checkbox -> 'S': true, sino false
                                              ],
                'cliente_bloqueo_gdpr' => flagType[
                    Integer.valueof( (Math.random() * flagType.size() - 1) ) // checkbox -> 'S': true, sino false
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
    public static List<Map<String, Object> > getINFOContactPointJson(
        Integer totalItems,
        String contactPointType
        )
    {
        if (
            String.isBlank(contactPointType) ||
            (!contactPointType.equalsIgnoreCase('A') &&
             !contactPointType.equalsIgnoreCase('B') &&
             !contactPointType.equalsIgnoreCase('E') &&
             !contactPointType.equalsIgnoreCase('P') &&
             !contactPointType.equalsIgnoreCase('T') )
            )
        {
            throw new TestException('incorrect value for contactPointType parameter');
        }
        return buildINFOContactPointJson(totalItems, contactPointType);
    }

    private static List<Map<String, Object> > buildINFOContactPointJson(
        Integer totalItems,
        String contactPointType
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        Schema.DescribeFieldResult homeTypeFieldResult = ContactPointAddress.HomeType__c.getDescribe();
        List<Schema.PicklistEntry> homeTypeValues = homeTypeFieldResult.getPicklistValues();

        Schema.DescribeFieldResult streetTypeFieldResult = ContactPointAddress.StreetType__c.getDescribe();
		List<Schema.PicklistEntry> streetTypeValues = streetTypeFieldResult.getPicklistValues();

        List<String> flagType = new List<String> { 'S', 'N', null };

        List<Integer> years = new List<Integer> {
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
        List<Integer> months = new List<Integer> {
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
        List<Integer> days = new List<Integer> {
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
            )
        {
            for (Integer i = 0; i < totalItems; i++)
            {
                auxDate = Date.newInstance(
                    years[Integer.valueof( (Math.random() * years.size() - 1) )],
                    months[Integer.valueof( (Math.random() * months.size() - 1) )],
                    days[Integer.valueof( (Math.random() * days.size() - 1) )]
                    );

                /* REGISTRO VIA DE CONTACTO POSTAL*/
                jsonElementsList.add(
                    new Map<String, Object> {
                    'id_unico_via_contacto' => contactPointType +
                                              String.valueOf(i + 1).leftPad(10, '0'),
                    'cliente_cod_filiacion' => 'F' +
                                              String.valueOf(i + 1).leftPad(9, '0'), // string
                    'cod_secuencial_domicilio' => String.valueOf(i + 1),
                    'tipo_domicilio' => contactPointType,
                    'clase_domicilio' => homeTypeValues[
                        Integer.valueof( (Math.random() * homeTypeValues.size() - 1) ) // clase domicilio,
                                        ].getValue(),
                    'tipo_via' => streetTypeValues[
                        Integer.valueof( (Math.random() * streetTypeValues.size() - 1) ) // clase domicilio,,
                                 ].getValue(),
                    'descripcion_dom' => 'Street_' + String.valueOf(i + 1), // dirección
                    'num_via' => String.valueOf(
                        Integer.valueof( (Math.random() * 6) ) + 1
                        ), // número vía
                    'via_info_adicional' => String.valueOf(
                        Integer.valueof( (Math.random() * 6) ) + 1
                        ),
                    'poblacion' => 'City_' + String.valueOf(i + 1), // población
                    'cod_poblacion_ine' => String.valueOf(
                        Math.round( (Math.random() * (900000000) + 100000000) )
                        ),
                    'provincia' => 'State_' + String.valueOf(i + 1), // provincia
                    'codigo_postal' => String.valueOf(
                        Math.round( (Math.random() * (90000) + 10000) )
                        ),
                    'pais_codigo' => 'ESP', // país
                    'indicador_domicilio_principal' => flagType[
                        Integer.valueof( (Math.random() * flagType.size() - 1) ) // checkbox -> 'S': true, sino false,
                                                      ],
                    'numero_prefijo_pais' => '',
                    'numero_tel' => '',
                    'numero_extension_tel' => '',
                    'fecha_alta' => String.valueOf(auxDate.year() ) +
                                   '-' +
                                   String.valueOf(auxDate.month() ).leftPad(2, '0') +
                                   '-' +
                                   String.valueOf(auxDate.day() ).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
                }
                    );
            }
        }
        else if (contactPointType.equalsIgnoreCase('T') )
        {
            for (Integer i = 0; i < totalItems; i++)
            {
                auxDate = Date.newInstance(
                    years[Integer.valueof( (Math.random() * years.size() - 1) )],
                    months[Integer.valueof( (Math.random() * months.size() - 1) )],
                    days[Integer.valueof( (Math.random() * days.size() - 1) )]
                    );

                /* REGISTRO VIA DE CONTACTO TELEFÓNICO */
                jsonElementsList.add(
                    new Map<String, Object> {
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
                        Math.round( (Math.random() * (90) + 10) )
                        ),
                    'numero_tel' => String.valueOf(
                        Math.round( (Math.random() * (900000000) + 100000000) )
                        ),
                    'numero_extension_tel' => '',
                    'fecha_alta' => String.valueOf(auxDate.year() ) +
                                   '-' +
                                   String.valueOf(auxDate.month() ).leftPad(2, '0') +
                                   '-' +
                                   String.valueOf(auxDate.day() ).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
                }
                    );
            }
        }
        else if (contactPointType.equalsIgnoreCase('E') )
        {
            for (Integer i = 0; i < totalItems; i++)
            {
                auxDate = Date.newInstance(
                    years[Integer.valueof( (Math.random() * years.size() - 1) )],
                    months[Integer.valueof( (Math.random() * months.size() - 1) )],
                    days[Integer.valueof( (Math.random() * days.size() - 1) )]
                    );

                /* REGISTRO VIA DE CONTACTO EMAIL*/
                jsonElementsList.add(
                    new Map<String, Object> {
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
                    'fecha_alta' => String.valueOf(auxDate.year() ) +
                                   '-' +
                                   String.valueOf(auxDate.month() ).leftPad(2, '0') +
                                   '-' +
                                   String.valueOf(auxDate.day() ).leftPad(2, '0') // Fecha alta registro -> 'YYYY-MM-DD'
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
    public static List<Map<String, Object> > getINFOProductJson(
        Integer totalItems
        )
    {
        return buildINFOProductJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOProductJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO PRODUCTO*/
            jsonElementsList.add(
                new Map<String, Object> {
                'producto' => String.valueOf(i + 1).leftPad(9, '0'),
                'producto_tecnico' => String.valueOf(i + 1).leftPad(9, '0'),
                'producto_comercial' => String.valueOf(i + 1).leftPad(9, '0'),
                'producto_nombre' => 'Product' + i,
                'producto_descripción' => 'Product' + i,
                'producto_estado' => 'S'
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
    public static List<Map<String, Object> > getINFOPolicyJson(
        Integer totalItems
        )
    {
        return buildINFOPolicyJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOPolicyJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult movTypeFieldResult = Policy__c.MovementType__c.getDescribe();
		List<Schema.PicklistEntry> movTypeValues = movTypeFieldResult.getPicklistValues();

        Schema.DescribeFieldResult movReasonFieldResult = Policy__c.MovementReason__c.getDescribe();
		List<Schema.PicklistEntry> movReasonValues = movReasonFieldResult.getPicklistValues();

        Schema.DescribeFieldResult paymentTypeFieldResult = Policy__c.PaymentType__c.getDescribe();
		List<Schema.PicklistEntry> paymentTypeValues = paymentTypeFieldResult.getPicklistValues();

        Schema.DescribeFieldResult statusFieldResult = Policy__c.PolicyStatus__c.getDescribe();
        List<Schema.PicklistEntry> statusValues = statusFieldResult.getPicklistValues();

        Schema.DescribeFieldResult legalEntityFieldResult = Policy__c.LegalEntity__c.getDescribe();
		List<Schema.PicklistEntry> legalEntityValues = legalEntityFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO PÓLIZA*/
            jsonElementsList.add(
                new Map<String, Object> {
                'poliza_id' => String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_version' => '01',
                'poliza_movimiento' => movTypeValues[
                    Integer.valueof( (Math.random() * movTypeValues.size() - 1) )
                                      ].getValue(),
                'poliza_movimiento_desc' => 'Test',
                'poliza_motivo_movimiento' => movReasonValues[
                    Integer.valueof( (Math.random() * movReasonValues.size() - 1) )
                                             ].getValue(),
                'poliza_motivo_movimiento_desc' => 'Test',
                'poliza_fecha_inicio' => '',
                'poliza_entidad_legal' => legalEntityValues[
                    Integer.valueof( (Math.random() * legalEntityValues.size() - 1) )
                                         ].getValue(),
                'poliza_entidad_legal_desc' => 'Test',
                'cliente_cod_filiacion' => 'F' +
                                          String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_producto' => String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_producto_tecnico' => String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_producto_comercial' => String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_estado' => statusValues[
                    Integer.valueof( (Math.random() * statusValues.size() - 1) )
                                  ].getValue(),
                'poliza_estado_desc' => 'Test',
                'poliza_estructura' => 'Test',
                'poliza_negocio' => 'Test',
                'poliza_negocio_desc' => 'Test',
                'poliza_mediador' => '',
                'poliza_fecha_vencimiento' => '',
                'poliza_procedencia_oferta' => '',
                'poliza_forma_pago' => paymentTypeValues[
                    Integer.valueof( (Math.random() * paymentTypeValues.size() - 1) )
                                      ].getValue(),
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
    public static List<Map<String, Object> > getINFOInsuredObjectJson(
        Integer totalItems
        )
    {
        return buildINFOInsuredObjecttJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOInsuredObjecttJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult objectTypeFieldResult = Asset.ObjectType__c.getDescribe();
		List<Schema.PicklistEntry> objectTypeValues = objectTypeFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OBJETO ASEGURADO*/
            jsonElementsList.add(
                new Map<String, Object> {
                'id_unico_riesgo_asegurado' => String.valueOf(i + 1).leftPad(9, '0'),
                'oferta_id' => '',
                'poliza_id' => '',
                'objeto_tipo' => objectTypeValues[
                    Integer.valueof( (Math.random() * objectTypeValues.size() - 1) )
                                ].getValue(),
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
     * de entidad Siniestro
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 23/10/2020
     */
    public static List<Map<String, Object> > getINFOClaimJson(
        Integer totalItems
        )
    {
        return buildINFOClaimJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOClaimJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult faultFactorFieldResult = Claim__c.FaultFactor__c.getDescribe();
		List<Schema.PicklistEntry> faultFactorValues = faultFactorFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO SINIESTRO*/
            jsonElementsList.add(
                new Map<String, Object> {
                    'siniestro_id' => String.valueOf(i + 1).leftPad(9, '0'),
                    'siniestro_fecha_ocurrencia' => '2020-11-05',
                    'siniestro_factor_culpa' => faultFactorValues[Integer.valueof( (Math.random() * faultFactorValues.size() - 1) )].getValue(),
                    'siniestro_factor_culpa_desc' => '',
                    'poliza_id' => String.valueOf(i + 1).leftPad(9, '0'),
                    'poliza_version' => '',
                    'cliente_cod_filiacion' => 'F' + String.valueOf(i + 1).leftPad(9, '0'),
                    'siniestro_situacion' => '',
                    'siniestro_situacion_desc' => '',
                    'siniestro_situacion_tecnica' => '',
                    'siniestro_situacion_tecnica_desc' => '',
                    'siniestro_motivo' => '',
                    'siniestro_motivo_desc' => '',
                    'riesgo_asegurado' => String.valueOf(i + 1).leftPad(9, '0')
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
    public static List<Map<String, Object> > getINFOPolicyRelationshipJson(
        Integer totalItems
        )
    {
        return buildINFOPolicyRelationshipJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOPolicyRelationshipJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult rolFieldResult = Relationship__c.Role__c.getDescribe();
		List<Schema.PicklistEntry> rolValues = rolFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO RELACIÓN PÓLIZA*/
            jsonElementsList.add(
                new Map<String, Object> {
                'id_unico_rol_poliza' => 'P' + String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_id' => String.valueOf(i + 1).leftPad(9, '0'),
                'poliza_rol' => rolValues[
                    Integer.valueof( (Math.random() * rolValues.size() - 1) )
                               ].getValue(),
                'poliza_rol_desc' => 'Test',
                'cliente_cod_filiacion' => 'F' + String.valueOf(i + 1).leftPad(9, '0')
            }
                );
        }

        return jsonElementsList;
    }

    /**
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Relación Oferta
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 23/10/2020
     */
    public static List<Map<String, Object> > getINFOQuoteRelationshipJson(
        Integer totalItems
        )
    {
        return buildINFOQuoteRelationshipJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOQuoteRelationshipJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult rolFieldResult = Relationship__c.Role__c.getDescribe();
		List<Schema.PicklistEntry> rolValues = rolFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO RELACIÓN OFERTA*/
            jsonElementsList.add(
                new Map<String, Object> {
                'id_unico_rol_oferta' => 'O' + String.valueOf(i + 1).leftPad(9, '0'),
                'oferta_id' => String.valueOf(i + 1).leftPad(9, '0'),
                'oferta_rol' => rolValues[
                    Integer.valueof( (Math.random() * rolValues.size() - 1) )
                               ].getValue(),
                'oferta_rol_desc' => 'Test',
                'cliente_cod_filiacion' => 'F' + String.valueOf(i + 1).leftPad(9, '0')
            }
                );
        }

        return jsonElementsList;
    }

    /**
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Relación Siniestro
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 23/10/2020
     */
    public static List<Map<String, Object> > getINFOClaimRelationshipJson(
        Integer totalItems
        )
    {
        return buildINFOClaimRelationshipJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOClaimRelationshipJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult rolFieldResult = Relationship__c.Role__c.getDescribe();
		List<Schema.PicklistEntry> rolValues = rolFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO RELACIÓN SINIESTRO*/
            jsonElementsList.add(
                new Map<String, Object> {
                'id_unico_rol_siniestro' => 'C' + String.valueOf(i + 1).leftPad(9, '0'),
                'siniestro_id' => String.valueOf(i + 1).leftPad(9, '0'),
                'siniestro_rol' => rolValues[
                    Integer.valueof( (Math.random() * rolValues.size() - 1) )
                               ].getValue(),
                'siniestro_rol_desc' => 'Test',
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
    public static List<Map<String, Object> > getINFOQuoteJson(Integer totalItems)
    {
        return buildINFOQuoteJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOQuoteJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult legalEntityFieldResult = Opportunity.LegalEntity__c.getDescribe();
		List<Schema.PicklistEntry> legalEntityValues = legalEntityFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OFERTA*/
            jsonElementsList.add(
                new Map<String, Object> {
                'oferta_id' => String.valueOf(i + 1).leftPad(9, '0'),
                'oferta_fecha_creacion' => Date.today(),
                'oferta_fecha_validez' => Date.today(),
                'oferta_fecha_efecto' => Date.today(),
                'oferta_entidad_legal' => legalEntityValues[
                    Integer.valueof( (Math.random() * legalEntityValues.size() - 1) )
                                         ].getValue(),
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
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Partner
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 09/11/2020
     */
    public static List<Map<String, Object> > getINFOPartnerJson(Integer totalItems)
    {
        return buildINFOPartnerJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOPartnerJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult statusFieldResult = Account.Status__c.getDescribe();
		List<Schema.PicklistEntry> statusValues = statusFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OFERTA*/
            jsonElementsList.add(
                new Map<String, Object> {
                    'partner_id' => 'Partner' + String.valueOf(i + 1).leftPad(3, '0'),
                    'partner_desc' => 'Partner' + i,
                    'partner_estado' => statusValues[Integer.valueof( (Math.random() * statusValues.size() - 1) )].getValue(),
                    'partner_estado_desc' => 'Test',
                    'partner_padre_id' => String.valueOf(i + 1).leftPad(9, '0'),
                    'partner_padre_desc' => 'Test',
                    'partner_estructura' => String.valueOf(i + 1).leftPad(9, '0'),
                    'partner_estructura_desc' => 'Test',
                    'partner_nombre_persona_contacto' => 'Contact' + i,
                    'partner_telefono_persona_contacto' => '123456789'
            }
                );
        }

        return jsonElementsList;
    }

    /**
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Mediador
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 09/11/2020
     */
    public static List<Map<String, Object> > getINFOIntermediaryJson(Integer totalItems)
    {
        return buildINFOIntermediaryJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOIntermediaryJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        Schema.DescribeFieldResult nationalTypeFieldResult = Account.NationalIdType__c.getDescribe();
        List<Schema.PicklistEntry> nationalTypeValues = nationalTypeFieldResult.getPicklistValues();

        Schema.DescribeFieldResult typeFieldResult = Account.Type.getDescribe();
        List<Schema.PicklistEntry> typeValues = typeFieldResult.getPicklistValues();

        Schema.DescribeFieldResult statusFieldResult = Account.Status__c.getDescribe();
		List<Schema.PicklistEntry> statusValues = statusFieldResult.getPicklistValues();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OFERTA*/
            jsonElementsList.add(
                new Map<String, Object> {
                    'mediador_id' => 'Inter' + String.valueOf(i + 1).leftPad(3, '0'),
                    'mediador_desc' => 'Test' + i,
                    'mediador_nombre' => 'Test' + i,
                    'mediador_tipo_documento' => nationalTypeValues[Integer.valueof( (Math.random() * nationalTypeValues.size() - 1) )].getValue(),
                    'mediador_nif_tipo' => 'Test',
                    'mediador_nif_tipo_desc' => 'Test',
                    'mediador_tipo' => typeValues[Integer.valueof( (Math.random() * typeValues.size() - 1) )].getValue(),
                    'mediador_tipo_desc' => 'Test',
                    'mediador_segmento_comercial' => 'Test',
                    'mediador_segmento_comercial_desc' => 'Test',
                    'mediador_codigo dsg' => 'Test',
                    'mediador_codigo_dt' => 'Test',
                    'mediador_codigo_dt_desc' => 'Test',
                    'mediador_zona' => 'Test',
                    'mediador_zona_desc' => 'Test',
                    'mediador_negocio_cod_filiacion' => '',
                    'mediador_negocio_nombre' => 'ParentBusiness' + i,
                    'mediador_tipo_estado' => statusValues[Integer.valueof( (Math.random() * statusValues.size() - 1) )].getValue(),
                    'mediador_tipo_estado_desc' => 'Test',
                    'mediador_fecha_asignacion' => '2021-10-15',
                    'mediador_domicilio' => 'Dom' + i,
                    'mediador_poblacion' => 'Pobl' + i,
                    'mediador_provincia' => 'Prov' + i,
                    'mediador_provincia_desc' => 'Intermediary' + i,
                    'mediador_email_principal' => 'testInter' + i + '@test.com',
                    'mediador_email_contratacion' => 'testInter' + i + '@test.com',
                    'mediador_email_siniestros' => 'testInter' + i + '@test.com',
                    'mediador_email_admin' => 'testInter' + i + '@test.com',
                    'mediador_telefono_principal' => '123456789',
                    'mediador_telefono_movil' => '123456789'

            }
                );
        }

        return jsonElementsList;
    }

    /**
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Opción oferta
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author adelgado
     * @date 16/11/2020
     */
    public static List<Map<String, Object> > getINFOQuoteOptionJson(Integer totalItems)
    {
        return buildINFOQuoteOptionJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFOQuoteOptionJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OFERTA*/
            jsonElementsList.add(
                new Map<String, Object> {
                    'id_unico_opcion' => String.valueOf(i + 1).leftPad(9, '0'),
                    'oferta_id' => String.valueOf(i + 1).leftPad(9, '0'),
                    'objeto_tipo' => 'Test',
                    'objeto_cod_secuencial' => 'Test',
                    'opcion' => 'Test',
                    'opcion_desc' => 'Test',
                    'opcion_seleccion' => 'Test',
                    'opcion_paquete_desc' => 'Test',
                    'importe_acumulado' => '50',
                    'prima_neta' => '50'
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
        )
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

        switch on type.toUpperCase()
        {
            // Persona física
            when 'NATURAL_ACCOUNT' {
                for (
                    Map<String, Object> payload : getINFOCustomerJson(numRecords, 'F')
                    )
                {
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
                for (Map<String, Object> payload : getINFOCustomerJson(numRecords, 'J') )
                {
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
                    )
                {
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
                    )
                {
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
                    )
                {
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
                for (Map<String, Object> payload : getINFOProductJson(numRecords) )
                {
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
                for (Map<String, Object> payload : getINFOQuoteJson(numRecords) )
                {
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
            // Opción oferta
            when 'QUOTE_OPTION' {
                for (Map<String, Object> payload : getINFOQuoteOptionJson(numRecords) )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'QUOTE_OPTION',
                            Action__c = 'UPSERT',
                            Payload__c = JSON.serialize(payload),
                            ContentFormat__c = 'JSON'
                            )
                        );
                }
            }
            // Póliza
            when 'POLICY' {
                for (Map<String, Object> payload : getINFOPolicyJson(numRecords) )
                {
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
                    )
                {
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
            // Siniestro
            when 'CLAIM' {
                for (
                    Map<String, Object> payload : getINFOClaimJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'CLAIM',
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
                    )
                {
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
            // Rol oferta
            when 'QUOTE_RELATIONSHIP' {
                for (
                    Map<String, Object> payload : getINFOQuoteRelationshipJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'QUOTE_RELATIONSHIP',
                            Action__c = 'UPSERT',
                            Payload__c = JSON.serialize(payload),
                            ContentFormat__c = 'JSON'
                            )
                        );
                }
            }
            // Rol siniestro
            when 'CLAIM_RELATIONSHIP' {
                for (
                    Map<String, Object> payload : getINFOClaimRelationshipJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'CLAIM_RELATIONSHIP',
                            Action__c = 'UPSERT',
                            Payload__c = JSON.serialize(payload),
                            ContentFormat__c = 'JSON'
                            )
                        );
                }
            }
            //Partner
            when 'PARTNER' {
                for (
                    Map<String, Object> payload : getINFOPartnerJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'PARTNER',
                            Action__c = 'UPSERT',
                            Payload__c = JSON.serialize(payload),
                            ContentFormat__c = 'JSON'
                            )
                        );
                }
            }
            //Mediador
            when 'INTERMEDIARY' {
                for (
                    Map<String, Object> payload : getINFOIntermediaryJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'INTERMEDIARY',
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
    
    /**
     * Genera oportunidades a partir de los campos especificados
     **
     * @param String type indica el tipo de oportunidades que se quieren crear
     * @param String stage indica la etapa de las oportunidades a crear
     * @param Date closeDate indica la fecha de cierre de la oportunidad, puede ser nulo
     * @param Integer numRecords número de elementos a generar
     * 
     * @return List<Opportunity> listado de Opportunities generadas
     * @author rlopez
     * @date 03/11/2020
     */
    public static List<Opportunity> generateOpportunities(List<Account> accounts, String type, String stage, Date closeDate, Integer numRecords)
    {
        List<Opportunity> opportunitiesGenerated = new List<Opportunity>();

        if(String.isBlank(stage))
        {
            stage = 'Qualification';
        }

        if(numRecords == null)
        {
            numRecords = 1;
        }

        switch on type.toLowerCase() {
            when 'ze' {
                for(Account relatedAccount: accounts)
                {
                    for(Integer i=0; i<numRecords; i++)
                    {
                        opportunitiesGenerated.add(
                            new Opportunity(
                                AccountId = relatedAccount.Id,
                                Name = 'Test Opportunity ' + i,
                                StageName = stage,
                                CloseDate = closeDate
                            )
                        );
                    }
                }
            }
            when else {
                for(Account relatedAccount: accounts)
                {
                    for(Integer i=0; i<numRecords; i++)
                    {
                        opportunitiesGenerated.add(
                            new Opportunity(
                                AccountId = relatedAccount.Id,
                                Name = 'Test Opportunity ' + i,
                                StageName = stage,
                                CloseDate = closeDate,
                                Scope__c = type
                            )
                        );
                    }
                }
            }
        }

        return opportunitiesGenerated;
    }

    /**
     * Genera EmailMessages huerfanos, no están relacionados con ningún registro
     **
     * @param Integer numRecords número de elementos a generar
     * 
     * @return List<EmailMessage> listado de EmailMessage generados
     * @author rlopez
     * @date 09/11/2020
     */
    public static List<EmailMessage> generateEmailMessages(Integer numRecords)
    {
        List<EmailMessage> emailMessagesGenerated = new List<EmailMessage>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Integer i=0; i<numRecords; i++)
        {
            emailMessagesGenerated.add(
                new EmailMessage(
                    Subject = 'testsubject' + i,
                    FromAddress = 'fromaddress' + i + '@nts-solutions.com.invalid',
                    ToAddress = 'toaddress' + i + '@nts-solutions.com.invalid'
                )
            );
        }

        return emailMessagesGenerated;
    }

    /**
     * Genera EmailMessage que dependen de un Email "padre"
     **
     * @param List<EmailMessage> emailMessages lista de emails para las que hay que generar un EmailMessage
     * @param Integer numRecords número de elementos a generar
     * 
     * @return List<EmailMessage> listado de EmailMessage generados
     * @author rlopez
     * @date 09/11/2020
     */
    public static List<EmailMessage> generateEmailMessagesFromEmailMessages(List<EmailMessage> emailMessages, Integer numRecords)
    {
        List<EmailMessage> emailMessagesGenerated = new List<EmailMessage>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(EmailMessage relatedEmailMessage: emailMessages)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                emailMessagesGenerated.add(
                    new EmailMessage(
                        Subject = 'inreplyto ' + relatedEmailMessage.Subject + i,
                        FromAddress = relatedEmailMessage.ToAddress,
                        ToAddress = relatedEmailMessage.FromAddress,
                        MessageIdentifier = relatedEmailMessage.Id
                    )
                );
            }
        }

        return emailMessagesGenerated;
    }

    /**
     * Genera EmailMessage relacionados con una lista de oportunidades
     **
     * @param List<Opportunity> opportunities lista de oportunidades para las que hay que generar un EmailMessage
     * @param Integer numRecords número de elementos a generar
     * 
     * @return List<EmailMessage> listado de EmailMessage generados
     * @author rlopez
     * @date 03/11/2020
     */
    public static List<EmailMessage> generateEmailMessagesFromOpportunities(List<Opportunity> opportunities, Integer numRecords)
    {
        List<EmailMessage> emailMessagesGenerated = new List<EmailMessage>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Opportunity opportunity: opportunities)
        {
            if(String.isNotBlank(opportunity.Name))
            {
                for(Integer i=0; i<numRecords; i++)
                {
                    emailMessagesGenerated.add(
                        new EmailMessage(
                            Subject = opportunity.Name,
                            RelatedToId = opportunity.Id,
                            FromAddress = 'fromaddress' + i + '@nts-solutions.com.invalid',
                            ToAddress = 'toaddress' + i + '@nts-solutions.com.invalid'
                        )
                    );
                }
            }
        }

        return emailMessagesGenerated;
    }

    /**
     * Genera EmailMessageRelation para un listado de Emails
     * (https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_emailmessagerelation.htm)
     **
     * @param List<EmailMessage> emails lista de emails para las que hay que generar un EmailMessageRelation
     * @param Id                 personId Id para la persona (user, contact or lead) que hay que generar un EmailMessageRelation
     * @param String             relationType tipo de relación a crear (ToAddress, CcAddress, BccAddress, FromAddress, OtherAddress)
     * 
     * @return List<EmailMessageRelation> listado de EmailMessageRelation generados
     * @author rlopez
     * @date 10/11/2020
     */
    public static List<EmailMessageRelation> generateEmailMessageRelations(List<EmailMessage> emails, Id personId, String relationType)
    {
        List<EmailMessageRelation> emailMessageRelationsGenerated = new List<EmailMessageRelation>();

        for(EmailMessage relationEmail: emails)
        {
            emailMessageRelationsGenerated.add(
                new EmailMessageRelation(
                    EmailMessageId = relationEmail.Id,
                    RelationId = personId,
                    RelationType = relationType
                )
            );
        }

        return emailMessageRelationsGenerated;
    }

    public class TestException extends Exception
    {}

    /**
     * Genera una lista de tareas con RecordType Interaction
     **
     * @param numTasks numero de elementos a generar
     * @return List<Task> listado de tareas de tipo Interaction
     * @author nescudero
     * @date 03/11/2020
     */
    public static List<Task> generateInteractionTasks(Integer numTasks)
    {
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numTasks; i++)
        {
            Task interaction = new Task();
            interaction.Status = 'Nueva';
            interaction.Priority = 'Normal';
            interaction.CallObject = 'ucid' + i;
            interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                       .get('Interaction')
                                       .getRecordTypeId();
            tasks.add(interaction);
        }
        return tasks;
    }

    /**
     * Genera una lista de Accounts
     **
     * @param String legalEntity indica a quien se envía el email
     * @param Integer numRecords número de elementos a generar
     * @return List<Account> listado de cuentas
     * @author rlopez
     * @date 04/11/2020
     */
    public static List<Account> generateAccounts(String legalEntity, String recordTypeName, Integer numRecords)
    {
        List<Account> accounts = new List<Account>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        Schema.RecordTypeInfo accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName);
        Id recordTypeId;
        if(accountRecordTypeInfo != null)
        {
            recordTypeId = accountRecordTypeInfo.getRecordTypeId();
        }

        switch on recordTypeName {
            when 'BusinessCustomer' {
                for (Integer i = 0; i < numRecords; i++)
                {
                    accounts.add(
                        new Account(
                            Name = 'testname' + i,
                            LegalEntity__c = legalEntity,
                            NationalId__c = generateSpanishFormatDNI(),
                            NationalIdType__c = 'N',
                            RecordTypeId = recordTypeId
                        )
                    );
                }
            }
            when else {
                for (Integer i = 0; i < numRecords; i++)
                {
                    accounts.add(
                        new Account(
                            LastName = 'testlastname' + i,
                            LegalEntity__c = legalEntity,
                            NationalId__c = generateSpanishFormatDNI(),
                            NationalIdType__c = 'N'
                        )
                    );
                }
            }
        }

        return accounts;
    }

    /**
     * Genera una lista de Accounts
     **
     * @param List<Account> accounts cuentas para las que se van a crear los contactos
     * @param String recordTypeName tipo de registro de los contactos
     * @param Integer numRecords número de contactos a generar por cada cuenta
     * @return List<Account> listado de cuentas
     * @author rlopez
     * @date 04/11/2020
     */
    public static List<Contact> generateContactsFromAccounts(List<Account> accounts, String recordTypeName, Integer numRecords)
    {
        List<Contact> contacts = new List<Contact>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        Schema.RecordTypeInfo contactRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordTypeName);
        Id recordTypeId;
        if(contactRecordTypeInfo != null)
        {
            recordTypeId = contactRecordTypeInfo.getRecordTypeId();
        }

        for(Integer i=0; i<numRecords; i++)
        {
            for(Account relatedAccount: accounts)
            {
                contacts.add(
                    new Contact(
                        LastName = 'testlastname' + i,
                        AccountId = relatedAccount.Id,
                        RecordTypeId = recordTypeId
                    )
                );
            }
        }

        return contacts;
    }

    private static String generateSpanishFormatDNI()
    {
        List<String> letters = new List<String> {
            'A',
            'B',
            'C',
            'D',
            'E',
            'F',
            'G',
            'H',
            'I',
            'J',
            'K',
            'L',
            'M',
            'N',
            'O',
            'P',
            'Q',
            'R',
            'S',
            'T',
            'U',
            'V',
            'W',
            'X',
            'Y',
            'Z'
        };

        Integer numbers = (Math.random() * 100000000).intValue();
        String letter = letters[Integer.valueof( (Math.random() * letters.size() - 1) )];
        return String.valueOf(numbers) + letter;
    }

    /**
     * Genera ContactPointPhone relacionados con una lista de accounts
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un ContactPointPhone
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<ContactPointPhone> listado de ContactPointPhones generados
     * @author rlopez
     * @date 04/11/2020
     */
    public static List<ContactPointPhone> generateContactPointPhonesFromAccounts(List<Account> accounts, Integer numRecords)
    {
        List<ContactPointPhone> contactPointPhones = new List<ContactPointPhone>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer phoneNumber = (Math.random() * 1000000000).intValue();
                contactPointPhones.add(
                    new ContactPointPhone(
                        ParentId = relatedAccount.Id,
                        TelephoneNumber = String.valueOf(phoneNumber)
                    )
                );
            }
        }

        return contactPointPhones;
    }

    /**
     * Genera ContactPointEmail relacionados con una lista de accounts
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un ContactPointEmail
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<ContactPointEmail> listado de ContactPointEmails generados
     * @author rlopez
     * @date 04/11/2020
     */
    public static List<ContactPointEmail> generateContactPointEmailsFromAccounts(List<Account> accounts, Integer numRecords)
    {
        List<ContactPointEmail> contactPointEmails = new List<ContactPointEmail>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer phoneNumber = (Math.random() * 1000000000).intValue();
                contactPointEmails.add(
                    new ContactPointEmail(
                        ParentId = relatedAccount.Id,
                        EmailAddress = relatedAccount.Name + '@nts-solutions.com'
                    )
                );
            }
        }

        return contactPointEmails;
    }

    /**
     * Genera Casos relacionados con cuentas
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA CUENTA
     *
     * @return List<Case> listado de registros generados
     * @author nescudero
     * @date 13/11/2020
     */
    public static List<Case> generateCasesForEachAccount(List<Account> accounts, Integer numRecords)
    {
        List<Case> cases = new List<Case>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                cases.add(
                    new Case(
                        OwnerId = USerInfo.getUserid(),
                        AccountId = relatedAccount.Id
                    )
                );
            }
        }

        return cases;
    }

    /**
     * Genera Casos relacionados con cuentas
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA CUENTA
     *
     * @return List<Opportunity> listado de registros generados
     * @author nescudero
     * @date 13/11/2020
     */
    public static List<Opportunity> generateOpportunitiesForEachAccount(List<Account> accounts, String scope, String stage, Date closeDate, Integer numRecords)
    {
        List<Opportunity> opportunities = new List<Opportunity>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                opportunities.add(
                    new Opportunity(
                        OwnerId = USerInfo.getUserid(),
                        AccountId = relatedAccount.Id,
                        Name = 'opp'+i,
                        StageName = stage,
                        CloseDate = closeDate,
                        Scope__c = scope
                    )
                );
            }
        }

        return opportunities;
    }

    /**
     * Genera scopes relacionados con cuentas
     * 
     * @param List<Account> accounts lista de accounts para las que hay que generar un listado de registros
     * @param String scope el valor del campo scope__c
     * @param Integer numRecords número de registros a generar POR CADA CUENTA
     *
     * @return List<Scope__c> listado de registros generados
     * @author rlopez
     * @date 20/11/2020 
     */
    public static List<Scope__c> generateScopesForEachAccount(List<Account> accounts, String scope, Integer numRecords)
    {
        List<Scope__c> scopes = new List<Scope__c>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        if(String.isBlank(scope))
        {
            scope = 'General';
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                scopes.add(
                    new Scope__c(
                        Name = scope + i,
                        Scope__c = scope,
                        AccountId__c = relatedAccount.Id
                    )
                );
            }
        }

        return scopes;
    }

    /**
     * Genera ContactPointEmail relacionados con una lista de scopes
     **
     * @param List<Scope> scopes lista de scopes para las que hay que generar un ContactPointEmail
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<ContactPointEmail> listado de ContactPointEmails generados
     * @author rlopez
     * @date 20/11/2020
     */
    public static List<ContactPointEmail> generateContactPointEmailsFromScopes(List<Scope__c> scopes, Integer numRecords)
    {
        List<ContactPointEmail> contactPointEmails = new List<ContactPointEmail>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Scope__c relatedScope: scopes)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                contactPointEmails.add(
                    new ContactPointEmail(
                        ParentId = relatedScope.AccountId__c,
                        EmailAddress = relatedScope.AccountId__r.Name + '@nts-solutions.com',
                        ScopeId__c = relatedScope.Id,
                        Scope__c = relatedScope.Scope__c
                    )
                );
            }
        }

        return contactPointEmails;
    }
}