/**
 * Clase de test para CollectionUtil
 *
 * @group Tests
 */
@isTest
private with sharing class CollectionUtilTest
{
    //#region Scenario
    //  #region Constants
    private final static List<String> ACCOUNT_TYPES;
    private final static List<Integer> ACCOUNT_NUMBER_OF_EMPLOYEES;
    private final static List<Double> ACCOUNT_ANNUAL_REVENUE;

    static
    {
        // 1 - Init account picklist values
        // 1.1 - Type field describe
        ACCOUNT_TYPES = new List<String>();

        for ( Schema.PicklistEntry p : Account.Type.getDescribe().getPicklistValues() )
        {
            ACCOUNT_TYPES.add( p.getValue() );
        }

        // 1.2 - WorkAround if there are no type values
        if(ACCOUNT_TYPES[0] == null)
            ACCOUNT_TYPES[0] = 'A';
        if(ACCOUNT_TYPES[1] == null)
            ACCOUNT_TYPES[1] = 'B';

        // 2 - Generate random number constants
        // 2.1 - NumberOfEmployees field values (Number 8,0)
        ACCOUNT_NUMBER_OF_EMPLOYEES = new List<Integer>
        {
            1000,
            5000,
            10000
        };

        // 2.2 - AnnualRevenue field values (Number 18,0)
        ACCOUNT_ANNUAL_REVENUE = new List<Double>
        {
            128160,
            50000000
        };
    }
    //  #endregion

    //  #region TestSetup
    @TestSetup
    private static void generateScenario()
    {
        // 1 - Generate Fake Accounts
        List<Account> accountList = new List<Account>
        {
            new Account(
                Name = 'A',
                NumberOfEmployees = ACCOUNT_NUMBER_OF_EMPLOYEES[0],
                AnnualRevenue = ACCOUNT_ANNUAL_REVENUE[0],
                Type = ACCOUNT_TYPES[0]
                ),
            new Account(
                Name = 'B',
                NumberOfEmployees = ACCOUNT_NUMBER_OF_EMPLOYEES[1],
                AnnualRevenue = ACCOUNT_ANNUAL_REVENUE[1],
                Type = ACCOUNT_TYPES[0]
                ),
            new Account(
                Name = 'C',
                NumberOfEmployees = ACCOUNT_NUMBER_OF_EMPLOYEES[2],
                AnnualRevenue = ACCOUNT_ANNUAL_REVENUE[1],
                Type = ACCOUNT_TYPES[1]
                ),
            new Account(
                Name = 'D',
                NumberOfEmployees = ACCOUNT_NUMBER_OF_EMPLOYEES[2],
                AnnualRevenue = ACCOUNT_ANNUAL_REVENUE[1],
                Type = ACCOUNT_TYPES[1]
                )
        };

        insert accountList;

        // 2 - Generate Fake Contacts
        insert new List<Contact>
        {
            new Contact(
                LastName = 'A',
                AccountId = accountList[0].Id,
                DoNotCall = false
                ),
            new Contact(
                LastName = 'B',
                AccountId = accountList[0].Id,
                DoNotCall = false
                ),
            new Contact(
                LastName = 'C',
                AccountId = accountList[0].Id,
                DoNotCall = false
                ),
            new Contact(
                LastName = 'D',
                AccountId = accountList[1].Id,
                DoNotCall = true
                ),
            new Contact(
                LastName = 'E',
                AccountId = accountList[1].Id,
                DoNotCall = true
                ),
            new Contact(
                LastName = 'F',
                AccountId = accountList[1].Id,
                DoNotCall = true
                )
        };

        // 3 - generate fake case (test date field)
        insert new List<Case>
        {
            new Case(
                Subject = 'A',
                DateReg__c = date.newInstance(2024, 11, 21),
                RecordTypeId = CaseUtil.RT_ID_ZDA
                ),
            new Case(
                Subject = 'B',
                DateReg__c = date.newInstance(2023, 11, 21),
                RecordTypeId = CaseUtil.RT_ID_ZDA
                )
        };
    }
    //  #endregion
    //#endregion

    //#region Test CollectionUtil.GroupListBy - sObject
    @isTest
    private static void groupListBy_testNoRows()
    {
        // When
        Test.startTest();

        Map<String, List<Account> > accountListMap = (Map<String, List<Account> >) CollectionUtil.groupListBy(new List<Account> (), 'Type');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountListMap, 'groupListBy_testNoRows: The generated map is null');
        Assert.isTrue(accountListMap.values().isEmpty(), 'groupListBy_testNoRows: The generated map is not empty');
    }


    @isTest
    private static void groupListBy_testNull()
    {
        // When
        Test.startTest();
        List<Account> accList = null;

        Map<String, List<Account> > accountListMap = (Map<String, List<Account> >) CollectionUtil.groupListBy(accList, 'Type');

        Test.stopTest();

        // Then
        Assert.isNull(accountListMap, 'groupListBy_testNull: The generated map is not null');
    }

    @isTest
    private static void groupListBy_testIdKey()
    {
        // When
        Test.startTest();

        Map<Id, List<Contact> > contactListMap = (Map<Id, List<Contact> >) CollectionUtil.groupListBy([SELECT Id, LastName, AccountId FROM Contact], 'AccountId');

        Test.stopTest();

        // Then
        Assert.isNotNull(contactListMap, 'groupListBy_testIdKey: The generated map is null');
        Assert.areEqual( 2, contactListMap.keySet().size(), 'groupListBy_testIdKey: Expected 2 groups in map, found ' + contactListMap.keySet().size() );
    }

    @isTest
    private static void groupListBy_testDateKey()
    {
        // When
        Test.startTest();

        Map<Date, List<Case> > caseListMap = (Map<Date, List<Case> >) CollectionUtil.groupListBy([SELECT Id, DateReg__c FROM Case], 'DateReg__c');

        Test.stopTest();

        // Then
        Assert.isNotNull(caseListMap, 'groupListBy_testDateKey: The generated map is null');
        Assert.areEqual( 2, caseListMap.keySet().size(), 'groupListBy_testDateKey: Expected 2 groups in map, found ' + caseListMap.keySet().size() );
    }

    @isTest
    private static void groupListBy_testStringKey()
    {
        // When
        Test.startTest();

        Map<String, List<Account> > accountListMap = (Map<String, List<Account> >) CollectionUtil.groupListBy([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'Type');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountListMap, 'groupListBy_testStringKey: The generated map is null');
        Assert.isTrue(accountListMap.containsKey(ACCOUNT_TYPES[0]) && accountListMap.containsKey(ACCOUNT_TYPES[1]), 'groupListBy_testStringKey: Keys ACCOUNT_TYPES[0] and ACCOUNT_TYPES[1] not found on generated map.');
        Assert.areEqual( 2, accountListMap.get(ACCOUNT_TYPES[1]).size(), 'groupListBy_testStringKey: Expected 2 accounts in the list group by ACCOUNT_TYPES[1], found ' + accountListMap.get(ACCOUNT_TYPES[1]).size() );
    }


    @isTest
    private static void groupListBy_testIntegerKey()
    {
        // When
        Test.startTest();

        Map<Integer, List<Account> > accountListMap = (Map<Integer, List<Account> >) CollectionUtil.groupListBy([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'NumberOfEmployees');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountListMap, 'groupListBy_testIntegerKey: The generated map is null');
        Assert.isTrue( accountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[0]) && accountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[1]) && accountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[2]), 'groupListBy_testIntegerKey: Keys ACCOUNT_NUMBER_OF_EMPLOYEES[0], ACCOUNT_NUMBER_OF_EMPLOYEES[1] and ACCOUNT_NUMBER_OF_EMPLOYEES[2] not found on generated map.');
        Assert.areEqual( 1, accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).size(), 'groupListBy_testIntegerKey: Expected 1 accounts in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[1] found ' + accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).size() );
        Assert.areEqual( 1, accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).size(), 'groupListBy_testIntegerKey: Expected 1 accounts in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[0], found ' + accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).size() );
        Assert.areEqual( 2, accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).size(), 'groupListBy_testIntegerKey: Expected 3 accounts in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[2], found ' + accountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).size() );
    }

    @isTest
    private static void groupListBy_testDoubleKey()
    {
        // When
        Test.startTest();

        Map<Double, List<Account> > accountListMap = (Map<Double, List<Account> >) CollectionUtil.groupListBy([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'AnnualRevenue');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountListMap, 'groupListBy_testDoubleKey: The generated map is null');
        Assert.isTrue(accountListMap.containsKey(ACCOUNT_ANNUAL_REVENUE[0]) && accountListMap.containsKey(ACCOUNT_ANNUAL_REVENUE[1]), 'groupListBy_testDoubleKey: Keys ACCOUNT_ANNUAL_REVENUE[0] and ACCOUNT_ANNUAL_REVENUE[1] not found on generated map.');
        Assert.areEqual( 3, accountListMap.get(ACCOUNT_ANNUAL_REVENUE[1]).size(), 'groupListBy_testDoubleKey: Expected 3 accounts in the list group by ACCOUNT_ANNUAL_REVENUE[1] found ' + accountListMap.get(ACCOUNT_ANNUAL_REVENUE[1]).size() );
        Assert.areEqual( 1, accountListMap.get(ACCOUNT_ANNUAL_REVENUE[0]).size(), 'groupListBy_testDoubleKey: Expected 3 accounts in the list group by ACCOUNT_ANNUAL_REVENUE[0], found ' + accountListMap.get(ACCOUNT_ANNUAL_REVENUE[0]).size() );
    }

    @isTest
    private static void groupListBy_testBooleanKey()
    {
        // When
        Test.startTest();

        Map<Boolean, List<Contact> > contactListMap = (Map<Boolean, List<Contact> >) CollectionUtil.groupListBy([SELECT Id, LastName, DoNotCall FROM Contact], 'DoNotCall');

        Test.stopTest();

        // Then
        Assert.isNotNull(contactListMap, 'groupListBy_testBooleanKey: The generated map is null');
        Assert.isTrue(contactListMap.containsKey(true) && contactListMap.containsKey(false), 'groupListBy_testIntegerKey: Keys true and false not found on generated map.');
        Assert.areEqual( 3, contactListMap.get(true).size(), 'groupListBy_testBooleanKey: Expected 3 contacts in the list group by true found ' + contactListMap.get(true).size() );
        Assert.areEqual( 3, contactListMap.get(false).size(), 'groupListBy_testBooleanKey: Expected 3 contacts in the list group by false, found ' + contactListMap.get(false).size() );
    }

    @isTest
    private static void groupListBy_testDatetimeKey()
    {


        // When
        Test.startTest();

        Map<Datetime, List<Contact> > contactListMap = (Map<Datetime, List<Contact> >) CollectionUtil.groupListBy([SELECT Id, LastName, DoNotCall, CreatedDate FROM Contact], 'CreatedDate');

        Test.stopTest();

        // Then
        Assert.isNotNull(contactListMap, 'groupListBy_testDatetimeKey: The generated map is null.');
        Assert.areEqual(1, contactListMap.keySet().size(), 'groupListBy_testDatetimeKey: Found more than one key in the map.');
        Assert.areEqual( 6, contactListMap.values()[0].size(), 'groupListBy_testDatetimeKey: Expected 6 contacts in the list group by CreatedDate found ' + contactListMap.values()[0].size() );
    }
    //#endregion

    //#region Test CollectionUtil.hashList
    @isTest
    private static void hashList_testNoRows()
    {


        // When
        Test.startTest();

        Map<String, Account> accountMap = (Map<String, Account>) CollectionUtil.hashList(new List<Account> (), 'Type');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountMap, 'groupListBy_testNoRows: The generated map is null');
        Assert.isTrue(accountMap.values().isEmpty(), 'groupListBy_testNoRows: The generated map is not empty');
    }

    @isTest
    private static void hashList_testNull()
    {


        // When
        Test.startTest();

        Map<String, Account> accountMap = (Map<String, Account>) CollectionUtil.hashList( (List<Account>) null, 'Type' );

        Test.stopTest();

        // Then
        Assert.isNull(accountMap, 'groupListBy_testNull: The generated map is not null');
    }

    @isTest
    private static void hashList_testIdKey()
    {
        // When
        Test.startTest();

        Map<Id, Account> accountListMap = (Map<Id, Account>) CollectionUtil.hashList([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'Id');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountListMap, 'groupListBy_testStringKeyy: The generated map is null');
        Assert.areEqual( 4, accountListMap.values().size(), 'groupListBy_testStringKey: Expected 4 accounts in the map, found ' + accountListMap.values().size() );
    }

    @isTest
    private static void hashList_testDateKey()
    {
        // When
        Test.startTest();

        Map<Date, Case> caseListMap = (Map<Date, Case>) CollectionUtil.hashList([SELECT Id, DateReg__c FROM Case], 'DateReg__c');

        Test.stopTest();

        // Then
        Assert.isNotNull(caseListMap, 'hashList_testDateKey: The generated map is null');
        Assert.areEqual( 2, caseListMap.values().size(), 'hashList_testDateKey: Expected 2 cases in the map, found ' + caseListMap.values().size() );
    }

    @isTest
    private static void hashList_testStringKey()
    {
        // When
        Test.startTest();

        Map<String, Account> accountMap = (Map<String, Account>) CollectionUtil.hashList([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'Name');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountMap, 'hashList_testStringKey: The generated map is null');
        Assert.areEqual( 4, accountMap.values().size(), 'hashList_testStringKey: Expected 4 accounts, found ' + accountMap.values().size() );
    }

    @isTest
    private static void hashList_testDoubleKey()
    {


        // When
        Test.startTest();

        Map<Double, Account> accountMap = (Map<Double, Account>) CollectionUtil.hashList([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'AnnualRevenue');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountMap, 'hashList_testDoubleKey: The generated map is null');
        Assert.isTrue(accountMap.containsKey(ACCOUNT_ANNUAL_REVENUE[0]) && accountMap.containsKey(ACCOUNT_ANNUAL_REVENUE[1]), 'hashList_testDoubleKey: Keys ACCOUNT_ANNUAL_REVENUE[0] and ACCOUNT_ANNUAL_REVENUE[1] not found on generated map.');
    }

    @isTest
    private static void hashList_testIntegerKey()
    {


        // When
        Test.startTest();

        Map<Integer, Account> accountMap = (Map<Integer, Account>) CollectionUtil.hashList([SELECT Id, Name, AnnualRevenue, NumberOfEmployees, Type FROM Account], 'NumberOfEmployees');

        Test.stopTest();

        // Then
        Assert.isNotNull(accountMap, 'hashList_testIntegerKey: The generated map is null');
        Assert.areEqual( 3, accountMap.values().size(), 'hashList_testIntegerKey: Expected 3 accounts in the map found ' + accountMap.values().size() );
    }

    @isTest
    private static void hashList_testBooleanKey()
    {


        // When
        Test.startTest();

        Map<Boolean, Contact> contactMap = (Map<Boolean, Contact>) CollectionUtil.hashList([SELECT Id, LastName, DoNotCall FROM Contact], 'DoNotCall');

        Test.stopTest();

        // Then
        Assert.isNotNull(contactMap, 'hashList_testBooleanKey: The generated map is null');
        Assert.areEqual( 2, contactMap.values().size(), 'hashList_testBooleanKey: Expected 2 contacts in the map found ' + contactMap.values().size() );
    }

    @isTest
    private static void hashList_testDatetimeKey()
    {


        // When
        Test.startTest();

        Map<Datetime, Contact> contactMap = (Map<Datetime, Contact>) CollectionUtil.hashList([SELECT Id, LastName, DoNotCall, CreatedDate FROM Contact], 'CreatedDate');

        Test.stopTest();

        // Then
        Assert.isNotNull(contactMap, 'hashList_testDatetimeKey: The generated map is null.');
        Assert.areEqual(1, contactMap.keySet().size(), 'hashList_testDatetimeKey: Found more than one key in the map.');
        Assert.areEqual( 1, contactMap.values().size(), 'hashList_testDatetimeKey: Expected 1 contacts in the map CreatedDate found ' + contactMap.values().size() );
    }
    //#endregion


    //#region Test CollectionUtil.GroupListBy - AggregateResult
    @isTest
    private static void groupListBy_testAggregateResult_NoRows()
    {
        // When
        Test.startTest();

        CollectionUtil.CollectionException expectedException;

        try
        {
            Map<String, List<AggregateResult> > aggregateAccountListMap = (Map<String, List<AggregateResult> >) CollectionUtil.groupListBy(new List<AggregateResult> (), 'Type');
        }
        catch(CollectionUtil.CollectionException ex)
        {
            expectedException = ex;
        }


        Test.stopTest();

        // Then
        Assert.isNotNull(expectedException, 'groupListBy_testAggregateResult_NoRows: CollectionException non captured');

    }


    @isTest
    private static void groupListBy_testAggregateResult_Null()
    {
        // When
        Test.startTest();
        List<AggregateResult> aggList = null;

        Map<String, List<AggregateResult> > aggregateAccountListMap = (Map<String, List<AggregateResult> >) CollectionUtil.groupListBy(aggList, 'Type');

        Test.stopTest();

        // Then
        Assert.isNull(aggregateAccountListMap, 'groupListBy_testAggregateResult_Null: The generated map is not null');
    }

    @isTest
    private static void groupListBy_testAggregateResult_IdKey()
    {
        // When
        Test.startTest();

        Map<Id, List<AggregateResult> > aggregateContactListMap = (Map<Id, List<AggregateResult> >) CollectionUtil.groupListBy([SELECT Count(Id), AccountId FROM Contact GROUP BY AccountId], 'AccountId');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregateContactListMap, 'groupListBy_testAggregateResult_IdKey: The generated map is null');
        Assert.areEqual( 2, aggregateContactListMap.keySet().size(), 'groupListBy_testAggregateResult_IdKey: Expected 2 groups in map, found ' + aggregateContactListMap.keySet().size() );
    }

    @isTest
    private static void groupListBy_testAggregateResult_StringKey()
    {
        // When
        Test.startTest();

        Map<String, List<AggregateResult> > aggregatedAccountListMap = (Map<String, List<AggregateResult> >) CollectionUtil.groupListBy([SELECT COUNT(Id), SUM(AnnualRevenue), NumberOfEmployees, Type FROM Account GROUP BY NumberOfEmployees, Type ], 'Type');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedAccountListMap, 'groupListBy_testAggregateResult_StringKey: The generated map is null');
        Assert.isTrue( aggregatedAccountListMap.containsKey(ACCOUNT_TYPES[0]) && aggregatedAccountListMap.containsKey(ACCOUNT_TYPES[1]), 'groupListBy_testAggregateResult_StringKey: Keys ACCOUNT_TYPE[0], and ACCOUNT_TYPE[1] not found on generated map.');
        Assert.areEqual( 2, aggregatedAccountListMap.get(ACCOUNT_TYPES[0]).size(), 'groupListBy_testAggregateResult_StringKey: Expected 2 aggregated results in the list group by ACCOUNT_TYPE[0] found ' + aggregatedAccountListMap.get(ACCOUNT_TYPES[0]).size() );
        Assert.areEqual( 1, aggregatedAccountListMap.get(ACCOUNT_TYPES[1]).size(), 'groupListBy_testAggregateResult_StringKey: Expected 1 aggregated results in the list group by ACCOUNT_TYPE[1], found ' + aggregatedAccountListMap.get(ACCOUNT_TYPES[1]).size() );
    }


    @isTest
    private static void groupListBy_testAggregateResult_IntegerKey()
    {
        // When
        Test.startTest();

        Map<Integer, List<AggregateResult> > aggregatedAccountListMap = (Map<Integer, List<AggregateResult> >) CollectionUtil.groupListBy([SELECT COUNT(Id), SUM(AnnualRevenue), NumberOfEmployees FROM Account GROUP BY NumberOfEmployees, Type ], 'NumberOfEmployees');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedAccountListMap, 'groupListBy_testIntegerKey: The generated map is null');
        Assert.isTrue( aggregatedAccountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[0]) && aggregatedAccountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[1]) && aggregatedAccountListMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[2]), 'groupListBy_testIntegerKey: Keys ACCOUNT_NUMBER_OF_EMPLOYEES[0], ACCOUNT_NUMBER_OF_EMPLOYEES[1] and ACCOUNT_NUMBER_OF_EMPLOYEES[2] not found on generated map.');
        Assert.areEqual( 1, aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).size(), 'groupListBy_testIntegerKey: Expected 1 aggregated results in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[1] found ' + aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).size() );
        Assert.areEqual( 1, aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).size(), 'groupListBy_testIntegerKey: Expected 1 aggregated results in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[0], found ' + aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).size() );
        Assert.areEqual( 1, aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).size(), 'groupListBy_testIntegerKey: Expected 2 aggregated results in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[2], found ' + aggregatedAccountListMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).size() );
    }

    @isTest
    private static void groupListBy_testAggregateResult_BooleanKey()
    {
        // When
        Test.startTest();

        Map<Boolean, List<AggregateResult> > aggregatedContactListMap = (Map<Boolean, List<AggregateResult> >) CollectionUtil.groupListBy([SELECT COUNT(Id), DoNotCall, AccountId FROM Contact GROUP BY DoNotCall, AccountId], 'DoNotCall');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedContactListMap, 'groupListBy_testAggregateResult_BooleanKey: The generated map is null');
        Assert.isTrue(aggregatedContactListMap.containsKey(true) && aggregatedContactListMap.containsKey(false), 'groupListBy_testIntegerKey: Keys true and false not found on generated map.');
        Assert.areEqual( 1, aggregatedContactListMap.get(true).size(), 'groupListBy_testAggregateResult_BooleanKey: Expected 3 aggregated results in the list group by true found ' + aggregatedContactListMap.get(true).size() );
        Assert.areEqual( 1, aggregatedContactListMap.get(false).size(), 'groupListBy_testAggregateResult_BooleanKey: Expected 3 aggregated results in the list group by false, found ' + aggregatedContactListMap.get(false).size() );
    }
    //#endregion


    //#region Test CollectionUtil.hashList - AggregateResult
    @isTest
    private static void hashList_testAggregateResult_NoRows()
    {
        // When
        Test.startTest();

        CollectionUtil.CollectionException expectedException;

        try
        {
            Map<String, AggregateResult> aggregateAccountMap = (Map<String, AggregateResult>) CollectionUtil.hashList(new List<AggregateResult> (), 'Type');
        }
        catch(CollectionUtil.CollectionException ex)
        {
            expectedException = ex;
        }


        Test.stopTest();

        // Then
        Assert.isNotNull(expectedException, 'hashList_testAggregateResult_NoRows: CollectionException not captured');

    }

    @isTest
    private static void hashList_testAggregateResult_Null()
    {
        // When
        Test.startTest();

        List<AggregateResult> aggList = null;

        Map<String, AggregateResult> aggregateAccountMap = (Map<String, AggregateResult>) CollectionUtil.groupListBy(aggList, 'Type');

        Test.stopTest();

        // Then
        Assert.isNull(aggregateAccountMap, 'hashList_testAggregateResult_Null: The generated map is not null');
    }

    @isTest
    private static void hashList_testAggregateResult_IdKey()
    {
        // When
        Test.startTest();

        Map<Id, AggregateResult> aggregateContactMap = (Map<Id, AggregateResult>) CollectionUtil.hashList([SELECT Count(Id), AccountId FROM Contact GROUP BY AccountId], 'AccountId');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregateContactMap, 'hashList_testAggregateResult_IdKey: The generated map is null');
        Assert.areEqual( 2, aggregateContactMap.keySet().size(), 'hashList_testAggregateResult_IdKey: Expected 2 groups in map, found ' + aggregateContactMap.keySet().size() );
    }

    @isTest
    private static void hashList_testAggregateResult_StringKey()
    {
        // When
        Test.startTest();

        Map<String, AggregateResult> aggregatedAccountMap = (Map<String, AggregateResult>) CollectionUtil.hashList([SELECT COUNT(Id) ids, SUM(AnnualRevenue), Type FROM Account GROUP BY Type ], 'Type');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedAccountMap, 'hashList_testAggregateResult_StringKey: The generated map is null');
        Assert.isTrue( aggregatedAccountMap.containsKey(ACCOUNT_TYPES[0]) && aggregatedAccountMap.containsKey(ACCOUNT_TYPES[1]), 'hashList_testAggregateResult_StringKey: Keys ACCOUNT_TYPE[0], and ACCOUNT_TYPE[1] not found on generated map.');
        Assert.areEqual( 2, aggregatedAccountMap.get(ACCOUNT_TYPES[0]).get('ids'), 'hashList_testAggregateResult_StringKey: Expected 2 ids counted in the group  ACCOUNT_TYPE[0] found ' + aggregatedAccountMap.get(ACCOUNT_TYPES[0]).get('ids') );
        Assert.areEqual( 2, aggregatedAccountMap.get(ACCOUNT_TYPES[1]).get('ids'), 'hashList_testAggregateResult_StringKey: Expected 2 ids in the group ACCOUNT_TYPE[1], found ' + aggregatedAccountMap.get(ACCOUNT_TYPES[1]).get('ids') );
    }

    @isTest
    private static void hashList_testAggregateResult_IntegerKey()
    {
        // When
        Test.startTest();

        Map<Integer, AggregateResult> aggregatedAccountMap = (Map<Integer, AggregateResult>) CollectionUtil.hashList([SELECT COUNT(Id) ids, SUM(AnnualRevenue), NumberOfEmployees FROM Account GROUP BY NumberOfEmployees], 'NumberOfEmployees');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedAccountMap, 'hashList_testAggregateResult_IntegerKey: The generated map is null');
        Assert.isTrue( aggregatedAccountMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[0]) && aggregatedAccountMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[1]) && aggregatedAccountMap.containsKey(ACCOUNT_NUMBER_OF_EMPLOYEES[2]), 'hashList_testAggregateResult_IntegerKey: Keys ACCOUNT_NUMBER_OF_EMPLOYEES[0], ACCOUNT_NUMBER_OF_EMPLOYEES[1] and ACCOUNT_NUMBER_OF_EMPLOYEES[2] not found on generated map.');
        Assert.areEqual( 1, aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).get('ids'), 'hashList_testAggregateResult_IntegerKey: Expected 1 id results in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[1] found ' + aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[1]).get('ids') );
        Assert.areEqual( 1, aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).get('ids'), 'hashList_testAggregateResult_IntegerKey: Expected 1 id results in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[0], found ' + aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[0]).get('ids') );
        Assert.areEqual( 2, aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).get('ids'), 'hashList_testAggregateResult_IntegerKey: Expected 2 ids in the list group by ACCOUNT_NUMBER_OF_EMPLOYEES[2], found ' + aggregatedAccountMap.get(ACCOUNT_NUMBER_OF_EMPLOYEES[2]).get('ids') );
    }

    @isTest
    private static void hashList_testAggregateResult_BooleanKey()
    {
        // When
        Test.startTest();

        Map<Boolean, AggregateResult> aggregatedContactMap = (Map<Boolean, AggregateResult>) CollectionUtil.hashList([SELECT COUNT(Id) ids, DoNotCall, AccountId FROM Contact GROUP BY DoNotCall, AccountId], 'DoNotCall');

        Test.stopTest();

        // Then
        Assert.isNotNull(aggregatedContactMap, 'hashList_testAggregateResult_BooleanKey: The generated map is null');
        Assert.isTrue(aggregatedContactMap.containsKey(true) && aggregatedContactMap.containsKey(false), 'hashList_testAggregateResult_BooleanKey: Keys true and false not found on generated map.');
        Assert.areEqual( 3, aggregatedContactMap.get(true).get('ids'), 'hashList_testAggregateResult_BooleanKey: Expected 3 id results in the list group by true found ' + aggregatedContactMap.get(true).get('ids') );
        Assert.areEqual( 3, aggregatedContactMap.get(false).get('ids'), 'hashList_testAggregateResult_BooleanKey: Expected 3 id results in the list group by false, found ' + aggregatedContactMap.get(false).get('ids') );
    }
    //#endregion
}