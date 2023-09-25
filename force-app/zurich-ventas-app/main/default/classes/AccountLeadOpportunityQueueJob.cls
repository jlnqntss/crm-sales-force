/**
 * @description       : Clase-queueable ejecutada desde el WS de Quote&Buy que inserta/actualiza/asigna un registro de Oferta de Lead e inserta un registro de Póliza (si aplica)
 * @author            : nts - overes
 * @last modified on  : 09-25-2023
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
    }

    /**
     * Método que se autoejecuta cuando se invoca la clase
     * *
     * @author overes | 08-31-2023
     * @param context
     **/
    public void execute(QueueableContext context)
    {
        processOpportunityAndPolicy(this.accountRecord, this.offerRecord, this.policyRecord, this.postalCode, this.phone);
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
    public static void processOpportunityAndPolicy(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode, String phone)
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
     * Método que gestiona la creación de una póliza
     * *
     * @author overes | 08-31-2023
     * @param policyRecord
     * @param offerToInsertUpdate
     */
    private static void managePolicyRecord(Policy__c policyRecord, Opportunity offerToInsertUpdate)
    {
        if (policyRecord != null && offerToInsertUpdate != null)
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