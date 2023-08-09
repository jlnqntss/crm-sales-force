public with sharing class CampaignMembersSelector extends BaseSelector
{
    //#region Contructores
    public CampaignMembersSelector()
    {}

    public CampaignMembersSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'CampaignMember';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca miembros de campaña a partir del Id de campaña y de un conjuno de Ids de contactos
     *
     * @author rlopez
     * @date 01/12/2020
     * @param  campaignId   Id de campaña a buscar
     * @param  contactIds   Conjunto de ids de Contacto
     * @return          Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectByCampaignAndContact(Id campaignId, Set<Id> contactIds)
    {
        if(campaignId != null && contactIds != null)
        {
            String query = String.format(
                'SELECT {0} FROM CampaignMember ' +
                'WHERE campaignId = : campaignId AND ContactId IN : contactIds ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<CampaignMember>) Database.query(query);
        }
        else
        {
            return new List<CampaignMember>();
        }
    }

    /**
     * Busca miembros de campaña a partir del Status
     *
     * @author rlopez
     * @date 21/12/2020
     * @param  status   Estado del miembro de campaña a buscar
     * @return          Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectByStatus(String status)
    {
        if( String.isNotBlank(status) )
        {
            String query = String.format(
                'SELECT {0} FROM CampaignMember ' +
                'WHERE Status = : status ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<CampaignMember>) Database.query(query);
        }
        else
        {
            return new List<CampaignMember>();
        }
    }

    /**
     * Busca miembros de campaña a partir del Status
     *
     * @author jfherrero
     * @date 07/08/2023
     * @param  status   Estado del miembro de campaña a buscar
     * @return          Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectById(List<String> campaignMembers)
    {
        if( campaignMembers != null && !campaignMembers.isEmpty() )
        {
            String query = String.format(
                'SELECT {0} FROM CampaignMember ' +
                'WHERE Id IN : campaignMembers ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<CampaignMember>) Database.query(query);
        }
        else
        {
            return new List<CampaignMember>();
        }
    }

    /**
     * Busca miembros de campaña a partir del Status
     *
     * @author jfherrero
     * @date 07/08/2023
     * @param  status   Estado del miembro de campaña a buscar
     * @return          Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectByCampaignType(List<String> campaignTypes)
    {
        if( campaignTypes != null && !campaignTypes.isEmpty() )
        {
            List<CampaignMember> queryResult = [SELECT Id, CampaignMember.CampaignId, CampaignMember.OfferAssignedCode__c, CampaignMember.OfferAssignedType__c,
                                                CampaignMember.Contact.AccountId, CampaignMember.Contact.Account.INFOCustomerNumber__c, CampaignMember.Contact.Account.Intermediary_Name__c,
                                                CampaignMember.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c, CampaignMember.Campaign.StartDate, CampaignMember.Campaign.EndDate,
                                                CampaignMember.Campaign.ExternalId__c, CampaignMember.Campaign.ProductBranch__c,CampaignMember.Campaign.BusinessCode__c
                                                FROM CampaignMember
                                                WHERE Campaign.Type IN : campaignTypes];

            return queryResult;
        }
        else
        {
            return new List<CampaignMember>();
        }
    }

}