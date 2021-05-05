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
                'cliente_restringido' => (10 * Math.random()) > 5 ? true : false,
                'cliente_morosidad' => (10 * Math.random()) > 5 ? true : false,
                'cliente_registro_mizurich' => (10 * Math.random()) > 5 ? true : false,
                'cliente_bloqueo_gdpr' => (10 * Math.random()) > 5 ? true : false
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
                    'indicador_domicilio_principal' => false,
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
                'producto_estado' => true,
                'producto_estado_desc' => 'ACTIVO'
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
                'poliza_forma_pago_desc' => 'Test',
                'prima_tecnica' => 10 * Math.random(),
                'prima_suma_recargos_descuentos' => 10 * Math.random(),
                'prima_suma_bonus_malus' => 10 * Math.random(),
                'prima_suma_impuestos' => 10 * Math.random(),
                'prima_total' => 10 * Math.random()
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
        String objectType = 
            objectTypeValues[Integer.valueof( (Math.random() * objectTypeValues.size() - 1) )].getValue();

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO OBJETO ASEGURADO*/
            jsonElementsList.add(
                new Map<String, Object> {
                'id_unico_riesgo_asegurado' => String.valueOf(i + 1).leftPad(9, '0'),
                'oferta_id' => '',
                'poliza_id' => '',
                'objeto_tipo' => objectType,
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

        Schema.DescribeFieldResult typeFieldResult = Account.Class__c.getDescribe();
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
                    'importe_acumulado' => 10 * Math.random(),
                    'prima_neta' => 10 * Math.random()
            }
                );
        }

        return jsonElementsList;
    }

    /**
     * Obtener estructura json del sistema de origen INFO para registros
     * de entidad Note
     **
     * @param Integer numero de elementos a generar
     * @return List<Map<String, Object>> listado de elementos simulando json
     * @author nts (agonzalezisasi)
     * @date 15/02/2021
     */
    public static List<Map<String, Object> > getINFONoteJson(
        Integer totalItems
        )
    {
        return buildINFONoteJson(totalItems);
    }

    private static List<Map<String, Object> > buildINFONoteJson(
        Integer totalItems
        )
    {
        if (totalItems == null || totalItems < 1)
        {
            throw new TestException('totalItems must be equal or greater than 1');
        }

        // From Metadata Robot_Hegeo_Field_Mapping__mdt
        String tipo = '1';
        String subtype = '5';
        String typeN3 = '';

        List<Map<String, Object> > jsonElementsList = new List<Map<String, Object> >();

        for (Integer i = 0; i < totalItems; i++)
        {
            /* REGISTRO SINIESTRO*/
            jsonElementsList.add(
                new Map<String, Object> {
                    'note_fec_alta' => '2021-02-15',
                    'note_usuario' => 'noteUser',
                    'note_desc_aviso' => 'case subject',
                    'note_texto' => 'case description',
                    'note_cod_oferta' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_cod_poliza_incompleta' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_num_recibo' => '1234',
                    'note_cod_siniestro' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_cod_poliza' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_producto_tecnico' => '',
                    'note_producto_comercial' => '',
                    'note_intermediario' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_cod_tarea' => String.valueOf(i + 1).leftPad(9, '0'),
                    'note_indicador_tarea' => '',
                    'note_cod_agrupacion_TA' => '',
                    'note_desc_grupo' => '',
                    'note_desc_tipo_envio' => tipo,
                    'note_desc_subtipo' => subtype,
                    'note_desc_nivel_division' => typeN3,
                    'note_cod_agrupacion' => ''
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

        Id infoRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();

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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
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
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId
                            )
                        );
                }
            }
            when 'NOTE' {
                for (
                    Map<String, Object> payload : getINFONoteJson(numRecords)
                    )
                {
                    externalRequestList.add(
                        new ExternalRequest__c(
                            Origin__c = origin,
                            Entity__c = 'NOTE',
                            Action__c = 'UPSERT',
                            Payload__c = JSON.serialize(payload),
                            ContentFormat__c = 'JSON',
                            recordTypeId = infoRecordTypeId,
                            NumRetry__c = 2
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
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        Task interaction;
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numTasks; i++)
        {
            interaction = new Task();
            interaction.Status = 'Nueva';
            interaction.Priority = 'Normal';
            interaction.CallObject = 'ucid' + i;
            interaction.RecordTypeId = recordTypeId;
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
            when 'Intermediary' {
                for (Integer i = 0; i < numRecords; i++)
                {
                    Integer phoneNumber = (Math.random() * 1000000000).intValue();
                    accounts.add(
                        new Account(
                            Name = 'intermediaryName' + i,
                            INFOIntermediaryCode__c = String.valueOf(phoneNumber).leftPad(10, '0'),
                            Phone = String.valueOf(phoneNumber),
                            RecordTypeId = recordTypeId
                        )
                    );
                }
            }
            when 'Partner' {
                for (Integer i = 0; i < numRecords; i++)
                {
                    Integer phoneNumber = (Math.random() * 1000000000).intValue();
                    accounts.add(
                        new Account(
                            Name = 'partnerName' + i,
                            INFOBusinessCode__c = String.valueOf(phoneNumber).leftPad(10, '0'),
                            Phone = String.valueOf(phoneNumber),
                            RecordTypeId = recordTypeId,
                            PartnerSector__c = 'Sector' + i,
                            PartnerSFCode__c = 'Code' + i
                        )
                    );
                }
            }
            when 'Customer' { // PersonalAccount
                for (Integer i = 0; i < numRecords; i++)
                {
                    accounts.add(
                        new Account(
                            LastName = 'testlastname' + i,
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
     * Genera ContactPointAddress relacionados con una lista de accounts
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un ContactPointAddress
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<ContactPointAddress> listado de ContactPointAddress generados
     * @author adelgado
     * @date 10/12/2020
     */
    public static List<ContactPointAddress> generateContactPointAddressesFromAccounts(List<Account> accounts, Integer numRecords)
    {
        List<ContactPointAddress> contactPointAddresses = new List<ContactPointAddress>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer phoneNumber = (Math.random() * 1000000000).intValue();
                contactPointAddresses.add(
                    new ContactPointAddress(
                        Name = 'Address' + i,
                        ParentId = relatedAccount.Id,
                        Street = 'Street ' + i
                    )
                );
            }
        }

        return contactPointAddresses;
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
                        Scope__c = scope,
                        InfoQuoteNumber__c = 'opp'+relatedAccount.Id+i
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
            Boolean isPrimary = true;
            for(Integer i=0; i<numRecords; i++)
            {
                contactPointEmails.add(
                    new ContactPointEmail(
                        ParentId = relatedScope.AccountId__c,
                        EmailAddress = relatedScope.AccountId__r.Name + '@nts-solutions.com',
                        ScopeId__c = relatedScope.Id,
                        Scope__c = relatedScope.Scope__c,
                        IsPrimary = isPrimary
                    )
                );
                isPrimary = false;
            }
        }

        return contactPointEmails;
    }

    /**
     * Genera ContactPointPhone relacionados con una lista de scopes
     **
     * @param List<Scope> scopes lista de scopes para las que hay que generar un ContactPointPhone
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<ContactPointPhone> listado de ContactPointPhones generados
     * @author rlopez
     * @date 23/11/2020
     */
    public static List<ContactPointPhone> generateContactPointPhonesFromScopes(List<Scope__c> scopes, Integer numRecords)
    {
        List<ContactPointPhone> contactPointPhones = new List<ContactPointPhone>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Scope__c relatedScope: scopes)
        {
            Boolean isPrimary = true;
            for(Integer i=0; i<numRecords; i++)
            {
                Integer phoneNumber = (Math.random() * 1000000000).intValue();
                contactPointPhones.add(
                    new ContactPointPhone(
                        ParentId = relatedScope.AccountId__c,
                        TelephoneNumber = String.valueOf(phoneNumber),
                        ScopeId__c = relatedScope.Id,
                        Scope__c = relatedScope.Scope__c,
                        IsPrimary = isPrimary
                    )
                );
                isPrimary = false;
            }
        }

        return contactPointPhones;
    }

    /**
     * Genera un JSON del formulario web de Zurich Empresas en función del paso indicado
     **
     * @param String lastStep paso del que queremos crear el JSON
     *
     * @return Map<String, Object> o String JSON generado
     * @author rlopez
     * @date 25/11/2020
     */
    public static Map<String, Object> generateBusinessInsuranceOffersWebJSON(String lastStep, String nationalId, String email, String phone, String businessCode, List<Product2> products)
    {
        Map<String, Object> jsonInformation = new Map<String, Object>();

        //Datos comunes
        jsonInformation.put('timeStamp', datetimeToISOString(System.now()));
        jsonInformation.put('webEmail', email);
        jsonInformation.put('sessionId', Math.random());
        jsonInformation.put('businessCode', businessCode);
        jsonInformation.put('lastStep', lastStep);

        switch on lastStep {
            when 'CRM-01' {
                jsonInformation.put('status', 'Abandono');
                jsonInformation.put('accountInformation', new Map<String, Object>
                {
                    'firstName'  => 'FirstName',
                    'lastName' => 'LastName'
                });
            }
            when 'CRM-02' {
                jsonInformation.put('status', 'Abandono');
                jsonInformation.put('accountInformation', new Map<String, Object>
                {
                    'firstName'  => 'FirstName',
                    'lastName' => 'LastName',
                    'family' => '10',
                    'commercialActivity' => '101100'
                });
            }
            when 'CRM-03' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'Activo');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));

                jsonInformation.put('accountInformation', new Map<String, Object>
                {
                    'firstName'  => 'FirstName',
                    'lastName' => 'LastName',
                    'family' => '10',
                    'commercialActivity' => '101100'
                });


                jsonInformation.put('offers', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'commercialPC' => (!products.isEmpty() ? products.get(0).CommercialCode__c : String.valueOf((Math.random() * 100000).intValue())),
                        'technicalPC' => (!products.isEmpty() ? products.get(0).TechnicalCode__c : String.valueOf((Math.random() * 100000).intValue()))
                    },
                    new Map<String, Object>{
                        'commercialPC' => (!products.isEmpty() && products.get(1) != null ? products.get(1).CommercialCode__c : String.valueOf((Math.random() * 100000).intValue())),
                        'technicalPC' => (!products.isEmpty() && products.get(1) != null ? products.get(1).TechnicalCode__c : String.valueOf((Math.random() * 100000).intValue()))
                    }
                });
            }
            when 'CRM-04' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'Abandono');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));
                jsonInformation.put('accountInformation', generateCompleteAccountInformation(nationalId));

                jsonInformation.put('offers', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'commercialPC' => (!products.isEmpty() ? products.get(0).CommercialCode__c : String.valueOf((Math.random() * 100000).intValue())),
                        'technicalPC' => (!products.isEmpty() ? products.get(0).TechnicalCode__c : String.valueOf((Math.random() * 100000).intValue())),
                        'offerRiskInformation' => generateOfferRiskInformation()
                    }
                });
            }
            when 'CRM-05' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'Abandono');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));
                jsonInformation.put('accountInformation', generateCompleteAccountInformation(nationalId));

                jsonInformation.put('offers', new List<Map<String, Object>>{
                    generateOfferWithRisk(products, businessCode)
                });
            }
            when 'CRM-06' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'Activo');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));
                jsonInformation.put('accountInformation', generateCompleteAccountInformation(nationalId));

                jsonInformation.put('offers', new List<Map<String, Object>>{
                    generateOfferWithRisk(products, businessCode)
                });
            }
            when 'CRM-07' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'Abandono');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));
                jsonInformation.put('accountInformation', generateCompleteAccountInformation(nationalId));

                jsonInformation.put('offers', new List<Map<String, Object>>{
                    generateOfferWithRisk(products, businessCode)
                });

                jsonInformation.put('manager', generateManagerInformation(email, phone));
            }
            when 'CRM-08' {
                jsonInformation.put('webPhone', phone);
                jsonInformation.put('status', 'ACtivo');
                jsonInformation.put('bestTimeFrom', datetimeToISOString(System.now()));
                jsonInformation.put('bestTimeUntil', datetimeToISOString(System.now().addHours(4)));
                jsonInformation.put('accountInformation', generateCompleteAccountInformation(nationalId));

                jsonInformation.put('offers', new List<Map<String, Object>>{
                    generateOfferWithRisk(products, businessCode)
                });

                jsonInformation.put('manager', generateManagerInformation(email, phone));
            }
        }

        return jsonInformation;
    }

    public static String datetimeToISOString(Datetime datetimeToConvert)
    {
        return  datetimeToConvert.year() + '-' +
                ('0'+datetimeToConvert.month()).right(2) + '-' +
                ('0'+datetimeToConvert.day()).right(2) +
                'T' +
                ('0'+datetimeToConvert.hour()).right(2) +
                ':' +
                ('0'+datetimeToConvert.minute()).right(2) +
                ':' +
                ('0'+datetimeToConvert.second()).right(2) +
                '.' +
                ('00'+datetimeToConvert.millisecond()).right(3) + 'Z';
    }

    private static Map<String, Object> generateCompleteAccountInformation(String nationalId)
    {
        return new Map<String, String>
        {
            'firstName'  => 'FirstName',
            'lastName' => 'LastName',
            'family' => '10',
            'commercialActivity' => '101100',
            'annualRevenue' => '200000.10',
            'numberOfEmployees' => '150',
            'tradeName' => 'TradeName',
            'companyName' => 'CompanyName',
            'nationalIdentifier' => nationalId
        };
    }

    private static Map<String, Object> generateOfferRiskInformation()
    {
        return new Map<String, Object>{
            'propertyStreetType' => 'VI',
            'propertyStreet' => 'Via Augusta',
            'propertyStreetNumber' => '12',
            'propertyAdditionalInfo' => '',
            'propertyPostalCode' => '08006',
            'propertyCity' => 'Barcelona',
            'propertyState' => '8',
            'propertyCountry' => 'ESP',
            'yearOfConstruction' => '1960',
            'ownership' => 'P',
            'insuredType' => 'I',
            'buildingType' => 'I',
            'height' => 'AL',
            'riskFactor01' => '0001',
            'riskFactor02' => '',
            'riskFactor03' => '',
            'riskFactor04' => '',
            'riskFactor05' => '',
            'riskFactor06' => '',
            'riskFactor07' => '',
            'riskFactor08' => '0039',
            'riskFactor09' => '',
            'area' => '50',
            'lockType' => true,
            'securityDoor' => false,
            'bulletproofDoor' => false,
            'connectedAlarm' => false,
            'fireHydrant' => false,
            'surveillance' => false,
            'smokeDetector' => false,
            'sprayer' => false,
            'fireExtinguisher' => true,
            'typeOfWindows' => '2',
            'strongbox' => 'N'
        };
    }

    private static Map<String, Object> generateOfferWithRisk(List<Product2> products, String businessCode)
    {
        Datetime twoWeeks = System.today().addDays(15);
        return new Map<String, Object>{
            'policyNumber' => String.valueOf((Math.random() * 10000000).intValue()),
            'quoteNumberINFO' => '456789456',
            'quoteNumberJRE' => '789989799',
            'operationCode' => 'P1',
            'businessCode' => businessCode,
            'effectiveDate' => twoWeeks.year()+'-'+('0'+twoWeeks.month()).right(2)+'-'+('0'+twoWeeks.day()).right(2),
            'commercialPC' => (!products.isEmpty() ? products.get(0).CommercialCode__c : String.valueOf((Math.random() * 100000).intValue())),
            'technicalPC' => (!products.isEmpty() ? products.get(0).TechnicalCode__c : String.valueOf((Math.random() * 100000).intValue())),
            'paymentType' => 'A',
            'paymentTypeSucc' => 'A',
            'paymentChannel' => 'CC',
            'paymentChannelSucc' => 'CC',
            'language' => 'ES',
            'buildingCapital' => '120000',
            'contentCapital' => '12000',
            'generalLiabilityLimit' => '12000',
            'netPremium' => '12000',
            'validationErrors' => '',
            'offerRiskInformation' => generateOfferRiskInformation()
        };
    }

    private static Map<String, Object> generateManagerInformation(String email, String phone)
    {
        return new Map<String, Object>{
            'email' => email,
            'phone' => phone,
            'firstName' => 'ManagerFirstName',
            'lastName' => 'ManagerLastName'
        };
    }

    public static List<Product2> generateProducts(Integer numRecords)
    {
        List<Product2> products = new List<Product2>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Integer i=0; i<numRecords; i++)
        {
            products.add(
                new Product2(
                    Name = 'Product Name ' + i,
                    CommercialCode__c = String.valueOf((Math.random() * 100000).intValue()),
                    TechnicalCode__c = String.valueOf((Math.random() * 100000).intValue())
                )
            );
        }

        return products;
    }

    /*
    * Genera Casos con un OwnerId determinado (Cola o Usuario)
    * @param ownerId ID de Cola o User
    * @param Integer numRecords número de registros a generar POR CADA CUENTA
    * @return List<Case> listado de registros generados
    */
   public static List<Case> generateCasesWithOwnerId(Id ownerId, Integer numRecords)
   {
       List<Case> cases = new List<Case>();

       if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }
        for(Integer i=0; i<numRecords; i++)
        {
            cases.add(
                new Case(
                    OwnerId = ownerId
                )
            );
        }

        return cases;
    }

    /**
     * Genera una lista de tareas con RecordType Interaction, con un WhatID relleno
     * @param numTasks numero de elementos a generar
     * @return List<Task> listado de tareas
     */
    public static List<Task> generateInteractionTasksWithWhatId(Id whatId, Integer numTasks)
    {
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        Task interaction;
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numTasks; i++)
        {
            interaction = new Task();
            interaction.Status = 'Nueva';
            interaction.WhatId = whatId;
            interaction.Priority = 'Normal';
            interaction.CallObject = 'ucid' + i;
            interaction.RecordTypeId = recordTypeId;
            tasks.add(interaction);
        }
        return tasks;
    }

    /**
     * Genera una lista colas aunque en los test se ven las que hay en la Org
     * @param num numero de elementos a generar
     * @return List<Group> listado de colas
     */
    public static List<Group> generateQueueGroups(Integer num)
    {
        Group queue;
        List<Group> queues = new List<Group>();
        for (Integer i = 0; i < num; i++)
        {
            queue = new Group();
            queue.Type = 'Queue';
            queue.Name = 'queue' + i;
            queues.add(queue);
        }
        return queues;
    }

    /**
     * Genera una lista colas aunque en los test se ven las que hay en la Org
     * @param num numero de elementos a generar
     * @param groupId id de la cola
     * @param queueObject el objeto a encola, por ejemplo 'Case'
     * @return List<Group> listado de colas
     */
    public static List<QueueSObject> generateQueueSObject(Id groupId, String queueObject, Integer num)
    {
        QueueSObject queue;
        List<QueueSObject> queues = new List<QueueSObject>();
        for (Integer i = 0; i < num; i++)
        {
            queue = new QueueSObject();
            queue.QueueId = groupId;
            queue.SObjectType = queueObject;
            queues.add(queue);
        }
        return queues;
    }

    /**
     * Genera Policy__c relacionadas con cuentas
     **
     * @param List<Account> accounts lista de accounts para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA CUENTA
     */
    public static List<Policy__c> generatePoliciesForEachAccount(List<Account> accounts, Integer numRecords)
    {
        List<Policy__c> policies = new List<Policy__c>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Account relatedAccount: accounts)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer policyNumber = (Math.random() * 1000000000).intValue();
                policies.add(
                    new Policy__c(
                        Name = String.valueOf(policyNumber),
                        PolicyHolder__c = relatedAccount.Id,
                        InfoPolicyNumber__c = String.valueOf(policyNumber).leftPad(14, '0'),
                        PolicyStatus__c= 'V'
                    )
                );
            }
        }

        return policies;
    }

    /**
     * Genera Asset relacionadas con pólizas
     **
     * @param List<Policy__c> policies lista de pólizas para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA PÓLIZA
     */
    public static List<Asset> generateInsuredObjectsForEachPolicy(String recordTypeName, List<Policy__c> policies, Integer numRecords)
    {
        List<Asset> insuredObjects = new List<Asset>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        Schema.RecordTypeInfo insuredObjectTypeInfo = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(recordTypeName);
        Id recordTypeId;
        if(insuredObjectTypeInfo != null)
        {
            recordTypeId = insuredObjectTypeInfo.getRecordTypeId();
        }

        for(Policy__c relatedPolicy: policies)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer insuredObjectNumber = (Math.random() * 1000000000).intValue();
                insuredObjects.add(
                    new Asset(
                        Name = String.valueOf(insuredObjectNumber),
                        AccountId = relatedPolicy.PolicyHolder__c,
                        INFOInsuredObjectCode__c = String.valueOf(insuredObjectNumber),
                        RegistrationNumber__c = 'RegistrationNumber' + i,
                        PolicyId__c = relatedPolicy.Id,
                        RecordTypeId = recordTypeId
                    )
                );
            }
        }

        return insuredObjects;
    }

    /**
     * Genera Asset relacionadas con pólizas
     **
     * @param List<Policy__c> policies lista de pólizas para las que hay que generar un listado de registros
     * @param List<Asset> insuredObjects lista de objetos asegurados para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA PÓLIZA-OBJETO ASEGURADO
     */
    public static List<Claim__c> generateClaimsForEachPolicyInsuredObject(List<Policy__c> policies, List<Asset> insuredObjects, Integer numRecords)
    {
        List<Claim__c> claims = new List<Claim__c>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Policy__c relatedPolicy: policies)
        {
            for(Asset relatedInsuredObject: insuredObjects)
            {
                for(Integer i=0; i<numRecords; i++)
                {
                    Integer claimNumber = (Math.random() * 1000000000).intValue();
                    claims.add(
                        new Claim__c(
                            Name = String.valueOf(claimNumber),
                            PolicyHolder__c = relatedPolicy.PolicyHolder__c,
                            Policy__c = relatedPolicy.Id,
                            InsuredObject__c = relatedInsuredObject.Id,
                            INFOClaimNumber__c = String.valueOf(claimNumber)
                        )
                    );
                }
            }
        }

        return claims;
    }

    /**
     * Genera Campaigns para una entidad legal
     **
     * @param String legalEntity entidad legal para la que vamos a crear las campañas
     * @param Integer numRecords número de elementos a generar
     *
     * @return List<Campaign> listado de Campaigns generadas
     * @author rlopez
     * @date 02/12/2020
     */
    public static List<Campaign> generateCampaigns(String legalEntity, Integer numRecords)
    {
        List<Campaign> campaigns = new List<Campaign>();

        if(numRecords == null)
        {
            numRecords = 1;
        }

        for(Integer i=0; i<numRecords; i++)
        {
            campaigns.add(
                new Campaign(
                    Name = 'TestCampaign ' + i,
                    LegalEntity__c = legalEntity
                )
            );
        }

        return campaigns;
    }

    /**
     * Genera CampaignMembers a partir de una lista de contactos y para cada campaña especificada
     **
     * @param List<Contact> contacts listado de contactos que vamos a suscribir en las campañas
     * @param List<Campaign> campaigns listado de campañas
     *
     * @return List<CampaignMember> listado de CampaignMembers generados
     * @author rlopez
     * @date 02/12/2020
     */
    public static List<CampaignMember> generateCampaignMembersForEachCampaign(List<Contact> contacts, List<Campaign> campaigns, String status)
    {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for(Contact member: contacts)
        {
            for(Campaign campaign: campaigns)
            {
                campaignMembers.add(
                    new CampaignMember(
                        ContactId = member.Id,
                        CampaignId = campaign.Id,
                        Status = status
                    )
                );
            }
        }

        return campaignMembers;
    }

    /**
     * Genera CampaignMembers a partir de una lista de cuentas personales y para cada campaña especificada
     **
     * @param List<Account> accounts listado de contactos que vamos a suscribir en las campañas
     * @param List<Campaign> campaigns listado de campañas
     *
     * @return List<CampaignMember> listado de CampaignMembers generados
     * @author rlopez
     * @date 02/12/2020
     */
    public static List<CampaignMember> generateCampaignMembersForEachCampaign(List<Account> contacts, List<Campaign> campaigns, String status)
    {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for(Account member: contacts)
        {
            if(member.PersonContactId != null)
            {
                for(Campaign campaign: campaigns)
                {
                    campaignMembers.add(
                        new CampaignMember(
                            ContactId = member.PersonContactId,
                            CampaignId = campaign.Id,
                            Status = status
                        )
                    );
                }
            }
        }

        return campaignMembers;
    }

    /**
     * Genera Oportunidades relacionadas con Scopes
     **
     * @param List<Scope__c> scopes lista de scopes para las que hay que generar un listado de registros
     * @param String stage etapa de las oportunidades
     * @param Date closeDate fecha de cierre de las oportunidades
     * @param Integer numRecords número de registros a generar POR CADA SCOPE
     *
     * @return List<Opportunity> listado de registros generados
     * @author rlopez
     * @date 02/12/2020
     */
    public static List<Opportunity> generateOpportunitiesForEachScope(List<Scope__c> scopes, String stage, Date closeDate, Integer numRecords)
    {
        List<Opportunity> opportunities = new List<Opportunity>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Scope__c relatedScope: scopes)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                opportunities.add(
                    new Opportunity(
                        OwnerId = USerInfo.getUserid(),
                        AccountId = relatedScope.AccountId__c,
                        Name = 'opp'+i,
                        StageName = stage,
                        CloseDate = closeDate,
                        Scope__c = relatedScope.Scope__c,
                        ScopeId__c = relatedScope.Id,
                        InfoQuoteNumber__c = 'opp'+relatedScope.AccountId__c+i
                    )
                );
            }
        }

        return opportunities;
    }

    /**
     * Genera Policy__c relacionadas con oportunidades
     **
     * @param List<Opportunity> opportunities lista de opportunities para las que hay que generar un listado de registros
     * @param Integer numRecords número de registros a generar POR CADA OPORTUNIDAD
     */
    public static List<Policy__c> generatePoliciesForEachOpportunity(List<Opportunity> opportunities, Integer numRecords)
    {
        List<Policy__c> policies = new List<Policy__c>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Opportunity relatedOpportunity: opportunities)
        {
            for(Integer i=0; i<numRecords; i++)
            {
                Integer policyNumber = (Math.random() * 1000000000).intValue();
                policies.add(
                    new Policy__c(
                        Name = String.valueOf(policyNumber),
                        PolicyHolder__c = relatedOpportunity.AccountId,
                        InfoPolicyNumber__c = String.valueOf(policyNumber).leftPad(14, '0'),
                        OpportunityName__c = relatedOpportunity.Id,
                        PolicyStatus__c = 'V'
                    )
                );
            }
        }

        return policies;
    }

    /**
     * Genera usuarios para un perfil dado
     **
     * @param String profileId
     * @param Integer numRecords número de registros a generar
     *
     * @return List<User> listado de Users generados
     * @author rlopez
     * @date 22/12/2020
     */
    public static List<User> generateUsersByProfile(String profileId, Integer numRecords)
    {
        List<User> users = new List<User>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Integer i=0; i<numRecords; i++)
        {
            if(String.isNotBlank(profileId))
            {
                String email = 'testuser'+i+'@nts-solutions.com.invalid';
                users.add(
                    new User(
                        Username=email + profileId,
                        LastName='User'+i,
                        Email=email,
                        Alias='user'+i,
                        ProfileId=profileId,
                        TimeZoneSidKey='Europe/Rome',
                        LocaleSidKey='es_ES',
                        EmailEncodingKey='UTF-8',
                        LanguageLocaleKey='es'
                    )
                );
            }
        }

        return users;
    }

    /**
     * Genera Colas de GenesysCloud -> Fallará si en la Org no está instalado el paquete gestionado
     * @param Integer numRecords número de registros a generar
     * @return List<User> listado de Users generados
     */
    public static List<purecloud__PureCloud_Queue__c> generateGenesysQueues(Integer numRecords)
    {
        List<purecloud__PureCloud_Queue__c> genesysQueues = new List<purecloud__PureCloud_Queue__c>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        for(Integer i=0; i<numRecords; i++)
        {
            genesysQueues.add(
                new purecloud__PureCloud_Queue__c(
                    Name='GenesysQueueName'+i,
                    purecloud__PureCloud_Queue_ID__c='GenesysQueueId'+i
                )
            );
        }
        return genesysQueues;
    }

    /**
     * Genera Orders de Klinc para OrdersSelector
     **
     * @param Id accountId
     * @param Id contactId
     * @param String customerNum el que tiene el contacto
     * @param String recordTypeName por ejemplo GI como el RT de su contacto
     * @param Integer numRecords número de registros a generar
     *
     * @return List<Order> listado de orders generados
     * @date 23/02/2021
     */
    public static List<Order> generateOrdersKlinc(Id accountId, Id contactId, String customerNum, String recordTypeName, Integer numRecords)
    {
        List<Order> orders = new List<Order>();

        if(numRecords == null || numRecords < 1)
        {
            numRecords = 1;
        }

        Id rtId = SystemUtil.getOrderRecordTypeIdByName(recordTypeName);
        for(Integer i=0; i<numRecords; i++)
        {
            String email = 'testuser'+i+'@nts-solutions.com.invalid';
            orders.add(
                new Order(
                    EffectiveDate = Date.valueOf('1994-01-01'),
                    PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
                    CustomerNum__c = customerNum,
                    LegalEntity__c = Label.GeneralInsurance,
                    RecordTypeId = rtId, //Importante PolicyGI o PolicyLife
                    Status = 'Sync',
                    AccountId = accountId,
                    ContactId__c = contactId, //Importante
                    PolicyStatus__c = Label.PolicyStatusActive, //Importante
                    PolicyNum__c = '8989'+i //debe ser único
                )
            );
        }

        return orders;
    }
}