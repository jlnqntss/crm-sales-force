/**
 * Clases de test para Batch_DeleteMasters
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private with sharing class Test_Batch_DeleteMasters
{
    /**
     * Create test data
     **
     * @author nbizkarra
     * @date 27/04/2020
     */
    @TestSetup
    private static void test_CreateData()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;
    }

    /**
     * **
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    private static void test_EliminarMaster()
    {
        Integer numMasters = [SELECT COUNT() FROM Account];
        System.assertEquals(1, numMasters);

        Test.startTest();
        Id BatchInstanceId = database.executeBatch(new Batch_DeleteMasters(), 200);
        Test.stopTest();

        numMasters = [SELECT COUNT() FROM Account];

        System.assertEquals(0, numMasters);
    }

    /**
     * Este método de test llama al Batch a través de una query personalizada.

     * *
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    private static void test_EliminarMasterQuery()
    {
        Integer numMasters = [SELECT COUNT() FROM Account];
        System.assertEquals(1, numMasters);

        String query = 'SELECT Id FROM Account  ';

        Test.startTest();
        Id BatchInstanceId = database.executeBatch(
            new Batch_DeleteMasters(query),
            200
            );
        Test.stopTest();

        numMasters = [SELECT COUNT() FROM Account];
        System.assertEquals(0, numMasters);
    }

    /**
     * For testing Schedule
     */
    @isTest
    private static void testBatch_schedule()
    {
        Batch_DeleteMasters m = new Batch_DeleteMasters();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        String jobID = system.schedule('Response External Request', sch, m);
        Test.stopTest();
        
    }
}