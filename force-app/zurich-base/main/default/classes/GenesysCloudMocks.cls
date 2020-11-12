@isTest
global class GenesysCloudMocks implements HttpCalloutMock {

    String body;
    Integer code;

    public GenesysCloudMocks(String body, Integer code)
    {
        this.body = body;
        this.code = code;
    }

    global HTTPResponse respond(HTTPRequest req) {

        //Respuesta FAKE
        if(req.getMethod() == 'POST')
        {
            if(req.getEndpoint().contains('/api/v2/conversations/emails'))
            {
                HttpResponse res = new HttpResponse();
                res.setBody(body);
                res.setStatusCode(code);
                return res;
            }
        }

        //No está implementado aún en el mock la respuesta:
        HttpResponse res = new HttpResponse();
        res.setStatusCode(500);
        return res;
    }
}