/**
 * @description       : 
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 11/09/2024
 * @last modified by  : rserrano
**/
public with sharing class TriggerBypassUtility 
{
    //Constantes
    private static final String ANOMYMIZED_API_NAME = 'Anonymized__c';
    private static final String BLOCKED_API_NAME = 'Blocked__c';

     /**
      * @description Metodo para before handler devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
      * @param  triggerRecords Listado de registros
      * @return                los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
      */
    public static List<sObject> gdprBypass(List<sObject> triggerRecords) 
    {
        List<sObject> result = new List<sObject> ();
        for (sObject record: triggerRecords) 
        {
            if (record.get(BLOCKED_API_NAME) == false && record.get(ANOMYMIZED_API_NAME) == false) 
            {
                result.add(record);
            }
        }

        return result;
    }
     
    /**
     * @description Metodo para after handler cuando tenemos los registros actuales y el mapa de registros con la foto anterior devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
     * @param  triggerRecords Listado con los registros actualizados
     * @param  oldMap         Mapa con los valores previos a la actualización
     * @return                Registros a los cuales no se le ha marcado a true el campo blocked or anonymized
     */
    public static List<sObject> gdprBypass(List<sObject> triggerRecords, Map<Id, sObject> oldMap) 
    {
        List<sObject> result = new List<sObject> ();
        for (sObject record: triggerRecords) 
        {
            if (!isBlockedChange(record, oldMap) && !isAnonymizedChange(record, oldMap)) 
            {
                result.add(record);
            }
        }

        return result;
    }
	
    /**
     * @description Metodo para after handler devuelve los registros a los cuales no se le ha marcado a true el campo blocked or anonymized
     * @param  oldMap Mapa con los valores previos a la actualización
     * @return        registros a los cuales no se le ha marcado a true el campo blocked or anonymized
     */
    public static List<sObject> gdprBypass(Map<Id, sObject> oldMap) 
    {
        List < sObject > result = new List < sObject > ();
        for (sObject record: oldMap.values()) 
        {
            if (record.get(BLOCKED_API_NAME) == false && record.get(ANOMYMIZED_API_NAME) == false) 
            {
                result.add(record);
            }
        }
        
        return result;
    }
	
	/**
     * @description Método que devuelve una excepción si hay registros bloqueados y no cambia el flag o hay registros 
     * @param  triggerRecords Listado con los registros actualizados
     * @param  oldMap         Mapa con los valores previos a la actualización
     */
    public static void throwExceptionIfBlockedOrAnonymized(List<sObject> triggerRecords, Map<Id, sObject> oldMap) 
    {

        for (sObject record: triggerRecords) 
        {        
            if ((record.get(BLOCKED_API_NAME) == true  && !isBlockedChange(record, oldMap)) || (record.get(ANOMYMIZED_API_NAME) == true && !isAnonymizedChange(record, oldMap))) 
            {
                record.addError(System.Label.GDPR_Error_DMLOnBlockedOrAnonymizedRecord); 
            }
        }
    }
	
    /**
    * @description Metodo que indica si ha cambiado el campo blocked de un registro con respecto al valor anterior
    * @param  record Registro actualizado
    * @param  oldMap Mapa con los valores previos a la actualización
    * @return        Indica si ha cambiado el campo blocked de un registro con respecto al valor anterior
    */
    private static Boolean isBlockedChange(sObject record, Map<Id, sObject> oldMap) 
    {
        Boolean result = true;
		
        if (record.get(BLOCKED_API_NAME).equals(oldMap.get(record.Id).get(BLOCKED_API_NAME))) 
        {
            result = false;
        }

        return result;
    }
    
     /**
      * @description Metodo que indica si ha cambiado el campo anomymized de un registro con respecto al valor anterior
      * @param  record Registro actualizado
      * @param  oldMap Mapa con los valores previos a la actualización
      * @return        return description
      */
    private static Boolean isAnonymizedChange(sObject record, Map<Id, sObject> oldMap) 
    {
        Boolean result = true;
        if (record.get(ANOMYMIZED_API_NAME).equals(oldMap.get(record.Id).get(ANOMYMIZED_API_NAME))) 
        {
            result = false;
        }
        
        return result;
    }
	
	private class TriggerBypassException extends Exception {}
}