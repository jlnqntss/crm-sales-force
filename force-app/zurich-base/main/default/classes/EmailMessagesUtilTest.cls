/**
 * Test para la clase EmailMessagesUtil
 *
 * @author nts (agonzalezisasi)
 * @date 01/12/2021
 */
@isTest
private with sharing class EmailMessagesUtilTest
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
    public static final String OCS_RECORDTYPE_VALUE = 'OCSInquiry';

    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     */
    @TestSetup
    private static void makeData()
    {
        List<purecloud__PureCloud_Queue__c> queues = TestDataFactory.generateGenesysQueues(1);
        queues[0].SalesforceRecipientEmail__c = EMAIL_QUEUE;
        queues[0].GenesysFlowId__c = GENESYS_FLOW_ID;
        queues[0].purecloud__PureCloud_Queue_ID__c = GENESYS_QUEUE_ID;
        queues[0].Industry__c = INDUSTRY_VALUE;
        queues[0].RecordTypeInfo__c = OCS_RECORDTYPE_VALUE;
        insert queues;
    }

    @isTest
    private static void checkEmailMessageForGenesysRouting_hegeo_ok()
    {
        // Prepare the emails message to be inserted.
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        System.assertEquals(true, NUM_EMAILS > 2, 'There should be more than 2 email message to be created');

        for(Integer i=0; i < emails.size(); i++)
        {
            List<String> addressList = new List<String> {
                String.format(EMAIL_FORMAT_TO, new List<String> {String.valueOf(i)}),
                EMAIL_HEGEO
            };

            emails[i].Incoming = true;

            if( i == 0 )   // The first one will have the hegeo email in the To field -> invalid
            {
                emails[i].ToAddress = String.join(addressList, ';');
            }
            else if( i == 1 )     // The second one will have the hegeo email in the Cc field -> invalid
            {
                emails[i].CcAddress = String.join(addressList, ';');
            }
            else     // The rest will not have the hegeo email -> valid
            {
                emails[i].ToAddress = String.format(EMAIL_FORMAT_TO, new List<String> {String.valueOf(i)});
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String> {String.valueOf(i)});
            }
        }

        EmailMessagesUtil emUtil = new EmailMessagesUtil();
        emUtil.testHegeoSettings = new List<Robot_Hegeo_Setting__mdt>();
        emUtil.testHegeoSettings.add( new Robot_Hegeo_Setting__mdt(
                                          RoutingAddresses__c = EMAIL_HEGEO
                                          ) );

        Test.startTest();
        emUtil.checkEmailMessageForGenesysRouting(emails, true);
        Test.stopTest();

        Integer num = NUM_EMAILS - 2;
        System.assertEquals(num, emUtil.emailMessageToCheck.size(), 'There should be ' + num + ' email messages');
    }

    @isTest
    private static void assignGenesysRoutingFields_insert_ok()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 5);
        cases[0].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[1].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[2].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[3].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[4].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        insert cases;

        // Prepare the emails message to be inserted. The first one will have the queue email
        // in the CC field
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        for(Integer i=0; i < emails.size(); i++)
        {
            List<String> addressList = new List<String>();
            addressList.add( String.format(EMAIL_FORMAT_TO, new List<String> {String.valueOf(i)}) );
            addressList.add(EMAIL_QUEUE);

            emails[i].Incoming = true;
            emails[i].ParentId = cases[i].Id;

            if( i == 0 )
            {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_FORMAT_CC, new List<String> {String.valueOf(i)});
            }
            else
            {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String> {String.valueOf(i)});
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

    /**
     * Test que comprueba que se añade correctamente la cola de genesys al email por el campo industry cuando está informado un email
     **
     * @author aberuete
     * @date 20/11/2023
     */
    @isTest
    private static void assignGenesysRoutingFieldsByIndustryEmail ()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 5);
        cases[0].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[1].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[2].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[3].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[4].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        insert cases;

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        for(Integer i=0; i < emails.size(); i++)
        {
            emails[i].Industry__c = EMAIL_QUEUE;
            emails[i].Incoming = true;
            emails[i].ParentId = cases[i].Id;
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
    private static void assignGenesysRoutingFields_update_ok()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 5);
        cases[0].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[1].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[2].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[3].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[4].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        insert cases;

        // The first time the emails dont have any valid genesys queue email receipts
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);

        for(Integer i=0; i < emails.size(); i++)
        {
            emails[i].Incoming = true;
            emails[i].ParentId = cases[i].Id;
        }

        insert emails;

        List<EmailMessage> emailsResult = [
            SELECT Id FROM EmailMessage WHERE GenesysFlowID__c != null AND GenesysQueueName__c != null
        ];
        System.assertEquals(0, emailsResult.size(), 'There should not be EmailMessages');

        // Then update the emails with the genesys queue email
        for(Integer i=0; i < emails.size(); i++)
        {
            List<String> addressList = new List<String>();
            addressList.add( String.format(EMAIL_FORMAT_TO, new List<String> {String.valueOf(i)}) );
            addressList.add(EMAIL_QUEUE);

            if( i == 0 )
            {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_FORMAT_CC, new List<String> {String.valueOf(i)});
            }
            else
            {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_FORMAT_CC, new List<String> {String.valueOf(i)});
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
    private static void assignGenesysRoutingIndustry_insert_ok()
    {

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        relatedCase.Industry__c = INDUSTRY_VALUE;
        insert relatedCase;
        system.debug('>>> RelatedcASE' + relatedCase);

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        system.debug('>>> emails' + emails);
        for(Integer i=0; i < emails.size(); i++)
        {
            List<String> addressList = new List<String>();
            addressList.add( String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)}) );
            addressList.add(EMAIL_INDUSTRY);

            emails[i].Status = '3'; // email was sent
            emails[i].ParentId = relatedCase.Id;
            emails[i].FromName = 'Javi Garcia'; // from name
            emails[i].Subject = 'Prueba Industria';
            emails[i].Incoming = true;
            emails[i].Industry__c = INDUSTRY_VALUE;

            if( i == 0 )
            {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)});
            }
            else
            {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)});
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
    private static void assignGenesysRoutingFieldsIndustry_update_ok()
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        relatedCase.Industry__c = INDUSTRY_VALUE;
        insert relatedCase;
        // The first time the emails dont have any valid genesys queue email receipts
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);

        for(Integer i=0; i < emails.size(); i++)
        {
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
        for(Integer i=0; i < emails.size(); i++)
        {
            List<String> addressList = new List<String>();
            addressList.add( String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)}) );
            addressList.add(EMAIL_INDUSTRY);

            if( i == 0 )
            {
                emails[i].CcAddress = String.join(addressList, ';');
                emails[i].ToAddress = String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)});
            }
            else
            {
                emails[i].ToAddress = String.join(addressList, ';');
                emails[i].CcAddress = String.format(EMAIL_INDUSTRY, new List<String> {String.valueOf(i)});
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
    private static void assignGenesysRoutingFields_insert_ko()
    {
        EmailMessagesUtil emUtil = new EmailMessagesUtil();
        emUtil.isTestUnknownError = true;
        Test.startTest();
        emUtil.assignGenesysRoutingFields();
        Test.stopTest();

        List<Error_Log__c> errorList = ( new ErrorLogSelector() ).findAll();
        System.assertEquals(false, errorList.isEmpty(), 'There should be an error log');
    }

    @isTest
    private static void delete_ok()
    {
        // For EmailMessagesHandler coverage
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
        insert emails;

        Test.startTest();
        delete emails;
        Test.stopTest();
    }

    @isTest
    private static void generateChildCases_OK()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 2);
        cases[0].Status = 'Asignado';
        cases[0].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        cases[1].Status = 'Cerrado';
        cases[1].RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        insert cases;

        List<Case> casosInciales = [SELECT id FROM Case];
        System.assertEquals( 2, casosInciales.size() );

        // al insertar los emailMessages debemos haber generado un 3er caso
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(2);
        emails[0].Incoming = true;
        emails[0].ParentId = casosInciales[0].Id;
        emails[0].HtmlBody = '';
        emails[0].TextBody = '';
        emails[1].Incoming = true;
        emails[1].ParentId = casosInciales[1].Id;
        emails[1].HtmlBody = '';
        emails[1].TextBody = '';

        EmailMessagesUtil emUtil = new EmailMessagesUtil();

        Test.startTest();
        System.debug('++++ Entramos en el checkblablabla');
        emUtil.checkNewCaseFromClosedCase(emails);
        System.debug('++++ Salimos del checkblablabla');
        Test.stopTest();

        // Comprobamos que se haya creado un 3er caso, y que el email se ha relacionado con el.
        List<Case> casosFinales = [SELECT id FROM Case];
        List<Case> casosHijos = [Select id, ParentId FROM Case Where ParentId != ''];
        System.assertEquals(3, casosFinales.size(), 'Hemos de tener un caso más');
        System.assertEquals(casosInciales[1].id, casosHijos[0].ParentId, 'El nuevo caso hijo ha de estar asociado al caso cerrado');
        System.assertEquals(emails[1].ParentId, casosHijos[0].Id, 'El email ha de estar asociado al nuevo caso hijo');
    }

    /**
     * Test que comprueba que se crea correctamente el caso hijo para los casos cuyo call center sea TWW Retención
     * @author aberuete
     * @date 26/06/2023
     */
    @isTest
    private static void generateChildCasesFromTranscom_OK()
    {
        Group queue = new Group (Name = 'Grupo_De_Prueba',Type = 'Queue' );
        insert queue;

        User usr = [Select id from User where Id = : UserInfo.getUserId()];

        System.RunAs(usr)
        {
            QueueSobject testQueue = new QueueSobject ();
            testQueue.QueueId = queue.id;
            testQueue.SobjectType = 'Case';
            insert testQueue;
        }

        // Generamos los casos que necesitamos
        Case caso = new Case ();
        caso.Status = 'Cerrado';
        caso.CallCenter__c = 'TWW Retención';
        caso.RecordTypeId = EmailMessagesUtil.ocsRecordTypeId;
        caso.OwnerId = queue.id;
        insert caso;

        List<Case> casosInciales = [SELECT id FROM Case];
        System.assertEquals( 1, casosInciales.size() );

        // al insertar los emailMessages debemos haber generado un 3er caso
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(2);
        emails[0].Incoming = true;
        emails[0].ParentId = casosInciales[0].Id;
        emails[0].HtmlBody = '';
        emails[0].TextBody = '';

        EmailMessagesUtil emUtil = new EmailMessagesUtil();

        Test.startTest();
        emUtil.checkNewCaseFromClosedCase(emails);
        Test.stopTest();

        // Comprobamos que se haya creado un 3er caso, y que el email se ha relacionado con el.
        List<Case> casosFinales = [SELECT id FROM Case];
        List<Case> casosHijos = [Select id, ParentId, OwnerId FROM Case Where ParentId != ''];
        System.assertEquals(2, casosFinales.size(), 'Hemos de tener un caso más');
        System.assertEquals(casosInciales[0].id, casosHijos[0].ParentId, 'El nuevo caso hijo ha de estar asociado al caso cerrado');
        System.assertEquals(emails[0].ParentId, casosHijos[0].Id, 'El email ha de estar asociado al nuevo caso hijo');
        System.assertEquals(queue.id, casosHijos[0].OwnerId, 'El owner del caso hijo no es correcto');
    }

    /**
     * Test que comprueba que se marca correctamente la tarea a pública cuando se crea un email message que tiene una tarea relacionada
     * @author aberuete
     * @date 26/07/2023
     */
    @isTest
    private static void test_markPublicActivity()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba',Status = 'Assigned', Origin = 'Email');
        insert casoToEmailMessage;

        Task taskToEmailMessage = new Task (Subject = 'Correo electrónico',Status = 'Nueva',Priority = 'Normal');
        taskToEmailMessage.WhatId = casoToEmailMessage.id;
        insert taskToEmailMessage;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;
        emailList[0].ActivityId = taskToEmailMessage.id;
        insert emailList;

        List<Task> tasksList = ActivitySelector.selectTasksById (new Set<Id> {taskToEmailMessage.id});
        System.assertEquals(true, tasksList[0].IsVisibleInSelfService, 'La tarea no se ha actualizado correctamente');
    }
}