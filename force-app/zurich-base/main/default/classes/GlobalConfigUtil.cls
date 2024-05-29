public with sharing class GlobalConfigUtil {

    public static final String instancesId='Instances_Id';
    public static final String DEFAULT_RETENTION = 'Default';
    private static final String CUSTOM_OBJECT_API_NAME_ENDING = '__c';

    public static Map<String, String> getGlobalConfigurationValues() {
        
        Map<String, String> configValues = new Map<String, String>();
        
        //Get de todos los registros del CMT
        Map<String, Global_Configuration__mdt> configs = Global_Configuration__mdt.getAll();
        // Agregar los valores al mapa
        for (Global_Configuration__mdt config : configs.values()) {
            configValues.put(config.DeveloperName, config.Value__c);
        }
        
        return configValues;
    }

    public static String getGlobalConfigurationValue(String globalValueName) {
        
        //Get del registro por devName
        Global_Configuration__mdt config = Global_Configuration__mdt.getInstance(globalValueName);
        return config.Value__c;

    }

    public static String getGlobalConfigurationValueId(String globalValueName) {
        
        //Get del registro por devName, nos descargaremos los 4 Ids
        Global_Configuration__mdt config = Global_Configuration__mdt.getInstance(globalValueName);

        //Para saber qué id devolver, necesitamos saber en qué entorno estamos
        Global_Configuration__mdt instanceConfig = Global_Configuration__mdt.getInstance(instancesId);
        
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
        if (objectName.endsWithIgnoreCase(CUSTOM_OBJECT_API_NAME_ENDING)) {
            objectName = objectName.removeEnd(CUSTOM_OBJECT_API_NAME_ENDING);
        }
        String val = Global_Configuration__mdt.getInstance(objectName+retentionType)?.Value__c;

        return Integer.valueOf(val);
    }

}