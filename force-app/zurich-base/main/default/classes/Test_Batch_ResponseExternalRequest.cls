/**
 * Clases de test para Batch_ResponseExternalRequest
 **
 * @author nbizkarra
 * @date 05/04/2020
 *
 * @update nts (agonzalezisasi) - 27/oct/2020 - Include Multi-Partner logic and some corrections
 */
@isTest
public class Test_Batch_ResponseExternalRequest
{
    @TestSetup
    static void makeData()
    {
        // Es nesecesario indicar que el standard pricebook está activo para que el procesamiento no falle
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        // update standardPricebook;
    }

    @isTest
    static void testBatch()
    {
        List<ExternalRequest__c> ers = new List<ExternalRequest__c>();

        // IBA (spain)
        ExternalRequest__c er = new ExternalRequest__c(
            Timestamp__c = DateTime.now(),
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'test',
            Error_Log__c = '',
            Json__c = '{Test}',
            Processed__c = true,
            Sent__c = false,
            ProcessResult__c = 'OK',
            Retry__c = 0
            );
        ers.add(er);

        // IBA (not spain)
        er = new ExternalRequest__c(
            Timestamp__c = DateTime.now(),
            Origin__c = 'IBA',
            Country__c = 'France',
            Entity__c = 'test',
            Error_Log__c = '',
            Json__c = '{Test}',
            Processed__c = true,
            Sent__c = false,
            Retry__c = 0
            );
        ers.add(er);

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String WS_SOURCE_IBA_MULTI_PARTNER = adminSetup.WS_Source_IBA_Multi_Partner__c;
        // IBA (multi-partner)
        er = new ExternalRequest__c(
            Timestamp__c = DateTime.now(),
            Origin__c = WS_SOURCE_IBA_MULTI_PARTNER,
            Country__c = 'Spain',
            Entity__c = 'test',
            Error_Log__c = '',
            Json__c = '{Test}',
            Processed__c = true,
            Sent__c = false,
            Retry__c = 0
            );
        ers.add(er);

        insert ers;

        // Set mock class
        Test.setMock( HttpCalloutMock.class, new Mock_IBA_ResponseGenerator() );

        // Test
        Test.startTest();
        Id BatchInstanceId = Database.executeBatch(
            new Batch_ResponseExternalRequest(),
            10
            );
        Test.stopTest();

        // Check results
        List<ExternalRequest__c> ersResult = [SELECT id, Sent__c FROM ExternalRequest__c];
        for( ExternalRequest__c e: ersResult)
        {
            System.assertEquals(true, e.Sent__c);
        }
    }

    /**
     * For testing process result NO ok, status request no 200 and for coverage
     * @change: nts (agonzalezisasi) - 11/dic/2020 - Include response error log 
     */
    @isTest
    static void testBatch_nok()
    {
        ExternalRequest__c er = new ExternalRequest__c(
            Timestamp__c = DateTime.now(),
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'test',
            Error_Log__c = '',
            Json__c = '{Test KO}',
            Processed__c = true,
            Sent__c = false,
            Retry__c = 0,
            ProcessResult__c = 'KO'
            );

        insert er;

        Test.setMock( HttpCalloutMock.class, new Mock_IBA_ResponseGenerator() );

        Test.startTest();
        Batch_ResponseExternalRequest b = new Batch_ResponseExternalRequest('select'); // for coverage
        b = new Batch_ResponseExternalRequest();
        Id BatchInstanceId = Database.executeBatch( b, 10 );
        Test.stopTest();
        // Check results
        List<ExternalRequest__c> ersResult = [SELECT id, Retry__c, Error_Log_Response__c FROM ExternalRequest__c];
        for( ExternalRequest__c e: ersResult)
        {
            System.assertEquals(1, e.Retry__c);
            System.assertNotEquals(null, e.Error_Log_Response__c);
        }
    }

    /**
     * For testing Schedule
     */
    @isTest
    static void testBatch_schedule()
    {
        Batch_ResponseExternalRequest m = new Batch_ResponseExternalRequest();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        String jobID = system.schedule('Response External Request', sch, m);
        Test.stopTest();
        
    }
}