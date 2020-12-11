public class ScopeSettingsSelector
{
    public Boolean isSandbox;

    public ScopeSettingsSelector()
    {
        isSandbox = [SELECT Id, isSandbox FROM Organization LIMIT 1].isSandbox;
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
            return [SELECT SandboxBusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt];
        }
        else
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt];
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
            return [SELECT SandboxBusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE SandboxBusinessCode__c IN : businessCodes];
        }
        else
        {
            return [SELECT BusinessCode__c, Scope__c, Scope_Name__c FROM Scope_Setting__mdt WHERE BusinessCode__c IN : businessCodes];
        }
    }

}