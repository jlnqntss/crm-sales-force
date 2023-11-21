/**
 * @description       : Clase-queueable ejecutada desde el WS de Quote&Buy que inserta/actualiza/asigna un registro de Oferta de Lead e inserta un registro de Póliza (si aplica)
 * @author            : nts - overes
 * @last modified on  : 02-10-2023
 **/

public with sharing class AccountLeadOpportunityQueueJob implements Queueable
{

    /**
     * Registro de Cuenta
     **/
    private Account accountRecord;
    /**
     * Registro de Oferta a insertar/actualizar/asignar
     **/
    private Opportunity offerRecord;
    /**
     * Registro de Póliza a insertar
     **/
    private Policy__c policyRecord;
    /**
     * Código Postal
     **/
    private String postalCode;
    /**
     * Teléfono
     **/
    private String phone;
    /**
     * Se requiere un CallMeBack o no
     **/
    private Boolean requiredCMB;

    private static final String CONTACT_CENTER = 'CONTACT_CENTER';

    /**
     * Constructor de la clase que inicializa los parámentros recibidos
     * *
     * @author overes | 08-31-2023
     * @param accountRecord
     * @param offerRecord
     * @param policyRecord
     * @param postalCode
     * @param phone
     **/
    public AccountLeadOpportunityQueueJob(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode, String phone)
    {
        this.accountRecord = accountRecord;
        this.offerRecord = offerRecord;
        this.policyRecord = policyRecord;
        this.postalCode = postalCode;
        this.phone = phone;
        this.requiredCMB = false;
    }

    public AccountLeadOpportunityQueueJob(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode, String phone, Boolean requiredCMB)
    {
        this.accountRecord = accountRecord;
        this.offerRecord = offerRecord;
        this.policyRecord = policyRecord;
        this.postalCode = postalCode;
        this.phone = phone;
        this.requiredCMB = requiredCMB;
    }

    /**
     * Método que se autoejecuta cuando se invoca la clase
     * *
     * @author overes | 08-31-2023
     * @param context
     **/
    public void execute(QueueableContext context)
    {
        processOpportunityAndPolicy(this.accountRecord, this.offerRecord, this.policyRecord, this.postalCode, this.phone, this.requiredCMB);
    }

    /**
     * Método
     * *
     * @author overes | 08-31-2023
     * @param accountRecord
     * @param offerRecord
     * @param policyRecord
     * @param postalCode
     **/
    public static void processOpportunityAndPolicy(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode, String phone, Boolean requiredCMB)
    {
        Opportunity offerToInsertUpdate = offerRecord;
        List<Opportunity> listOffer = new List<Opportunity>();
        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        if ( String.isBlank(offerRecord.InfoQuoteNumber__c) )
        {
            listOffer = oppSelector.findOppWhenInfoQuoteNumberIsNull(offerRecord);
        }
        else
        {
            listOffer = oppSelector.findOppWhenInfoQuoteNumberIsNOTNull(offerRecord);
        }

        manageOfferRecord(offerRecord, offerToInsertUpdate, listOffer);

        offerToInsertUpdate = manageOfferToInsertUpdate (offerToInsertUpdate, accountRecord, postalCode, phone, requiredCMB);

        if (offerToInsertUpdate != null && offerToInsertUpdate.Id == null)
        {
            insert offerToInsertUpdate;
        }
        else if (offerToInsertUpdate != null && offerToInsertUpdate.Id != null)
        {
            update offerToInsertUpdate;
        }

        managePolicyRecord(policyRecord, offerToInsertUpdate);
    }

    /**
     * @description
     * @author overes | 27-09-2023
     * @param offerToInsertUpdate
     * @param accountRecord
     * @param postalCode
     * @param phone
     * @return Opportunity
     **/
    public static Opportunity manageOfferToInsertUpdate (Opportunity offerToInsertUpdate, Account accountRecord, String postalCode, String phone, Boolean requiredCMB)
    {
        Opportunity offerToUpdate = offerToInsertUpdate;
        if (offerToInsertUpdate != null && offerToInsertUpdate.Id == null && offerToInsertUpdate.StageName != 'Cerrada-Ganada')   //Ejecutar Proceso de Asignación si la Oferta se debe insertar y no es el escenario de integración 3.
        {
            Map<String, Account> assign = AccountLeadUtil.leadAssignment(accountRecord, offerToInsertUpdate.IntermediaryCode__c, offerToInsertUpdate.IntermediaryCode__c, null, postalCode);
            offerToUpdate = manageConstrainsKey(assign, accountRecord, offerToInsertUpdate, phone, requiredCMB);
        }
        return offerToUpdate;
    }

    /**
     * @description
     * @author overes | 27-09-2023
     * @param assign
     * @param accountRecord
     * @param offerToInsertUpdate
     * @param phone
     * @return Opportunity
     **/
    public static Opportunity manageConstrainsKey (Map<String,Account> assign, Account accountRecord, Opportunity offerToInsertUpdate, String phone, Boolean requiredCMB)
    {
        Opportunity offerToUpdate = offerToInsertUpdate;
        if ( requiredCMB )
        {
            Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
            manageCallMeBack(accountRecord, offerToInsertUpdate, leadOffersCS, phone);

            if (offerToInsertUpdate.InfoQuoteNumber__c == null)
            {
                offerToUpdate = null;
            }
            else
            {
                offerToUpdate.BusinessCode__c = leadOffersCS.BusinessCode__c;
            }
        }
        else
        {
            offerToUpdate.OwnerId = new List<String>( assign.keySet() ).get(0);
            if (assign.get(offerToInsertUpdate.OwnerId) != null)
            {
                offerToUpdate.IntermediaryId__c = assign.get(offerToInsertUpdate.OwnerId).Id;
                offerToUpdate.IntermediaryCode__c = assign.get(offerToInsertUpdate.OwnerId).INFOIntermediaryCode__c;
            }
        }
        return offerToUpdate;
    }

    /**
     * @description
     * @author overes | 27-09-2023
     * @param accountRecord
     * @param offerToInsertUpdate
     * @param leadOffersCS
     * @param phone
     **/
    public static void manageCallMeBack(Account accountRecord, Opportunity offerToInsertUpdate, Lead_Offers__c leadOffersCS, String phone)
    {
        CallMeBackUtil.CallMeBack callMeBack = new CallMeBackUtil.CallMeBack();
        callMeBack.name = accountRecord.LastName;
        callMeBack.phone = phone;
        callMeBack.bestTimeFrom = accountRecord.PreferedContactStart__c;
        callMeBack.bestTimeUntil = accountRecord.PreferedContactEnd__c;
        callMeBack.businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBackFull fullObj = new CallMeBackUtil.CallMeBackFull();
        fullObj.request = callMeBack;
        fullObj.queueName = leadOffersCS.VoiceQueue__c;
        fullObj.businessHoursName = leadOffersCS.BusinessHour__c;

        List<CallMeBackUtil.CallMeBackFull> lstCallMeBack = new List<CallMeBackUtil.CallMeBackFull>();
        lstCallMeBack.add(fullObj);

        CallMeBackUtil.insertCallMeBack(lstCallMeBack);
    }

    /**
     * Método que gestiona la creación de una póliza
     * *
     * @author overes | 08-31-2023
     * @param policyRecord
     * @param offerToInsertUpdate
     */
    private static void managePolicyRecord(Policy__c policyRecord, Opportunity offerToInsertUpdate)
    {
        if ( (policyRecord != null && offerToInsertUpdate != null) && (policyRecord.InfoPolicyNumber__c != null && offerToInsertUpdate.InfoQuoteNumber__c != null) )
        {
            Policy__c policyToInsert = policyRecord;
            AccountsSelector accSelector = new AccountsSelector();
            List<Account> listAcc = accSelector.findByINFOIntermediaryCode(new List<String> {(String) offerToInsertUpdate.IntermediaryCode__c});
            policyToInsert.OpportunityName__c = offerToInsertUpdate.Id;
            policyToInsert.InfoQuoteNumber__c = offerToInsertUpdate.InfoQuoteNumber__c;
            if (listAcc.size() > 0)
            {
                policyToInsert.IntermediaryId__c = listAcc.get(0).Id;
            }
            policyToInsert.Intermediary_Code__c = offerToInsertUpdate.IntermediaryCode__c;
            insert policyToInsert;
        }
    }

    /**
     * Método que gestiona la creación o la actualización de Policy__c
     * *
     * @author overes | 08-31-2023
     * @param offerRecordParam
     * @param offerToInsertUpdateParam
     */
    @TestVisible
    private static void manageOfferRecord(Opportunity offerRecord, Opportunity offerToInsertUpdate,List<Opportunity> listOffer)
    {
        for (Opportunity offerQuery : listOffer)
        {
            if ( ( offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c && (offerQuery.StageName == 'Cerrada-Ganada' || offerQuery.StageName == 'Cerrada-Perdida') )  || (offerRecord.InfoQuoteNumber__c == null && offerQuery.SessionId__c == offerRecord.SessionId__c) )
            {
                offerToInsertUpdate = null;
                break;
            }
            else if (offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c)
            {
                offerToInsertUpdate.Id = offerQuery.Id;
            }
            else if (offerToInsertUpdate.Id == null && offerQuery.InfoQuoteNumber__c == null)
            {
                offerToInsertUpdate.Id = offerQuery.Id;
            }
        }
    }
}