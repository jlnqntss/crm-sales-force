@isTest
private with sharing class ContactsSelectorTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = new List<Account>
        {
            new Account (
                Name = 'Test 1'
                ),
            new Account (
                Name = 'Test 2'
                )
        };

        insert accounts;
    }

    @isTest
    static void test_matchedRecordIds_mathedRecords()
    {
    }
}
