/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 20-10-2021
 * @last modified by  : jjuaristi
**/
@RestResource(urlMapping = '/genesys-cloud/*/*')
global without sharing class WS_GenesysAPIService extends WS_BaseAPIService
{
    /**
     * Recibe y procesa peticiones GET
     * Identifica el resource, procesa los parámetros y los delega a una segunda clase
     * @author jmartinezpisson
     * @date 22/10/2020
     */
    @HttpGet
    global static void doGet()
    {
        Savepoint sp = Database.setSavepoint();
        RestResponse response = RestContext.response;

        response.addHeader('Content-Type', 'application/json');

        try
        {
            WS_GenesysAPIService.validateRequest();

            switch on WS_BaseAPIService.resource {
                // 1 - GET /people: Procesa búsqueda de clientes
                when 'people' {
                    GenesysInteractionsService.version =  WS_BaseAPIService.version;
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(
                        GenesysInteractionsService.findPeopleBy(new GenesysInteractionsService.SearchRequest(RestContext.request.params) ).toString()
                    );
                }
                // 2 - GET /policies: Procesa búsqueda de pólizas
                when 'policies' {
                    GenesysInteractionsService.version =  WS_BaseAPIService.version;
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(
                        GenesysInteractionsService.findActivePolicy(RestContext.request.requestURI.substringAfterLast('/')).toString()
                    );
                }
                // 3 - GET /claims: Procesa búsqueda de siniestros
                when 'claims' {
                    GenesysInteractionsService.version =  WS_BaseAPIService.version;
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(
                        GenesysInteractionsService.findOpenedClaim(new GenesysInteractionsService.SearchRequest(RestContext.request.params) ).toString()
                    );
                }
                when 'digitalcustomer' {
                    GenesysInteractionsService.version =  WS_BaseAPIService.version;
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(
                        GenesysInteractionsService.findDigitalCustomer(new GenesysInteractionsService.DigitalCustomer(RestContext.request.params)).toString()
                    );
                }
                when else 
                {
                    // else code
                }
            }
        }
        catch (WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(apiError.toErrorString() );
        }
        catch (GenesysInteractionsService.GenesysPeopleServiceException genesysServiceError)
        {
            Database.rollback(sp);
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(
                WS_BaseAPIService.API_BAD_REQUEST_KO, genesysServiceError.getMessage(), false).toErrorString());
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, genesysServiceError.getMessage(),
                GenesysInteractionsService.class.getName(), genesysServiceError.getStackTraceString());
        }
        catch (GenesysInteractionsService.GenesysPoliciesServiceException genesysServiceError)
        {
            Database.rollback(sp);
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(
                WS_BaseAPIService.API_BAD_REQUEST_KO, genesysServiceError.getMessage(), false).toErrorString());
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, genesysServiceError.getMessage(),
                GenesysInteractionsService.class.getName(), genesysServiceError.getStackTraceString());
        }
        catch (GenesysInteractionsService.GenesysClaimsServiceException genesysServiceError)
        {
            Database.rollback(sp);
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(
                WS_BaseAPIService.API_BAD_REQUEST_KO, genesysServiceError.getMessage(), false).toErrorString());
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, genesysServiceError.getMessage(),
                GenesysInteractionsService.class.getName(), genesysServiceError.getStackTraceString());
        }
        catch (GenesysInteractionsService.GenesysInteractionsServiceException genesysServiceError)
        {
            Database.rollback(sp);
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(
                WS_BaseAPIService.API_BAD_REQUEST_KO, genesysServiceError.getMessage(), false).toErrorString());
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, genesysServiceError.getMessage(),
                GenesysInteractionsService.class.getName(), genesysServiceError.getStackTraceString());
        }
        catch (DmlException dmlError)
        {
            Database.rollback(sp);
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(dmlError).toErrorString() );
        }
        catch (Exception genericError)
        {
            Database.rollback(sp);
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_GENERIC_KO, genericError.getMessage() ).toErrorString() );
        }
    }

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

        response.addHeader('Content-Type', 'application/json');

        Savepoint sp = Database.setSavepoint();

        try
        {
            validateRequest();

            String resource = WS_BaseAPIService.resource;
            Integer version = WS_BaseAPIService.version;
            String vendor = WS_BaseAPIService.vendor;

            switch on resource {
                when 'interactions' {
                    GenesysInteractionsService.version = version;

                    // Init Interaction Resource
                    if ( RestContext.request.requestURI.endsWith('/init') )
                    {
                        GenesysInteractionsService.Interaction interaction = GenesysInteractionsService.initInteraction(
                            (GenesysInteractionsService.Interaction) JSON.deserialize(
                                request.requestBody.toString(),
                                GenesysInteractionsService.Interaction.class
                                ) );

                        response.statusCode = 200;
                        response.responseBody = Blob.valueOf(interaction.toString() );
                    }
                }// POST /surveys: Upsert de encuestas y sus respuestas
                when 'surveys' {
                    GenesysSurveysService.version =  WS_BaseAPIService.version;
                    GenesysSurveysService.initSurvey((GenesysSurveysService.Survey) JSON.deserialize(request.requestBody.toString(), GenesysSurveysService.Survey.class));
                    response.statusCode = 200;
                }
                when else 
                {
                    // else code
                }
            }
        }
        catch (WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);

            response.statusCode = 400;
            response.responseBody = Blob.valueOf(apiError.toErrorString() );
        }
        catch (DmlException dmlError)
        {
            Database.rollback(sp);

            response.statusCode = 500;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(dmlError).toErrorString() );
        }
        catch (Exception genericError)
        {
            Database.rollback(sp);

            response.statusCode = 500;
            response.responseBody = Blob.valueOf(new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_GENERIC_KO, genericError.getMessage() ).toErrorString() );
        }
    }
}
