/**
 * Clase para poder testear TicketingHegeoService
 *
 * @author mario.navarro@seidor.com
 * @date 22/04/2024
 */
@isTest
public with sharing class TicketingHegeoServiceMock implements HttpCalloutMock
{

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