public with sharing class GlobalConfigUtil {

    public static final String instancesId='Instances_Id';
    public static final String DEFAULT_RETENTION = 'Default';

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

    /**
     * Obtiene la retencion estandar para un objeto concreto
     *
     * @author mario.navarro@seidor.com
     * @date 27/05/2024
     * @param objectName API name del objeto
     * @return valor entero de la retencion definida en el campo Value del metadato
     * @throws TypeException en caso de que el campo Value del metadato no este definido con un valor numerico
     * @throws NullPointerException en caso de que el metadato no exista
     */
    public static Integer getDefaultObjectRetention(String objectName)
    {
        return getObjectRetention(objectName, DEFAULT_RETENTION);
    }

    /**
     * Obtiene la retencion para un objeto y un tipo concreto
     * 
     * @author mario.navarro@seidor.com
     * @date 27/05/2024
     * @param objectName API name del objeto
     * @param retentionType tipo de retencion a obtener
     * @return valor entero de la retencion definida en el campo Value del metadato
     * @throws TypeException en caso de que el campo Value del metadato no este definido con un valor numerico
     * @throws NullPointerException en caso de que el metadato no exista
     */
    public static Integer getObjectRetention(String objectName, String retentionType)
    {
        if (String.isBlank(objectName))
        {
            throw new IllegalArgumentException(Label.ObjectNameMandatory);
        }
        if (objectName.endsWithIgnoreCase('__c')) {
            objectName = objectName.removeEnd('__c');
        }
        String val = Global_Configuration__mdt.getInstance(objectName+retentionType)?.Value__c;

        return Integer.valueOf(val);
    }

}