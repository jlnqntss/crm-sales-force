/**
 * @description       : 
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 11/09/2024
 * @last modified by  : rserrano
**/
public with sharing class TriggerBypassUtility {
    // Metodo para before handler devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
    public static List < sObject > gdprBypass(List<sObject> triggerRecords) {
        List<sObject> result = new List<sObject> ();
        for (sObject record: triggerRecords) {
            if (record.get('Blocked__c') == false && record.get('Anonymized__c') == false) {
                result.add(record);
            }
        }
        return result;
    }
    // Metodo para after handler cuando tenemos los registros actuales y el mapa de registros con la foto anterior devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
    public static List < sObject > gdprBypass(List<sObject> triggerRecords, Map<Id, sObject> oldMap) {
        List<sObject> result = new List<sObject> ();
        for (sObject record: triggerRecords) {
            if (!isBlockedChange(record, oldMap) && !isAnonymizedChange(record, oldMap)) {
                result.add(record);
            }
        }
        return result;
    }
	
	// Metodo para after handler devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
    public static List < sObject > gdprBypass(Map<Id, sObject> oldMap) {
        List < sObject > result = new List < sObject > ();
        for (sObject record: oldMap.values()) {
            if (record.get('Blocked__c') == false && record.get('Anonymized__c') == false) {
                result.add(record);
            }
        }
        return result;
    }
	
	// metodo que devuelve una excepción si hay registros bloqueados y no cambia el flag o hay registros 
    public static void throwExceptionIfBlockedOrAnonymized(List<sObject> triggerRecords, Map<Id, sObject> oldMap) {

        for (sObject record: triggerRecords) {
            
            if ((record.get('Blocked__c') == true  && !isBlockedChange(record, oldMap)) || (record.get('Anonymized__c') == true && !isAnonymizedChange(record, oldMap))) {
                record.addError(System.Label.GDPR_Error_DMLOnBlockedOrAnonymizedRecord); 
            }
        }
    }
	
    // Metodo que indica si ha cambiado el campo blocked de un registro con respecto al valor anterior
    private static Boolean isBlockedChange(sObject record, Map < Id, sObject > oldMap) {
        Boolean result = true;
		
        if (record.get('Blocked__c').equals(oldMap.get(record.Id).get('Blocked__c'))) {
            result = false;
        }
        return result;
    }
	
    // Metodo que indica si ha cambiado el campo blocked de un registro con respecto al valor anterior
    private static Boolean isAnonymizedChange(sObject record, Map < Id, sObject > oldMap) {
        Boolean result = true;
        if (record.get('Anonymized__c').equals(oldMap.get(record.Id).get('Anonymized__c'))) {
            result = false;
        }
        return result;
    }
	
	private class TriggerBypassException extends Exception {}
}