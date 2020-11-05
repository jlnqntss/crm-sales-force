@isTest
global class GenesysCloudMocks implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        //Respuesta FAKE para:
        // /platform/api/v2/conversations/emails
        // /platform/api/v2/conversations/emails/{conversationId}/participants/{participantId}/replace
        if(req.getMethod() == 'POST')
        {
            if(req.getEndpoint().contains('replace'))
            {
                //El replace no devuelve un body si la respuesta ha ido bien:
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                return res;
            }
            else{
                //TODO: falta definir qué se necesita del body de la respuesta:
                //https://developer.mypurecloud.com/api/rest/v2/conversations/#response-json-post-api-v2-conversations-emails-200
            }
        }

        //Respuesta FAKE para:
        // /platform/api/v2/conversations/emails/{conversationId}
        else if(req.getMethod() == 'PATCH')
        {
                //TODO: falta definir qué se necesita del body de la respuesta:
                //https://developer.mypurecloud.com/api/rest/v2/conversations/#response-json-patch-api-v2-conversations-emails--conversationId--200
        }

        //TODO: falta definir respuesta FAKE para RoutingWork

        //BAD REQUEST
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        return res;
    }
}