/**
 * Clase de test para TicketingHegeoService
 *
 * @author mario.navarro@seidor.com
 * @date 22/04/2024
 */
@isTest
private with sharing class Test_TicketingHegeoService
{

    /**
     * Testea que el envio se ha realizado correctamente
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendOk()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();

        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            TicketingHegeoServiceMock.HTTP_CODE_OK,
            TicketingHegeoServiceMock.RESULT_OK,
            TicketingHegeoServiceMock.HEADER_CONTENT_TYPE,
            TicketingHegeoServiceMock.RESPONSE_BODY,
            false
            );

        String response;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        response = TicketingHegeoService.updateVsegTicket(request);
        Test.stopTest();

        Assert.areEqual(TicketingHegeoServiceMock.RESULT_OK, response);
    }

    /**
     * Testea que se lanza una excepcion si hay algun campo de la request no informado
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendException()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();
        request.ticket.event = null;

        Test.startTest();
        try
        {
            TicketingHegeoService.updateVsegTicket(request);
            Assert.fail('Se deberia haber producido una excepcion al no haberse informado el campo event');
        }
        catch (Exception ex)
        {}
        Test.stopTest();
    }

    /**
     * Testea que si hay una excepcion en el callout escribe un registro de ErrorLog__c
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendCalloutException()
    {
        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            null,
            null,
            null,
            null,
            true
            );

        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();

        String response;
        Test.startTest();
        response = TicketingHegeoService.updateVsegTicket(request);
        Test.stopTest();

        List<Error_Log__c> foundErrors = [SELECT Id FROM Error_Log__c WHERE Source_Class__c = : TicketingHegeoService.class.getName() AND Source_Method__c = 'updateVsegTicket'];

        Assert.areEqual('KO', response);
        Assert.isFalse( foundErrors.isEmpty() );
        Assert.areEqual( 1, foundErrors.size() );
    }

    /**
     * Testea que el envio da error de autenticacion
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendUnauthorized()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();

        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            401,
            'Unauthorized',
            null,
            null,
            false
            );

        String response;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        response = TicketingHegeoService.updateVsegTicket(request);
        Test.stopTest();

        Assert.areEqual('401 - Unauthorized', response);
    }

    /**
     * Testea que el envio da error de tipo SOAP FAULT
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendSoapFault()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();
        
        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            TicketingHegeoServiceMock.HTTP_CODE_OK,
            TicketingHegeoServiceMock.RESULT_OK,
            TicketingHegeoServiceMock.HEADER_CONTENT_TYPE,
            TicketingHegeoServiceMock.RESPONSE_BODY_FAULT,
            false
            );

        String response;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        response = TicketingHegeoService.updateVsegTicket(request);
        Test.stopTest();

        Assert.areEqual('soap:Sender - ERROR DESCRIPTION', response);
    }

    /**
     * Testea que el envio da error porque no se ha encontrado el ticket en canal unico
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_sendTicketNotFound()
    {
        CanalUnicoUpdateVsegTicketRequest request = Test_TicketingHegeoService.generateRequest();
        
        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            TicketingHegeoServiceMock.HTTP_CODE_OK,
            TicketingHegeoServiceMock.RESULT_OK,
            TicketingHegeoServiceMock.HEADER_CONTENT_TYPE,
            TicketingHegeoServiceMock.RESPONSE_BODY_TICKET_NOT_FOUND,
            false
            );

        String response;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        response = TicketingHegeoService.updateVsegTicket(request);
        Test.stopTest();

        Assert.areEqual('Error al recuperar el identificador', response);
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
        ticket.event = '1';
        ticket.ticketStatus = '1';
        ticket.ticketSubStatus = '0';
        ticket.eventReason = '1';
        ticket.estimatedEndDate = DateTime.now();

        CanalUnicoUpdateVsegTicketRequest request = new CanalUnicoUpdateVsegTicketRequest();
        request.ticket = ticket;

        return request;
    }
}