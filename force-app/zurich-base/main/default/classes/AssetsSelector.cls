public with sharing class AssetsSelector extends RecordsSelector
{

    //#region Contructores

    public AssetsSelector()
    {
        super( Asset.getSObjectType() );
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
    public List<Asset> selectByPolicyID(List<String> policyId)
    {
        if(!policyId.isEmpty() && policyId != null)
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionIn(Asset.PolicyId__c, policyId);

            return (List<Asset>) this.baseQuery.run();
        }
        else
        {
            return new List<Asset>();
        }
    }

    /**
     * Busca assets a partir del número de matrícula
     **
     * @author jfherrero
     * @date 24/10/2023
     * @param   String       policyID   Identificador de la póliza a buscar
     * @return  List<Asset>  Listado de assets asociados a la póliza que estamos buscando
     */
    public List<Asset> selectByRegistrationNumber(List<String> registrationNumbers)
    {
        if(!registrationNumbers.isEmpty() && registrationNumbers != null)
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionIn(Asset.RegistrationNumber__c, registrationNumbers);

            return (List<Asset>) this.baseQuery.run();
        }
        else
        {
            return new List<Asset>();
        }
    }
}