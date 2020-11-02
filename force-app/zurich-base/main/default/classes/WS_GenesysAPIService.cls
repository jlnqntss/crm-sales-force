@RestResource(urlMapping = '/genesys-cloud/*/*')
global without sharing class WS_GenesysAPIService extends WS_BaseAPIService
{
    static final String INVALID_URI_MESSAGE = 'Invalid URI versioning';
    static final String INVALID_CONTENTTYPE_MESSAGE = 'Invalid Content-Type on request headers';
    static final String REGEXP_URI = 'v[0-9]+$';
    /**
     * Recibe las peticiones POST provenientes de genesys
     * Dependiendo del resource se llamará a una clase u otra de apex
     * De momento solo está implementado 'iteractions'
     * Dependiendo de la función, llamará a un método de GenesysInteractionsSerive u otro
     * De momento solo está implementado 'init'
     * @author nescudero
     * @date 22/10/2020
     */
    @HttpPost
    global static void doPost()
    {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        Savepoint sp = Database.setSavepoint();

        try
        {
            response.addHeader('Content-Type', 'application/json');

            //Si la versión no es correcta, lanzamos error
            if(!WS_BaseAPIService.isValidVersion)
            {
                response.statusCode = 400;
                throw new WS_BaseAPIService.ApiException('BAD_REQUEST', INVALID_URI_MESSAGE);
            }

            //Si la cabecera content-type no es JSON, lanzamos error
            if(!WS_BaseAPIService.isJSONContentType)
            {
                response.statusCode = 400;
                throw new WS_BaseAPIService.ApiException('BAD_REQUEST', INVALID_CONTENTTYPE_MESSAGE);
            }

            String resource = WS_BaseAPIService.resource;
            Integer version = WS_BaseAPIService.version;
            String vendor = WS_BaseAPIService.vendor;

            switch on resource {
                when 'interactions' {
                    GenesysInteractionsService.version = version;
                    if (RestContext.request.requestURI.endsWith('/init') )
                    {
                        GenesysInteractionsService.InteractionRequest interactionRequest = (GenesysInteractionsService.InteractionRequest) JSON.deserialize(
                            request.requestBody.toString(),
                            GenesysInteractionsService.InteractionRequest.class
                            );
                        GenesysInteractionsService.BestAgent bestAgent = GenesysInteractionsService.initInteraction(
                            interactionRequest
                            );
                        response.responseBody = Blob.valueOf(JSON.serialize(bestAgent) );
                        response.statusCode = 201;
                    }
                }
            }
        }
        catch (WS_BaseAPIService.ApiException exAPI)
        {
            Database.rollback(sp);

            response.statusCode = 400;
            response.responseBody = Blob.valueOf(JSON.serialize(exAPI) );
        }
        catch (Exception e)
        {
            Database.rollback(sp);
            ErrorLogUtil.commitError(e);

            response.statusCode = 500;
            response.responseBody = Blob.valueOf(JSON.serialize(e) );
        }
    }
}
