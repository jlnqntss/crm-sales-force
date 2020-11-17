/**
 * Clase de test para la clase INFOHandler
 **
 * @author adelgado
 * @date 15/10/2020
 */
@isTest
private class INFOHandlerTest
{
    @TestSetup
    static void makeData()
    {
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
            TestDataFactory.generateExternalRequest('INFO', 'CONTACT_POINT_ADDRESS', 10)
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

        //Opciones ofertas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'QUOTE_OPTION', 10)
            );

        //Pólizas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'POLICY', 10)
            );

        //Objetos asegurados
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'INSURED_OBJECT', 10)
            );

        //Siniestros
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'CLAIM', 10)
            );

        //Roles póliza
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'POLICY_RELATIONSHIP', 10)
            );

        //Roles oferta
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'QUOTE_RELATIONSHIP', 10)
            );

        //Roles siniestro
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'CLAIM_RELATIONSHIP', 10)
            );

        //Partner
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'PARTNER', 10)
            );

        //Mediador
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'INTERMEDIARY', 10)
            );

        insert externalRequestList;
    }

    @isTest
    static void test_prepare()
    {
        Transformer transformer = new Transformer('INFO');

        Set<String> objects = new Set<String>();

        for ( Transformer__mdt setting : TransformerSelector.selectMetadataByOrigin('INFO') )
        {
            objects.add(setting.OriginEntity__c);
        }

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c}).selectByOrigin(new Set<String> {'INFO'});

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        Test.stopTest();

        System.assertEquals(
            objects.size(),
            INFOHandler.recordsToUpsertByEntity.size(),
            'No se ha generado correctamente el mapa por entidades'
            );
        System.assertEquals(
            objects.size(),
            INFOHandler.recordsToDeleteByEntity.size(),
            'No se ha generado correctamente el mapa por entidades'
            );
    }

    @isTest
    static void test_process_upsert_OK()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(
            20,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            ); // 10 cuentas de personas físicas y 10 de personas jurídicas
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Contact').size(),
            'No se ha generado correctamente el mapa de registros de contact'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointAddress').size(),
            'No se ha generado correctamente el mapa de registros de contactPointAddress'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointPhone').size(),
            'No se ha generado correctamente el mapa de registros de contactPointPhone'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointEmail').size(),
            'No se ha generado correctamente el mapa de registros de contactPointEmail'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.PRODUCT).get('Product2').size(),
            'No se ha generado correctamente el mapa de registros de product'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE).get('Opportunity').size(),
            'No se ha generado correctamente el mapa de registros de opportunity'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE_OPTION).get('Quote').size(),
            'No se ha generado correctamente el mapa de registros de quote'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.POLICY).get('Policy__c').size(),
            'No se ha generado correctamente el mapa de registros de policy'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.INSURED_OBJECT).get('Asset').size(),
            'No se ha generado correctamente el mapa de registros de asset'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CLAIM).get('Claim__c').size(),
            'No se ha generado correctamente el mapa de registros de claim'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de quote relationship'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de policy relationship'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CLAIM_RELATIONSHIP).get('Relationship__c').size(),
            'No se ha generado correctamente el mapa de registros de claim relationship'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.PARTNER).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            );
        System.assertEquals(
            10,
            INFOHandler.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY).get('Account').size(),
            'No se ha generado correctamente el mapa de registros de account'
            );
    }

    @isTest
    static void test_process_delete_OK()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        for(ExternalRequest__c externalRequest : externalRequestList)
        {
            if(externalRequest.Entity__c == 'POLICY' || externalRequest.Entity__c == 'POLICY_RELATIONSHIP')
            {
                externalRequest.Processed__C = false;
                externalRequest.Action__C = 'DELETE';
            }
        }
        update externalRequestList;

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(20, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account'); // 10 cuentas de personas físicas y 10 de personas jurídicas
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.ACCOUNT).get('Contact').size(), 'No se ha generado correctamente el mapa de registros de contact');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointAddress').size(), 'No se ha generado correctamente el mapa de registros de contactPointAddress');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointPhone').size(), 'No se ha generado correctamente el mapa de registros de contactPointPhone');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CONTACT_POINT).get('ContactPointEmail').size(), 'No se ha generado correctamente el mapa de registros de contactPointEmail');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.PRODUCT).get('Product2').size(), 'No se ha generado correctamente el mapa de registros de product');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE).get('Opportunity').size(), 'No se ha generado correctamente el mapa de registros de opportunity');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE_OPTION).get('Quote').size(), 'No se ha generado correctamente el mapa de registros de quote');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.INSURED_OBJECT).get('Asset').size(), 'No se ha generado correctamente el mapa de registros de asset');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CLAIM).get('Claim__c').size(), 'No se ha generado correctamente el mapa de registros de claim');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.QUOTE_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de quote relationship');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.CLAIM_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de claim relationship');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.PARTNER).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account');
        System.assertEquals(10, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.INTERMEDIARY).get('Account').size(), 'No se ha generado correctamente el mapa de registros de account');

        System.assertEquals(0, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.POLICY).get('Policy__c').size(), 'No se ha generado correctamente el mapa de registros de policy');
        System.assertEquals(0, INFOHandler.recordsToUpsertByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de policy relationship');
        System.assertEquals(10, INFOHandler.recordsToDeleteByEntity.get(INFOHandler.POLICY).get('Policy__c').size(), 'No se ha generado correctamente el mapa de registros de borrado de policy');
        System.assertEquals(10, INFOHandler.recordsToDeleteByEntity.get(INFOHandler.POLICY_RELATIONSHIP).get('Relationship__c').size(), 'No se ha generado correctamente el mapa de registros de borrado de policy relationship');
    }

    @isTest
    static void test_process_ERROR_NoEntity()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Entity__c = 'TTTTTTTTTTTTTT';
        }

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(
            160,
            INFOHandler.externalRequestResultList.size(),
            'No se han marcado como erroneas todas las external request'
            );
    }

    @isTest
    static void test_process_ERROR_NoPayload()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Payload__c = null;
        }

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        Test.stopTest();

        System.assertEquals(
            160,
            INFOHandler.externalRequestResultList.size(),
            'No se han marcado como erroneas todas las external request'
            );
    }

    @isTest
    static void test_persists_upsert_OK()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

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

        System.assertEquals(
            40,
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
            quoteList.size(),
            'No se han insertado todos los registros de opciones de oferta'
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
            10,
            claimList.size(),
            'No se han insertado todos los registros de siniestro'
            );
        System.assertEquals(
            30,
            relaList.size(),
            'No se han insertado todos los registros de relaciones'
            );
    }

    @isTest
    static void test_persists_delete_OK()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);

        List<ExternalRequest__c> externalRequestListUpserted = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                            { ExternalRequest__c.Entity__c,
                                                                                              ExternalRequest__c.Action__c,
                                                                                              ExternalRequest__c.Payload__c,
                                                                                              ExternalRequest__c.ContentFormat__c,
                                                                                              ExternalRequest__c.NumRetry__c,
                                                                                              ExternalRequest__c.Origin__c,
                                                                                              ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        List<ExternalRequest__c> externalRequestToDelete = new List<ExternalRequest__c>();

        for(ExternalRequest__c externalRequest : externalRequestListUpserted)
        {
            if(externalRequest.Entity__c == 'POLICY' || externalRequest.Entity__c == 'POLICY_RELATIONSHIP')
            {
                externalRequest.Processed__C = false;
                externalRequest.Action__C = 'DELETE';
                externalRequestToDelete.add(externalRequest);
            }
        }
        update externalRequestToDelete;

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestToDelete);
        INFOHandler.persists(externalRequestToDelete);
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

        System.assertEquals(40, accountList.size(), 'No se han insertado todos los registros de cuenta');
        System.assertEquals(20, contactList.size(), 'No se han insertado todos los registros de contacto');
        System.assertEquals(10, cpaList.size(), 'No se han insertado todos los registros de contactPointAddress');
        System.assertEquals(10, cppList.size(), 'No se han insertado todos los registros de contactPointPhone');
        System.assertEquals(10, cpeList.size(), 'No se han insertado todos los registros de contactPointEmail');
        System.assertEquals(10, prodList.size(), 'No se han insertado todos los registros de producto');
        System.assertEquals(10, oppList.size(), 'No se han insertado todos los registros de oferta');
        System.assertEquals(10, quoteList.size(), 'No se han insertado todos los registros de opciones de oferta');
        System.assertEquals(0, policyList.size(), 'No se han borrado todos los registros de póliza');
        System.assertEquals(10, insObjList.size(), 'No se han insertado todos los registros de objeto asegurado');
        System.assertEquals(10, claimList.size(), 'No se han insertado todos los registros de siniestro');
        System.assertEquals(20, relaList.size(), 'No se han borrado todos los registros de relaciones');

    }

    @isTest
    static void test_manageResult_OK()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

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
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {'INFO'});

        List<ExternalRequestError__c> externalRequestErrors = [
            SELECT Id
            FROM ExternalRequestError__c
            WHERE Origin__c = 'INFO'
        ];

        System.assertEquals(
            160,
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
    static void test_manageResult_ERROR()
    {
        Transformer transformer = new Transformer('INFO');

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {'INFO'});

        externalRequestList.get(0).Payload__c = null;

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
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {'INFO'});

        List<ExternalRequestError__c> errors = [SELECT Id FROM ExternalRequestError__c];

        System.assertEquals(
            160,
            externalRequestListUpdated.size(),
            'No se han procesado todas las external request'
            );
        System.assertEquals(
            1,
            errors.size(),
            'No se han generado los errores correctamente'
            );
    }
}