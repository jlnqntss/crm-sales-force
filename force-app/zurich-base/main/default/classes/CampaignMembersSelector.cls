/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 21-03-2024
 * @last modified by  : amiranda
 **/
public with sharing class CampaignMembersSelector extends BaseSelector
{
    //#region Atributos
    private final static String BASE_SELECT = 'SELECT {0} FROM CampaignMember ';
    private static final Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
    private static final String PRODUCT_BRANCH_VIDA_CODE = configValues.get('Product_Branch_Vida_Code');
    private static final String CAMPAIGN_CROSS_SELLING_TYPE = configValues.get('Campaign_Cross_Selling_Type');
    private static final String CAMPAIGN_STATUS_PDT_REVISION_MEDIADOR = configValues.get('CampaignMemberPdteRevisionMediador_value');

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
    public List<CampaignMember> findZRMPendingRevMediatorCampaignMembers()
    {
        List<CampaignMember> result = new List<CampaignMember>([SELECT ContactId, CampaignId, Campaign.ExternalId__c, LeadPhone__c, Contact.AccountId
                                                                FROM CampaignMember
                                                                WHERE Campaign.Type = :CAMPAIGN_CROSS_SELLING_TYPE
                                                                                      AND Campaign.IsActive = true
                                                                                                              AND Campaign.StartDate <= TODAY
                                                                                                              AND Status = :CAMPAIGN_STATUS_PDT_REVISION_MEDIADOR
                                                                                                              AND Campaign.ProductBranch__c != :PRODUCT_BRANCH_VIDA_CODE]);
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
            SELECT CampaignId, ContactId, Contact.AccountId
            FROM CampaignMember
            WHERE CampaignId IN : campaignIds
            AND Contact.AccountId IN : accountIds
        ];
    }

    public with sharing class ProperCampaignMembersSelector extends RecordsSelector
    {
        public ProperCampaignMembersSelector()
        {
            super( CampaignMember.getSObjectType() );
        }

        List<CampaignMember> selectCampaignMembersByCampaignIdAndAccountFromContact(Set<Id> campaignIds, Set<Id> accountIds)
        {
            this.baseQuery
            .selectFields(new List<Schema.SObjectField> {CampaignMember.CampaignId,CampaignMember.Contact.AccountId})
            .addConditionIn(CampaignMember.CampaignId, campaignIds)
            .addConditionIn(CampaignMember.Contact.AccountId, accountIds);

            return this.baseQuery.run();
        }

        /**
         * @description Método que recupera los miembros de campaña pertenecientes
         * a una campaña concreta.
         *
         * @author amiranda
         * @date 09-10-2023
         * @param campaignId Id de la campaña sobre la que recuperar los miembros de campaña
         * @return List<CampaignMember> Miembros de campañana relacionads con la campaña
         * @where AuraEnabled method
         * 
         * amiranda 21/03/2024 Se refactoriza para la reutilización de un método
         * con un parámetro adicional.
         **/
        public List<CampaignMember> selectByCampaignId(Id campaignId)
        {
            return selectByCampaignIdAndOfferAssignedCode(campaignId, null);
        }

        /**
        * @description Método que recupera los miembros de campaña pertenecientes
        * a una campaña concreta y cuyo campo 'OfferAssignedCode__c' coincide
        * con los códigos de mediador pasados por parámetro.
        *
        * @author amiranda
        * @date 21-03-2024 
        * @param campaignId Id de la campaña sobre la que recuperar los miembros de campaña
        * @param offerAssignedCodes Códigos de mediador que deben coincidir con el campo 'OfferAssignedCode__c'
        * @return List<CampaignMember> Miembros de campaña
         * @where AuraEnabled method
        **/
        public List<CampaignMember> selectByCampaignIdAndOfferAssignedCode(Id campaignId, Set<String> offerAssignedCodes)
        {
            List<CampaignMember> campaignMembers = new List<CampaignMember>();

            /*
             * Se crea un conjunto de Strings porque algunos campos dan error al
             * tratar de pasarlos como 'Schema.sObjectField'
             * https://salesforce.stackexchange.com/questions/118597/schema-sobjectfield-inconsistency-with-relationship-fields
             */
            Set<String> fieldsToRetrieve = new Set<String>
            {
                'CampaignId',
                'Name',
                'OfferAssignedCode__c',
                'Campaign.StartDate',
                'Contact.AccountId',
                'Contact.Account.Name',
                'Contact.Account.INFOCustomerNumber__c'
            };

            if (campaignId != null)
            {
                if (offerAssignedCodes != null)
                {
                    this.baseQuery.addConditionIn(CampaignMember.OfferAssignedCode__c, offerAssignedCodes);
                }

                campaignMembers = this.baseQuery
                                  .selectFields(fieldsToRetrieve)
                                  .toLabel('Contact.Account.RecordType.Name')
                                  .toLabel('Status')
                                  .addConditionEq(CampaignMember.CampaignId, campaignId)
                                  .orderBy('Contact.Account.Name')
                                  .enforceSecurity()
                                  .run();
            }

            return campaignMembers;
        }
    }
}