/**
 * Clase de test para CanalUnicoUpdateVsegTicketRequest
 *
 * @author mario.navarro@seidor.com
 * @date 22/04/2024
 */
@isTest
private with sharing class Test_CanalUnicoUpdateVsegTicketRequest
{

    /**
     * Testea que el metodo buildRequest de la clase CanalUnicoUpdateVsegTicketRequest genera el cuerpo
     * de la peticion correctamente
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_buildRequest()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        Test.startTest();
        String soapRequest = request.buildRequest();
        Test.stopTest();

        Assert.areNotEqual(null, soapRequest, 'Peticion SOAP no deberia ser nulo');
        Assert.areNotEqual('', soapRequest, 'Peticion SOAP no deberia estar vacia');
        Assert.isTrue(soapRequest.contains('<v1:updateVsegTicketRequest>'), 'Peticion SOAP deberia contener <v1:updateVsegTicketRequest>');
        Assert.isTrue(soapRequest.contains('<v1:ticketId>' + request.ticket.ticketId + '</v1:ticketId>'), 'Peticion SOAP deberia contener ticketId correcto');
        Assert.isTrue(soapRequest.contains('<v1:externalTicketId>' + request.ticket.externalTicketId + '</v1:externalTicketId>'), 'Peticion SOAP deberia contener externalTicketId correcto');
    }

    /**
     * Testea que el metodo buildRequest de la clase CanalUnicoUpdateVsegTicketRequest genera excepciones
     * en caso de que los valores del objeto request no sean correctos
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_buildRequest_ko()
    {
        //Valor nulo event
        CanalUnicoUpdateVsegTicketRequest reqEventNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqEventNull.ticket.event = null;
        Boolean reqEventNullThrown = false;
        //Valor invalido event
        CanalUnicoUpdateVsegTicketRequest reqEventInvalid = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqEventInvalid.ticket.event = 55;
        Boolean reqEventInvalidThrown = false;
        //Valor nulo ticketStatus
        CanalUnicoUpdateVsegTicketRequest reqTicketStatusNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqTicketStatusNull.ticket.ticketStatus = null;
        Boolean reqTicketStatusNullThrown = false;
        //Valor invalido ticketStatus
        CanalUnicoUpdateVsegTicketRequest reqTicketStatusInvalid = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqTicketStatusInvalid.ticket.ticketStatus = 55;
        Boolean reqTicketStatusInvalidThrown = false;
        //Valor nulo ticketSubStatus
        CanalUnicoUpdateVsegTicketRequest reqTicketSubStatusNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqTicketSubStatusNull.ticket.ticketSubStatus = null;
        Boolean reqTicketSubStatusNullThrown = false;
        //Valor invalido ticketSubStatus
        CanalUnicoUpdateVsegTicketRequest reqTicketSubStatusInvalid = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqTicketSubStatusInvalid.ticket.ticketSubStatus = 55;
        Boolean reqTicketSubStatusInvalidThrown = false;

        Test.startTest();
        reqEventNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqEventNull);
        reqEventInvalidThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqEventInvalid);
        reqTicketStatusNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqTicketStatusNull);
        reqTicketStatusInvalidThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqTicketStatusInvalid);
        reqTicketSubStatusNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqTicketSubStatusNull);
        reqTicketSubStatusInvalidThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqTicketSubStatusInvalid);
        Test.stopTest();

        Assert.isTrue(reqEventNullThrown, 'Se deberia haber lanzado una excepcion de event null');
        Assert.isTrue(reqEventInvalidThrown, 'Se deberia haber lanzado una excepcion de event invalido');
        Assert.isTrue(reqTicketStatusNullThrown, 'Se deberia haber lanzado una excepcion de ticket status null');
        Assert.isTrue(reqTicketStatusInvalidThrown, 'Se deberia haber lanzado una excepcion de ticket status invalido');
        Assert.isTrue(reqTicketSubStatusNullThrown, 'Se deberia haber lanzado una excepcion de ticket substatus null');
        Assert.isTrue(reqTicketSubStatusInvalidThrown, 'Se deberia haber lanzado una excepcion de ticket substatus invalido');
    }

    /**
     * Testea que el metodo buildRequest de la clase CanalUnicoUpdateVsegTicketRequest genera excepciones
     * en caso de que los valores del objeto CanalUnicoQuote no sean correctos
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_buildRequestCanalUnicoQuote_ko()
    {
        //Valor nulo duration
        CanalUnicoUpdateVsegTicketRequest reqDurationNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqDurationNull.ticket.quotesList[0].duration = null;
        Boolean reqDurationNullThrown = false;
        //Valor nulo anualNetPremium
        CanalUnicoUpdateVsegTicketRequest reqAnualNetPremiumNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqAnualNetPremiumNull.ticket.quotesList[0].anualNetPremium = null;
        Boolean reqAnualNetPremiumNullThrown = false;
        //Valor nulo totalAnualReceipt
        CanalUnicoUpdateVsegTicketRequest reqTotalAnualReceiptNull = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqTotalAnualReceiptNull.ticket.quotesList[0].totalAnualReceipt = null;
        Boolean reqTotalAnualReceiptNullThrown = false;
        //Valor invalido paymentType
        CanalUnicoUpdateVsegTicketRequest reqPaymentTypeInvalid = Test_CanalUnicoUpdateVsegTicketRequest.generateRequest();
        reqPaymentTypeInvalid.ticket.quotesList[0].paymentType = '55';
        Boolean reqPaymentTypeThrown = false;

        Test.startTest();
        reqDurationNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqDurationNull);
        reqAnualNetPremiumNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqAnualNetPremiumNull);
        reqTotalAnualReceiptNullThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqTotalAnualReceiptNull);
        reqPaymentTypeThrown = Test_CanalUnicoUpdateVsegTicketRequest.isExceptionOnBuild(reqPaymentTypeInvalid);
        Test.stopTest();

        Assert.isTrue(reqDurationNullThrown, 'Se deberia haber lanzado una excepcion de duration null');
        Assert.isTrue(reqAnualNetPremiumNullThrown, 'Se deberia haber lanzado una excepcion de anualNetPremium null');
        Assert.isTrue(reqTotalAnualReceiptNullThrown, 'Se deberia haber lanzado una excepcion de totalAnualReceipt null');
        Assert.isTrue(reqPaymentTypeThrown, 'Se deberia haber lanzado una excepcion de paymentType invalido');
    }

    /**
     * Ejecuta el build y comprueba si se lanza excepcion
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     * @return true si se ha producido excepcion, false en caso contrario
     */
    private static Boolean isExceptionOnBuild(CanalUnicoUpdateVsegTicketRequest request)
    {
        try
        {
            request.buildRequest();
            return false;
        }
        catch (Exception ex)
        {
            return true;
        }
    }

    /**
     * Genera una request para la ejecucion de los diferentes tests
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     * @return CanalUnicoUpdateVsegTicketRequest la request generada
     */
    private static CanalUnicoUpdateVsegTicketRequest generateRequest()
    {
        CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        ticket.ticketId = '12345678901234567890';
        ticket.externalTicketId = 'SF-123';
        ticket.event = 1;
        ticket.ticketStatus = 1;
        ticket.ticketSubStatus = 0;
        ticket.subStatusDesc = 'SubStatus Description';
        ticket.agent = 'Test Agent';
        ticket.eventDate = DateTime.now();
        ticket.eventReason = 1;
        ticket.eventDesc = 'Test Event Description';
        ticket.estimatedEndDate = DateTime.now();
        ticket.comments = 'Test Comments';

        CanalUnicoUpdateVsegTicketRequest.CanalUnicoQuote quote = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoQuote();
        quote.externalQuoteId = 'Q123';
        quote.company = 'ZURICH';
        quote.modality = 'Test Modality';
        quote.paymentType = '1';
        quote.duration = DateTime.now();
        quote.anualNetPremium = 1000.00;
        quote.totalAnualReceipt = 1200.00;
        quote.comments = 'Test Quote Comments';
        quote.eventReason = 'Test Event Reason';
        quote.eventDesc = 'Test Event Description';

        CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument document = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument();
        document.documentCode = 'DOC001';

        CanalUnicoUpdateVsegTicketRequest.CanalUnicoAttachedDocument attachedDocument = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoAttachedDocument();
        attachedDocument.fileName = 'TestFile.txt';
        attachedDocument.mimeType = 'text/plain';
        attachedDocument.data = 'Test data';
        attachedDocument.encoding = 'UTF-8';
        document.attachedDocument = attachedDocument;

        quote.documentList = new List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument> {document};
        ticket.quotesList = new List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoQuote> {quote};
        ticket.documentList = new List<CanalUnicoUpdateVsegTicketRequest.CanalUnicoDocument> {document};

        CanalUnicoUpdateVsegTicketRequest request = new CanalUnicoUpdateVsegTicketRequest();
        request.ticket = ticket;

        return request;
    }

}