/**
 * Batch that responds to external system with the result of the processing
 * @Autor: nbizkarra (04/05/2020)
 **/

global class Batch_ResponseExternalRequest implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts
{
    public String query;
    public Boolean esTest;

    global Batch_ResponseExternalRequest()
    {
        query = SystemUtil.getProcessedExternalRequests();
    }

    global Batch_ResponseExternalRequest(String p_query)
    {
        this();
        if ( !String.isBlank(p_query) )
        {
            query = p_query;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {

        if ( Test.isRunningTest() )
        {
            esTest = true;
        }
        else if (esTest == null)
        {
            esTest = false;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new Batch_ResponseExternalRequest(query), 10);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            List<ExternalRequest__c> listExternalRequest = (List<ExternalRequest__c>) scope;
            AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
            String json;

            try
            {
                for (ExternalRequest__c ExtReq : listExternalRequest)
                {
                    String errorCode = '';
                    if (ExtReq.ProcessResult__c == 'OK')
                    {
                        errorCode = Label.ErrorCodeSuccess;
                    }
                    else
                    {
                        errorCode = Label.ErrorCodeFail;
                    }

                    json = SystemUtil.createJSON(
                        ExtReq.ID,
                        errorCode,
                        ExtReq.Error_Log__c,
                        Datetime.now(),
                        ExtReq.Origin__c,
                        ExtReq.Country__c,
                        ExtReq.Entity__c,
                        ExtReq.Timestamp__c,
                        ExtReq.Json__c
                        );

                    System.debug('**** JSON: ' + json);
                    if ( !String.isBlank(json) )
                    {
                        Http http = new Http();
                        HttpRequest request = new HttpRequest();
                        System.debug('**** COUNTRY' + ExtReq.Country__c);
                        if (ExtReq.Country__c != 'Spain')
                        {
                            request.setEndpoint(adminSetup.IBA_EMEA_endpoint__c);
                        }
                        else
                        {
                            request.setEndpoint(adminSetup.IBA_endpoint__c);
                        }
                        request.setMethod('PUT');
                        request.setHeader('Content-Type', 'application/json');
                        //request.setHeader('Ocp-Apim-Subscription-Key', adminSetup.IBA_Auth_token__c);

                        if (ExtReq.Country__c != 'Spain')
                        {
                            request.setHeader(
                                'Authorization',
                                adminSetup.IBA_EMEA_Authorization_token__c
                                );
                        }
                        else
                        {
                            request.setHeader('Authorization', adminSetup.IBA_Auth_token__c);
                        }

                        request.setBody(json);
                        request.setTimeout(30000);
                        HttpResponse response = new HttpResponse();

                        if (esTest)
                        {
                            response = Mock_IBA_ResponseGenerator.respond(request);
                        }
                        else
                        {
                            System.debug('**** REQUEST: ' + request);
                            response = http.send(request);
                        }

                        if (response.getStatusCode() == 200)
                        {
                            ExtReq.Sent__c = true;
                        }
                        else
                        {
                            ExtReq.Retry__c = ExtReq.Retry__c + 1;
                        }
                    }
                    else
                    {
                        //System.debug('Error creando Json de respuesta');
                        ErrorLogUtil.commitError(
                            Label.Error,
                            Label.ErrorJSON +
                            ' ' +
                            ExtReq.Id,
                            'Batch_ResponseExternalRequest'
                            );
                    }
                }

                update listExternalRequest;
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError(e, 'Batch_ResponseExternalRequest');
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}