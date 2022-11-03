/**
 * Test para la clase EmailMessagesUtil
 *
 * @author nts (agonzalezisasi)
 * @date 01/12/2021
 */ 
@isTest
private class EmailMessagesUtilTest
{
    public static final Integer NUM_EMAILS = 5;
    public static final String EMAIL_FORMAT_TO = 'toaddress{0}@zurich.com.invalid';    
    public static final String EMAIL_FORMAT_CC = 'ccaddress{0}@zurich.com.invalid';
    public static final String EMAIL_HEGEO = 'hegeo@zurich.com.invalid';
    public static final String EMAIL_QUEUE = 'toGenesysQueue@zurich.com.invalid';
    public static final String GENESYS_FLOW_ID = 'genesys flow id';
    public static final String GENESYS_QUEUE_ID = 'gnesys queue id';
    public static final String EMAIL_INDUSTRY = 'empresas.dtmad@zurich.com';
    public static final String INDUSTRY_VALUE = 'Prueba Industria';

    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     */
    @TestSetup
    static void makeData() 
    {
        List<purecloud__PureCloud_Queue__c> queues = TestDataFactory.generateGenesysQueues(1);
        queues[0].SalesforceRecipientEmail__c = EMAIL_QUEUE;
        queues[0].GenesysFlowId__c = GENESYS_FLOW_ID;
        queues[0].purecloud__PureCloud_Queue_ID__c = GENESYS_QUEUE_ID;
        queues[0].Industry__c = INDUSTRY_VALUE;
        insert queues;
    }

    @isTest
    static void checkEmailMessageForGenesysRouting_hegeo_ok() 
    {
        // Prepare the emails message to be inserted. 
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        System.assertEquals(true, NUM_EMAILS > 2, 'There should be more than 2 email message to be created');
        
        for(Integer i=0; i<emails.size(); i++) {
            List<String> addressList = new List<String>{
                String.format(EMAIL_FORMAT_TO, new List<String>{String.valueOf(i)}),
                EMAIL_HEGEO
            };

            emails[i].Incoming = true;

            if( i == 0 ) { // The first one will have the hegeo email in the To field -> invalid
                emails[i].ToAddress = String.join(addressList, ';');
            } else if( i == 1 ) { // The second one will have the hegeo email in the Cc field -> invalid
                emails[i].CcAddress = String.join(addressList, ';');
            } else { // The rest will not have the hegeo email -> valid
                emails[i].ToAddress = String.format(EMAIL_FORMAT_TO, new List<String>{String.valueOf(i)});
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String>{String.valueOf(i)});
            }
        }        

        EmailMessagesUtil emUtil = new EmailMessagesUtil();
        emUtil.testHegeoSettings = new List<Robot_Hegeo_Setting__mdt>();
        emUtil.testHegeoSettings.add(new Robot_Hegeo_Setting__mdt(
            RoutingAddresses__c = EMAIL_HEGEO
        ));

        Test.startTest();
        emUtil.checkEmailMessageForGenesysRouting(emails, true);
        Test.stopTest();

        Integer num = NUM_EMAILS-2;
        System.assertEquals(num, emUtil.emailMessageToCheck.size(), 'There should be ' + num + ' email messages');         
    }

    @isTest
    static void assignGenesysRoutingFields_insert_ok()
    {
        // Prepare the emails message to be inserted. The first one will have the queue email
        // in the CC field
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        for(Integer i=0; i<emails.size();i++) {
            List<String> addressList = new List<String>();
            addressList.add(String.format(EMAIL_FORMAT_TO, new List<String>{String.valueOf(i)}));
            addressList.add(EMAIL_QUEUE);

            emails[i].Incoming = true;

            if( i == 0 ) {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_FORMAT_CC, new List<String>{String.valueOf(i)});
            } else {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String>{String.valueOf(i)});
            }
        }        

        Test.startTest();
        insert emails;
        Test.stopTest();

        List<EmailMessage> emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(NUM_EMAILS, emailsResult.size(), 'There should be ' + NUM_EMAILS + ' EmailMessages');
    }

    @isTest
    static void assignGenesysRoutingFields_update_ok() 
    {
        // The first time the emails dont have any valid genesys queue email receipts
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        
        for(Integer i=0; i<emails.size();i++) {
            emails[i].Incoming = true;
        }
        
        insert emails;

        List<EmailMessage> emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(0, emailsResult.size(), 'There should not be EmailMessages');

        // Then update the emails with the genesys queue email
        for(Integer i=0; i<emails.size();i++) {
            List<String> addressList = new List<String>();
            addressList.add(String.format(EMAIL_FORMAT_TO, new List<String>{String.valueOf(i)}));
            addressList.add(EMAIL_QUEUE);

            if( i == 0 ) {
                emails[i].CcAddress = String.join(addressList, ',');
                emails[i].ToAddress = String.format(EMAIL_FORMAT_CC, new List<String>{String.valueOf(i)});
            } else {
                emails[i].ToAddress = String.join(addressList, ',');
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String>{String.valueOf(i)});
            }
        }        

        Test.startTest();
        update emails;
        Test.stopTest();

        emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(NUM_EMAILS, emailsResult.size(), 'There should be ' + NUM_EMAILS + ' EmailMessages');
    }

    @isTest
    static void assignGenesysRoutingIndustry_insert_ok()
    {

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        relatedCase.Industry__c = INDUSTRY_VALUE;
        insert relatedCase;
        system.debug('>>> RelatedcASE'+ relatedCase);
        
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        system.debug('>>> emails'+ emails);
        for(Integer i=0; i<emails.size();i++) 
        {
            List<String> addressList = new List<String>();
            addressList.add(String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)}));
            addressList.add(EMAIL_INDUSTRY);

            emails[i].Status = '3'; // email was sent
            emails[i].ParentId = relatedCase.Id; 
            emails[i].FromName = 'Javi Garcia'; // from name
            emails[i].Subject = 'Prueba Industria';
            emails[i].Incoming = true;
            emails[i].Industry__c = INDUSTRY_VALUE;

            if( i == 0 ) {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)});
            } else {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)});
            }
        
        }

        Test.startTest();
        insert emails;  
        Test.stopTest();
        List<EmailMessage> emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(NUM_EMAILS, emailsResult.size(), 'There should be ' + NUM_EMAILS + ' EmailMessages');
    }

    @isTest
    static void assignGenesysRoutingFieldsIndustry_update_ok() 
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        relatedCase.Industry__c = INDUSTRY_VALUE;
        insert relatedCase;
        // The first time the emails dont have any valid genesys queue email receipts
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        
        for(Integer i=0; i<emails.size();i++) {
            emails[i].Incoming = true;
            emails[i].Subject = 'Update Industria';
            emails[i].ParentId = relatedCase.Id;
            emails[i].Industry__c = INDUSTRY_VALUE;
        }
        
        insert emails;

        List<EmailMessage> emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(0, emailsResult.size(), 'There should not be EmailMessages');

        // Then update the emails with the genesys queue email
        for(Integer i=0; i<emails.size();i++) {
            List<String> addressList = new List<String>();
            addressList.add(String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)}));
            addressList.add(EMAIL_INDUSTRY);

            if( i == 0 ) {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)});
            } else {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_INDUSTRY, new List<String>{String.valueOf(i)});
            }
        }        

        Test.startTest();
        update emails;
        Test.stopTest();

        emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(NUM_EMAILS, emailsResult.size(), 'There should be ' + NUM_EMAILS + ' EmailMessages');
    }
    

    @isTest
    static void assignGenesysRoutingFields_insert_ko() 
    {
        EmailMessagesUtil emUtil = new EmailMessagesUtil();
        emUtil.isTestUnknownError = true;
        Test.startTest();
        emUtil.assignGenesysRoutingFields();
        Test.stopTest();

        List<Error_Log__c> errorList = (new ErrorLogSelector()).findAll();
        System.assertEquals(false, errorList.isEmpty(), 'There should be an error log');
    }

    @isTest
    static void delete_ok() 
    {
        // For EmailMessagesHandler coverage
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        insert emails;

        Test.startTest();
        delete emails;
        Test.stopTest();
    }
    
}