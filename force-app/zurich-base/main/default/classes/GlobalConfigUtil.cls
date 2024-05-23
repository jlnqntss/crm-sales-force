public with sharing class GlobalConfigUtil {

    public static final String instancesId='Instances_Id';

    public static Map<String, String> getGlobalConfigurationValues() {
        Map<String, String> configValues = new Map<String, String>();
        
        //Get de todos los registros del CMT
        List<Global_Configuration__mdt> configs = [
            SELECT DeveloperName, Value__c 
            FROM Global_Configuration__mdt
        ];
        
        // Agregar los valores al mapa
        for (Global_Configuration__mdt config : configs) {
            configValues.put(config.DeveloperName, config.Value__c);
        }
        
        return configValues;
    }

    public static String getGlobalConfigurationValue(String globalValueName) {
        
        //Get del registro por devName
        Global_Configuration__mdt config = [
            SELECT Value__c 
            FROM Global_Configuration__mdt
            WHERE DeveloperName = :globalValueName
        ];
        
        return config.Value__c;
    }

    public static String getGlobalConfigurationValueId(String globalValueName) {
        
        //Get del registro por devName, nos descargaremos los 4 Ids
        Global_Configuration__mdt config = [
            SELECT Value__c, Dev_Value__c, Staging_Value__c, Uat_Value__c
            FROM Global_Configuration__mdt
            WHERE DeveloperName = :globalValueName
        ];

        //Para saber qué id devolver, necesitamos saber en qué entorno estamos
        Global_Configuration__mdt instanceConfig = [
            SELECT Value__c, Staging_Value__c, Uat_Value__c
            FROM Global_Configuration__mdt
            WHERE DeveloperName = :instancesId LIMIT 1
        ];
        
        Organization org = [SELECT Id FROM Organization LIMIT 1];
        String orgId = org.Id;

        //Devolveremos el Id dependiendo del entorno en el que estemos
        if(orgId == instanceConfig.Value__c){
            return config.Value__c;
        } else if(orgId == instanceConfig.Uat_Value__c){
            return config.Uat_Value__c;
        } else if(orgId == instanceConfig.Staging_Value__c){
            return config.Staging_Value__c;
        } else{
            return config.Dev_Value__c;
        }

    }

}