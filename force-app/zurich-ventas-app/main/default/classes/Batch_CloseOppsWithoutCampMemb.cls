/**
 * @description       : Clase-batch invocada bajo demanda que recorre registros de Oferta asociados a
 *                      Campañas de “Venta Cruzada” en los que el Miembro de Campaña no existe, cerrando dichas Ofertas.
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11/09/2023
 * @last modified by  : jgallaga
**/
global with sharing class Batch_CloseOppsWithoutCampMemb implements Database.Batchable<SObject>
{
    @InvocableMethod
    (label='Ejecutar Batch cierre de ofertas sin miembros de campaña' description='Elimina los miembros de camapaña de una campaña que' category='Opportunity')
    global static void invocableExecuteBatch()
    {
        Database.executeBatch(new Batch_CloseOppsWithoutCampMemb());
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        OpportunitiesSelector opportunitiesToCheck = new OpportunitiesSelector();
        String query = opportunitiesToCheck.findCrossSellingOpportunitiesNotClosed();

        System.debug('QUERY START ' + query);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        Map<Schema.SObjectType ,Set<Id>> campaignData = getCampaignAndAccountIds(scope);
        List<CampaignMember> campaignMembers = getCampaignMembers(campaignData);
        List<Opportunity> opportunitiesToUpdate = getOpportunitiesToUpdate(scope, campaignMembers);

        update opportunitiesToUpdate;

    }

    private List<CampaignMember> getCampaignMembers(Map<Schema.SObjectType,Set<Id>> campaignData)
    {
        CampaignMembersSelector campaignMembersSelector = new CampaignMembersSelector();

        Set<Id> campaignIds = campaignData.get(Campaign.getSObjectType());
        Set<Id> accountIds = campaignData.get(Account.getSObjectType());

        List<CampaignMember> campaignMembers = campaignMembersSelector.selectCampaignMembersByCampaignIdAndAccountFromContact(campaignIds, accountIds);

        System.debug('MIEMBROS DE CAMPAÑA ' + campaignMembers);

        return campaignMembers;
    }


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

    private List<Opportunity> getOpportunitiesToUpdate(List<Opportunity> scope, List<CampaignMember> campaignMembers)
    {
        List<Opportunity> changedOpportunities = new List<Opportunity>();

        for(Opportunity currentOpportunity : scope)
        {
            Boolean tieneMiembro = false;

            for(CampaignMember currentCampaignMember : campaignMembers)
            {
                if( currentCampaignMember.Contact.AccountId == currentOpportunity.AccountId &&
                    currentCampaignMember.CampaignId == currentOpportunity.CampaignId)
                {
                   tieneMiembro = true;
                   break;
                }
            }

            if(!tieneMiembro)
            {
                currentOpportunity.StageName = 'Closed Lost';
                currentOpportunity.Sales_Loss_Reason__c = 'Not interested Policy - Revocation Consents';

                changedOpportunities.add(currentOpportunity);
            }
        }

        return changedOpportunities;
    }

    global void finish(Database.BatchableContext bc) {}
}