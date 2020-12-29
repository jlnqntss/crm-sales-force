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
}