/**
 * @description       : Clase controladora utilizada en los componentes relacionados
 * con la página custom desarrollada para la ficha de campañas en la comunidad ZRM
 *
 * @author            : amiranda
 * @date              : 28-12-2023
 * @last modified on  : 28-12-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   25-10-2023   amiranda   Initial Version
 **/
public with sharing class CampaignZRMCustomPageController
{
    private static final String CLASS_NAME = 'CampaignZRMCustomPageConroller';
    private static final Set<String> ASSIGNED_CUSTOMER_STATUS = new Set<String> {'Gestión Mediador'};
    private static final Set<String> ASSIGNED_CC_STATUS = new Set<String> {'Gestión CC', 'Pdte. Revisión Mediador'};

    /**
     * @description Método que retorna las campañas con los datos a visualizar
     * en el componente LWC IntermediaryCampaignList a las que el usuario que
     * visualiza el componente en cuestión tiene acceso.
     *
     * @author amiranda
     * @date 30-10-2023
     * @param intermediaryId Id de la cuenta de tipo 'Intermediario'
     * @return List<CampaignData> Lista de campañas
     * @where LWC IntermediaryCampaignList
     * 
     * @change amiranda 28/12/2023 Se añade el parámetro 'intermediaryId' al método.
     **/
    @AuraEnabled(cacheable=true)
    public static List<CampaignData> getCampaigns(Id intermediaryId)
    {
        List<CampaignData> campaigns = new List<CampaignData>();

        try
        {
            List<Campaign> retrievedCampaigns = new CampaignsSelector().selectCampaigns(intermediaryId);

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

            // Se obtienen todas las ofertas que no han sido clonadas asociadas a las cuentas asociadas a los contactos que a su vez están asociados a los miembros de campaña
            List<Opportunity> offersRelatedToCampaignMembers = new OpportunitiesSelector().selectByAccountIdsAndCampaignId(campaignMembersByAccountId.keySet(), campaignId, false);

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
                    cmData.offerPendingIntermediaryReview = offer.PendingIntermediaryReview__c;
                    cmData.offerIsClosed = offer.IsClosed;
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
     * @description Método que se encarga de lanzar el flujo que se encarga de actualizar
     * la oferta y el miembro de campaña con los Ids que se pasan por parámetro.
     *
     * @author amiranda
     * @date 18-12-2023
     * @param offerId Id de la oferta a actualizar
     * @param campaignMemberId Id del miembro de campaña a actualizar
     * @param userIntermediaryCode Código de intermediario que se asignará al miembro de campañá
     * @param userId Id del usuario que pasará a ser el propietario de la oferta a actualizar
     * @where LWC IntermediaryCampaignMember
     **/
    @AuraEnabled
    public static void updateOfferAndCampaignMember(Id offerId, Id campaignMemberId, String userIntermediaryCode, Id userId)
    {
        try
        {
            Map<String, Object> inputs = new Map<String, Object> {
                'OfferId' => offerId,
                'CampaignMemberId' => campaignMemberId,
                'UserIntermediaryCode' => userIntermediaryCode,
                'UserId' => userId
            };

            Flow.Interview.UpdateOfferAndCampaignMember updateOfferAndCampaignMember = new Flow.Interview.UpdateOfferAndCampaignMember(inputs);
            updateOfferAndCampaignMember.start();
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException( ex.getMessage() );
        }
    }

    /**
     * @description Método que se encarga de lanzar el flujo 'CloneOfferForIntermediary'
     * que se encarga del clonado de ofertas.
     *
     * @author amiranda
     * @date 21-12-2023
     * @param offerId Id de la oferta a clonar
     **/
    @AuraEnabled
    public static void cloneOffer(Id offerId)
    {
        try
        {
            Opportunity offerToClone = new Opportunity(Id = offerId);
            Map<String, Object> inputs = new Map<String, Object> {
                'OriginOffer' => offerToClone,
                'LaunchFromZRM' => true,
                'GetOfferRecord' => true
            };

            Flow.Interview.CloneOfferForIntermediary cloneOfferForIntermediary = new Flow.Interview.CloneOfferForIntermediary(inputs);
            cloneOfferForIntermediary.start();
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException( ex.getMessage() );
        }
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
        @AuraEnabled
        public Boolean offerPendingIntermediaryReview {get; set;}
        @AuraEnabled
        public Boolean offerIsClosed {get; set;}
    }
}