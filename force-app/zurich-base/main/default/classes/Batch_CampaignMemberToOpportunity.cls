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

    private Set<Id> campMemberIdSet = new Set<Id>();
    private Id defaultUserCC {get; set;}
    private Set<String> cmOfferAssignedCodes = new Set<String>();
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

    public void execute(Database.BatchableContext bc, List<sObject> records)
    {
        String aliasDefaultUserCC = Cross_Selling__c.getInstance().ContactCenterUser__c;

        defaultUserCC = usersSelector.findByAlias(aliasDefaultUserCC).Id;

        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for(sObject record : records)
        {
            campaignMembers.add( (CampaignMember) record );
        }

        // 1. Inicializa el mapa accountByIntermCode a partir del campo OfferAssignedCode__c (Código de Mediador) y el campo
        // Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c de todos los registros de CampaignMember del scope
        Map<String, Account> accountByIntermCode = getAccountByIntermCode(campaignMembers);

        // 2. Inicializa el mapa userIdByAccountId a partir del mapa accountByIntermCode
        Map<Id, Id> userIdByAccountId = getUserIdByAccountId(accountByIntermCode);

        // 3. Recorre los registros de CampaignMember del scope (consulta ejecutada en el método start) y para cada uno cm
        // crea un nuevo registro opp de Opportunity con los siguientes campos informados:
        generateOpportunities(campaignMembers, accountByIntermCode, userIdByAccountId);

        insert oppsToInsert;
    }

    public void finish(Database.BatchableContext bc)
    {
        //No se requiere de acciones
    }

    // ##regionend Métodos propios del batch

    // ##region Resto métodos

    private Map<String, Account> getAccountByIntermCode(List<CampaignMember> campaignMembers)
    {
        cmOfferAssignedCodes = new Set<String>();

        for (CampaignMember cr : campaignMembers)
        {
            if (cr.OfferAssignedCode__c != null)
            {
                cmOfferAssignedCodes.add(cr.OfferAssignedCode__c);
            }

            if (cr.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c != null)
            {
                cmOfferAssignedCodes.add(cr.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c);
            }
        }

        AccountsSelector accountsSelector = new AccountsSelector();

        List<Account> accountInCmOfferAssignedCodes = accountsSelector.findByIntermediaryCode( new List<String>(cmOfferAssignedCodes) );

        Map<String, Account> accountByIntermCode = new Map<String, Account>();

        for(Account acc : accountInCmOfferAssignedCodes)
        {
            accountByIntermCode.put(acc.INFOIntermediaryCode__c, acc);
        }

        return accountByIntermCode;
    }

    private Map<Id, Id> getUserIdByAccountId(Map<String, Account> accountByIntermCode)
    {
        Set<Id> intermAccountIds = new Set<Id>();

        for ( String abic : accountByIntermCode.keySet() )
        {
            intermAccountIds.add(accountByIntermCode.get(abic).Id);

            if (accountByIntermCode.get(abic).Parent.IntermediaryWithUser__c != null)
            {
                intermAccountIds.add(accountByIntermCode.get(abic).Parent.IntermediaryWithUser__c);
            }
        }

        // Mapa <Id Cuenta Mediador, Id Usuario> para poder asignar las Ofertas de Mediador

        List<User> intermUsers = usersSelector.findByContactAccountId(intermAccountIds);

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();

        for (User u : intermUsers)
        {
            userIdByAccountId.put(u.Contact.AccountId, u.Id);
        }

        return userIdByAccountId;
    }

    /* Método para generar las oportunidades a partir de los miembros de campaña y los mapas generados.
     * @author jfherrero
     * @date 03/08/2023
     * @param campaignMembers Lista con los registros a tratar.
     * @param accountByIntermCode Mapa de cuentas por código de intermediario.
     * @param userIdByAccountId Mapa de usuarios por cuenta.
     **/
    private void generateOpportunities(List<CampaignMember> campaignMembers, Map<String, Account> accountByIntermCode, Map<Id, Id> userIdByAccountId)
    {
        for (CampaignMember cm :campaignMembers)
        {
            Opportunity opp = new Opportunity();

            opp.Name = ('OF' + cm.Campaign.ExternalId__c + cm.Contact.Account.INFOCustomerNumber__c).left(120);
            opp.StageName = 'Legit Lead';
            opp.CloseDate = cm.Campaign.EndDate;
            opp.AccountId = cm.Contact.AccountId;
            opp.ProductBranch__c = cm.Campaign.ProductBranch__c;
            opp.CampaignId = cm.CampaignId;


            // M se corresponde con miembros de campaña para Agentes Mediador
            if (cm.OfferAssignedType__c == 'M')
            {
                opp = fillMediatorData(opp, cm, accountByIntermCode, userIdByAccountId);
            }

            // CC se corresponde con miembros de campaña para el Contact Center, que se asignarán a un usuario genérico
            else if  (cm.OfferAssignedType__c == 'CC')
            {
                opp = fillCCData(opp, cm);
            }

            oppsToInsert.add(opp);
        }

    }

    /* Método para informar campos de forma específica para miembros de campaña tipo Mediador
     * @author jfherrero
     * @date 03/08/2023
     * @param opp Oportunidad a generar.
     * @param cm MMiembro de campaña del que se genera la oportunidad.
     * @param userIdByAccountId Mapa de usuarios por cuenta.
     **/
    private Opportunity fillMediatorData(Opportunity opp, CampaignMember cm, Map<String, Account> accountByIntermCode, Map<Id, Id> userIdByAccountId)
    {
        if (accountByIntermCode.get(cm.OfferAssignedCode__c).Id != null)
        {
            opp.IntermediaryId__c = accountByIntermCode.get(cm.OfferAssignedCode__c).Id;
        }

        opp.IntermediaryCode__c = cm.OfferAssignedCode__c;

        if (accountByIntermCode.get(cm.OfferAssignedCode__c).Parent.IntermediaryWithUser__c != null )
        {
            if (accountByIntermCode.get(cm.OfferAssignedCode__c) != null &&
                userIdByAccountId.get(accountByIntermCode.get(cm.OfferAssignedCode__c).Parent.IntermediaryWithUser__c) != null)
            {
                opp.OwnerId = userIdByAccountId.get(accountByIntermCode.get(cm.OfferAssignedCode__c).Parent.IntermediaryWithUser__c);
            }
        }

        else
        {
            if (userIdByAccountId.get(accountByIntermCode.get(cm.OfferAssignedCode__c).Id) != null)
            {
                opp.OwnerId = userIdByAccountId.get(accountByIntermCode.get(cm.OfferAssignedCode__c).Id);
            }

            opp.OwnerId = userIdByAccountId.get(accountByIntermCode.get(cm.OfferAssignedCode__c).Id);
        }

        return opp;
    }

    /* Método para informar campos de forma específica para miembros de campaña tipo Contact Center.
     * @author jfherrero
     * @date 04/08/2023
     * @param opp Oportunidad a generar.
     * @param cm MMiembro de campaña del que se genera la oportunidad.
     **/
    private Opportunity fillCCData(Opportunity opp, CampaignMember cm)
    {
        opp.IntermediaryId__c = cm.Contact.Account.Intermediary_Name__c;
        opp.IntermediaryCode__c = cm.Contact.Account.Intermediary_Name__r.INFOIntermediaryCode__c;
        opp.OwnerId = defaultUserCC;
        opp.BusinessCode__c = cm.Campaign.BusinessCode__c;

        return opp;
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

        Database.executeBatch( new Batch_CampaignMemberToOpportunity(campMemberIdSetFlow) );
    }

    // ##endregion Resto métodos

}
