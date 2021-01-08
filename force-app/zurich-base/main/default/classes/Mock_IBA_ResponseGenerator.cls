/**
 * Global class to specify the response expected of the http callout made to IBA.
 * @Autor: nbizkarra (04/05/2020)
 *
 * @change: nts (agonzalezisasi) - 27/oct/2020 - Add Error status code
 * @change: nts (agonzalezisasi) - 11/dic/2020 - Include response error log 
 **/

@isTest
global class Mock_IBA_ResponseGenerator implements HttpCalloutMock
{
    static global HTTPResponse respond(HTTPRequest req)
    {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(Label.IBA_Response_Body);
        if( req.getBody().contains('{Test KO}') )
        {
            res.setStatusCode(400);
            res.setBody('Error log test');
        }
        else
        {
            res.setStatusCode(200);
        }
        return res;
    }
}