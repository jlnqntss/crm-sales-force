public class ScopeSettingsSelector
{
    Boolean isSandbox;

    public ScopeSettingsSelector()
    {
        if( Test.isRunningTest() )
        {
            isSandbox = true;
        }
        else
        {
            isSandbox = [SELECT Id, isSandbox FROM Organization LIMIT 1].isSandbox;
        }
    }

    /**
     * Obtiene una lista de metadatos de scope
     *
     * @author adelgado
     * @date 09/12/2020
     * @return Listado scope settings recuperados
     */
    public List<Scope_Setting__mdt> selectAll()
    {
        if(isSandbox)
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE Sandbox__c = true];
        }
        else
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE Sandbox__c = false];
        }
    }

    /**
     * Obtiene una lista de metadatos de scope a partir de una lista de códigos de negocio
     *
     * @author adelgado
     * @date 09/12/2020
     * @param  businessCodes Listado de códigos de negocio
     * @return Listado scope settings recuperados
     */
    public List<Scope_Setting__mdt> selectByBusinessCode(Set<String> businessCodes)
    {
        if(isSandbox)
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE Sandbox__c = true AND BusinessCode__c IN : businessCodes];
        }
        else
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE Sandbox__c = false AND BusinessCode__c IN : businessCodes];
        }
    }

}