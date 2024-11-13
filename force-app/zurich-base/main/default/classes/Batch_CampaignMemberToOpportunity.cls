/**
 * Procesa los miembros de campaña tras su inserción, para generar Ofertas de forma automática.
 * En función de su tipología se asignarán a un Agente Mediador o al usuario genérico del Contact Center.
 *
 * @author nts (jfherrero)
 * @date 24/07/2023
 **/

public with sharing class Batch_CampaignMemberToOpportunity implements Database.Batchable<sObject>
{
    // #region Atributos

    
    private static final String CLASS_NAME = 'Batch_CampaignMemberToOpportunity';
    private static final Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
    private static final String PRODUCT_BRANCH_VIDA_CODE = configValues.get('Product_Branch_Vida_Code');
    private static final Id OFFER_RECORD_TYPE_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_Life')).getRecordTypeId();
    private static final Id OFFER_RECORD_TYPE_NO_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_NoLife')).getRecordTypeId();
    private static final String LEGAL_ENTITY_LIFE_INSURANCE = configValues.get('Legal_Entity_Life_Insurance');

    private Set<Id> campMemberIdSet = new Set<Id>();
    private List<Opportunity> oppsToInsert = new List <Opportunity>();
    private static UsersSelector usersSelector = new UsersSelector();

    private static Boolean isAGRUser;

    // #endregion Atributos

    // #region Métodos propios del batch

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

            // 0. Obtengo el usuario logueado
            // Obtengo el usuario logueado
            User loggedUser = ( new UsersSelector() ).findUserIntermediaryByUserId( UserInfo.getUserId() );
            isAGRUser = ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR.equals(loggedUser.Profile.Name) && String.isNotBlank(loggedUser.Contact.Account.IntermediaryGroup__c);

            Set<Id> accountList = new Set<Id>();
            Set<String> intermediaryList = new Set<String>();

            // 1º Recupero datos de cliente y codigos de mediador de los miembros de campaña obtenidos
            for (CampaignMember cm: campaignMembers) {
                accountList.add(cm.Contact.AccountId);
                intermediaryList.add(cm.OfferAssignedCode__c);
            }

            // 2º Revisar los pares cliente - mediador tienen una oferta u poliza a los cuales se puede generar oferta
            Map<String, List<CampaignMember>> processedCampaignMembersMap = checkVisibility(campaignMembers, accountList, intermediaryList, loggedUser);

            // 3º Para los miembros de campaña permitidos se generan las ofertas
            insertNewOffers(processedCampaignMembersMap.get('ValidCampaignMembers'), loggedUser);

            // 4º Actualizar miembros de campaña a Mediador Sin Visibilidad
            updateInvalidCampaignMembers(processedCampaignMembersMap.get('InvalidCampaignMembers'));

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

    // #regionend

    // #region Check Visibilidad

    /**
     * Recorremos los datos de entrada para determinar que el par cliente- mediador tiene una oferta o una poliza en el sistema
     *
     * @author dmunoz
     * @date 13/11/2024
     *
     * @return Map<String, List<CampaignMember>>
     */
    private Map<String, List<CampaignMember>> checkVisibility(List<CampaignMember> campaignMembers, Set<Id> accountList, Set<String> intermediaryCodesList, User loggedUser) {
        Map<String, List<CampaignMember>> result = new Map<String, List<CampaignMember>>();

        List<CampaignMember> validCampaignMembers = new List<CampaignMember>();
        List<CampaignMember> invalidCampaignMembers = new List<CampaignMember>();
        

        // Obtengo un conjunto de valores AccountId-CodigoMediador de ofertas y polizas o el par AccountId-AgrupacionId
        Set<String> campaignMembersPoliciesSet = getPolicyHolderIntermediaryPolicies(accountList, intermediaryCodesList, loggedUser);
        Set<String> campaignMembersOpportunitiesSet = getAccountIdIntermediaryOpportunities(accountList, intermediaryCodesList, loggedUser);
        
        // recorro los miembros de campaña y los clasifico en validos o no
        String parAux;
        for (CampaignMember cm : campaignMembers) {
            parAux = cm.Contact.AccountId + '-' + cm.OfferAssignedCode__c;
            if (campaignMembersPoliciesSet.contains(parAux) || campaignMembersOpportunitiesSet.contains(parAux)) {
                validCampaignMembers.add(cm);
            } else {
                invalidCampaignMembers.add(cm);
            }
        }

        result.put('ValidCampaignMembers', validCampaignMembers);
        result.put('InvalidCampaignMembers', invalidCampaignMembers);

        
        return result;
    }


    /**
     * Obtenemos todas las polizas de los clientes y los mediadores y lo devolvemos como conjunto de string AccountId-CodigoMediador
     *
     * @author dmunoz
     * @date 13/11/2024
     *
     * @return Set<String> par accountId-CodigoMediador
     */
    private Set<String> getPolicyHolderIntermediaryPolicies(Set<Id> accountList, Set<String> intermediaryCodesList, User loggedUser) {

        Set<String> result = new Set<String>();

        List<Policy__c> policyQuery = new List<Policy__c>();
        

        // Obtenemos las pólizas si el usuario es agente de ventas AGR
        if (isAGRUser)
        {
            policyQuery = ( new PoliciesSelector() ).policiesHoldersFromIntermediaryGroup(new Set<String> {accountList}, new Set<String> { loggedUser.Contact.Account.IntermediaryGroup__c });

            for (Policy__c policy: policyQuery) {
                result.add(policy.PolicyHolder__c + '-' + policy.IntermediaryId__r.IntermediaryGroup__c);
            }
        }
        else
        {
            policyQuery = ( new PoliciesSelector() ).findPoliciesByAccountId(accountList, intermediaryCodesList);

            for (Policy__c policy: policyQuery) {
                result.add(policy.PolicyHolder__c + '-' + policy.IntermediaryId__r.INFOIntermediaryCode__c);
            }
        }

        return result;
    }


    /**
     * Obtenemos todas las ofertas de los clientes y los mediadores y lo devolvemos como conjunto de string AccountId-CodigoMediador / AccountId-AgrupacionId
     *
     * @author dmunoz
     * @date 13/11/2024
     *
     * @return Set<String> par accountId-CodigoMediador
     */
    private Set<String> getAccountIdIntermediaryOpportunities(Set<Id> accountList, Set<String> intermediaryCodesList, User loggedUser) {

        Set<String> result = new Set<String>();

        List<Opportunity> opportunityQuery = new List<Opportunity>();        

        // Obtenemos las ofertas si el usuario es agente de ventas AGR
        if (isAGRUser)
        {
            opportunityQuery = ( new OpportunitiesSelector() ).findOpportunitiesByAccountIdAndIntermediaryGroup(accountList, new Set<String> { loggedUser.Contact.Account.IntermediaryGroup__c });

            for (Opportunity opportunity: opportunityQuery) {
                result.add(opportunity.AccountId + '-' + opportunity.IntermediaryId__r.IntermediaryGroup__c);
            }
        }
        else // Resto de perfiles
        {
            opportunityQuery = ( new OpportunitiesSelector() ).findOpportunitiesByAccountIdAndIntermediary(accountList, intermediaryCodesList);

            for (Opportunity opportunity: opportunityQuery) {
                result.add(opportunity.AccountId + '-' + opportunity.IntermediaryId__r.INFOIntermediaryCode__c);
            }
        }

        return result;
    }

    //#region Insertar Ofertas


    /* Método para generar las oportunidades a partir de los miembros de campaña y los mapas generados.
     * @author jfherrero
     * @date 03/08/2023
     * @param campaignMembers Lista con los registros a tratar.
     * @param accountByIntermCode Mapa de cuentas por código de intermediario.
     * @param userIdByAccountId Mapa de usuarios por cuenta.
     **/
    private void insertNewOffers(List<CampaignMember> campaignMembers, User loggedUser)
    {

        for (CampaignMember cm :campaignMembers)
        {
            Opportunity opp = new Opportunity();

            opp.Name = ('OF' + cm.Campaign.ExternalId__c + cm.Contact.Account.INFOCustomerNumber__c).left(120);
            opp.StageName = GlobalConfigUtil.getGlobalConfigurationValueId('Opportunity_Stage_Name_Legit_Lead');
            opp.CloseDate = cm.Campaign.EndDate;
            opp.AccountId = cm.Contact.AccountId;
            opp.ProductBranch__c = cm.Campaign.ProductBranch__c;
            opp.CampaignId = cm.CampaignId;
            opp.IntermediaryCode__c = cm.OfferAssignedCode__c;
            opp.OwnerId = obtainDefaultUser();

            // Asociar el mediador en funcion del usuario logueado
            if (isAGRUser) {
                opp.IntermediaryId__c = loggedUser.Contact.AccountId;
            } else {
                opp.IntermediaryId__r = new Account(INFOIntermediaryCode__c = cm.OfferAssignedCode__c);
            }

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
                opp.Scope__c = GlobalConfigUtil.getGlobalConfigurationValueId('Opportunity_Scope_Ventas');
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

        if (!oppsToInsert.isEmpty()) {
            insert oppsToInsert;
        }

    }

    // #region Mediador Sin Visibilidad

    /**
     * Actualiza el estado de los miembros de campaña que recibe como parámetro y que no se encuentran en el filtro
     *
     * @author fpalomo
     * @date 04/04/2024
     *
     * @return List<Opportunities>
     */
    private void updateInvalidCampaignMembers(List<CampaignMember> campaignMembers)
    {

        if (!campaignMembers.isEmpty()) {

            for (CampaignMember cm : campaignMembers)
            {                
                cm.Status = GlobalConfigUtil.getGlobalConfigurationValueId('CampaignMemberStatusMediadorSinVisibilid');             
            }

            update campaignMembers;
        }
    }

    //#region Flow invocation
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

    // #region Otros metodos Auxiliares
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



    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Devuelve la lista de CampaignMembers que recibe como parámetro, filtrada para eliminar todos aquellos para los que el mediador no tenga visibilidad
     *
     * @author fpalomo
     * @date 04/04/2024
     *
     * @return List<Opportunities>
     */
    /*private List<CampaignMember> getFilteredCampaignMembers(Map<Id, CampaignMember> campaignMembersAccountMap, Set<String> intermediaryCodes)
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
    }*/

    

}