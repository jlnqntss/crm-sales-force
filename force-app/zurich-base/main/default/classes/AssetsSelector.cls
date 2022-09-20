public with sharing class AssetsSelector extends RecordsSelector {
    
     //#region Contructores

     public AssetsSelector()
     {
         super(Asset.getSObjectType());
     }
    
     //#endregion


    /**
     * Busca assets a partir del número de la póliza
     **
     * @author arcortazar
     * @date 09/09/2022
     * @param   String       policyID   Identificador de la póliza a buscar
     * @return  List<Asset>  Listado de assets asociados a la póliza que estamos buscando
     */
    public List<Asset> selectByPolicyID(String policyId)
    {
        if(String.isNotBlank(policyId))
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionEq(Asset.PolicyId__c, policyId);

            return (List<Asset>) this.baseQuery.run();
        }
        else
        {
            return new List<Asset>();
        }
    }
}
