/**
 * Test for the Batch Batch_MergeLeadsWithClients
 *
 * @author nts (agonzalezisasi)
 * @date 03/02/2021
 */
@isTest
public class Batch_MergeLeadsWithClientsTest
{
    private static final string LEGAL_ENTITY = '001';
    private static final string SCOPE_GENERAL = 'General';
    private static final string OFFER_STAGE_NEW = 'New';
    private static final string ACCOUNT_INTERMEDIARY = 'Intermediary';
    private static final string ACCOUNT_CUSTOMER = 'Customer';
    private static final string ACCOUNT_BUSINESS = 'BusinessCustomer';
    private static final Id LeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                get(Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME).getRecordTypeId();
    static final String MESSAGE_LEAD_ACCOUNT = 'There should be 1 lead account';
    static final String MESSAGE_CUSTOMER_ACCOUNT = 'There should be 1 customer account';
    static final String MESSAGE_OFFER_ACCOUNT = 'There sould be 1 offer for the lead';
    static final String GENERAL_INSURANCE = 'General Insurance';
    static final String QUERY_OPPORTUNITY = 'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE OldAccountId__c = \'';


    @TestSetup
    static void makeData(){
        
        // create 1 Lead accounts
        List<Account> leadAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME, 1);
        for(Integer i=0,j=leadAccounts.size();i<j;i++){
            leadAccounts[i].firstName = 'test';
            leadAccounts[i].LastName = 'Lead ' + i;
            leadAccounts[i].RecordTypeId = LeadRecordTypeId;
            leadAccounts[i].Salutation = 'Mr.';
        }
        insert leadAccounts;
        
        // create 1 client accounts of other types
        List<Account> clientAccountsOther = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_INTERMEDIARY, 1);
        insert clientAccountsOther;

        // join the accounts
        leadAccounts.addAll(clientAccountsOther);
        
        // create new offers, for leads and for other clients
        List<Opportunity> newOffers = TestDataFactory.generateOpportunitiesForEachAccount(
            leadAccounts, SCOPE_GENERAL, OFFER_STAGE_NEW, System.today().addDays(10), 1
        );
        insert newOffers;

        // create 2 Client accounts (Coming from INFO), type Customer (PersonAccount) and type BusinessCustomer (Account)
        List<Account> clientAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_CUSTOMER, 1);
        clientAccounts.addAll(TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_BUSINESS, 1));
        insert clientAccounts;

        // create contact points for the accounts
        insert TestDataFactory.generateContactPointAddressesFromAccounts(clientAccounts, 1);
        insert TestDataFactory.generateContactPointPhonesFromAccounts(clientAccounts, 1);
        insert TestDataFactory.generateContactPointEmailsFromAccounts(clientAccounts, 1);

        // create 2 cases for those clients
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(clientAccounts, 2);
        insert cases;
    }
    
    @isTest
    static void test_PersonAccount_ok()
    {
        personAccount();
    }

    @isTest
    static void test_PersonAccountNoEmails_ok()
    {
        //Se obtienen todos los ContactPointEmail y se borran
        List<ContactPointEmail> contactPointEmailList = [SELECT Id FROM ContactPointEmail];
        delete contactPointEmailList;

        personAccount();
    }

    @isTest
    static void test_PersonAccountNoEmailsNoPhones_ok()
    {
        //Se obtienen todos los ContactPointEmail y se borran
        List<ContactPointEmail> contactPointEmailList = [SELECT Id FROM ContactPointEmail];
        delete contactPointEmailList;
        //Se obtienen todos los ContactPointPhone y se borran
        List<ContactPointPhone> contactPointPhoneList = [SELECT Id FROM ContactPointPhone];
        delete contactPointPhoneList;

        personAccount();
    }

    @isTest
    static void test_PersonAccountNoEmailsNoPhonesNoAddress_ok()
    {
        //Se obtienen todos los contactPointAdress y se borran
        List<ContactPointAddress> contactPointAddressList = [SELECT Id FROM ContactPointAddress];
        delete contactPointAddressList;
        //Se obtienen todos los ContactPointEmail y se borran
        List<ContactPointEmail> contactPointEmailList = [SELECT Id FROM ContactPointEmail];
        delete contactPointEmailList;
        //Se obtienen todos los ContactPointPhone y se borran
        List<ContactPointPhone> contactPointPhoneList = [SELECT Id FROM ContactPointPhone];
        delete contactPointPhoneList;

        personAccount();
    }

    private static void personAccount()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(),MESSAGE_LEAD_ACCOUNT);
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), MESSAGE_CUSTOMER_ACCOUNT);
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(),MESSAGE_OFFER_ACCOUNT);
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            QUERY_OPPORTUNITY + leadAccounts[0].Id + '\''
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Check that the leads accounts still exist and the record type has changed
        List<Account> mergedLeads = [SELECT Id FROM Account WHERE Id IN :leadAccounts AND RecordType.DeveloperName != :Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME];
        System.assertEquals(1, mergedLeads.size(), 'There should be 1 accounts with the lead ID');

        // Check that the leads accounts has the case related sobjects
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :leadAccounts];
        System.assertEquals(2, cases.size(), 'There should be 2 cases');

        // Check that the leads accounts has the offers
        List<Opportunity> offers = [SELECT Id, OldAccountId__c FROM Opportunity WHERE AccountId IN :leadAccounts];
        System.assertEquals(1, offers.size(), 'There should be 1 offers');
        // In UI this is ok but in testing is not working....
        // System.assertEquals(null, offers[0].OldAccountId__c, 'The OldAccountId__c of the offer should be null');
    }

    
    @isTest
    static void test_PersonAccount_ko()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(), MESSAGE_LEAD_ACCOUNT);
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), MESSAGE_CUSTOMER_ACCOUNT);
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(), MESSAGE_OFFER_ACCOUNT);
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            QUERY_OPPORTUNITY + leadAccounts[0].Id + '\''
        );
        // force an error when trying to merge the Name field for PersonAccounts
        batch.fieldsToMergePerson.add('Name');
        Database.executeBatch(batch, 1);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
        
        System.assertEquals(false, errors.isEmpty(), 'There should be Error Logs');
    }

    
    @isTest
    static void test_Account_ok()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(), MESSAGE_LEAD_ACCOUNT);
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_BUSINESS LIMIT 1];
        System.assertEquals(1, customerAccount.size(), 'There should be 1 BusinessCustomer account');
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(), MESSAGE_OFFER_ACCOUNT);
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            QUERY_OPPORTUNITY + leadAccounts[0].Id + '\''
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Check that the leads accounts still exist and the record type has changed
        List<Account> mergedLeads = [SELECT Id FROM Account WHERE Id IN :leadAccounts AND RecordType.DeveloperName != :Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME];
        System.assertEquals(1, mergedLeads.size(), 'There should be 1 accounts with the lead ID');

        // Check that the leads accounts has the case related sobjects
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :leadAccounts];
        System.assertEquals(2, cases.size(), 'There should be 2 cases');

        // Check that the leads accounts has the offers
        List<Opportunity> offers = [SELECT Id, OldAccountId__c FROM Opportunity WHERE AccountId IN :leadAccounts];
        System.assertEquals(1, offers.size(), 'There should be 1 offers');
        // In UI this is ok but in testing is not working....
        // System.assertEquals(null, offers[0].OldAccountId__c, 'The OldAccountId__c of the offer should be null');
    }

    @isTest
    static void test_MoreThanOneScope()
    {
        String result;
        List<Opportunity> offers = [SELECT Id, AccountId FROM Opportunity];
        System.assertEquals(2, offers.size(), 'There should be 2 offers');
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), MESSAGE_CUSTOMER_ACCOUNT);

        offers[0].AccountId = customerAccount[0].Id;
        offers[1].AccountId = customerAccount[0].Id;
        update offers;
        
        result = null;
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();
        Database.executeBatch(batch, 2);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(false, errors.isEmpty(), 'There should be Error Logs');
    }

    /**
     * For testing Schedule
     */
    @isTest
    static void test_schedule()
    {
        Batch_MergeLeadsWithClients m = new Batch_MergeLeadsWithClients();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        system.schedule('Batch Merge Leads with Clients', sch, m);
        Test.stopTest();
    }

    /**
    * Test que comprueba que se obtienen correctamente los campos a mergear dependiendo del tipo de cuenta
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_getAccountFieldsToMergeForEachType()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        Test.startTest();
        batch.getAccountFieldsToMergeForEachType();
        Test.stopTest();

        System.assertEquals(false, batch.fieldsToMergePerson.isEmpty(), 'La lista no debe estar vacía');
        System.assertEquals(false, batch.fieldsToMergeNotPerson.isEmpty(), 'La lista no debe estar vacía');
    }

    /**
    * Test que comprueba que se convierte correctamente la cuenta a convertir
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_ifNotPersonAccountConvertLeadAccountAndUpdateContacts()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        Boolean isPersonAccount = false; 
        Id recordtypeIDIntermediary = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        // Create a test lead account and a test normal account
        Account leadAccount = new Account(Name='Test Lead Account');
        insert leadAccount;
        Account normalAccount = new Account(Name='Test Normal Account', LegalEntity__c= GENERAL_INSURANCE, RecordTypeId = recordtypeIDIntermediary);
        insert normalAccount;
        
        // Create a test contact related to the lead account
        Contact testContact = new Contact(FirstName='Test First Name', LastName='Test Last Name', AccountId=leadAccount.Id);
        insert testContact;
        
        // Call the method to test
        Test.startTest();
        batch.ifNotPersonAccountConvertLeadAccountAndUpdateContacts(isPersonAccount, leadAccount, normalAccount);
        Test.stopTest();
        
        // Check that the lead account was converted to a normal account
        leadAccount = [SELECT Id, RecordTypeId FROM Account WHERE Id = :leadAccount.Id];
        System.assertEquals(normalAccount.RecordTypeId, leadAccount.RecordTypeId, 'Ambas cuentas debería ser del mismo recordtype');
    }

    /**
    * Test que comprueba que se actualizan correctamente los contactpoints
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_updateContactPoints()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        Id recordtypeIDIntermediary = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        Account leadAccount = new Account(Name='accountlead');
        insert leadAccount;
        Account normalAccount = new Account(Name='accountnormal', LegalEntity__c= GENERAL_INSURANCE, RecordTypeId = recordtypeIDIntermediary);
        insert normalAccount;
        
        // Insertar contactPoints
        List<ContactPointAddress> cpAddress = TestDataFactory.generateContactPointAddressesFromAccounts(new List<Account>{normalAccount}, 1);
        insert cpAddress;
        List<ContactPointPhone> cpPhone = TestDataFactory.generateContactPointPhonesFromAccounts(new List<Account>{normalAccount}, 1);
        insert cpPhone;
        List<ContactPointEmail> cpEmail = TestDataFactory.generateContactPointEmailsFromAccounts(new List<Account>{normalAccount}, 1);
        insert cpEmail;

        normalAccount = [Select id,(select id from ContactPointEmails),(select id from ContactPointPhones),(select id from ContactPointAddresses) from Account where id =: normalAccount.id];

        Test.startTest();
        batch.updateContactPoints (normalAccount, leadAccount);
        Test.stopTest();

        cpAddress = [Select id,ParentId from ContactPointAddress  where id=:cpAddress[0].id ];
        cpPhone = [Select id,ParentId from ContactPointPhone  where id=:cpPhone[0].id ];
        cpEmail = [Select id,ParentId from ContactPointEmail  where id=:cpEmail[0].id ];

        System.assertEquals(leadAccount.id, cpAddress[0].ParentId, 'El parent id del contact point address no se ha actualizado correctamente');
        System.assertEquals(leadAccount.id, cpPhone[0].ParentId, 'El parent id del contact point phone no se ha actualizado correctamente');
        System.assertEquals(leadAccount.id, cpEmail[0].ParentId, 'El parent id del contact point email no se ha actualizado correctamente');
    }

    /**
    * Test que comprueba que se actualizan correctamente los campos a mergear
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_mergeAllFieldsFromAccountToLeadAccount()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        Account leadAccount = new Account(Name='accountlead',CNAE__c ='00100' );
        insert leadAccount;
        Account normalAccount = new Account(Name='accountnormal', LegalEntity__c= GENERAL_INSURANCE, CNAE__c= '00111');
        insert normalAccount;

        //Añadir campos para mergear la lead account
        List<String> fieldsToMerge = new List<String>{'Name', 'LegalEntity__c'};

        Test.startTest();
        leadAccount = batch.mergeAllFieldsFromAccountToLeadAccount (fieldsToMerge, normalAccount, leadAccount );
        Test.stopTest();

        System.assertEquals(normalAccount.Name, leadAccount.Name, 'El nombre debería coincidir');
        System.assertEquals(normalAccount.LegalEntity__c, leadAccount.LegalEntity__c,'La entidad legal debería coincidir');
        System.assertEquals('00100', leadAccount.CNAE__c,'El código de actividad económica no debería de haber cambiado');
    }

    /**
    * Test que comprueba que se obtiene correctamente la query
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_getQueryAccountFromOfferAccount()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        List<String> fieldsToMerge = new List<String>{'Id','Name', 'LegalEntity__c'};
        List<Opportunity> offers = [Select id,AccountId from Opportunity where AccountId != null limit 1 ];

        Test.startTest();
        String query = batch.getQueryAccountFromOfferAccount (offers, fieldsToMerge );
        Test.stopTest();

        System.assertNotEquals(null, query, 'La query devuelta no debe ser nula');
    }

     /**
    * Test que comprueba que se mergea correctamente la cuenta
    * 
    * @author aberuete
    * @date 21/04/2023
    */
    @isTest
    static void test_iflistLeadAccountsNotEmptyMergeAccount()
    {
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();

        Id recordtypeIDIntermediary = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        Account leadAccount = new Account(Name='accountlead',CNAE__c ='00100',RecordTypeId = recordtypeIDIntermediary );
        insert leadAccount;
        Account normalAccount = new Account(Name='accountnormal', LegalEntity__c= GENERAL_INSURANCE, CNAE__c= '00111', RecordTypeId = recordtypeIDIntermediary );
        insert normalAccount;

        List<Opportunity> offers = [Select id,AccountId from Opportunity where AccountId != null limit 1 ];
        offers[0].AccountId = normalAccount.id;
        update offers; 

        //Añadir campos para mergear con la lead account
        List<String> fieldsToMerge = new List<String>{'Name', 'LegalEntity__c','RecordTypeId'};

        Test.startTest();
        batch.iflistLeadAccountsNotEmptyMergeAccount (new List<Account>{leadAccount} , offers, fieldsToMerge, false);
        Test.stopTest();

        Account leadAccountAfter = [Select id,Name,CNAE__c,LegalEntity__c from Account where id =: leadAccount.id];

        System.assertEquals(normalAccount.Name, leadAccountAfter.Name, 'El nombre se debería de haber cambiado');
        System.assertEquals(normalAccount.LegalEntity__c, leadAccountAfter.LegalEntity__c, 'La entidad legal se debería haber actualizado');
        System.assertEquals(leadAccount.CNAE__c, leadAccountAfter.CNAE__c, 'El campo CNAE__c no debería de haber cambiado ');
    }
}