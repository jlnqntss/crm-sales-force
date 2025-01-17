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
        List<purecloud__PureCloud_Queue__c> queues = TestDataFactory.generateGenesysQueues(2);
        queues[0].SalesforceRecipientEmail__c = EMAIL_QUEUE;
        queues[0].GenesysFlowId__c = GENESYS_FLOW_ID;
        queues[0].purecloud__PureCloud_Queue_ID__c = GENESYS_QUEUE_ID;
        queues[0].Industry__c = INDUSTRY_VALUE;
        queues[0].RecordTypeInfo__c = OCS_RECORDTYPE_VALUE;

        queues[1].Name = GlobalConfigUtil.getGlobalConfigurationValue('Queue_FullName_GestionCartera');
        queues[1].GenesysFlowId__c = GENESYS_FLOW_ID + '1';
        queues[1].purecloud__PureCloud_Queue_ID__c = GENESYS_QUEUE_ID + '1';
        queues[1].RecordTypeInfo__c = GlobalConfigUtil.getGlobalConfigurationValue('Case_RecordType_ZDA');

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

    // comprobamos que si llega el toAddress vacio se genera un reigstro de error log
    @isTest
    private static void checkEmailMessageForGenesysRouting_hegeo_KO()
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
                emails[i].ToAddress = null;
            }
            else if( i == 1 )     // The second one will have the hegeo email in the Cc field -> invalid
            {
                emails[i].CcAddress = String.join(addressList, ';');
            }
            else     // The rest will not have the hegeo email -> valid
            {
                emails[i].ToAddress = '';
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

        // Comprobamos que se haya creado un registro de error log
        List<Error_Log__c> errorLogs = new List<Error_Log__c>([SELECT Id FROM Error_Log__c WHERE Level__c = :ErrorLogUtil.ERROR_LEVEL_WARNING]);
        Assert.isTrue(errorLogs.size() > 0, 'Debe existir un registro de error log de nivel warning');
    }

    @isTest
    private static void assignGenesysRoutingFields_insert_ok()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
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
        List<Account> accounts = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
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
        List<Account> accounts = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
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
        relatedCase.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
        relatedCase.Industry__c = INDUSTRY_VALUE;
        insert relatedCase;

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(NUM_EMAILS);
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
        relatedCase.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
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
        List<Account> accounts = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
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
        emUtil.checkNewCaseFromClosedCase(emails);
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
     * Test que comprueba que se crea correctamente el caso hijo para los casos de tipo SAM
     * @author aberuete
     * @date 18/04/2024
     */
    @isTest
    private static void generateChildCasesFromSAM_OK()
    {
        // Generamos los casos que necesitamos
        List<Account> accounts = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 2);
        cases[0].Status = 'Asignado';
        cases[0].RecordTypeId = EmailMessagesUtil.samRecordTypeId;
        cases[1].Status = 'Cerrado';
        cases[1].RecordTypeId = EmailMessagesUtil.samRecordTypeId;
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
        emUtil.checkNewCaseFromClosedCase(emails);
        Test.stopTest();

        // Comprobamos que se haya creado un 3er caso, y que el email se ha relacionado con el.
        List<Case> casosFinales = [SELECT id FROM Case];
        List<Case> casosHijos = [Select id, ParentId FROM Case Where ParentId != ''];
        Assert.areEqual(3, casosFinales.size(), 'Hemos de tener un caso más');
        Assert.areEqual(casosInciales[1].id, casosHijos[0].ParentId, 'El nuevo caso hijo ha de estar asociado al caso cerrado');
        Assert.areEqual(emails[1].ParentId, casosHijos[0].Id, 'El email ha de estar asociado al nuevo caso hijo');
    }

    /**
     * Test que comprueba que se marca correctamente la tarea a pública cuando se crea un email message que tiene una tarea relacionada
     * @author aberuete
     * @date 26/07/2023
     */
    @isTest
    private static void test_markPublicActivity()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba',Status = 'Assigned', Origin = 'Email', RecordTypeId = EmailMessagesUtil.ocsRecordTypeId);
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

    /**
     * Test para cerrar casos creados para buzones que están sólo en CCC
     * @author jfherrero
     * @date 22/01/2024
     */
    @isTest
    static void test_closeCaseOnlyInCc_Cerrar()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba',Status = 'Assigned', Origin = 'Email', RecordTypeId = EmailMessagesUtil.ocsRecordTypeId);
        insert casoToEmailMessage;

        List<CloseOnCcMailboxList__mdt> closeOnCcMailboxList = CloseOnCcMailboxList__mdt.getAll().values();
        String mailToCloseIfOnlyCc = closeOnCcMailboxList[0].Email__c;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;
        emailList[0].ToAddress = 'mail@ficticio.es';
        emailList[0].CcAddress = mailToCloseIfOnlyCc;

        insert emailList;
    }

    /**
     * Test para cerrar casos creados para buzones que están sólo en CCC
     * @author jfherrero
     * @date 22/01/2024
     */
    @isTest
    static void test_closeCaseOnlyInCc_No_Cerrar()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba',Status = 'Assigned', Origin = 'Email', RecordTypeId = EmailMessagesUtil.ocsRecordTypeId);
        insert casoToEmailMessage;

        List<CloseOnCcMailboxList__mdt> closeOnCcMailboxList = CloseOnCcMailboxList__mdt.getAll().values();
        String mailToCloseIfOnlyCc = closeOnCcMailboxList[0].Email__c;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;
        emailList[0].ToAddress = mailToCloseIfOnlyCc;
        emailList[0].CcAddress = 'mail@ficticio.es';

        insert emailList;
    }

    /**
     * Test para activar campo ControlEmailCC__c
     * @author lrodriguez
     * @date 27/03/2024
     */
    @isTest
    static void test_checkMailCc_Activar()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba activar',Status = 'Assigned', Origin = 'Email', RecordTypeId = CaseUtil.RT_ID_USPINQUIRY);
        insert casoToEmailMessage;

        List<EmailFromByDefaultCC__mdt> emailFromByDefaultCC = EmailFromByDefaultCC__mdt.getAll().values();
        String mailOnlyCc = emailFromByDefaultCC[0].Email__c;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;
        emailList[0].ToAddress = 'mail@ficticio.es';
        emailList[0].CcAddress = mailOnlyCc;

        Test.startTest();

        insert emailList;

        Test.stopTest();

        Case casesEmailDefault = [SELECT Id,ControlEmailCC__c FROM Case WHERE Subject = 'prueba activar'];

        System.assertEquals(casesEmailDefault.ControlEmailCC__c,true,'Debe ser false');

    }

    /**
     * Test para activar campo ControlEmailCC__c
     * @author lrodriguez
     * @date 27/03/2024
     */
    @isTest
    static void test_checkMailCc_Desactivar()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba Desactivar',Status = 'Assigned', Origin = 'Email', RecordTypeId = CaseUtil.RT_ID_USPINQUIRY);
        insert casoToEmailMessage;

        List<EmailFromByDefaultCC__mdt> emailFromByDefaultCC = EmailFromByDefaultCC__mdt.getAll().values();
        String mailOnlyCc = emailFromByDefaultCC[0].Email__c;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;
        emailList[0].ToAddress = mailOnlyCc;

        Test.startTest();

        insert emailList;

        Test.stopTest();

        Case casesEmailDefault = [SELECT Id,ControlEmailCC__c FROM Case WHERE Subject = 'prueba Desactivar'];

        System.assertEquals(casesEmailDefault.ControlEmailCC__c,false,'Debe ser false');

    }

    /**
     * Test para infromar id Genesys + link USP
     * @author lrodriguez
     * @date 16/05/2024
     */
    @isTest
    static void test_IdGenesys_USP()
    {
        Case casoToEmailMessage = new Case (Subject = 'prueba Genesys',Status = 'Assigned', Origin = 'Email', RecordTypeId = CaseUtil.RT_ID_USPINQUIRY);
        insert casoToEmailMessage;

        List<EmailMessage> emailList = TestDataFactory.generateEmailMessages(1);
        emailList[0].RelatedToId = casoToEmailMessage.id;


        Test.startTest();

        insert emailList;
        emailList[0].GenesysInteractionId__c='d7faf2ef-aadc-4001-85a4-17633fcfe492';
        update emailList;

        Test.stopTest();

        Case casesEmailDefault = [SELECT Id,GenesysID__c,LinkIdGenesys__c FROM Case WHERE Subject = 'prueba Genesys'];

        System.assertEquals(casesEmailDefault.GenesysID__c,'d7faf2ef-aadc-4001-85a4-17633fcfe492','Debe estar informado con id Genesys');
        System.assertEquals(casesEmailDefault.LinkIdGenesys__c,'https://apps.mypurecloud.ie/directory/#/engage/admin/interactions/d7faf2ef-aadc-4001-85a4-17633fcfe492','Debe estar informado con link id Genesys');

    }



    /**
     * Test para cerrar casos creados para buzones que están sólo en CCC
     * @author jfherrero
     * @date 06/02/2024
     */
    @isTest
    static void test_getEmailGenesisQueueId()
    {
        // Generar mail
        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(3);
        Group queueGroup = new Group (Name='Cola_Test', DeveloperName='Cola_Test', Type='Queue');
        insert queueGroup;

        emails[0].GenesysQueueName__c = 'Cola_Test';
        emails[1].GenesysQueueName__c = 'Cola_Test_fallo';

        Id integratorUserId;
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {'OCS Community User'});

        if ( UserInfo.getProfileId() != listaPerfiles.keySet().iterator().next() )
        {
            integratorUserId = [Select Id FROM User WHERE Profile.Name like : Label.IntegratorUser].get(0).Id;
        }

        Test.startTest();

        EmailMessagesUtil emailMessagesUtil =new EmailMessagesUtil();

        Id test01 = emailMessagesUtil.getEmailGenesisQueueId(emails[0], integratorUserId);
        Id test02 = emailMessagesUtil.getEmailGenesisQueueId(emails[1], integratorUserId);
        Id test03 = emailMessagesUtil.getEmailGenesisQueueId(emails[2], integratorUserId);

        Test.stopTest();

        System.assertEquals(test01, queueGroup.Id, 'Ambas ids deben ser iguales');
        System.assertEquals(test02, integratorUserId, 'Debe ser el fallback por no encontrar grupos');
        System.assertEquals(test03, integratorUserId, 'Debe ser el fallback venir el grupo vacío');
    }

    /**
     * Test para cerrar vincular casos de ciertos buzones con mediadores
     * @author jfherrero
     * @date 17/06/2024
     * 
     * @author jfherrero
     * @date 30/08/2024 
     */
    @isTest
    static void test_relateToIntermediary_ok()
    {
        List<Email_Case_AccountId_to_Intermediary__mdt> emailsCaseAccountIdToIntermediary = Email_Case_AccountId_to_Intermediary__mdt.getAll().values();
        Assert.areNotEqual(0, emailsCaseAccountIdToIntermediary.size(), 'Metadato Email_Case_AccountId_to_Intermediary__mdt NO existe');

        // Generar mediador y su contacto
        List<Account> intermediaries = TestDataFactory.generateAccounts('001', AccountUtil.INTERMEDIARY_RT_DEVELOPER_NAME, 1);
        insert intermediaries;

        List<Contact> contactIntermediary = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactUtil.AGENT_INTERMEDIARY_RT_DEVELOPER_NAME, 1);
        contactIntermediary[0].Email = 'email.test.ok@test.es';
        insert contactIntermediary;

		// Generar no mediador y su contacto        
        List<Account> customers = TestDataFactory.generateAccounts('001', AccountUtil.BUSINESS_CUSTOMER_RT_DEVELOPER_NAME, 1);
        insert customers;
      
        List<Contact> contactCustomer = TestDataFactory.generateContactsFromAccounts(customers, ContactsSelector.RT_NAME_CONTACT, 1);
        contactCustomer[0].Email = 'email.test.error@test.es';
		insert contactCustomer;
      
        // Generar casos
        List<Case> casesIntermediary = TestDataFactory.generateCasesForEachAccount(intermediaries, 1);
        casesIntermediary[0].RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY;
        casesIntermediary[0].AccountId = null;
        casesIntermediary[0].SuppliedEmail = contactIntermediary[0].Email;
        insert casesIntermediary;

        List<Case> casesCustomer = TestDataFactory.generateCasesForEachAccount(customers, 1);
        casesCustomer[0].AccountId = CaseUtil.RT_ID_OCSINQUIRY;
        casesCustomer[0].AccountId = null;
        casesCustomer[0].SuppliedEmail = contactCustomer[0].Email;
        insert casesCustomer;

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(2);
        emails[0].FromAddress = contactIntermediary[0].Email;
        emails[0].ToAddress = emailsCaseAccountIdToIntermediary[0].Email__c;
        emails[0].ParentId = casesIntermediary[0].Id;
        emails[0].Incoming = true;

        emails[1].FromAddress = contactIntermediary[0].Email;
        emails[1].ToAddress = emailsCaseAccountIdToIntermediary[0].Email__c;
        emails[1].ParentId = casesCustomer[0].Id;
        emails[1].Incoming = true;

        Test.startTest();

        insert emails[0];
        insert emails[1];

        Test.stopTest();

        List<Case> caseIntermediaryResults = [SELECT Id, AccountId FROM Case WHERE Id = : casesIntermediary[0].Id];
        List<Case> caseCustomerResults = [SELECT Id, AccountId FROM Case WHERE Id = : casesCustomer[0].Id];

        Assert.areEqual(caseIntermediaryResults[0].AccountId, intermediaries[0].Id, 'El AccountId debe ser el mediador');
        Assert.areEqual(caseCustomerResults[0].AccountId, null, 'El AccountId NO debe ser el cliente');
    }

    /**
     * Test para validar que si llega un email a la cola de urgencias de ZDA, con el asunto que contiene
     * un identificador de canal unico, no se crea un nuevo caso, el correo se vincula al caso al que se
     * menciona y la cola asignada es la cola del caso relacionado
     *
     * @author mario.navarro@seidor.com
     * @date 18/07/2024
     */
    @isTest
    static void test_checkExistingCaseZDAUrgencias()
    {
        String nameQueueGCartera = GlobalConfigUtil.getGlobalConfigurationValue('Queue_FullName_GestionCartera');
        String nameQueueUrgencias = GlobalConfigUtil.getGlobalConfigurationValue('Queue_FullName_Urgencias');
        List<Group> queueGCartera = new GroupSelector().findByName(nameQueueGCartera);
        Assert.isFalse( queueGCartera.isEmpty() );

        //Se crea el caso con el que se debe vincular el correo 'enviado'
        Case zdaCase = TestDataFactory.generateZDACases(1)[0];
        zdaCase.OwnerId = queueGCartera[0].Id;
        insert zdaCase;

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(2);
        emails[0].Subject += ' ' + zdaCase.CuTicketId__c;
        emails[0].GenesysQueueName__c = nameQueueUrgencias;
        emails[1].Subject = 'Email urgencia sin relacion con ningun ticket previo';
        emails[1].GenesysQueueName__c = nameQueueUrgencias;

        Test.startTest();
        insert emails;
        Test.stopTest();

        //Email relacionado con caso existente
        EmailMessage createdRelatedEmailMessage = [SELECT ParentId, RelatedToId, IsUrgent__c FROM EmailMessage WHERE Id = : emails[0].Id];

        Assert.areEqual(zdaCase.Id, createdRelatedEmailMessage.ParentId);
        Assert.areEqual(zdaCase.Id, createdRelatedEmailMessage.RelatedToId);
        Assert.isTrue(createdRelatedEmailMessage.IsUrgent__c);

        //Email NO relacionado con caso existente
        EmailMessage createdNotRelatedEmailMessage = [SELECT ParentId, IsUrgent__c, GenesysQueueName__c FROM EmailMessage WHERE Id = : emails[1].Id];

        Assert.areNotEqual(zdaCase.Id, createdNotRelatedEmailMessage.ParentId);
        Assert.isTrue(createdNotRelatedEmailMessage.IsUrgent__c);
        Assert.areEqual(GlobalConfigUtil.getGlobalConfigurationValue('Queue_FullName_GestionCartera'), createdNotRelatedEmailMessage.GenesysQueueName__c);
    }

    /**
     * Test para asignar el área de origen a casos del SAM en función del buzón
     * @author jfherrero
     * @date 17/07/2024
     */
    @isTest
    static void test_assignSourceAreaSAM_ok()
    {
        Map<String, CaseSettingsByEmail__mdt> caseSettingsByEmailMap = EmailMessagesUtil.getCaseSettingsByEmail();
        Assert.areNotEqual(0, caseSettingsByEmailMap.size(), 'Metadato CaseSettingsByEmail__mdt NO existe');

        CaseSettingsByEmail__mdt myCaseSetting = caseSettingsByEmailMap.get( new List<String>( caseSettingsByEmailMap.keyset() ).get(0) );

        List<Account> customers = TestDataFactory.generateAccounts('001', AccountUtil.CUSTOMER_RT_DEVELOPER_NAME, 1);
        customers[0].MainEmail__c = 'email.test.error@test.es';
        insert customers;

        List<Case> casesCustomer = TestDataFactory.generateCasesForEachAccount(customers, 1);
        casesCustomer[0].RecordTypeId = CaseUtil.RT_ID_SAMINQUIRY;

        insert casesCustomer;

        List<EmailMessage> emails = TestDataFactory.generateEmailMessages(1);

        emails[0].FromAddress = customers[0].MainEmail__c;
        emails[0].ToAddress = myCaseSetting.EmailAddress__c;
        emails[0].ParentId = casesCustomer[0].Id;
        emails[0].Incoming = true;

        Test.startTest();

        insert emails[0];

        Test.stopTest();

        List<Case> caseResults = [SELECT Id, SourceArea__c FROM Case WHERE Id = : casesCustomer[0].Id];

        Assert.areEqual(caseResults[0].SourceArea__c, myCaseSetting.SourceArea__c, 'El Área de origen no coincide');
    }
}