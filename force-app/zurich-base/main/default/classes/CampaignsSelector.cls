public with sharing class CampaignsSelector extends BaseSelector
{
    //#region Contructores
    public CampaignsSelector()
    {}

    public CampaignsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Campaign';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca campañas a partir del Name
     *
     * @author rlopez
     * @date 01/12/2020
     * @param  names    Listado de nombres. Válido cualquier formato
     * @return          Listado de Campaigns sobre los que se ha realizado match
     */
    public List<Campaign> selectByName(Set<String> names)
    {
        if(names != null)
        {
            String query = String.format(
                'SELECT {0} FROM Campaign ' +
                'WHERE Name IN : names ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Campaign>) Database.query(query);
        }
        else
        {
            return new List<Campaign>();
        }
    }

    /**
     * Busca campaña a partir de un conjunto de external id
     *
     * @author dmunoz
     * @date 11/08/2023
     * @return          Listado de CampaignMembers 
     */
    public List<Campaign> findCampaignByExternalId(Set<String> externalIdSet) {

        List<Campaign> result = new List<Campaign>();

        if (!externalIdSet.isEmpty()) {
            result = new List<Campaign>([SELECT Id, ExternalId__c FROM Campaign WHERE ExternalId__c IN :externalIdSet]);
        }

        return result;
    }

    /**
     * Busca campaña a partir de un conjunto de external id
     *
     * @author arcortazar
     * @date 11/10/2023
     * @return          Listado de Campañas 
     */
    public List<Campaign> findCampaignById(List<String> listaIds) {

        List<Campaign> result = new List<Campaign>();

        if (!listaIds.isEmpty()) {
            result = new List<Campaign>([SELECT Id, Type, IsActive, StartDate FROM Campaign WHERE Id IN :listaIds]);
        }

        return result;
    }

    /**
     * Devuelve las campañas cuyo ID este en la lista que se pasa como parámetro y que sea de tipo Cross Seling, o esté activa, o haya comezado ya
     * 
     * @author arcortazar
     * @date 11/10/2023
     * @param   Lista de ID 
     * @return  Listado de Campañas 
     */
    public List<Campaign> findZRMInitiatedCrossSellingCampaings(List<String> listaIds)
    {
        List<Campaign> result = new List<Campaign>();

        if (!listaIds.isEmpty()) {
            result = new List<Campaign>([SELECT Id FROM Campaign WHERE (Type != 'Cross Selling' OR IsActive = false OR StartDate <= TODAY) AND id IN :listaIds]);
        }
        return result;
    }

    /**
     * @description Método selector que devuelve todas las campañas y sus respectivos
     * miembros de campaña. Se aplica un filtro para que devuelva exclusivamente
     * aquellas campañas que contienen al menos un miembro de campaña cuyo 
     * 'OfferAssignedCode__c' coincide con alguno de los pasados por parámetro.
     *
     * @author amiranda
     * @date 30-10-2023
     * @param offerAssignedCodes Códigos de mediador que deben coincidir con el 
     * campo 'OfferAssignedCode__c'
     * @return List<Campaign> Lista de campañas y sus respectivos miembros de campañaa
     * @where Restringido a llamarse desde métodos donde se debe verificar el control
     * de acceso a los objetos/campos.
     *
     **/
    public List<Campaign> selectCampaignsAndCampaignMembersByOfferAssignedCodes(Set<String> offerAssignedCodes)
    {
        List<Campaign> campaigns = new List<Campaign>();

        campaigns = [SELECT Id, Name, StartDate, EndDate, toLabel(Type),
                        toLabel(ProductBranch__c), isActive,
                        (SELECT Id, Status
                        FROM CampaignMembers WHERE OfferAssignedCode__c IN :offerAssignedCodes)
                    FROM Campaign
                    WHERE Id IN (SELECT CampaignId
                                FROM CampaignMember WHERE OfferAssignedCode__c IN :offerAssignedCodes)
                    WITH USER_MODE ORDER BY Name ];
        
        return campaigns;
    }

}