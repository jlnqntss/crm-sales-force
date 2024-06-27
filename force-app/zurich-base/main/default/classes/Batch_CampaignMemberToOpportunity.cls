/**
 * Procesa los miembros de campaña tras su inserción, para generar Ofertas de forma automática.
 * En función de su tipología se asignarán a un Agente Mediador o al usuario genérico del Contact Center.
 *
 * @author nts (jfherrero)
 * @date 24/07/2023
 **/

public with sharing class Batch_CampaignMemberToOpportunity implements Database.Batchable<sObject>
{
    // ##region Atributos

    
    private static final String CLASS_NAME = 'Batch_CampaignMemberToOpportunity';
    private static final Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
    private static final String PRODUCT_BRANCH_VIDA_CODE = configValues.get('Product_Branch_Vida_Code');
    private static final Id OFFER_RECORD_TYPE_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_Life')).getRecordTypeId();
    private static final Id OFFER_RECORD_TYPE_NO_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_NoLife')).getRecordTypeId();
    private static final String LEGAL_ENTITY_LIFE_INSURANCE = configValues.get('Legal_Entity_Life_Insurance');

    private Set<Id> campMemberIdSet = new Set<Id>();
    private List<Opportunity> oppsToInsert = new List <Opportunity>();
    private static UsersSelector usersSelector = new UsersSelector();

    // ##endregion Atributos

    // ##region Métodos propios del batch

    /**
     * Constructor.
     * @author jfherrero
     * @date 27/07/2023
     * @param campMemberIdSet Set con los Id de los miembros de campaña
     **/
    public Batch_CampaignMemberToOpportunity (Set<Id> campMemberIdSet)
    {
        this.campMemberIdSet = campMemberIdSet;
    }

    public List<CampaignMember> start(Database.BatchableContext bc)
    {
        List<String> crossSellingCampaigns = new List<String> {'Cross Selling', 'Venta Cruzada'};

        CampaignMembersSelector campaignMembersSelector = new CampaignMembersSelector(new Set<String> {
            'Id', 'CampaignMember.CampaignId', 'CampaignMember.OfferAssignedCode__c', 'CampaignMember.OfferAssignedType__c',
            'CampaignMember.Contact.AccountId', 'CampaignMember.Contact.Account.INFOCustomerNumber__c',
            'CampaignMember.Contact.Account.Intermediary_Name__c', 'CampaignMember.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c',
            'CampaignMember.Campaign.StartDate', 'CampaignMember.Campaign.EndDate', 'CampaignMember.Campaign.ExternalId__c',
            'CampaignMember.Campaign.ProductBranch__c', 'CampaignMember.Campaign.BusinessCode__c'
        });

        return ( campaignMembersSelector.selectByCampaignTypeAndId(crossSellingCampaigns, campMemberIdSet) );
    }

    public void execute(Database.BatchableContext bc, List<CampaignMember> campaignMembers)
    {
        try
        {
            oppsToInsert.clear();

            Map<Id, CampaignMember> campaignMembersAccountMap = new Map<Id, CampaignMember>();
            Set<String> intermediaryCodes = new Set<String>();

            for(CampaignMember campaignMember : campaignMembers)
            {
                if (campaignMember.Contact.AccountId != null)
                {
                    campaignMembersAccountMap.put(campaignMember.Contact.AccountId, campaignMember);
                }

                if (campaignMember.OfferAssignedCode__c != null)
                {
                    intermediaryCodes.add(campaignMember.OfferAssignedCode__c);
                }
            }

            // 1. Filtra los miembros de campaña para solo generar oportunidades sobre los que tengan un cliente con una póliza asociada en estado "Vigor" o "Anulada" y cuyo check de GDPR esté a true
            List<CampaignMember> filteredCampaignMembers = getFilteredCampaignMembers(campaignMembersAccountMap, intermediaryCodes);

            // 2. Actualiza el campo Status de los registros de CampaignMember del scope con el valor "Mediador Sin Visibilidad" si no cumplen con el filtro
            List<CampaignMember> updatedCampaignMembers = getUpdatedCampaignMembersNoVisibility(campaignMembers, filteredCampaignMembers);

            if (updatedCampaignMembers.size() > 0)
            {
                update updatedCampaignMembers;
            }

            // 3. Recorre los registros de CampaignMember filtrados y genera para cada uno la oferta
            // crea un nuevo registro opp de Opportunity con los siguientes campos informados:
            generateOpportunities(filteredCampaignMembers);
            if ( !oppsToInsert.isEmpty() )
            {
                insert oppsToInsert;

            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }

    }

    public void finish(Database.BatchableContext bc)
    {
        //No se requiere de acciones
    }

    // ##regionend Métodos propios del batch

    // ##region Resto métodos

    /**
     * Devuelve la lista de CampaignMembers que recibe como parámetro, filtrada para eliminar todos aquellos para los que el mediador no tenga visibilidad
     *
     * @author fpalomo
     * @date 04/04/2024
     *
     * @return List<Opportunities>
     */
    private List<CampaignMember> getFilteredCampaignMembers(Map<Id, CampaignMember> campaignMembersAccountMap, Set<String> intermediaryCodes)
    {
        List<CampaignMember> filteredCampaignMembers = new List<CampaignMember>();
        List<Policy__c> campaignMembersPolicies = new List<Policy__c>();
        User loggedUser = ( new UsersSelector() ).findUserIntermediaryByUserId( UserInfo.getUserId() );

        // Obtenemos las pólizas
        if ( ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR.equals(loggedUser.Profile.Name) && String.isNotBlank(loggedUser.Contact.Account.IntermediaryGroup__c) )
        {
            campaignMembersPolicies = ( new PoliciesSelector() ).selectByIntermediaryGroupId(new Set<String> { loggedUser.Contact.Account.IntermediaryGroup__c });
        }
        else
        {
            campaignMembersPolicies = ( new PoliciesSelector() ).findPoliciesByAccountId(campaignMembersAccountMap.keySet(), intermediaryCodes);
        }

        // Lista con las IDs de cuenta para las que se van a generar ofertas
        Set<String> toOfferAccountIDs = new Set<String>();

        // Añadimos los clientes de las pólizas a la lista de cuentas
        for(Policy__c policy : campaignMembersPolicies)
        {
            toOfferAccountIDs.add(policy.PolicyHolder__c);
        }

        Set<String> campaignIDsToExcludeMembers = new Set<String>();
        for ( CampaignMember cm : campaignMembersAccountMap.values() )
        {
            campaignIDsToExcludeMembers.add(cm.CampaignId);
        }

        // Recuperamos las ofertas, excluyendo las que pertenezcan a clientes que ya estén en la lista
        List<Opportunity> campaignMembersOffers = ( new OpportunitiesSelector() ).getIntermediaryOtherOffersByCampaignMembers(campaignIDsToExcludeMembers, toOfferAccountIDs, loggedUser.Contact.AccountId);

        // Añadimos los clientes de las ofertas recuperadas a la lista de cuentas a las que se le van a generar ofertas
        for(Opportunity offer : campaignMembersOffers)
        {
            toOfferAccountIDs.add(offer.AccountId);
        }

        // Añadimos a la lista los miembros de campaña que cumplan el filtro
        for ( CampaignMember campaignMember : campaignMembersAccountMap.values() )
        {
            if ( toOfferAccountIDs.contains(campaignMember.Contact.AccountId) )
            {
                filteredCampaignMembers.add(campaignMember);
            }
        }

        return filteredCampaignMembers;
    }

    /**
     * Actualiza el estado de los miembros de campaña que recibe como parámetro y que no se encuentran en el filtro
     *
     * @author fpalomo
     * @date 04/04/2024
     *
     * @return List<Opportunities>
     */
    private List<CampaignMember> getUpdatedCampaignMembersNoVisibility(List<CampaignMember> campaignMembers, List<CampaignMember> filteredCampaignMembers)
    {
        Map<Id, CampaignMember> updatedCampaignMembers = new Map<Id, CampaignMember>();

        for (CampaignMember cm : campaignMembers)
        {
            if ( !filteredCampaignMembers.contains(cm) && !updatedCampaignMembers.containsKey(cm.Id) )
            {
                cm.Status = 'Mediador Sin Visibilidad';
                updatedCampaignMembers.put(cm.Id, cm);
            }
        }

        return updatedCampaignMembers.values();
    }

    /* Método para generar las oportunidades a partir de los miembros de campaña y los mapas generados.
     * @author jfherrero
     * @date 03/08/2023
     * @param campaignMembers Lista con los registros a tratar.
     * @param accountByIntermCode Mapa de cuentas por código de intermediario.
     * @param userIdByAccountId Mapa de usuarios por cuenta.
     **/
    private void generateOpportunities(List<CampaignMember> campaignMembers)
    {

        Map<String, String> intermediaryIdMap = getIntermediaryMap(campaignMembers);

        for (CampaignMember cm :campaignMembers)
        {
            Opportunity opp = new Opportunity();

            opp.Name = ('OF' + cm.Campaign.ExternalId__c + cm.Contact.Account.INFOCustomerNumber__c).left(120);
            opp.StageName = 'Legit Lead';
            opp.CloseDate = cm.Campaign.EndDate;
            opp.AccountId = cm.Contact.AccountId;
            opp.ProductBranch__c = cm.Campaign.ProductBranch__c;
            opp.CampaignId = cm.CampaignId;
            opp.IntermediaryId__c = intermediaryIdMap.containsKey(cm.OfferAssignedCode__c) ? intermediaryIdMap.get(cm.OfferAssignedCode__c) : null;
            opp.IntermediaryCode__c = cm.OfferAssignedCode__c;
            opp.OwnerId = obtainDefaultUser();

            // M se corresponde con miembros de campaña para Agentes Mediador
            if (cm.OfferAssignedType__c == 'M')
            {
                opp.ZRM__c = true;
            }

            // CC se corresponde con miembros de campaña para el Contact Center, que se asignarán a un usuario genérico
            else if  (cm.OfferAssignedType__c == 'CC')
            {
                opp.LegalEntity__c = '001';
                opp.BusinessCode__c = cm.Campaign.BusinessCode__c;
                opp.Scope__c = 'Ventas';
                opp.ZRM__c = false;
            }

            if(PRODUCT_BRANCH_VIDA_CODE.equals(opp.ProductBranch__c))
            {
                opp.RecordTypeId = OFFER_RECORD_TYPE_VIDA;
                opp.LegalEntity__c = LEGAL_ENTITY_LIFE_INSURANCE;
            }
            else
            {
                opp.RecordTypeId = OFFER_RECORD_TYPE_NO_VIDA;    
            }

            oppsToInsert.add(opp);
        }

    }


    /**
     * Obtener los ids de los mediadores a los que apunta el miembro de campaña
     *
     * @author dmunoz
     * @date 29/02/2024
     */
    private Map<String, String> getIntermediaryMap(List<CampaignMember> campaignMembers)
    {

        Map<String, String> accountByIntermCode = new Map<String, String>();

        List<String> cmOfferAssignedCodes = new List<String>();

        for (CampaignMember cm: campaignMembers)
        {
            cmOfferAssignedCodes.add(cm.OfferAssignedCode__c);
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        List<Account> accountInCmOfferAssignedCodes = accountsSelector.findByIntermediaryCode(cmOfferAssignedCodes);


        for(Account acc : accountInCmOfferAssignedCodes)
        {
            accountByIntermCode.put(acc.INFOIntermediaryCode__c, acc.Id);
        }

        return accountByIntermCode;
    }

    /**
     * Clase para el acceso a los registros y poder lanzar el batch desde un flow.
     * @author jfherrero
     * @date 27/07/2023
     **/
    public class FlowInputs
    {
        @InvocableVariable public List<Id> campMemberIds;

    }

    /**
     * Método invocable para poder lanzar el batch desde un Action en un flow.
     * @author jfherrero
     * @date 27/07/2023
     * @param campaignMembers Lista con los registros a tratar.
     **/
    @InvocableMethod(label='Create Offers from Campaign Members'
                            description='Genera ofertas para mediadores o agente genérico CC a partir de miembros de campaña'
                                         category='Campaign Member')
    public static void createOffers(List<String> campaignMembers)
    {
        if( System.isBatch() )
        {
            return;
        }

        Set<Id> campMemberIdSetReceived = new Set<Id>();

        for (String cmId : campaignMembers)
        {
            campMemberIdSetReceived.add(cmId);
        }

        List<String> crossSellingCampaigns = new List<String> {'Cross Selling', 'Venta Cruzada'};

        CampaignMembersSelector campaignMembersSelector = new CampaignMembersSelector(new Set<String> {
            'Id', 'CampaignMember.CampaignId', 'CampaignMember.OfferAssignedCode__c', 'CampaignMember.OfferAssignedType__c',
            'CampaignMember.Contact.AccountId', 'CampaignMember.Contact.Account.INFOCustomerNumber__c',
            'CampaignMember.Contact.Account.Intermediary_Name__c', 'CampaignMember.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c',
            'CampaignMember.Campaign.StartDate', 'CampaignMember.Campaign.EndDate', 'CampaignMember.Campaign.ExternalId__c',
            'CampaignMember.Campaign.ProductBranch__c', 'CampaignMember.Campaign.BusinessCode__c'
        });

        Map<Id, CampaignMember> cms = new Map<Id, CampaignMember>( campaignMembersSelector.selectByCampaignTypeAndId(crossSellingCampaigns, campMemberIdSetReceived) );
        Set<Id> campMemberIdSetFlow = cms.keyset();

        Database.executeBatch( new Batch_CampaignMemberToOpportunity(campMemberIdSetFlow), 100 );
    }


    /**
     * @description Método para recuperar los Ids de los usuarios configurados para ser los
     *              Ids por defecto para el usuario por defecto CC y el usuario por defecto
     *              en caso de error.
     * @author      jgallaga
     * @date        18/08/2023
     */
    private String obtainDefaultUser()
    {

        String defaultUserId;
        String aliasDeaultUser = Cross_Selling__c.getinstance().DefaultUser__c;

        UsersSelector userQuery = new UsersSelector();

        List<User> defaultUsers = userQuery.findUsersByAlias(new List<String> {aliasDeaultUser});

        defaultUserId = defaultUsers.get(0).Id;

        return defaultUserId;
    }

    // ##endregion Resto métodos

}