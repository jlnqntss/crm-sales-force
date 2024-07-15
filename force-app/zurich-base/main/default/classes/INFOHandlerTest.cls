/**
 * Clase de test para la clase INFOHandler
 **
 * @author adelgado
 * @date 15/10/2020
 */
@isTest
private with sharing class INFOHandlerTest
{
    private static final Integer NUM_ER_NATURAL_ACCOUNT = 5;
    private static final Integer NUM_ER_LEGAL_ACCOUNT = 5;
    private static final Integer NUM_ER_CONTACT_POINT_ADDRESS = 5;
    private static final Integer NUM_ER_CONTACT_POINT_PHONE = 5;
    private static final Integer NUM_ER_CONTACT_POINT_EMAIL = 5;
    private static final Integer NUM_ER_PRODUCT = 5;
    private static final Integer NUM_ER_QUOTE = 5;
    private static final Integer NUM_ER_QUOTE_OPTION = 5;
    private static final Integer NUM_ER_POLICY = 5;
    private static final Integer NUM_ER_INSURED_OBJECT = 5;
    private static final Integer NUM_ER_CLAIM = 5;
    private static final Integer NUM_ER_POLICY_RELATIONSHIP = 5;
    private static final Integer NUM_ER_QUOTE_RELATIONSHIP = 5;
    private static final Integer NUM_ER_CLAIM_RELATIONSHIP = 5;
    private static final Integer NUM_ER_PARTNER = 5;
    private static final Integer NUM_ER_INTERMEDIARY = 5;
    private static final Integer NUM_ER_NOTE = 5;
    private static final Integer NUM_ER_SPECIAL_CONDITION = 5;
    private static final Integer NUM_ER_INTERMEDIARY_KPI = 5;
    private static final Integer NUM_ER_INTERMEDIARY_GROUP = 1;
    private static final Integer NUM_ER_INTERMEDIARY_HIERARCHY = 1;
    private static final Integer NUM_ER_CONSENT = 5;
    private static final Integer NUM_ER_ACCOUNT_SCORE_KPI = 1;
    private static final Integer NUM_ER_INTERMEDIARY_TNPS = 1;

    @TestSetup
    private static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

        Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();

        //Personas físicas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'NATURAL_ACCOUNT', NUM_ER_NATURAL_ACCOUNT)
            );

        //Personas jurídicas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'LEGAL_ACCOUNT', NUM_ER_LEGAL_ACCOUNT)
            );

        //Vías de contacto postal
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CONTACT_POINT_ADDRESS', NUM_ER_CONTACT_POINT_ADDRESS)
            );

        //Vías de contacto telefónico
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CONTACT_POINT_PHONE', NUM_ER_CONTACT_POINT_PHONE)
            );

        //Vías de contacto email
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CONTACT_POINT_EMAIL', NUM_ER_CONTACT_POINT_EMAIL)
            );

        //Productos
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'PRODUCT', NUM_ER_PRODUCT)
            );

        //Ofertas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'QUOTE', NUM_ER_QUOTE)
            );

        //Opciones ofertas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'QUOTE_OPTION', NUM_ER_QUOTE_OPTION)
            );

        //Pólizas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'POLICY', NUM_ER_POLICY)
            );

        //Objetos asegurados
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'INSURED_OBJECT', NUM_ER_INSURED_OBJECT)
            );

        //Siniestros
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CLAIM', NUM_ER_CLAIM)
            );

        //Roles póliza
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'POLICY_RELATIONSHIP', NUM_ER_POLICY_RELATIONSHIP)
            );

        //Roles oferta
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'QUOTE_RELATIONSHIP', NUM_ER_QUOTE_RELATIONSHIP)
            );

        //Roles siniestro
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CLAIM_RELATIONSHIP', NUM_ER_CLAIM_RELATIONSHIP)
            );

        //Partner
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'PARTNER', NUM_ER_PARTNER)
            );

        //Mediador
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'INTERMEDIARY', NUM_ER_INTERMEDIARY)
            );

        //Note
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'NOTE', NUM_ER_NOTE)
            );

        //Special Condition
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'SPECIAL_CONDITION', NUM_ER_SPECIAL_CONDITION)
            );

        //SDM KPIs
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'INTERMEDIARY_KPI', NUM_ER_INTERMEDIARY_KPI)
            );
        // INTERMEDIARY_GROUP
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'INTERMEDIARY_GROUP', NUM_ER_INTERMEDIARY_GROUP)
            );
        // INTERMEDIARY_GROUP
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'INTERMEDIARY_HIERARCHY', NUM_ER_INTERMEDIARY_HIERARCHY)
            );
        // CONSENT
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'CONSENT', NUM_ER_CONSENT)
        );
        // ACCOUNT_SCORE_KPI
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, configValues.get('ER_ACCOUNT_SCORE_KPI'), NUM_ER_ACCOUNT_SCORE_KPI)
        );
        // INTERMEDIARY_TNPS
        externalRequestList.addAll( 
            TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, configValues.get('ER_INTERMEDIARY_TNPS'), NUM_ER_INTERMEDIARY_TNPS)
        );

        insert externalRequestList;
    }

    /**
     * Crea datos de prueba en el mapa de equivalencias por entidad para usarlo en los Test
     *
     * @author nts (agonzalezisasi)
     * @date 25/02/2021
     *
     * @param {Map<String, Map<String, String>>} mapa de equivalencias por Entidad (debera estar inicializado)
     */
    private static void createEquivalenceSettigs(Map<String, Map<String, String>> mapEquivalences)
    {
        // Ejemplo de equivalencia: INSURED_OBJECT => (0000000057 => Boat)

        // Recuperamos un RecordType de Asset para usarlo como valor en la equivalencia
        Map<String, Schema.RecordTypeInfo> recordTypes =  Schema.SObjectType.Asset.getRecordTypeInfosByName();
        RecordTypeInfo rt = recordTypes.values()[0];

        // Recuperamos los valores de la picklist ObjectType__c para usarlos como clave en la equivalencia
        Schema.DescribeFieldResult objectTypeFieldResult = Asset.ObjectType__c.getDescribe();
        List<Schema.PicklistEntry> objectTypeValues = objectTypeFieldResult.getPicklistValues();
        mapEquivalences.put(INFOHandler.INSURED_OBJECT, new Map<String, String>());
        for(Schema.PicklistEntry pe: objectTypeValues) {
            mapEquivalences.get(INFOHandler.INSURED_OBJECT).put(pe.value, rt.developername);
        }
    }

    /**
     * Devuelve una nueva instancia del selector de ExternalRequests
     *
     * @author fpalomo
     * @date 24/06/2024
     */
    private static ExternalRequestsSelector getExternalRequestsSelector()
    {
        return new ExternalRequestsSelector(new List<Schema.SObjectField>{
            ExternalRequest__c.Entity__c,
            ExternalRequest__c.Action__c,
            ExternalRequest__c.Payload__c,
            ExternalRequest__c.ContentFormat__c,
            ExternalRequest__c.NumRetry__c,
            ExternalRequest__c.Origin__c,
            ExternalRequest__c.CreatedDate
        });
    }

    /**
     * Prepara los datos para realizar el test persist_delete_ok sobre la entidad especificada
     *
     * @author fpalomo
     * @date 24/06/2024
     */
    private static void preparePersistDeleteTest(Set<String> entities)
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);
        Set<String> origins = new Set<String> {INFOHandler.HANDLER_ORIGIN};
        List<ExternalRequest__c> externalRequestToDelete = new List<ExternalRequest__c>();

        List<ExternalRequest__c> externalRequestList = getExternalRequestsSelector().selectByOriginAndEntity(origins, entities);

        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);

        List<ExternalRequest__c> externalRequestListUpserted = getExternalRequestsSelector().selectByOriginAndEntity(origins, entities);

        for(ExternalRequest__c externalRequest : externalRequestListUpserted)
        {
            if(entities.contains(externalRequest.Entity__c))
            {
                externalRequest.Processed__C = false;
                externalRequest.Action__C = 'DELETE';
                externalRequestToDelete.add(externalRequest);
            }
        }
        update externalRequestToDelete;

        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        INFOHandler.prepare(transformer, externalRequestToDelete);
        INFOHandler.process(externalRequestToDelete);
        INFOHandler.persists(externalRequestToDelete);
    }

    @isTest
    private static void test_prepare()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        Set<String> objects = new Set<String>();

        for ( Transformer__mdt setting : TransformerSelector.selectMetadataByOrigin(INFOHandler.HANDLER_ORIGIN) )
        {
            objects.add(setting.OriginEntity__c);
        }

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        Test.stopTest();

        System.assertEquals(
            objects.size(),
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.size(),
            'No se ha generado correctamente el mapa por entidades'
            );
        System.assertEquals(
            objects.size(),
            ExternalRequestHandlerUtil.recordsToDeleteByEntity.size(),
            'No se ha generado correctamente el mapa por entidades'
            );
    }

    @isTest
    private static void test_process_upsert_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});


        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(
            NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            ); // 10 cuentas de personas físicas y 10 de personas jurídicas
        System.assertEquals(
            NUM_ER_LEGAL_ACCOUNT,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Contact').size(),
            'No se ha generado correctamente el mapa de registros de contact'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_ADDRESS,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointAddress').size(),
            'No se ha generado correctamente el mapa de registros de contactPointAddress'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_PHONE,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointPhone').size(),
            'No se ha generado correctamente el mapa de registros de contactPointPhone'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_EMAIL,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointEmail').size(),
            'No se ha generado correctamente el mapa de registros de contactPointEmail'
            );
        System.assertEquals(
            NUM_ER_PRODUCT,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.PRODUCT).get('Product2').size(),
            'No se ha generado correctamente el mapa de registros de product'
            );
        System.assertEquals(
            NUM_ER_QUOTE,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE).get('Opportunity').size(),
            'No se ha generado correctamente el mapa de registros de opportunity'
            );
        System.assertEquals(
            NUM_ER_QUOTE_OPTION,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE_OPTION).get('Quote').size(),
            'No se ha generado correctamente el mapa de registros de quote'
            );
        System.assertEquals(
            NUM_ER_POLICY,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.POLICY).get('Policy__c').size(),
            'No se ha generado correctamente el mapa de registros de policy'
            );
        // FIXME:
        System.assertEquals(
            NUM_ER_INSURED_OBJECT,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INSURED_OBJECT).get('Asset').size(),
            'No se ha generado correctamente el mapa de registros de asset'
            );
        System.assertEquals(
            NUM_ER_CLAIM,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CLAIM).get('Claim__c').size(),
            'No se ha generado correctamente el mapa de registros de claim'
            );
        System.assertEquals(
            NUM_ER_QUOTE_RELATIONSHIP,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de quote relationship'
            );
        System.assertEquals(
            NUM_ER_POLICY_RELATIONSHIP,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de policy relationship'
            );
        System.assertEquals(
            NUM_ER_CLAIM_RELATIONSHIP,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CLAIM_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de claim relationship'
            );
        System.assertEquals(
            NUM_ER_PARTNER,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.PARTNER).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            );
        System.assertEquals(
            NUM_ER_INTERMEDIARY,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            );
        System.assertEquals(
                NUM_ER_NOTE,
                ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.NOTE).get('Case').size(),
                'No se ha generado correctamente el mapa de registros de Case'
                );
        System.assertEquals(
            NUM_ER_SPECIAL_CONDITION,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.SPECIAL_CONDITION).get('Special_Condition__c').size(),
            'No se ha generado correctamente el mapa de registros de Special_Condition__c'
            );
        System.assertEquals(
            NUM_ER_INTERMEDIARY_KPI,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY_KPI).get('KPI__c').size(),
            'No se ha generado correctamente el mapa de registros de KPI__c'
            );
        Assert.areEqual(
            NUM_ER_CONSENT,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONSENT).get('Consent__c').size(), 
            'No se ha generado correctamente el mapa de registros de Consent__c');
        Assert.areEqual(
            NUM_ER_ACCOUNT_SCORE_KPI,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT_SCORE_KPI).get('Account').size(), 
            'No se ha generado correctamente el mapa de registros de Account_SCORE_KPI');
        Assert.areEqual(
            NUM_ER_INTERMEDIARY_TNPS,
            ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY_TNPS).get(Schema.TNPS__c.sObjectType.getDescribe().getName()).size(), 
            'No se ha generado correctamente el mapa de registros de INTERMEDIARY_TNPS');
    }

    @isTest
    private static void test_process_delete_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        for(ExternalRequest__c externalRequest : externalRequestList)
        {
            if(externalRequest.Entity__c == INFOHandler.POLICY || externalRequest.Entity__c == INFOHandler.POLICY_RELATIONSHIP)
            {
                externalRequest.Processed__C = false;
                externalRequest.Action__C = 'DELETE';
            }
        }
        update externalRequestList;

        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account'); // 10 cuentas de personas físicas y 10 de personas jurídicas
        System.assertEquals(NUM_ER_LEGAL_ACCOUNT, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Contact').size(), 'No se ha generado correctamente el mapa de registros de contact');
        System.assertEquals(NUM_ER_CONTACT_POINT_ADDRESS, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointAddress').size(), 'No se ha generado correctamente el mapa de registros de contactPointAddress');
        System.assertEquals(NUM_ER_CONTACT_POINT_PHONE, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointPhone').size(), 'No se ha generado correctamente el mapa de registros de contactPointPhone');
        System.assertEquals(NUM_ER_CONTACT_POINT_EMAIL, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointEmail').size(), 'No se ha generado correctamente el mapa de registros de contactPointEmail');
        System.assertEquals(NUM_ER_PRODUCT, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.PRODUCT).get('Product2').size(), 'No se ha generado correctamente el mapa de registros de product');
        System.assertEquals(NUM_ER_QUOTE, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE).get('Opportunity').size(), 'No se ha generado correctamente el mapa de registros de opportunity');
        System.assertEquals(NUM_ER_QUOTE_OPTION, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE_OPTION).get('Quote').size(), 'No se ha generado correctamente el mapa de registros de quote');

        System.assertEquals(NUM_ER_INSURED_OBJECT, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INSURED_OBJECT).get('Asset').size(), 'No se ha generado correctamente el mapa de registros de asset');
        System.assertEquals(NUM_ER_CLAIM, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CLAIM).get('Claim__c').size(), 'No se ha generado correctamente el mapa de registros de claim');
        System.assertEquals(NUM_ER_QUOTE_RELATIONSHIP, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.QUOTE_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de quote relationship');
        System.assertEquals(NUM_ER_CLAIM_RELATIONSHIP, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CLAIM_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de claim relationship');
        System.assertEquals(NUM_ER_PARTNER, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.PARTNER).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account');
        System.assertEquals(NUM_ER_INTERMEDIARY, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account');

        System.assertEquals(0, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.POLICY).get('Policy__c').size(), 'No se ha generado correctamente el mapa de registros de policy');
        System.assertEquals(0, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de policy relationship');
        System.assertEquals(NUM_ER_POLICY, ExternalRequestHandlerUtil.recordsToDeleteByEntity.get(INFOHandler.POLICY).get('Policy__c').size(), 'No se ha generado correctamente el mapa de registros de borrado de policy');
        System.assertEquals(NUM_ER_POLICY_RELATIONSHIP, ExternalRequestHandlerUtil.recordsToDeleteByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de borrado de policy relationship');
        System.assertEquals(NUM_ER_NOTE, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.NOTE).get('Case').size(), 'No se ha generado correctamente el mapa de registros de Case');
        System.assertEquals(NUM_ER_SPECIAL_CONDITION, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.SPECIAL_CONDITION).get('Special_Condition__c').size(), 'No se ha generado correctamente el mapa de registros de Special_Condition__c');
        System.assertEquals(NUM_ER_INTERMEDIARY_KPI, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY_KPI).get('KPI__c').size(), 'No se ha generado correctamente el mapa de registros de KPI__c');
        Assert.areEqual(NUM_ER_CONSENT, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.CONSENT).get('Consent__c').size(), 'No se ha generado correctamente el mapa de registros de Consent__c');
        //Assert.areEqual(NUM_ER_ACCOUNT_SCORE_KPI, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT_SCORE_KPI).get('Account').size(), 'No se ha generado correctamente el mapa de registros de Account Score KPI');
        Assert.areEqual(NUM_ER_INTERMEDIARY_TNPS, ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY_TNPS).get('TNPS__c').size(), 'No se ha generado correctamente el mapa de registros de INTERMEDIARY_TNPS');
        
    }

    @isTest
    private static void test_process_ERROR_NoEntity()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Entity__c = 'TTTTTTTTTTTTTT';
        }

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        Integer totalExternalRequests = NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_CONTACT_POINT_ADDRESS + NUM_ER_CONTACT_POINT_EMAIL + 
                                        NUM_ER_CONTACT_POINT_PHONE +  NUM_ER_PRODUCT + NUM_ER_QUOTE + NUM_ER_QUOTE_OPTION + NUM_ER_POLICY + NUM_ER_INSURED_OBJECT +
                                        NUM_ER_CLAIM + NUM_ER_POLICY_RELATIONSHIP + NUM_ER_QUOTE_RELATIONSHIP + NUM_ER_CLAIM_RELATIONSHIP + NUM_ER_PARTNER + NUM_ER_INTERMEDIARY +
                                        NUM_ER_NOTE + NUM_ER_SPECIAL_CONDITION + NUM_ER_INTERMEDIARY_KPI + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_INTERMEDIARY_HIERARCHY + NUM_ER_CONSENT + NUM_ER_ACCOUNT_SCORE_KPI
                                        + NUM_ER_INTERMEDIARY_TNPS;

        System.assertEquals(
            totalExternalRequests,
            ExternalRequestHandlerUtil.externalRequestResultList.size(),
            'No se han marcado como erroneas todas las external request'
            );
    }

    @isTest
    private static void test_process_ERROR_NoPayload()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>([SELECT Entity__c, Action__c, Payload__c, ContentFormat__c, NumRetry__c, CreatedDate, Origin__c
                                                                                    FROM ExternalRequest__c
                                                                                    WHERE Origin__c = :INFOHandler.HANDLER_ORIGIN
                                                                                    AND Entity__c != 'INTERMEDIARY_HIERARCHY']); //

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Payload__c = null;
        }

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        Integer totalExternalRequests = NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_CONTACT_POINT_ADDRESS + NUM_ER_CONTACT_POINT_EMAIL + 
                                        NUM_ER_CONTACT_POINT_PHONE +  NUM_ER_PRODUCT + NUM_ER_QUOTE + NUM_ER_QUOTE_OPTION + NUM_ER_POLICY + NUM_ER_INSURED_OBJECT +
                                        NUM_ER_CLAIM + NUM_ER_POLICY_RELATIONSHIP + NUM_ER_QUOTE_RELATIONSHIP + NUM_ER_CLAIM_RELATIONSHIP + NUM_ER_PARTNER + NUM_ER_INTERMEDIARY +
                                        NUM_ER_NOTE + NUM_ER_SPECIAL_CONDITION + NUM_ER_INTERMEDIARY_KPI + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_CONSENT + NUM_ER_ACCOUNT_SCORE_KPI
                                        + NUM_ER_INTERMEDIARY_TNPS; 
                                        
        System.assertEquals(
            totalExternalRequests,
            ExternalRequestHandlerUtil.externalRequestResultList.size(),
            'No se han marcado como erroneas todas las external request'
            );
    }

    @isTest
    private static void test_persists_upsert_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
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
        List<Quote> quoteList = [SELECT Id FROM Quote];
        List<Policy__c> policyList = [SELECT Id FROM Policy__c];
        List<Asset> insObjList = [SELECT Id FROM Asset];
        List<Claim__c> claimList = [SELECT Id FROM Claim__c];
        List<Relationship__c> relaList = [SELECT Id FROM Relationship__c];
        List<Case> caseList = [SELECT Id FROM Case];
        List<Special_Condition__c> specialConditionList = [SELECT Id FROM Special_Condition__c];
        List<KPI__c> kpiList = [SELECT Id FROM KPI__c];
        List<Consent__c> consents = [SELECT Id FROM Consent__c];

        System.assertEquals(
            (NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_INTERMEDIARY_HIERARCHY) * 2,
            accountList.size(),
            'No se han insertado todos los registros de cuenta'
            );
        System.assertEquals(
            NUM_ER_LEGAL_ACCOUNT * 2,
            contactList.size(),
            'No se han insertado todos los registros de contacto'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_ADDRESS,
            cpaList.size(),
            'No se han insertado todos los registros de contactPointAddress'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_PHONE,
            cppList.size(),
            'No se han insertado todos los registros de contactPointPhone'
            );
        System.assertEquals(
            NUM_ER_CONTACT_POINT_EMAIL,
            cpeList.size(),
            'No se han insertado todos los registros de contactPointEmail'
            );
        System.assertEquals(
            NUM_ER_PRODUCT,
            prodList.size(),
            'No se han insertado todos los registros de producto'
            );
        System.assertEquals(
            NUM_ER_QUOTE,
            oppList.size(),
            'No se han insertado todos los registros de oferta'
            );
        System.assertEquals(
            NUM_ER_QUOTE_OPTION,
            quoteList.size(),
            'No se han insertado todos los registros de opciones de oferta'
            );
        System.assertEquals(
            NUM_ER_POLICY,
            policyList.size(),
            'No se han insertado todos los registros de póliza'
            );
        System.assertEquals(
            NUM_ER_INSURED_OBJECT,
            insObjList.size(),
            'No se han insertado todos los registros de objeto asegurado'
            );
        System.assertEquals(
            NUM_ER_CLAIM,
            claimList.size(),
            'No se han insertado todos los registros de siniestro'
            );
        // FIXME: System.assertEquals(
        //     30,
        //     relaList.size(),
        //     'No se han insertado todos los registros de relaciones'
        //     );
        System.assertEquals(
            NUM_ER_NOTE,
            caseList.size(),
            'No se han insertado todos los registros de Case'
            );
        System.assertEquals(
            NUM_ER_SPECIAL_CONDITION,
            specialConditionList.size(),
            'No se han insertado todos los registros de Special_Condition__c'
            );
        System.assertEquals(
            NUM_ER_INTERMEDIARY_KPI,
            kpiList.size(),
            'No se han insertado todos los registros de KPI__c'
            );
        Assert.areEqual(NUM_ER_CONSENT,
                        consents.size(),
                        'No se han insertado todos los registros de Consent__c');
    }

    @isTest
    private static void testPersistInsertOK()
    {
        List<ContactPointAddress> contactPointAddressList = new List<ContactPointAddress>();
        List<ContactPointPhone> contactPointPhoneList = new List<ContactPointPhone>();
        List<ContactPointEmail> contactPointEmailList = new List<ContactPointEmail>();
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        List<Product2> productList = new List<Product2>();
        List<Opportunity> offerList = new List<Opportunity>();
        List<Quote> quoteList = new List<Quote>();
        List<Asset> insuredObjectList = new List<Asset>();

        Test.startTest();
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);
        Set<String> origins = new Set<String> {INFOHandler.HANDLER_ORIGIN};
        List<ExternalRequest__c> externalRequestToDelete = new List<ExternalRequest__c>();

        List<ExternalRequest__c> externalRequestList = getExternalRequestsSelector().selectByOrigin(origins);

        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);

        contactPointAddressList = [SELECT Id FROM ContactPointAddress];
        contactPointPhoneList = [SELECT Id FROM ContactPointPhone];
        contactPointEmailList = [SELECT Id FROM ContactPointEmail];
        accountList = [SELECT Id FROM Account];
        contactList = [SELECT Id FROM Contact];
        productList = [SELECT Id FROM Product2];
        offerList = [SELECT Id FROM Opportunity];
        quoteList = [SELECT Id FROM Quote];
        insuredObjectList = [SELECT Id FROM Asset];
        Test.stopTest();
        
        Assert.areEqual(NUM_ER_CONTACT_POINT_ADDRESS, contactPointAddressList.size(), 'No se han insertado todos los registros de contactPointAddress');
        Assert.areEqual(NUM_ER_CONTACT_POINT_PHONE, contactPointPhoneList.size(), 'No se han insertado todos los registros de contactPointPhone');
        Assert.areEqual(NUM_ER_CONTACT_POINT_EMAIL, contactPointEmailList.size(), 'No se han insertado todos los registros de contactPointEmail');
        Assert.areEqual((NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_INTERMEDIARY_HIERARCHY) * 2, accountList.size(), 'No se han insertado todos los registros de cuenta');
        Assert.areEqual((NUM_ER_LEGAL_ACCOUNT) * 2, contactList.size(), 'No se han insertado todos los registros de contacto');
        Assert.areEqual(NUM_ER_PRODUCT, productList.size(), 'No se han insertado todos los registros de producto');
        Assert.areEqual(NUM_ER_QUOTE, offerList.size(), 'No se han insertado todos los registros de oferta');
        Assert.areEqual(NUM_ER_QUOTE_OPTION, quoteList.size(), 'No se han insertado todos los registros de opciones de oferta');
        Assert.areEqual(NUM_ER_INSURED_OBJECT, insuredObjectList.size(), 'No se han insertado todos los registros de objeto asegurado');
    }

    @isTest
    private static void testPersistDeleteOK_Account()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.ACCOUNT
        });
        Test.stopTest();

        List<Account> customerAccountList = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.CUSTOMER_RT_DEVELOPER_NAME];
        Assert.isTrue(customerAccountList.isEmpty(), 'No se han borrado todos los registros de Account (Customer)');
        List<Account> businessCustomerAccountList = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.BUSINESS_CUSTOMER_RT_DEVELOPER_NAME];
        Assert.isTrue(businessCustomerAccountList.isEmpty(), 'No se han borrado todos los registros de Account (BusinessCustomer)');
    }

    @isTest
    private static void testPersistDeleteOK_SpecialCondition()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.SPECIAL_CONDITION
        });
        Test.stopTest();

        List<Special_Condition__c> result = [SELECT Id FROM Special_Condition__c];
        Assert.isTrue(result.isEmpty(), 'No se han borrado todos los registros de Special_Condition__c');
    }

    @isTest
    private static void testPersistDeleteOK_KPI()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.INTERMEDIARY_KPI
        });
        Test.stopTest();

        List<KPI__c> intermediaryKpiList = [SELECT Id FROM KPI__c];
        Assert.isTrue(intermediaryKpiList.isEmpty(), 'No se han borrado todos los registros de KPI__c');
    }

    @isTest
    private static void testPersistDeleteOK_Consent()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.CONSENT
        });
        Test.stopTest();

        List<Consent__c> result = [SELECT Id FROM Consent__c];
        Assert.isTrue(result.isEmpty(), 'No se han borrado todos los registros de Consent__c');
    }

    @isTest
    private static void testPersistDeleteOK_Policy()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.POLICY
        });
        Test.stopTest();

        List<Policy__c> result = [SELECT Id FROM Policy__c];
        Assert.isTrue(result.isEmpty(), 'No se han borrado todos los registros de Policy__c');
    }

    @isTest
    private static void testPersistDeleteOK_Relationship()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.POLICY_RELATIONSHIP,
            INFOHandler.QUOTE_RELATIONSHIP,
            INFOHandler.CLAIM_RELATIONSHIP
        });
        Test.stopTest();

        List<Relationship__c> result = [SELECT Id FROM Relationship__c];
        Assert.isTrue(result.isEmpty(), 'No se han borrado todos los registros de Relationship__c');
    }

    @isTest
    private static void testPersistDeleteOK_Case()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.NOTE
        });
        Test.stopTest();

        List<Case> noteList = [SELECT Id FROM Case WHERE Origin = :INFOHandler.NOTE_CASE_ORIGIN];
        Assert.isTrue(noteList.isEmpty(), 'No se han borrado todos los registros de Caso (Origin = NOTE_CASE_ORIGIN)');
    }

    @isTest
    private static void testPersistDeleteOK_Claim()
    {
        Test.startTest();
        preparePersistDeleteTest(new Set<String>{
            INFOHandler.CLAIM
        });
        Test.stopTest();

        List<Claim__c> noteList = [SELECT Id FROM Claim__c];
        Assert.isTrue(noteList.isEmpty(), 'No se han borrado todos los registros de Claim__c');
    }

    @isTest
    private static void test_manageResult_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);
        Test.stopTest();

        List<ExternalRequest__c> externalRequestListUpdated = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                           { ExternalRequest__c.Entity__c,
                                                                                             ExternalRequest__c.Action__c,
                                                                                             ExternalRequest__c.Payload__c,
                                                                                             ExternalRequest__c.ContentFormat__c,
                                                                                             ExternalRequest__c.NumRetry__c,
                                                                                             ExternalRequest__c.Origin__c,
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        List<ExternalRequestError__c> externalRequestErrors = [
            SELECT Id
            FROM ExternalRequestError__c
            WHERE Origin__c = :INFOHandler.HANDLER_ORIGIN
        ];

        Integer totalExternalRequests = NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_CONTACT_POINT_ADDRESS + NUM_ER_CONTACT_POINT_EMAIL + 
                                        NUM_ER_CONTACT_POINT_PHONE +  NUM_ER_PRODUCT + NUM_ER_QUOTE + NUM_ER_QUOTE_OPTION + NUM_ER_POLICY + NUM_ER_INSURED_OBJECT +
                                        NUM_ER_CLAIM + NUM_ER_POLICY_RELATIONSHIP + NUM_ER_QUOTE_RELATIONSHIP + NUM_ER_CLAIM_RELATIONSHIP + NUM_ER_PARTNER + NUM_ER_INTERMEDIARY +
                                        NUM_ER_NOTE + NUM_ER_SPECIAL_CONDITION + NUM_ER_INTERMEDIARY_KPI + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_INTERMEDIARY_HIERARCHY + NUM_ER_CONSENT + NUM_ER_ACCOUNT_SCORE_KPI
                                        + NUM_ER_INTERMEDIARY_TNPS;

        System.assertEquals(
            totalExternalRequests,
            externalRequestListUpdated.size(),
            'No se han procesado todas las external request'
            );
        // FIXME:
        System.assertEquals(
            0,
            externalRequestErrors.size(),
            'Se han insertado external request erróneas en la entidad External Request Error'
            );
    }

    @isTest
    private static void test_manageResult_ERROR()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        externalRequestList.get(0).Payload__c = null;

        // Configuracion de los metadatos para el Test
        INFOHandler.mapEquivalencesByEntityTest = new Map<String, Map<String, String>>();
        createEquivalenceSettigs(INFOHandler.mapEquivalencesByEntityTest);

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);
        Test.stopTest();

        List<ExternalRequest__c> externalRequestListUpdated = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                           { ExternalRequest__c.Entity__c,
                                                                                             ExternalRequest__c.Action__c,
                                                                                             ExternalRequest__c.Payload__c,
                                                                                             ExternalRequest__c.ContentFormat__c,
                                                                                             ExternalRequest__c.NumRetry__c,
                                                                                             ExternalRequest__c.Origin__c,
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        List<ExternalRequestError__c> errors = [SELECT Id FROM ExternalRequestError__c];

        Integer totalExternalRequests = NUM_ER_NATURAL_ACCOUNT + NUM_ER_LEGAL_ACCOUNT + NUM_ER_CONTACT_POINT_ADDRESS + NUM_ER_CONTACT_POINT_EMAIL + 
                                        NUM_ER_CONTACT_POINT_PHONE +  NUM_ER_PRODUCT + NUM_ER_QUOTE + NUM_ER_QUOTE_OPTION + NUM_ER_POLICY + NUM_ER_INSURED_OBJECT +
                                        NUM_ER_CLAIM + NUM_ER_POLICY_RELATIONSHIP + NUM_ER_QUOTE_RELATIONSHIP + NUM_ER_CLAIM_RELATIONSHIP + NUM_ER_PARTNER + NUM_ER_INTERMEDIARY +
                                        NUM_ER_NOTE + NUM_ER_SPECIAL_CONDITION + NUM_ER_INTERMEDIARY_KPI + NUM_ER_INTERMEDIARY_GROUP + NUM_ER_INTERMEDIARY_HIERARCHY + NUM_ER_CONSENT + NUM_ER_ACCOUNT_SCORE_KPI
                                        + NUM_ER_INTERMEDIARY_TNPS;
        
        System.assertEquals(
            totalExternalRequests,
            externalRequestListUpdated.size(),
            'No se han procesado todas las external request'
            );
    }

    @isTest
    private static void test_getFirstAndLastName()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'NATURAL_ACCOUNT', 1);
        
        Map<String, Object> recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(externalRequestList[0].Payload__c);

        for ( String field : recordValuesMap.keySet() )
        {
            recordValuesMap.put(field.toUpperCase(), recordValuesMap.get(field));
        }

        Test.startTest();
        List<String> nameAndLastName = INFOHandler.getFirstAndLastName (recordValuesMap);
        Test.stopTest();

        System.assertEquals(false, nameAndLastName.isEmpty(), 'Debería de haber devuelto el nombre y apellidos');
        System.assertEquals('Name_1', nameAndLastName[0], 'El nombre no es correcto');
        System.assertEquals('Surname_1_1'+' '+'Surname_2_1', nameAndLastName[1], 'Los apellidos no son correctos');
    }

    @isTest
    private static void test_getLegalEntity()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'NATURAL_ACCOUNT', 1);
        
        Map<String, Object> recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(externalRequestList[0].Payload__c);

        for ( String field : recordValuesMap.keySet() )
        {
            recordValuesMap.put(field.toUpperCase(), recordValuesMap.get(field));
        }

        Test.startTest();
        String legalEntity = INFOHandler.getLegalEntity (recordValuesMap);
        Test.stopTest();

        System.assertEquals(false, legalEntity == null, 'La entidad legal no debería ser nula');
    }
}