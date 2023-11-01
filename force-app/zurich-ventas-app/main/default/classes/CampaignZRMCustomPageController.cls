/**
 * @description       : Clase controladora utilizada en los componentes relacionados
 * con la página custom desarrollada para la ficha de campañas en la comunidad ZRM
 *
 * @author            : amiranda
 * @date              : 01-11-2023
 * @last modified on  : 01-11-2023
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
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException( ex.getMessage() );
        }

        return campaigns;
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
}