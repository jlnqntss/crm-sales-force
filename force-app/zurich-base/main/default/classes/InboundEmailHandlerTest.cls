@isTest(SeeAllData = false)
private class InboundEmailHandlerTest
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
        List<Opportunity> opportunities = TestDataFactory.generateOpportunities('ZE', 'Qualification', System.today(), 10);
        insert opportunities;

        List<EmailMessage> emailMessages = TestDataFactory.generateEmailMessagesFromOpportunities(opportunities, 1);
        insert emailMessages;

        List<EmailMessageRelation> emailMessageRelations = TestDataFactory.generateEmailMessageRelations(emailMessages, UserInfo.getUserId(), 'ToAddress');
        insert emailMessageRelations;
    }

    /**
     * Prueba que se realiza correctamente la ejecución de EmailToOpportunity y
     * que el campo success es true
     * @author rlopez
     * @date 10/11/2020
     */
    @isTest
    static void test_handleInboundEmail_ok()
    {
        //Creamos un nuevo email que no está relacionado con ninguno previamente registrado en Salesforce
        String emailSubject = 'Inbound Email Received';
        Messaging.InboundEmail firstEmail = new Messaging.InboundEmail();
        firstEmail.subject = emailSubject;
        firstEmail.fromAddress = EMAIL_SOPORTE;
        firstEmail.headers = new List<Messaging.InboundEmail.Header>();
        firstEmail.toAddresses = new List<String> {System.UserInfo.getUserEmail()};

        Test.startTest();
        InboundEmailHandler inboundEmail = new InboundEmailHandler();
        Messaging.InboundEmailResult emailResult = inboundEmail.handleInboundEmail(firstEmail, null);
        Test.stopTest();

        System.assertEquals(true, emailResult.success, 'Success should be true');
    }
}