@isTest

public with sharing class SpliteEmailAddressTest {
    @isTest
    static void test_spliteEmailAddressTest_OK()
    {
        List<String> emailsToSplit=new List<String>();

        String twoEmails='email1@seidor.com; email2@seidor.com';

        emailsToSplit.add(twoEmails);


        SplitEmailAddress.FlowInputs flowInput= new SplitEmailAddress.FlowInputs();
		flowInput.stringToSplit=twoEmails;
        List<List<String>> listaReturn= new List<List<String>>();
        List<SplitEmailAddress.FlowInputs> listFlowInputs= new List<SplitEmailAddress.FlowInputs>();
        listFlowInputs.add(flowInput);

        Test.startTest();
        listaReturn= SplitEmailAddress.splitEmailAddress(listFlowInputs);
        Test.stopTest();
        
        System.assertEquals(2, listaReturn[0].size());
    }
}