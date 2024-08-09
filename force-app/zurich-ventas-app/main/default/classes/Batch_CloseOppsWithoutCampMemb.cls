/**
 * @description       : Clase-batch invocada bajo demanda que recorre registros de Oferta asociados a
 *                      Campañas de “Venta Cruzada” en los que el Miembro de Campaña no existe, cerrando dichas Ofertas.
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 12/09/2023
 * @last modified by  : jgallaga
**/
global with sharing class Batch_CloseOppsWithoutCampMemb implements Database.Batchable<SObject>
{

    private String salesLossReason = '';

    global Batch_CloseOppsWithoutCampMemb()
    {}

    global Batch_CloseOppsWithoutCampMemb(String salesLossReason)
    {
        this.salesLossReason = salesLossReason;
    }

    /**
     * @description: Método invocable que inicia la ejecución del Batch.
     *               Este método puede ser llamado desde un flujo o proceso de Salesforce para iniciar el proceso de cierre de oportunidades.
     * @Author: jgallaga
     * @Date: 12/09/2023
     **/
    @InvocableMethod
    (label='Ejecutar Batch cierre de ofertas sin miembros de campaña' description='Elimina los miembros de camapaña de una campaña que' category='Opportunity')
    global static void invocableExecuteBatch()
    {
        Database.executeBatch(new Batch_CloseOppsWithoutCampMemb());
    }

    /**
     * @description: Método que proporciona un Database.QueryLocator que se utiliza para identificar los registros que el Batch procesará.
     *               En este caso, se utiliza una consulta para encontrar oportunidades de "Venta Cruzada" que tal vez deban pasarse a cerradas.
     * @Author: jgallaga
     * @Date: 12/09/2023
     **/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        OpportunitiesSelector opportunitiesToCheck = new OpportunitiesSelector();
        String query = opportunitiesToCheck.findCrossSellingOpportunitiesNotClosed();

        return Database.getQueryLocator(query);
    }

    /**
     * @description: Este es el núcleo del Batch. Aquí, se realizan las operaciones sobre los registros seleccionados.
     *               En este caso, se siguen los siguientes pasos:
     *               - Se obtienen los IDs de campaña y cuenta asociados a las oportunidades en el scope.
     *               - Se obtienen los miembros de campaña asociados a esas campañas y cuentas.
     *               - Se determina si cada oportunidad tiene o no un miembro de campaña asociado y se marca para cierre si no lo tiene.
     * @Author: jgallaga
     * @Date: 12/09/2023
    **/
    global void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        // Se recogen las campañas y las cuentas a las que apuntan las oportunidades
        Map<Schema.SObjectType ,Set<Id>> campaignData = getCampaignAndAccountIds(scope);
        // Se recogen los miembros de campaña que también apuntan a esas campañas y cuentas
        List<CampaignMember> campaignMembers = getCampaignMembers(campaignData);
        // Se modifican y recogen las oportunidades que han perdido su miembro de campaña porque se ha borrado
        List<Opportunity> opportunitiesToUpdate = getOpportunitiesToUpdate(scope, campaignMembers, this.salesLossReason);

        update opportunitiesToUpdate;
    }

    /**
     * @description:    Método que obtiene los IDs de campaña y cuenta asociados a las oportunidades del scope.
     * @param           scope Lista de oportunidades a procesar.
     * @return          Mapa que contiene los tipos de objeto (Campaña y Cuenta) y sus IDs asociados.
     * @Author: jgallaga
     * @Date: 12/09/2023
     **/
    private Map<Schema.SObjectType, Set<Id>> getCampaignAndAccountIds(List<Opportunity> scope)
    {
        Map<Schema.SObjectType,Set<Id>> result = new Map<Schema.SObjectType,Set<Id>>();

        for(Opportunity currentOpportunity : scope)
        {
            if(!result.containsKey(Account.getSObjectType()))
            {
                result.put(Account.getSObjectType(), new Set<Id>());
            }

            result.get(Account.getSObjectType()).add(currentOpportunity.AccountId);

            if(!result.containsKey(Campaign.getSObjectType()))
            {
                result.put(Campaign.getSObjectType(), new Set<Id>());
            }

            result.get(Campaign.getSObjectType()).add(currentOpportunity.CampaignId);

        }

        return result;
    }

    /**
     * @description:    Método que obtiene los miembros de campaña asociados a las campañas y cuentas proporcionadas.
     * @param           campaignData Mapa que contiene los tipos de objeto (Campaña y Cuenta) y sus IDs asociados.
     * @return          Lista de miembros de campaña asociados.
     * @Author: jgallaga
     * @Date: 12/09/2023
     **/
    private List<CampaignMember> getCampaignMembers(Map<Schema.SObjectType,Set<Id>> campaignData)
    {
        CampaignMembersSelector campaignMembersSelector = new CampaignMembersSelector();

        Set<Id> campaignIds = campaignData.get(Campaign.getSObjectType());
        Set<Id> accountIds = campaignData.get(Account.getSObjectType());

        List<CampaignMember> campaignMembers = campaignMembersSelector.selectCampaignMembersByCampaignIdAndAccountFromContact(campaignIds, accountIds);

        return campaignMembers;
    }

    /**
     * @description:    Método que determina qué oportunidades deben ser actualizadas y devuelve una lista de oportunidades que necesitan ser cerradas.
     * @param           scope Lista de oportunidades a procesar.
     * @param           campaignMembers Lista de miembros de campaña asociados.
     * @return          Lista de oportunidades que necesitan ser actualizadas.
     * @Author: jgallaga
     * @Date: 12/09/2023
     **/
    private List<Opportunity> getOpportunitiesToUpdate(List<Opportunity> scope, List<CampaignMember> campaignMembers, String salesLossReason)
    {
        List<Opportunity> changedOpportunities = new List<Opportunity>();

        for(Opportunity currentOpportunity : scope)
        {
            Boolean hasMember = false;

            for(CampaignMember currentCampaignMember : campaignMembers)
            {
                if( currentCampaignMember.Contact.AccountId == currentOpportunity.AccountId &&
                    currentCampaignMember.CampaignId == currentOpportunity.CampaignId)
                {
                   hasMember = true;
                   break;
                }
            }

            if(!hasMember)
            {
                String sLossR = GlobalConfigUtil.getGlobalConfigurationValue('Offer_SalesLossReason_RemovedCampaign');
                currentOpportunity.StageName = 'Closed Lost';
                
                if( currentOpportunity.Account.RecordType.DeveloperName == 'Lead' )
                {
                    currentOpportunity.SalesProcess__c = 'L';
                }
                else if (currentOpportunity.Account.RecordType.DeveloperName == 'BusinessCustomer' ||
                         currentOpportunity.Account.RecordType.DeveloperName == 'Customer' )
                {
                    currentOpportunity.SalesProcess__c = 'VC';
                }
                
                if ( salesLossReason.contains(sLossR) && currentOpportunity.SalesProcess__c == 'VC' )
                {
                    currentOpportunity.Sales_Loss_Reason__c = sLossR;
                }
                else
                {
                    currentOpportunity.Sales_Loss_Reason__c = 'Not interested Policy - Revocation Consents';
                }
                
                changedOpportunities.add(currentOpportunity);
            }
        }

        return changedOpportunities;
    }

    global void finish(Database.BatchableContext bc) {}
}