public with sharing class ClaimsSelector extends BaseSelector
{
    //#region Contructores
    public ClaimsSelector() {}

    public ClaimsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Claim__c';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca siniestros a partir de número de siniestro en INFO
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          claimNumber   Números de siniestro a buscar
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByNumber(String claimNumber)
    {
        if(String.isNotBlank(claimNumber))
        {
            String query = String.format(
                'SELECT {0} FROM Claim__c ' +
                'WHERE INFOClaimNumber__c = : claimNumber ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Claim__c>) Database.query(query);
        }
        else
        {
            return new List<Claim__c>();
        }
    }

    /**
     * Busca siniestros a partir de número matrícula del vehículo
     * No devuelve los siniestros marcados como Terminados
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          plateNumber   Matrícula del vehículo
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByPlate(String plateNumber)
    {
        if(String.isNotBlank(plateNumber))
        {
            String query = String.format(
                'SELECT {0} FROM Claim__c ' +
                'WHERE Status__c != \'T\' AND InsuredObject__r.RegistrationNumber__c = : plateNumber ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Claim__c>) Database.query(query);
        }
        else
        {
            return new List<Claim__c>();
        }
    }

    /**
     * Busca siniestros de pólizas activas a partir Id de la cuenta del cliente
     * No devuelve los siniestros marcados como Terminados
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          claimNumber   Listado de números de póliza a buscar
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByHolder(Id policyHolder)
    {
        if(policyHolder != null)
        {
            String query = String.format(
                'SELECT {0} FROM Claim__c ' +
                'WHERE Status__c != \'T\' AND PolicyHolder__c = : policyHolder AND (Policy__r.EndDate__c = null OR Policy__r.EndDate__c >= TODAY)',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Claim__c>) Database.query(query);
        }
        else
        {
            return new List<Claim__c>();
        }
    }
}