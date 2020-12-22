/**
 * Clases de test para Batch_DeleteErrorLogs
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private class Test_Batch_DeleteErrorLogs
{
    private static final Integer NUM_OF_ERRORS = 10;

    /**
     * Create test data
     **
     * @author nbizkarra
     * @date 27/04/2020
     */
    @TestSetup
    static void test_CreateData()
    {
        Datetime fechaHora = Datetime.newInstance(1996, 10, 7, 18, 10, 7);

        List<Error_Log__c> errors = new List<Error_Log__c>();
        for (Integer i = 1; i <= NUM_OF_ERRORS; i++)
        {
            errors.add(
                new Error_Log__c(
                    Message__c = 'e.Message__c',
                    Source_Class__c = 'e.Source_Class__c',
                    Source_Method__c = 'e.Source_Method__c',
                    Level__c = 'Error',
                    Stack_Trace__c = 'e.Stack_Trace__c',
                    Job_ID__c = 'e.Job_ID__c',
                    Record_External_ID__c = 'e.Record_External_ID__c',
                    Record_Object__c = 'e.Record_Object__c',
                    Type_Name__c = 'e.Type_Name__c',
                    Throwing_time__c = fechaHora
                    )
                );
        }

        insert errors;
    }

    /**
     * El campo 'createdDate' de los registros de Error
       no son más antiguos que 7 días, no se elimina ningún regitro de Error.
     **
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    static void test_NoEliminarErrores()
    {
        Integer numErrores = [SELECT COUNT() FROM Error_Log__c];
        System.assertEquals(NUM_OF_ERRORS, numErrores);

        String query = 'SELECT Id FROM Error_Log__c WHERE createdDate < LAST_N_DAYS:7';
        Test.startTest();
        Id BatchInstanceId = database.executeBatch(
            new Batch_DeleteErrorLogs(query),
            200
            );
        Test.stopTest();

        numErrores = [SELECT COUNT() FROM Error_Log__c];
        System.assertEquals(NUM_OF_ERRORS, numErrores);
    }

    /**
     * Este método de test llama al Batch a través de una query personalizada
       y elimina todos los registros existentes de 'Error_Log__c' .
     * *
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    static void test_EliminarErrores()
    {
        Integer numErrores = [SELECT COUNT() FROM Error_Log__c];
        System.assertEquals(NUM_OF_ERRORS, numErrores);

        String query = 'SELECT Id FROM Error_Log__c WHERE Throwing_time__c < LAST_N_DAYS:7';

        Test.startTest();
        Batch_DeleteErrorLogs b = new Batch_DeleteErrorLogs(); // for coverage
        b = new Batch_DeleteErrorLogs(query);
        Id BatchInstanceId = database.executeBatch( b, 200 );
        Test.stopTest();

        numErrores = [SELECT COUNT() FROM Error_Log__c];
        System.assertEquals(0, numErrores);
    }


    /**
     * For testing Schedule
     */
    // @isTest
    // static void testBatch_schedule() {
    //   Batch_DeleteErrorLogs m = new Batch_DeleteErrorLogs();
    //   String sch = '20 30 8 10 2 ?';

    //   Test.startTest();
    //   String jobID = system.schedule('Delete error logs', sch, m);
    //   Test.stopTest();
    //   System.Debug('jobID: ' + jobID);
    // }
}