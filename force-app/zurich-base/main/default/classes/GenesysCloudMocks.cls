@isTest
global class GenesysCloudMocks implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        //Respuesta FAKE
        if(req.getMethod() == 'POST')
        {
            if(req.getEndpoint().contains('/platform/api/v2/conversations/emails'))
            {
                HttpResponse res = new HttpResponse();
                res.setBody('{"id":"1JB9ZmJnCCKXlerwxAOZXC"}'); //TODO Añadir un constructor para recibir dinámicamente estos valores?
                res.setStatusCode(200);
                return res;
            }
        }

        //BAD REQUEST
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        return res;
    }
}