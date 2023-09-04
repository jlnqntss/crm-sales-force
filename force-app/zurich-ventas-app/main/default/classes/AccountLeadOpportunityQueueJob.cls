/**
 * @description       : Clase-queueable ejecutada desde el WS de Quote&Buy que inserta/actualiza/asigna un registro de Oferta de Lead e inserta un registro de Póliza (si aplica)
 * @author            : nts - overes
 * @last modified on  : 09-01-2023
**/

public with sharing class AccountLeadOpportunityQueueJob implements Queueable {

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
    * Constructor de la clase que inicializa los parámentros recibidos
    * *
    * @author overes | 08-31-2023
    * @param accountRecord
    * @param offerRecord
    * @param policyRecord
    * @param postalCode
    **/
    public AccountLeadOpportunityQueueJob(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode) {
        this.accountRecord = accountRecord;
        this.offerRecord = offerRecord;
        this.policyRecord = policyRecord;
        this.postalCode = postalCode;
    }

    /**
    * Método que se autoejecuta cuando se invoca la clase
    * *
    * @author overes | 08-31-2023
    * @param context
    **/
    public void execute(QueueableContext context) {
        processOpportunityAndPolicy(this.accountRecord, this.offerRecord, this.policyRecord, this.postalCode);
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
    public static void processOpportunityAndPolicy(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode) {
        List<Opportunity> listOffer = new List<Opportunity>();
        Opportunity offerToInsertUpdate = offerRecord;

        //Construye una query sobre Opportunity para obtener registros duplicados de la Oferta a procesar
        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        // List<Opportunity> duplicateOpp = oppSelector.findDuplicatesById(offerRecord.Id);

        if (offerRecord.InfoQuoteNumber__c == null) {
            listOffer = oppSelector.findOppWhenInfoQuoteNumberIsNull(offerRecord);
        } else {
            listOffer = oppSelector.findOppWhenInfoQuoteNumberIsNOTNull(offerRecord);
        }

        for (Opportunity offerQuery : listOffer) {
            //3.1. Se debe finalizar el proceso si es alguno de los escenarios de integración 2 o 3 y existe una Oferta cerrada con el mismo QuoteNumber de INFO, o si es el escenario de integración 1 y existe una Oferta ya registrada para la misma Sesión del Asistente.
            if ((offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c && (offerQuery.StageName == 'Cerrada-Ganada' || offerQuery.StageName == 'Cerrada-Perdida'))  || (offerRecord.InfoQuoteNumber__c == null && offerQuery.SessionId__c == offerRecord.SessionId__c)) {
                offerToInsertUpdate = null;
                break;
            } else if (offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c) {
                offerToInsertUpdate.Id = offerQuery.Id;
            } else if (offerToInsertUpdate.Id == null && offerQuery.InfoQuoteNumber__c == null) {
                offerToInsertUpdate.Id = offerQuery.Id;
            }
        }

        if (offerToInsertUpdate != null && offerToInsertUpdate.Id == null) {
            insert offerToInsertUpdate;
        } else if (offerToInsertUpdate != null && offerToInsertUpdate.Id != null) {
            update offerToInsertUpdate;
        }

        if (policyRecord != null && offerToInsertUpdate != null) {
            Policy__c policyToInsert = policyRecord;
            AccountsSelector accSelector = new AccountsSelector();
            List<Account> listAcc = accSelector.findByINFOIntermediaryCode(new List<String>{(String)offerToInsertUpdate.IntermediaryCode__c});
            policyToInsert.OpportunityName__c = offerToInsertUpdate.Id;
            policyToInsert.InfoQuoteNumber__c = offerToInsertUpdate.InfoQuoteNumber__c;
            if (listAcc.size() > 0) {
                policyToInsert.IntermediaryId__c = listAcc.get(0).Id;
            }
            policyToInsert.Intermediary_Code__c = offerToInsertUpdate.IntermediaryCode__c; 
            insert policyToInsert;
        }
    }
}