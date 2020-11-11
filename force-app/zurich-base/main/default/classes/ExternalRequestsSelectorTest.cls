@isTest
private class ExternalRequestsSelectorTest
{
    @TestSetup
    static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10);
        insert externalRequestList;
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_null()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectByOrigin(null);
        Test.stopTest();

        System.assertEquals(true, selectedExtReq.isEmpty(), 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_ok()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(10, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_ok_limit()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).selectByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(1, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectPendingByRecordType_null()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectPendingByRecordType(null);
        Test.stopTest();

        System.assertEquals(true, selectedExtReq.isEmpty(), 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectPendingByRecordType_ok()
    {
        Id infoRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();

        List<ExternalRequest__c> externalRequestInserted = new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'});

        for(ExternalRequest__c externalRequest : externalRequestInserted)
        {
            externalRequest.Processed__c = false;
        }

        update externalRequestInserted;

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectPendingByRecordType(infoRecordTypeId);
        Test.stopTest();

        System.assertEquals(10, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectPendingByRecordType_ok_limit()
    {
        Id infoRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();

        List<ExternalRequest__c> externalRequestInserted = new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'});

        for(ExternalRequest__c externalRequest : externalRequestInserted)
        {
            externalRequest.Processed__c = false;
        }

        update externalRequestInserted;

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).selectPendingByRecordType(infoRecordTypeId);
        Test.stopTest();

        System.assertEquals(1, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectById_null()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectById(null);
        Test.stopTest();

        System.assertEquals(true, selectedExtReq.isEmpty(), 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectById_ok()
    {
        Set<Id> externalRequestIds = new Set<Id>();

        for( ExternalRequest__c externalRequest : new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'}) )
        {
            externalRequestIds.add(externalRequest.Id);
        }

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectById(externalRequestIds);
        Test.stopTest();

        System.assertEquals(10, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectById_ok_limit()
    {
        Set<Id> externalRequestIds = new Set<Id>();

        for( ExternalRequest__c externalRequest : new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'}) )
        {
            externalRequestIds.add(externalRequest.Id);
        }

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).selectById(externalRequestIds);
        Test.stopTest();

        System.assertEquals(1, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectProcessedByOrigin_null()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectProcessedByOrigin(null);
        Test.stopTest();

        System.assertEquals(true, selectedExtReq.isEmpty(), 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectProcessedByOrigin_ok()
    {
        List<ExternalRequest__c> externalRequestInserted = new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'});

        for(ExternalRequest__c externalRequest : externalRequestInserted)
        {
            externalRequest.ProcessResult__c = 'OK';
        }

        update externalRequestInserted;

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectProcessedByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(10, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectProcessedByOrigin_ok_limit()
    {
        List<ExternalRequest__c> externalRequestInserted = new ExternalRequestsSelector().selectByOrigin(new Set<String> {'INFO'});

        for(ExternalRequest__c externalRequest : externalRequestInserted)
        {
            externalRequest.ProcessResult__c = 'OK';
        }

        update externalRequestInserted;

        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).selectProcessedByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(1, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_queryLocatorPendingByRecordtype_null()
    {
        Test.startTest();
        Database.QueryLocator selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).queryLocatorPendingByRecordtype(null);
        Test.stopTest();

        System.assertEquals(null, selectedExtReq, 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_queryLocatorPendingByRecordtype_ok()
    {
        Id infoRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();

        Test.startTest();
        Database.QueryLocator selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).queryLocatorPendingByRecordtype(infoRecordTypeId);
        Test.stopTest();

        Integer numRecords = 0;
        Database.QueryLocatorIterator iterator = selectedExtReq.iterator();

        while ( iterator.hasNext() )
        {
            numRecords++;
            iterator.next();
        }

        System.assertEquals(10, numRecords, 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_queryLocatorPendingByRecordtype_ok_limit()
    {
        Id infoRecordTypeId = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();

        Test.startTest();
        Database.QueryLocator selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).queryLocatorPendingByRecordtype(infoRecordTypeId);
        Test.stopTest();

        Integer numRecords = 0;
        Database.QueryLocatorIterator iterator = selectedExtReq.iterator();

        while ( iterator.hasNext() )
        {
            numRecords++;
            iterator.next();
        }

        System.assertEquals(1, numRecords, 'No se han obtenido external request');
    }


}