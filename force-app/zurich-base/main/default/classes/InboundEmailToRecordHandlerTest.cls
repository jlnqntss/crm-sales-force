@isTest(SeeAllData = false)
private class InboundEmailToRecordHandlerTest
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
        //1. Opportunities
        List<Opportunity> opportunities = TestDataFactory.generateOpportunities('ZE', 'Qualification', System.today(), 1);
        insert opportunities;

        //2. Emails relacionados con las oportunidades
        List<EmailMessage> emailMessages = TestDataFactory.generateEmailMessagesFromOpportunities(opportunities, EMAIL_SOPORTE, System.UserInfo.getUserEmail(), 1);
        insert emailMessages;
    }

    /**
     * Prueba que, cuando se recibe un Email que no es respuesta de otro previo, se genera
     * correctamente su oportunidad y el email queda registrado en Salesforce
     * @author rlopez
     * @date 03/11/2020
     */
    @isTest
    static void test_inboundEmail_firstEmail_ok()
    {
        //Creamos un nuevo email que no está relacionado con ninguno previamente registrado en Salesforce
        String emailSubject = 'First Email Received';
        Messaging.InboundEmail firstEmail = new Messaging.InboundEmail();
        firstEmail.subject = emailSubject;
        firstEmail.fromAddress = EMAIL_SOPORTE;
        firstEmail.headers = new List<Messaging.InboundEmail.Header>();
        firstEmail.toAddresses = new List<String> {System.UserInfo.getUserEmail()};

        Test.startTest();
        InboundEmailToRecordHandler inboundEmail = new InboundEmailToRecordHandler();
        inboundEmail.handleInboundEmail(firstEmail, null);
        Test.stopTest();

        //Comprobamos que se ha creado una oportunidad para el email recibido
        List<Opportunity> opportunitiesCreated = [SELECT Id FROM Opportunity WHERE Name =: emailSubject AND CloseDate =: System.today()];
        System.assertEquals(1, opportunitiesCreated.size(), 'There should be one new opportunity');

        //Comprobamos que se ha creado un EmailMessage relacionado con la oportunidad
        List<EmailMessage> emailMessagesCreated = [SELECT Id FROM EmailMessage WHERE RelatedToId =: opportunitiesCreated.get(0).Id];
        System.assertEquals(1, emailMessagesCreated.size(), 'There should be an EmailMessage related to the opportunity');

        //Comprobamos que se ha creado un EmailMessageRelation entre el usuario y el EmailMessage creado
        List<EmailMessageRelation> emailMessageRelationsCreated = [SELECT Id FROM EmailMessageRelation WHERE EmailMessageId =: emailMessagesCreated.get(0).Id AND RelationId =: System.UserInfo.getUserId()];
        System.assertEquals(1, emailMessageRelationsCreated.size(), 'There should be an EmailMessageRelation between the EmailMessage and the current user');
    }

    /**
     * Prueba que, cuando se recibe un email en respuesta a otro previamente relacionado con una oportunidad,
     * el nuevo email queda relacionado con la misma oportunidad y el email queda registrado en Salesforce
     * @author rlopez
     * @date 03/11/2020
     */
    @isTest
    static void test_inboundEmail_inReplyTo_ok()
    {
        //Recuperamos un email creado para añadirlo a la cabecera del nuevo email
        List<EmailMessage> existingEmails = [SELECT Id, RelatedToId FROM EmailMessage LIMIT 1];
        System.assertEquals(1, existingEmails.size(), 'There should be one EmailMessage');

        //Creamos un nuevo email
        String emailSubject = 'Second Email Received';
        Messaging.InboundEmail secondEmail = new Messaging.InboundEmail();
        secondEmail.subject = emailSubject;
        secondEmail.fromAddress = EMAIL_SOPORTE;
        secondEmail.toAddresses = new List<String> {System.UserInfo.getUserEmail()};

        //Lo relacionamos con el email previamente recuperado y que ya existe en Salesforce relacionado con una Oportunidad
        Messaging.InboundEmail.Header inReplyToEmailHeader = new Messaging.InboundEmail.Header();
        inReplyToEmailHeader.name = 'In-Reply-To';
        inReplyToEmailHeader.value = existingEmails.get(0).Id;
        Messaging.InboundEmail.Header referencesEmailHeader = new Messaging.InboundEmail.Header();
        referencesEmailHeader.name = 'References';
        referencesEmailHeader.value = '';
        secondEmail.headers = new List<Messaging.InboundEmail.Header> {inReplyToEmailHeader, referencesEmailHeader};

        Test.startTest();
        InboundEmailToRecordHandler inboundEmail = new InboundEmailToRecordHandler();
        inboundEmail.handleInboundEmail(secondEmail, null);
        Test.stopTest();

        //Comprobamos que NO se ha creado una oportunidad para el email recibido
        List<Opportunity> opportunitiesCreated = [SELECT Id FROM Opportunity WHERE Name =: emailSubject AND CloseDate =: System.today()];
        System.assertEquals(0, opportunitiesCreated.size(), 'The list should be empty');

        //Comprobamos que se ha creado un nuevo email relacionado con la oportunidad del primer email
        List<EmailMessage> emailMessagesRelatedToOpportunity = [SELECT Id FROM EmailMessage WHERE RelatedToId =: existingEmails.get(0).RelatedToId];
        System.assertEquals(2, emailMessagesRelatedToOpportunity.size(), 'There should be 2 emails related with the opportunity');

        //Comprobamos que existen 2 EmailMessageRelations entre el usuario y los EmailMessages creados
        //List<EmailMessageRelation> emailMessageRelationsCreated = [SELECT Id FROM EmailMessageRelation WHERE EmailMessageId IN: emailMessagesRelatedToOpportunity AND RelationId =: System.UserInfo.getUserId()];
        //System.assertEquals(2, emailMessageRelationsCreated.size(), 'There should be 2 EmailMessageRelations between the EmailMessages and the current user');
    }
}