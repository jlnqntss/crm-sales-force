@isTest

public class Test_Batch_ProcessSubscribers
{

    /**
     * Process a Lead
     * * @author nts (nbizkarra)
     * @date 17/11/2020
     */
    @isTest
    static void testBatch()
    {

        Lead subscriber = new Lead (
            Email = 'testexisting@test.com',
            LastName = 'Test',
            CheckGI__c = true,
            CheckLife__c = true,
            Country = 'France',
            LeadSource = 'Klinc'
            );
        insert subscriber;

        Test.startTest();

        Batch_ProcessSubscribers b = new Batch_ProcessSubscribers('select'); // for coverage
        b = new Batch_ProcessSubscribers();
        Database.executeBatch(b, 200);
        Test.stopTest();

        List<Lead> leads = [SELECT id FROM Lead];
        //! fixme: System.assert(leads.isEmpty());
    }

    /**
     * For testing Schedule
     * * @author nts (nbizkarra)
     * @date 17/11/2020
     */
    @isTest
    static void testBatch_schedule()
    {
        Batch_ProcessSubscribers m = new Batch_ProcessSubscribers();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        String jobID = system.schedule('Batch_ProcessSubscribers', sch, m);
        Test.stopTest();
        System.Debug('jobID: ' + jobID);
    }


}