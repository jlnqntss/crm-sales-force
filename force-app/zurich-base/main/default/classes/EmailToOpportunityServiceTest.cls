@isTest(SeeAllData = false)
private class EmailToOpportunityServiceTest
{
    static final String EMAIL_SOPORTE = 'soporte-ocs@nts-solutions.com';
    /**
     * Preparación de datos para los tests
     **
     * @author rlopez
     * @date 03/11/2020
     */
    @testSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 1);
        insert contactPointEmails;

        contactPointEmails.get(0).EmailAddress = EMAIL_SOPORTE;
        update contactPointEmails.get(0);

        List<Opportunity> opportunities = TestDataFactory.generateOpportunities(accounts, 'ZE', 'Qualification', System.today(), 10);
        insert opportunities;

        List<EmailMessage> emailMessages = TestDataFactory.generateEmailMessagesFromOpportunities(opportunities, 1);
        insert emailMessages;

        List<EmailMessageRelation> emailMessageRelations = TestDataFactory.generateEmailMessageRelations(emailMessages, UserInfo.getUserId(), 'ToAddress');
        insert emailMessageRelations;
    }

    /**
     * Prueba que, cuando se recibe un Email que no es respuesta de otro previo,
     * el email queda registrado en Salesforce pero sin estar relacionado
     * @author rlopez
     * @date 03/11/2020
     */
    @isTest
    static void test_inboundEmail_firstEmail_ok()
    {
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks('{"id":"1JB9ZmJnCCKXlerwxAOZXC"}', 200);

        //Creamos un nuevo email que no está relacionado con ninguno previamente registrado en Salesforce
        String emailSubject = 'First Email Received';
        Messaging.InboundEmail firstEmail = new Messaging.InboundEmail();
        firstEmail.subject = emailSubject;
        firstEmail.fromAddress = EMAIL_SOPORTE;
        firstEmail.headers = new List<Messaging.InboundEmail.Header>();
        firstEmail.toAddresses = new List<String> {System.UserInfo.getUserEmail()};

        // SOSL - Resultados de búsqueda
        Set<String> contactPointRecordIds = new Set<String>();

        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointEmail WHERE EmailAddress =: EMAIL_SOPORTE])
        {
            contactPointRecordIds.add(contactPoint.ParentId);
            contactPointRecordIds.add(contactPoint.Id);
        }

        Test.setFixedSearchResults( new List<String>(contactPointRecordIds) );

        Test.startTest();
        EmailToOpportunityService.searchRelatedEmailAndOpportunity(firstEmail, null);
        Test.stopTest();

        //Comprobamos que NO se ha creado una oportunidad para el email recibido
        List<Opportunity> opportunitiesCreated = [SELECT Id FROM Opportunity WHERE Name =: emailSubject AND CloseDate =: System.today()];
        System.assertEquals(0, opportunitiesCreated.size(), 'There shouldnt be one new opportunity');

        //Instanciamos EmailMessagesSelector
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'RelatedToId'};

        //Comprobamos que se ha creado un EmailMessage "huérfano"
        List<EmailMessage> emailMessagesCreated = emailMessagesSelectorObj.selectBySubject(new List<String> {emailSubject});
        System.assertEquals(false, emailMessagesCreated.isEmpty(), 'List shoudnt be empty');
        System.assertEquals(1, emailMessagesCreated.size(), 'There should be an EmailMessage');
        System.assertEquals(true, String.isNotEmpty(emailMessagesCreated.get(0).RelatedToId), 'RelatedToId field should be not empty');

        //Recuperamos el Contacto para la dirección de email
        List<Contact> contactsByEmail = new ContactsSelector().applyScope('all').findByEmail(new List<String> { EMAIL_SOPORTE });
        System.assertEquals(false, contactsByEmail.isEmpty(), 'List shoudnt be empty');

        //Comprobamos que se ha creado un EmailMessageRelation entre el contacto y el EmailMessage creado
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id'};
        List<EmailMessageRelation> emailMessageRelationsCreated = emailMessagesSelectorObj.selectRelationByEmailAndRelation(new Set<String> {emailMessagesCreated.get(0).Id}, new Set<String> {contactsByEmail.get(0).Id});
        System.assertEquals(1, emailMessageRelationsCreated.size(), 'There should be an EmailMessageRelation between the EmailMessage and the email contact');
    }

    /**
     * Prueba que, cuando se recibe un email en respuesta a otro previamente relacionado con una oportunidad,
     * el nuevo email queda registrado en Salesforce y relacionado con la misma oportunidad
     * @author rlopez
     * @date 03/11/2020
     */
    @isTest
    static void test_inboundEmail_inReplyTo_ok()
    {
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks('{"id":"1JB9ZmJnCCKXlerwxAOZXC"}', 200);

        //Recuperamos un email creado para añadirlo a la cabecera del nuevo email
        List<EmailMessage> existingEmails = [SELECT Id, RelatedToId FROM EmailMessage LIMIT 1];
        // FIXME: System.assertEquals(1, existingEmails.size(), 'There should be one EmailMessage');

        //Creamos un nuevo email
        String emailSubject = 'Second Email Received';
        Messaging.InboundEmail secondEmail = new Messaging.InboundEmail();
        secondEmail.subject = emailSubject;
        secondEmail.fromAddress = EMAIL_SOPORTE;
        secondEmail.toAddresses = new List<String> {System.UserInfo.getUserEmail()};

        //Lo relacionamos, a traves de las cabeceras, con el email previamente recuperado y que ya existe en Salesforce relacionado con una Oportunidad
        Messaging.InboundEmail.Header inReplyToEmailHeader = new Messaging.InboundEmail.Header();
        inReplyToEmailHeader.name = 'In-Reply-To';
        inReplyToEmailHeader.value = existingEmails.get(0).Id;
        Messaging.InboundEmail.Header referencesEmailHeader = new Messaging.InboundEmail.Header();
        referencesEmailHeader.name = 'References';
        referencesEmailHeader.value = '';
        secondEmail.headers = new List<Messaging.InboundEmail.Header> {inReplyToEmailHeader, referencesEmailHeader};

        // SOSL - Resultados de búsqueda
        Set<String> contactPointRecordIds = new Set<String>();

        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointEmail WHERE EmailAddress =: EMAIL_SOPORTE])
        {
            contactPointRecordIds.add(contactPoint.ParentId);
            contactPointRecordIds.add(contactPoint.Id);
        }

        Test.setFixedSearchResults( new List<String>(contactPointRecordIds) );

        Test.startTest();
        EmailToOpportunityService.searchRelatedEmailAndOpportunity(secondEmail, null);
        Test.stopTest();

        //Comprobamos que NO se ha creado una oportunidad para el email recibido
        List<Opportunity> opportunitiesCreated = [SELECT Id FROM Opportunity WHERE Name =: emailSubject AND CloseDate =: System.today()];
        // FIXME: System.assertEquals(0, opportunitiesCreated.size(), 'The list should be empty');

        //Instanciamos EmailMessagesSelector
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id'};

        //Comprobamos que se ha creado un nuevo email relacionado con la oportunidad del primer email
        List<EmailMessage> emailMessagesRelatedToOpportunity = emailMessagesSelectorObj.selectByRelatedObjectId(new Set<String> {existingEmails.get(0).RelatedToId});
        // FIXME: System.assertEquals(2, emailMessagesRelatedToOpportunity.size(), 'There should be 2 emails related with the opportunity');

        //Recuperamos el último email creado para comprobar si se ha creado correctamente la relación con el contacto
        List<EmailMessage> emailMessagesCreated = emailMessagesSelectorObj.selectBySubject(new List<String> {emailSubject});
        // FIXME: System.assertEquals(1, emailMessagesCreated.size(), 'There should be an EmailMessage');

        //Recuperamos el Contacto para la dirección de email
        List<Contact> contactsByEmail = new ContactsSelector().applyScope('all').findByEmail(new List<String> { EMAIL_SOPORTE });
        // FIXME: System.assertEquals(false, contactsByEmail.isEmpty(), 'List shoudnt be empty');

        //Comprobamos que se ha creado un EmailMessageRelation entre el contacto y el EmailMessage creado
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id'};
        List<EmailMessageRelation> emailMessageRelationsCreated = emailMessagesSelectorObj.selectRelationByEmailAndRelation(new Set<String> {emailMessagesCreated.get(0).Id}, new Set<String> {contactsByEmail.get(0).Id});
        // FIXME: System.assertEquals(1, emailMessageRelationsCreated.size(), 'There should be an EmailMessageRelation between the EmailMessage and the email contact');
    }
}