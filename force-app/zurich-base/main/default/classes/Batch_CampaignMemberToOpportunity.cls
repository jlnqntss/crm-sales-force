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

    public void execute(Database.BatchableContext bc, List<sObject> records)
    {
        try {
            oppsToInsert.clear();           
    
            Map<Id, CampaignMember> campaignMembersAccountMap = new Map<Id, CampaignMember>();
            Set<String> intermediaryCodes = new Set<String>();
    
            for(sObject record : records)
            {
                campaignMembersAccountMap.put(((CampaignMember) record).Contact.AccountId, (CampaignMember) record);
                intermediaryCodes.add(((CampaignMember) record).OfferAssignedCode__c); 
            }        
    
            // 1. Filtra los miembros de campaña para solo generar oportunidades sobre los que tengan un cliente con una póliza asociada en estado "Vigor" o "Anulada" y cuyo check de GDPR esté a true
            List<CampaignMember> filteredCampaignMembers = filterCampaignMembersByCustomerVisibility(campaignMembersAccountMap, intermediaryCodes);
    
            // 2. Actualiza el campo Status de los registros de CampaignMember del scope con el valor "Mediador Sin Visibilidad" si no cumplen con el filtro
            List<CampaignMember> updatedCampaignMembers = getUpdatedCampaignMembersNoVisibility(campaignMembersAccountMap, filteredCampaignMembers);
    
            if (updatedCampaignMembers.size() > 0)
            {
                update updatedCampaignMembers;
            }
    
            // 3. Recorre los registros de CampaignMember filtrados y genera para cada uno la oferta
            // crea un nuevo registro opp de Opportunity con los siguientes campos informados:
            generateOpportunities(filteredCampaignMembers);
    
            if (!oppsToInsert.isEmpty()) {
                insert oppsToInsert;
    
            }
        } catch (Exception e) {
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
     * Devuelve la lista de miembros de campaña que recibe como parámetro, filtrada sin los miembros de campaña para cuyos clientes el agente no tiene visibilidad
     *
     * @author fpalomo
     * @param campaignMembersAccountMap Map<Id, CampaignMember>
     * @param intermediaryIds Set<Id>
     * @return List<CampaignMember>
     */
    private List<CampaignMember> filterCampaignMembersByCustomerVisibility(Map<Id, CampaignMember> campaignMembersAccountMap, Set<String> intermediaryCodes)
    {
        List<CampaignMember> result = new List<CampaignMember>();
        List<Policy__c> campaignMembersPolicies = new PoliciesSelector().findPoliciesByAccountId(campaignMembersAccountMap.keySet(), intermediaryCodes);

        // Ordeno las polizas encontradas en un mapa por mediador <IntermediaryCode, Set<PolicyHolderId>
        Map<String, Set<String>> intermediaryPolicyHoldersMap = getIntermediaryPolicyHoldersMap(campaignMembersPolicies);

        // Recorro cada miembro de campaña que llega al batch y si cumple que el cliente y mediador de ese miembro de campaña no tiene una poliza lo marcamos para "Mediador sin visibilidad"
        for (CampaignMember campaignMember: campaignMembersAccountMap.values()) {
            if (intermediaryPolicyHoldersMap.containsKey(campaignMember.OfferAssignedCode__c) && !!intermediaryPolicyHoldersMap.get(campaignMember.OfferAssignedCode__c).contains(campaignMember.Contact.AccountId)) {
                result.add(campaignMember);
            }
        }

        return result;
    }

    private List<CampaignMember> getUpdatedCampaignMembersNoVisibility(Map<Id, CampaignMember> campaignMembersAccountMap, List<CampaignMember> filteredCampaignMembers)
    {
        Map<Id, CampaignMember> updatedCampaignMembers = new Map<Id, CampaignMember>();
        for (CampaignMember cm : campaignMembersAccountMap.values())
        {
            if (!filteredCampaignMembers.contains(cm) && !updatedCampaignMembers.containsKey(cm.Id))
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
            if (cm.OfferAssignedType__c == 'M') {
                opp.ZRM__c = true;
            }

            // CC se corresponde con miembros de campaña para el Contact Center, que se asignarán a un usuario genérico
            else if  (cm.OfferAssignedType__c == 'CC') 
            {
                opp = fillCCData(opp, cm); 
                opp.ZRM__c = false; 
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
    private Map<String, String> getIntermediaryMap(List<CampaignMember> campaignMembers) {

        Map<String, String> accountByIntermCode = new Map<String, String>();

        List<String> cmOfferAssignedCodes = new List<String>();

        for (CampaignMember cm: campaignMembers) {
            cmOfferAssignedCodes.add(cm.OfferAssignedCode__c);
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        List<Account> accountInCmOfferAssignedCodes = accountsSelector.findByIntermediaryCode(cmOfferAssignedCodes);


        for(Account acc : accountInCmOfferAssignedCodes) {
            accountByIntermCode.put(acc.INFOIntermediaryCode__c, acc.Id);
        }

        return accountByIntermCode;
    }

    /* Método para informar campos de forma específica para miembros de campaña tipo Contact Center.
     * @author jfherrero
     * @date 04/08/2023
     * @param opp Oportunidad a generar.
     * @param cm MMiembro de campaña del que se genera la oportunidad.
     **/
    private Opportunity fillCCData(Opportunity opp, CampaignMember cm)
    {
        opp.LegalEntity__c = '001'; // añadimos entidad legal Zurich
        opp.BusinessCode__c = cm.Campaign.BusinessCode__c;
        opp.Scope__c = 'Ventas';

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

        Database.executeBatch( new Batch_CampaignMemberToOpportunity(campMemberIdSetFlow) );
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


    /**
     * Metodo que ordena las polizas encontradas en bd en formato <CodigoMediador, Set<PolicyHolderId>>
     * 
     * @author dmunoz
     * @date 11/3/2024
     */
    private static Map<String, Set<String>> getIntermediaryPolicyHoldersMap(List<Policy__c> campaignMembersPolicies) {

        Map<String, Set<String>> result = new Map<String, Set<String>>();
        for (Policy__c policy: campaignMembersPolicies) {
            result = generateSetMap(result, policy.IntermediaryId__r.INFOIntermediaryCode__c, policy.PolicyHolder__c);
        }

        return result;
    }

    /**
     * Método que añade un valor a un Map<String, Set<String>>
     *
     * @author dmunoz
     * @date 05/03/2024 
     */
    private static Map<String, Set<String>> generateSetMap(Map<String, Set<String>> mapToInsert, String key, String valueToAdd) {
        Set<String> aux;
        if (mapToInsert.containsKey(key)) {
            aux = mapToInsert.get(key);
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        } else {
            aux = new Set<String>();
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }

        return mapToInsert;
    }

    // ##endregion Resto métodos

}