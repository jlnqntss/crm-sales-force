@IsTest(SeeAllData=true)    
private with sharing class DynamicSelectorTest {
    

    @IsTest(SeeAllData=true)    
    private static void test_getQueryStringMetadataInfoToExport_matchedRecord()
    {
        List<Export_CSV_Field__mdt> listMatchedRecords= new List<Export_CSV_Field__mdt>();
        Export_CSV_Field__mdt metadataFieldObject = new Export_CSV_Field__mdt();
        String sobjectName='Case';

        metadataFieldObject= [SELECT Id,FieldToExport__c,Labels__c FROM Export_CSV_Field__mdt WHERE Object__c=:sobjectName];

        // Test
        Test.startTest();
        listMatchedRecords = new DynamicSelector(metadataFieldObject.getsobjectType()).getQueryStringMetadataInfoToExport(sobjectName);
        Test.stopTest();

        System.assertEquals(listMatchedRecords[0].FieldToExport__c,metadataFieldObject.FieldToExport__c);
        System.assertEquals(listMatchedRecords[0].Labels__c,metadataFieldObject.Labels__c);
    }


    @IsTest(SeeAllData=true)    
    private static void test_GetRecordsExportsButton_matchedRecord()
    {
        List<SObject> objectsExport= new List<SObject>();

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 2);
        insert cases;

        List<String> listIdsRecordsExports= new List<String>();

        for(Case record: cases)
        {
            listIdsRecordsExports.add(record.Id);
        }

        String fieldsQuery='Id,CaseNumber';
        String objetExportName='Case';

        // Test
        Test.startTest();
        objectsExport= new DynamicSelector(cases[0].getsobjectType()).getListSobjectToExport(fieldsQuery,objetExportName,listIdsRecordsExports);
        Test.stopTest();

        System.assertEquals(objectsExport.size(),2);

    }

    
}