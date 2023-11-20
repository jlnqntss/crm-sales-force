/**
 * @description       : Clase controladora utilizada en los componentes relacionados
 * con la página custom desarrollada para la ficha de campañas en la comunidad ZRM
 *
 * @author            : amiranda
 * @date              : 17-11-2023
 * @last modified on  : 17-11-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   25-10-2023   amiranda   Initial Version
 **/
public with sharing class CampaignZRMCustomPageController
{
    private static final String CLASS_NAME = 'CampaignZRMCustomPageConroller';
    private static final Set<String> ASSIGNED_CUSTOMER_STATUS = new Set<String> {'Gestión Mediador'};
    private static final Set<String> ASSIGNED_CC_STATUS = new Set<String> {'Gestión CC', 'Pdtes. Revisión Mediador'};

    /**
     * @description Método que retorna las campañas con los datos a visualizar
     * en el componente LWC IntermediaryCampaignList a las que el usuario que
     * visualiza el componente en cuestión tiene acceso.
     *
     * @author amiranda
     * @date 30-10-2023
     * @return List<CampaignData> Lista de campañas
     * @where LWC IntermediaryCampaignList
     **/
    @AuraEnabled(cacheable=true)
    public static List<CampaignData> getCampaigns()
    {
        List<CampaignData> campaigns = new List<CampaignData>();

        try
        {
            List<Campaign> retrievedCampaigns = new CampaignsSelector().selectCampaigns();

            if ( !retrievedCampaigns.isEmpty() )
            {
                for (Campaign retrievedCampaign : retrievedcampaigns)
                {
                    CampaignData campaign = new CampaignData();
                    campaign.id = retrievedCampaign.Id;
                    campaign.name = retrievedCampaign.Name;
                    campaign.startDate = retrievedCampaign.StartDate;
                    campaign.endDate = retrievedCampaign.EndDate;
                    campaign.type = retrievedCampaign.Type;
                    campaign.branch = retrievedCampaign.ProductBranch__c;
                    campaign.isActive = retrievedCampaign.IsActive;

                    for (CampaignMember campaignMember : retrievedCampaign.CampaignMembers)
                    {
                        if( ASSIGNED_CUSTOMER_STATUS.contains(campaignMember.Status) )
                        {
                            campaign.assignedToCustomers++;
                        }
                        else if ( ASSIGNED_CC_STATUS.contains(campaignMember.Status) )
                        {
                            campaign.assignedToCC++;
                        }
                    }

                    campaigns.add(campaign);
                }
            }
        }
        catch (Exception ex)
        {
            throw new AuraHandledException( ex.getMessage() );
        }

        return campaigns;
    }

    /**
     * @description Método que retorna una lista de de una clase interna que representa
     * los miembros de campaña con datos adicionales extraídos de los registros de objetos
     * como 'Account' u 'Opportunity'.
     *
     * @author amiranda
     * @date 14-11-2023
     * @param campaignId Id de la campañá
     * @return List<CampaignMemberData>  Lista con los miembros de campañá
     * representados por la clase interna 'CampaignMemberData' limitados por el
     * acceso que tiene el usuario a la cuenta relacionada con el contacto
     * relacionado con el miembro de campaña
     *
     * @where LWC IntermediaryCampaignMember
     **/
    @AuraEnabled(cacheable=true)
    public static List<CampaignMemberData> getCampaignMembers(Id campaignId)
    {
        List<CampaignMemberData> campaignMembers = new List<CampaignMemberData>();

        try
        {
            List<CampaignMember> campaignMembersRelatedToCampaign = new CampaignMembersSelector.ProperCampaignMembersSelector().selectByCampaignId(campaignId);

            // Obtener todos los Ids de las cuentas relacionadas con los miembros de campaña
            Map<Id, CampaignMember> campaignMembersByAccountId = new Map<Id, CampaignMember>();

            for (CampaignMember campaignMemberRelatedToCampaign : campaignMembersRelatedToCampaign)
            {
                /*
                 * Si el usuario no tiene acceso a la cuenta relacionada con el
                 * contacto que a su vez está relacionado con el miembro de campaña,
                 * el campo 'AccountId' será null. Se puede evitar lanzar una nueva
                 * consulta al objeto 'UserRecordAccess'
                 */
                if (campaignMemberRelatedToCampaign.Contact.AccountId != null)
                {
                    campaignMembersByAccountId.put(campaignMemberRelatedToCampaign.Contact.AccountId, campaignMemberRelatedToCampaign);
                }
            }

            // Se obtienen todas las ofertas asociadas a las cuentas asociadas a los contactos que a su vez están asociados a los miembros de campaña
            List<Opportunity> offersRelatedToCampaignMembers = new OpportunitiesSelector().selectByAccountIdsAndCampaignId(campaignMembersByAccountId.keySet(), campaignId);

            Map<Id, Opportunity> offersByAccountId = new Map<Id, Opportunity>();
            for (Opportunity offerRelatedToCampaignMember : offersRelatedToCampaignMembers)
            {
                offersByAccountId.put(offerRelatedToCampaignMember.AccountId, offerRelatedToCampaignMember);
            }

            for ( Id accountId : campaignMembersByAccountId.keySet() )
            {
                CampaignMember campaignMember = campaignMembersByAccountId.get(accountId);

                CampaignMemberData cmData = new CampaignMemberData();
                cmData.cmId = campaignMember.Id;
                cmData.cmCampaignStartDate = campaignMember.Campaign.StartDate;
                cmData.cmAffiliationCode = campaignMember.Contact.Account.INFOCustomerNumber__c;
                cmData.cmName = campaignMember.Contact.Account.Name;
                cmData.cmRelatedAccountId = campaignMember.Contact.AccountId;
                cmData.cmStatus = campaignMember.Status;
                cmData.cmRelatedAccountRTName = campaignMember.Contact.Account.RecordType.Name;
                cmData.cmIntermediaryCode = campaignMember.OfferAssignedCode__c;

                Opportunity offer = offersByAccountId.get(accountId);

                if (offer != null)
                {
                    cmData.offerName = offer.Name;
                    cmData.offerId = offer.Id;
                    cmData.offerStage = offer.StageName;
                    cmData.offerSalesLossReason = offer.Sales_Loss_Reason__c;
                    cmData.offerSalesLossReasonLabel = (String) offer.get('salesLossReasonLabel');
                }

                campaignMembers.add(cmData);
            }
        }
        catch (Exception ex)
        {
            throw new AuraHandledException( ex.getMessage() );
        }

        return campaignMembers;
    }


    /**
     * Clase interna que representa una Campaña con los datos necesarios que
     * necesita el componente LWC IntermediaryCampaignList
     */
    @TestVisible
    private class CampaignData
    {
        @AuraEnabled
        public Id id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Date startDate {get; set;}
        @AuraEnabled
        public Date endDate {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public String branch {get; set;}
        @AuraEnabled
        public Boolean isActive {get; set;}
        @AuraEnabled
        public Integer assignedToCustomers {get; set;}
        @AuraEnabled
        public Integer assignedToCC {get; set;}

        public CampaignData()
        {
            this.assignedToCustomers = 0;
            this.assignedToCC = 0;
        }
    }

    /**
     * Clase interna que representa un 'Miembro de Campaña' dentro de la tabla
     * del componente 'intermediaryCampaingMember'. Esta representación contiene
     * datos de registros de diferentes objetos como 'Account' u 'Opportunity'.
     */
    @TestVisible
    private class CampaignMemberData
    {
        @AuraEnabled
        public String cmId {get; set;}
        @AuraEnabled
        public Date cmCampaignStartDate {get; set;}
        @AuraEnabled
        public String cmAffiliationCode {get; set;}
        @AuraEnabled
        public String cmName {get; set;}
        @AuraEnabled
        public String cmIntermediaryCode {get; set;}
        @AuraEnabled
        public String cmRelatedAccountId { get; set;}
        @AuraEnabled
        public String cmRelatedAccountRTName {get; set;}
        @AuraEnabled
        public String cmStatus {get; set;}
        @AuraEnabled
        public String offerId {get; set;}
        @AuraEnabled
        public String offerName {get; set;}
        @AuraEnabled
        public String offerStage {get; set;}
        @AuraEnabled
        public String offerSalesLossReason {get; set;}
        @AuraEnabled
        public String offerSalesLossReasonLabel {get; set;}
    }
}