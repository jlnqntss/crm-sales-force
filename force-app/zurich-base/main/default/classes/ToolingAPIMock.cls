@isTest
public with sharing class ToolingAPIMock implements HttpCalloutMock
{
    public static String RESPONSE_JSON = '{"controllerValues":{"Campañas":0,"Gestión Cliente":1},"values":[{"attributes":null,"label":"Anulación","validFor":[0],"value":"Anulación"},{"attributes":null,"label":"Cambio de intermediario","validFor":[1],"value":"Cambio de intermediario"},{"attributes":null,"label":"Campaña","validFor":[0,1],"value":"Campaña"}]}';

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'text/json');
        res.setBody(RESPONSE_JSON);
        return res;
    }
}