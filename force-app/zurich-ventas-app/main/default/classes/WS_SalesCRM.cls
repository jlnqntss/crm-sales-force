/**
 * @description       : Clase que implementa un servicio REST que servirá de API
 * para los Web Services relacionados con el CRM de Ventas
 *
 * @author            : amiranda
 * @date              : 22-09-2023
 * @last modified on  : 22-09-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   01-09-2023   amiranda   Initial Version
 **/
@RestResource(urlMapping = '/zrm/*/*')
global with sharing class WS_SalesCRM extends WS_BaseAPIService
{
    // #region Constants

    private static final String INTERNAL_ERROR = 'INTERNAL_ERROR';
    private static final String CONTACT_CENTER = 'CONTACT_CENTER';

    // #endregion

    // #region API Rest methods

    /**
     * @description Método post que recibe la información del formulario web para
     * la entrada de Leads y generación de ofertas relacionadas con dicho Lead.
     *
     * @author amiranda
     * @date 01-09-2023
     **/
    @HttpPost
    global static void doPost()
    {
        // Se establece un punto de rollback
        Savepoint sp = Database.setSavepoint();

        // Variables de contexto API Rest
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;

        // Para la traza de la peticion, inicialmente presuponemos que irá bien
        String requestResultType = ErrorLogUtil.ERROR_LEVEL_WARNING;
        String requestResult = 'OK.200';
        String requestResultErrorMessage;
        String requestResultErrorStackTrace;
        
        response.addHeader('Content-Type', 'application/json');

        // Si no se lanza ninguna excepción significa que la petición se ha procesado OK
        response.statusCode = 200;

        try
        {
            validateRequest();

            String resource = WS_BaseAPIService.resource;
            String requestInformation = request.requestBody.toString();

            switch on resource
            {
                when 'leadGeneration'
                {
                    SalesCRMLeadGenerationService.Lead deserializedRequest = (SalesCRMLeadGenerationService.Lead) JSON.deserializeStrict(
                        requestInformation,
                        SalesCRMLeadGenerationService.Lead.class);

                    SalesCRMLeadGenerationService.validateRequestData(deserializedRequest);

                    Account leadAccount = SalesCRMLeadGenerationService.manageLead(deserializedRequest);
                    Opportunity offer;
                    
                    Map<String, Account> accountByRelatedUser = AccountLeadUtil.leadAssignment(leadAccount,
                                                                                               deserializedRequest.intermediaryCode,
                                                                                               deserializedRequest.origin,
                                                                                               deserializedRequest.language,
                                                                                               deserializedRequest.postalCode);
                    if ( accountByRelatedUser.containsKey(CONTACT_CENTER) )
                    {
                        SalesCRMLeadGenerationService.manageCallMeBack(deserializedRequest);
                    }
                    else
                    {
                        offer = SalesCRMLeadGenerationService.manageOffer(accountByRelatedUser,
                                                                          leadAccount.Id,
                                                                          deserializedRequest);
                    }

                    ResponseData responseData = new ResponseData('success', leadAccount.Id, offer != null ? offer.Id : null);
                    response.responseBody = Blob.valueOf( JSON.serialize(responseData) );
                }
                when 'quoteAndBuy'
                {
                    SalesCRMQuoteAndBuyService.Lead deserializedRequest = (SalesCRMQuoteAndBuyService.Lead) JSON.deserializeStrict(requestInformation, SalesCRMQuoteAndBuyService.Lead.class);
                    SalesCRMQuoteAndBuyService.validateRequestData(deserializedRequest);
                    Account leadAccount = SalesCRMQuoteAndBuyService.manageLead(deserializedRequest);
                    Policy__c pol = SalesCRMQuoteAndBuyService.managePolicy(leadAccount,deserializedRequest);
                    Opportunity offer = SalesCRMQuoteAndBuyService.manageOpportunity(leadAccount, deserializedRequest, pol);
                    AccountLeadOpportunityQueueJob.processOpportunityAndPolicy(leadAccount, offer, pol, deserializedRequest.cliente.contacto.codigoPostal);

                    response.responseBody = Blob.valueOf('{"status":"success", "message":"Success creating client"}');
                }
                when else
                {
                    throw new IntegrationException(
                              'Invalid resource for the request: ' + WS_BaseAPIService.resource
                              );
                }
            }
        }
        catch(WS_BaseAPIService.ApiException apiError)
        {
            Database.rollback(sp);

            response.statusCode = 400;
            ResponseData responseData = new ResponseData(apiError, 'error');
            response.responseBody = Blob.valueOf( JSON.serialize(responseData) );

            // Se recoge la información de la excepción para el log errores
            requestResultErrorMessage = apiError.getMessage();
            requestResultErrorStackTrace = apiError.getStackTraceString();
        }
        catch(SalesCRMLeadGenerationService.LeadGenerationException leadGenerationException)
        {
            Database.rollback(sp);

            response.statusCode = 400;
            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(leadGenerationException.statusCode,
                                                                                             leadGenerationException.getMessage(),
                                                                                             false);
            ResponseData responseData = new ResponseData(apiException, 'error');
            response.responseBody = Blob.valueOf( JSON.serialize(responseData) );

            // Se recoge la información de la excepción para el log errores
            requestResultErrorMessage = leadGenerationException.getMessage();
            requestResultErrorStackTrace = leadGenerationException.getStackTraceString();
        }
        catch (JSONException jsonException)
        {
            Database.rollback(sp);

            response.statusCode = 400;
            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(WS_BaseAPIService.API_JSON_KO,
                                                                                             jsonException.getMessage(),
                                                                                             false);
            ResponseData responseData = new ResponseData(apiException, 'error');
            response.responseBody = Blob.valueOf( JSON.serialize(responseData) );

            // Se recoge la información de la excepción para el log errores
            requestResultErrorMessage = jsonException.getMessage();
            requestResultErrorStackTrace = jsonException.getStackTraceString();
        }
        catch(IntegrationException integrationException)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(INTERNAL_ERROR,
                                                                                             integrationException.getMessage(),
                                                                                             false);
            ResponseData responseData = new ResponseData(apiException, 'error');
            response.responseBody = Blob.valueOf( JSON.serialize(responseData) );

            // Se recoge la información de la excepción para el log errores
            requestResultErrorMessage = integrationException.getMessage();
            requestResultErrorStackTrace = integrationException.getStackTraceString();
        }
        catch (Exception genericError)
        {
            Database.rollback(sp);

            response.statusCode = 500;

            WS_BaseAPIService.ApiException apiException = new WS_BaseAPIService.ApiException(INTERNAL_ERROR,
                                                                                             'Error processing the request',
                                                                                             false);
            ResponseData responseData = new ResponseData(apiException, 'error');
            response.responseBody = Blob.valueOf( JSON.serialize(responseData) );

            // Se recoge la información de la excepción para el log errores
            requestResultErrorMessage = genericError.getMessage();
            requestResultErrorStackTrace = genericError.getStackTraceString();
        }
        finally
        {
            // Se recoge el JSON recibido en la petición
            String stackTraceText = request.requestBody?.toString();

            if( String.isNotBlank(requestResultErrorMessage) )
            {
                requestResultType = ErrorLogUtil.ERROR_LEVEL_ERROR;
                requestResult = 'KO.' + response.statusCode + '. ' + requestResultErrorMessage;
                stackTraceText += '\n' + requestResultErrorStackTrace;
            }

            ErrorLogUtil.commitError(requestResultType, 'New webform request: ' + requestResult, 'WS_LeadGeneration', stackTraceText);
        }
    }

    // #endregion

    // #region Auxiliar classes

    /**
     * Clase interna que representa el contenido enviado como respuesta al WS
     * 'WS_SalesCRM'
     */
    private class ResponseData
    {
        private String status {get; set;}
        private String accountId {get; set;}
        private String offerId {get; set;}
        private List<ErrorData> errors {get; set;}

        private ResponseData(String status, String accountId, String offerId)
        {
            this.status = status;
            this.accountId = accountId;
            this.offerId = offerId;
            this.errors = new List<ErrorData>();
        }

        private ResponseData(WS_BaseAPIService.ApiException apiException, String status)
        {
            ErrorData errorData = new ErrorData();
            errorData.message = apiException.message;
            errorData.errorCode = apiException.statusCode;

            this.status = status;
            this.accountId = null;
            this.offerId = null;
            this.errors = new List<ErrorData> {errorData};
        }
    }

    private class ErrorData
    {
        private String message {get; set;}
        private String errorCode {get; set;}
    }

    // #endregion
}