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
     * @author xsobera
     * @date 21/01/2021
     * @param   String          claimNumber   Números de siniestro a buscar
     * @return  List<Asset>  Listado de siniestros sobre los que se ha realizado match
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
