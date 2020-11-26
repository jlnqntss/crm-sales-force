/**
 * Batch that responds to external system with the result of the processing
 * @Autor: nbizkarra (04/05/2020)
 * 
 * @change: nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
 **/

global class Batch_ResponseExternalRequest implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts {
    public String query;
  
    global Batch_ResponseExternalRequest() {
    }
  
    global Batch_ResponseExternalRequest(String p_query) {
      if (!String.isBlank(p_query)) {
        query = p_query;
      }
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC) {
      if (query == null || query == '') {
        query = SystemUtil.getProcessedExternalRequests();
      }
  
      return Database.getQueryLocator(query);
    }
  
    global void execute(SchedulableContext SC) {
      Database.executeBatch(new Batch_ResponseExternalRequest(query), 10);
    }
  
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
      if (scope != null && !scope.isEmpty()) {
        // Scope
        List<ExternalRequest__c> listExternalRequest = (List<ExternalRequest__c>) scope;
        // Metadata configuration
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        // JSON
        String json;
  
        try {
          // For each External Request
          for (ExternalRequest__c ExtReq : listExternalRequest) {
            String errorCode = Label.ErrorCodeSuccess;
            if (ExtReq.ProcessResult__c != 'OK') {
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
            if( !String.isBlank(json) ) {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                System.debug('**** COUNTRY [' + ExtReq.Country__c + ']');
                System.debug('**** ORIGIN [' + ExtReq.Origin__c + ']');
  
                // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
                // IBA Endpoint & Authorization Token
                String endPoint = adminSetup.IBA_endpoint__c;
                String authToken = adminSetup.IBA_Auth_token__c;
                if( ExtReq.Origin__c == adminSetup.IBA_Multi_Partner_Origin__c ) {
                    endPoint = adminSetup.IBA_Multi_Partner_endpoint__c;
                    authToken = adminSetup.IBA_Multi_Partner_Authorization_token__c;
                } else if( ExtReq.Country__c != adminSetup.IBA_EMEA_Non_Country__c ) {
                    endPoint = adminSetup.IBA_EMEA_endpoint__c;
                    authToken = adminSetup.IBA_EMEA_Authorization_token__c;
                }
  
                // Endpoint
                request.setEndpoint( endPoint );
                // Method
                request.setMethod('PUT');
                // Header: Content-Type
                request.setHeader('Content-Type', 'application/json');
                //request.setHeader('Ocp-Apim-Subscription-Key', adminSetup.IBA_Auth_token__c);
                // Header: Authorization
                request.setHeader( 'Authorization', authToken );
                // Body
                request.setBody(json);
                // SetTimeout
                request.setTimeout(30000);
  
                // Response
                HttpResponse response = new HttpResponse();
  
                System.debug('**** REQUEST: ' + request);
                response = http.send(request);
                
                // Respuesta a mi respuesta. Status Code
                if (response.getStatusCode() == 200) {
                  ExtReq.Sent__c = true;
                } else {
                  ExtReq.Retry__c = ExtReq.Retry__c + 1;
                }
            } else {
                //System.debug('Error creando Json de respuesta');
                ErrorLogUtil.commitError(Label.Error, Label.ErrorJSON + ' ' + ExtReq.Id, 'Batch_ResponseExternalRequest');
            }
          }
  
          update listExternalRequest;
        } catch (Exception e) {
          ErrorLogUtil.commitError(e, 'Batch_ResponseExternalRequest');
        }
      }
    }
  
    global void finish(Database.BatchableContext BC) {
    }
  }