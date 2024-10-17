/*
 * Esta acción es llamada desde un flow para obtener el id de registros determinados 
 * @author lrodriguez6@seidor.es
 * @date 07/08/2024
 */

 public with sharing class GetGlobalConfigurationValueIdFlow {
    /*
     * Método que obtiene los valores de Id en funcion del entorno en el que se encuentre 
     * de un registro recogido en el metadato Global Configuration
     * Como parametro de entrada tiene dos String donde están el nombre del registro del metadato a recuperar
     * y id de la organizacion
     * @author lrodriguez6@seidor.es
     * @date 07/08/2024
     * @param String nombre del registro del metadato String id de la organizacion
     * @return Id
     */

     @InvocableMethod
     (  
         label='GetGlobalConfigurationValueIdFlow' 
         description='Return Id Record wthout queries'
     )
     public static List<List<String>> getIdValueGlobalConfiguration(List<FlowInputs> flowInputs) 
    {
        List<List<String>> listValuesToReturn = new List<List<String>>();
        List<String> valuesToReturn = new List<String>();

        if(! flowInputs.isEmpty())
        {
            for( FlowInputs flowInput:flowInputs)
            {
                valuesToReturn=getIdValue(flowInput);
                listValuesToReturn.add(valuesToReturn);
            }
        }
        
        return listValuesToReturn;    
    }

    public static List<String> getIdValue(FlowInputs flowInputs) {

    List<String> filteredListByInstance= new List<String>();

    Global_Configuration__mdt config = Global_Configuration__mdt.getInstance(flowInputs.globalValueName);
    String instancesId = GlobalConfigUtil.getGlobalConfigurationValue('Instances_Id_Value');
    Global_Configuration__mdt instanceConfig = Global_Configuration__mdt.getInstance(instancesId);

    if(flowInputs.idOrg == instanceConfig.Value__c){
        filteredListByInstance.add(config.Value__c);
    } else if(flowInputs.idOrg == instanceConfig.Uat_Value__c){
        filteredListByInstance.add(config.Uat_Value__c);
    } else if(flowInputs.idOrg == instanceConfig.Staging_Value__c){
        filteredListByInstance.add(config.Staging_Value__c);
    } else{
        filteredListByInstance.add(config.Dev_Value__c);
    }

    return filteredListByInstance;

    }

    public class FlowInputs
    {
        @InvocableVariable 
        public String globalValueName;
        @InvocableVariable 
        public String idORg;
    }
}