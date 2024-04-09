/**
 Clase Utilidad para los métodos a utilizar en el proceso batch Batch_ProcessIntermediaryOrAccountChangeUtil y Batch_IntermediaryOrAccountChangeDML
 * 
 * @author dmunoz
 * @date 04/04/2024
 **/
public with sharing class Batch_IntermediaryOrAccountChangeUtil {
    

    public static final String MOVEMENT_TYPE_CAMBIO_MEDIADOR = 'IntermediaryChange';
    public static final String MOVEMENT_TYPE_CAMBIO_CLIENTE = 'AccountChange';
    private static final String ZRM_NUM_MAX_RETRIES = 'ZRMNumMaxRetries';

    //#region updateRecordWithProcessKO

    /**
     En caso que se haya producido una excepción se ejecuta esta actualización del registro para que se procese al dia siguiente de nuevo. 
     Este método se ejecuta en un catch por lo que añado un try catch propio para evitar errores adicionaes
    * @author dmunoz
    * @date 04/04/2024
    **/
    public static void updateRecordWithProcessKO(List<sObject> recordsToProcess, String className) {

        try {

            if (recordsToProcess != null && !recordsToProcess.isEmpty()) {
                sObject record = recordsToProcess.get(0);
                AdminSetupParameter__mdt numMaxRetriesMTD = AdminSetupParameter__mdt.getInstance(ZRM_NUM_MAX_RETRIES);
    
                Schema.SObjectType offerObject = Schema.Opportunity.getSObjectType();
                Schema.SObjectType policyObject = Schema.Policy__c.getSObjectType();
                Schema.SObjectType recordObject = record.getsobjecttype();
        
                if (offerObject == recordObject) {
                    updateOfferWithProcessKO((Opportunity) record, numMaxRetriesMTD);
    
                } else if (policyObject == recordObject) {
                    updatePolicyWithProcessKO((Policy__c) record, numMaxRetriesMTD);
                }
            }
            
        } catch(Exception e) {
            ErrorLogUtil.commitError(e, className);
        }
    }

    /**
    Actualiza el registro fallido para el reproceso al dia siguiente
    * @author dmunoz
    * @date 04/04/2024
    **/
    private static void updateOfferWithProcessKO(Opportunity opportunity, AdminSetupParameter__mdt numMaxRetriesMTD) {

        Opportunity recordToUpdate = new Opportunity();
        recordToUpdate.Id = opportunity.Id;
        recordToUpdate.VisibilityRetry__c = opportunity.VisibilityRetry__c + 1;

        // solo seteamos la fecha en caso que el numero de reintentos esté por debajo del límite de la metadata
        if (opportunity.VisibilityRetry__c <= Integer.valueOf(numMaxRetriesMTD.Value__c)) {
            recordToUpdate.LastDateIntermediaryOrAccountChange__c = Date.today();
        }
        
        update recordToUpdate;
    }

    /**
    Actualiza el registro fallido para el reproceso al dia siguiente
    * @author dmunoz
    * @date 04/04/2024
    **/
    private static void updatePolicyWithProcessKO(Policy__c policy, AdminSetupParameter__mdt numMaxRetriesMTD) {

        if (numMaxRetriesMTD != null) {
            Policy__c recordToUpdate = new Policy__c();
            recordToUpdate.Id = policy.Id;
            recordToUpdate.VisibilityRetry__c = policy.VisibilityRetry__c + 1;
    
            // solo seteamos la fecha en caso que el numero de reintentos esté por debajo del límite de la metadata
            if (policy.VisibilityRetry__c <= Integer.valueOf(numMaxRetriesMTD.Value__c)) {
                recordToUpdate.LastDateIntermediaryOrAccountChange__c = Date.today();
            }
            
            update recordToUpdate;
        }
    }


}