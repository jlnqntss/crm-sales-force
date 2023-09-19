/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 13/09/2023
 * @last modified by  : jgallaga
**/
public with sharing class CampaignMembersSelector extends BaseSelector
{
    //#region Atributos
    private final static String BASE_SELECT = 'SELECT {0} FROM CampaignMember ';
    //#endregion

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
     * Recupera miembros de campaña a partir del Id
     *
     * @author fpalomo
     * @date 11/09/2023
     * 
     * @param  campaignMembersIds Set de IDs de CampaignMember
     * @return Listado de CampaignMembers correspondientes a las IDs recibidas
     */
    public List<CampaignMember> selectById(Set<Id> campaignMembersIds)
    {
        if(campaignMembersIds != null)
        {
            String query = String.format(
                BASE_SELECT +
                'WHERE Id IN :campaignMembersIds ',
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
                BASE_SELECT +
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
                BASE_SELECT +
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
     * Busca miembros de campaña para utilizar en el batch Batch_InitCrossSellingCampaign
     *
     * @author dmunoz
     * @date 11/08/2023
     * @return          Listado de CampaignMembers
     */
    public List<CampaignMember> findZRMPendingRevMediatorCampaignMembers() {
        List<CampaignMember> result = new List<CampaignMember>([SELECT ContactId, CampaignId, Campaign.ExternalId__c, LeadPhone__c
                                                                FROM CampaignMember
                                                                WHERE Campaign.Type = 'Cross Selling'
                                                                AND Campaign.IsActive = true
                                                                AND Campaign.StartDate >= TODAY
                                                                AND Status = 'Pdte. Revisión Mediador']);
        return result;
    }

    /**
     * Busca miembros de campaña a partir del Status
     *
     * @author jfherrero
     * @date 07/08/2023
     * @param  campaignTypes       Tipologías que deben tener todos los miembros de campaña
     * @param  campaignMemberIds   Ids de miembros de campaña a recuperar
     * @return                     Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectByCampaignTypeAndId(List<String> campaignTypes, Set<Id> campaignMemberIds)
    {
        if( campaignTypes != null && !campaignTypes.IsEmpty() &&
            campaignMemberIds != null && !campaignMemberIds.IsEmpty() )
        {
            String query = String.format(
                BASE_SELECT +
                'WHERE Campaign.Type IN : campaignTypes and Id IN : campaignMemberIds ',
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
     * Método para recoger aquellos miembros de campaña pertenecientes a unas campañas concretas relacionadas con una cuentas concretas.
     * *
     * @author  jgallaga | 07-09-2023
     * @param   Set<Id>
     *          Set de Ids de campaña
     * @param   Set<Id>
     *          Set de ids de cuenta
     */
    public List<CampaignMember> selectCampaignMembersByCampaignIdAndAccountFromContact(Set<Id> campaignIds, Set<Id> accountIds)
    {
        return [
            SELECT  CampaignId, ContactId, Contact.AccountId
            FROM    CampaignMember
            WHERE   CampaignId IN :campaignIds
            AND     Contact.AccountId IN : accountIds
            ];
    }

    public class ProperCampaignMembersSelector extends RecordsSelector
    {
        ProperCampaignMembersSelector()
        {
            super(CampaignMember.getSObjectType());
        }

        List<CampaignMember> selectCampaignMembersByCampaignIdAndAccountFromContact(Set<Id> campaignIds, Set<Id> accountIds)
        {
            this.baseQuery
                .selectFields(new List<Schema.SObjectField>{CampaignMember.CampaignId,CampaignMember.Contact.AccountId})
                .addConditionIn(CampaignMember.CampaignId, campaignIds)
                .addConditionIn(CampaignMember.Contact.AccountId, accountIds);

            return this.baseQuery.run();
        }
    }
}
