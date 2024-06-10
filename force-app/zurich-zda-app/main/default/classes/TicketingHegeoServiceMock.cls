/**
 * Clase para poder testear TicketingHegeoService
 *
 * @author mario.navarro@seidor.com
 * @date 22/04/2024
 */
@isTest
public with sharing class TicketingHegeoServiceMock implements HttpCalloutMock
{
    public static final Integer HTTP_CODE_OK = 200;
    public static final String RESULT_OK = 'OK';

    public static final String HEADER_CONTENT_TYPE = 'application/soap+xml;charset=utf-8';
    public static final String RESPONSE_BODY = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><NS1:Security xmlns:NS1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>2024-04-12T09:14:24.786Z</Created></Timestamp></NS1:Security></soap:Header><soap:Body><io:updateVsegTicketResponse xmlns:io="http://webservices.zurich.com/proxy/Hegeo/Ticketing/v1_0"><io:ticket><io:ticketId>102845</io:ticketId></io:ticket></io:updateVsegTicketResponse></soap:Body></soap:Envelope>';
    public static final String RESPONSE_BODY_FAULT = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body><soap:Fault><soap:Code><soap:Value>soap:Sender</soap:Value></soap:Code><soap:Reason><soap:Text xml:lang="es">ERROR DESCRIPTION</soap:Text></soap:Reason></soap:Fault></soap:Body></soap:Envelope>';
    public static final String RESPONSE_BODY_TICKET_NOT_FOUND = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><NS1:Security xmlns:NS1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>2024-04-22T11:34:35.959Z</Created></Timestamp></NS1:Security></soap:Header><soap:Body><io:updateVsegTicketResponse xmlns:io="http://webservices.zurich.com/proxy/Hegeo/Ticketing/v1_0"><io:status><io:errorCode>2</io:errorCode><io:errorDescription>Error al recuperar el identificador</io:errorDescription></io:status><io:ticket><io:ticketId>12345678901234567890</io:ticketId></io:ticket></io:updateVsegTicketResponse></soap:Body></soap:Envelope>';

    private Integer statusCode;
    private String status;
    private String contentType;
    private String body;
    private Boolean throwCalloutException;

    public TicketingHegeoServiceMock(Integer statusCode, String status, String contentType, String body, Boolean throwCalloutException)
    {
        this.statusCode = statusCode;
        this.status = status;
        this.contentType = contentType;
        this.body = body;
        this.throwCalloutException = throwCalloutException;
    }

    /**
     * Implementacion del metodo respond de la interfaz HttpCalloutMock
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     * @param req la peticion a realizar
     * @return la respuesta HTTP simulada
     */
    public HTTPResponse respond(HTTPRequest req)
    {
        if (this.throwCalloutException)
        {
            CalloutException e = new CalloutException();
            e.setMessage('Mocked exception');
            throw e;
        }
        else
        {
            HTTPResponse res = new HTTPResponse();
            res.setStatus(this.status);
            res.setStatusCode(this.statusCode);
            if (this.statusCode == 200)
            {
                res.setHeader('Content-Type', this.contentType);
                res.setBody(this.body);
            }
            return res;
        }
    }

}