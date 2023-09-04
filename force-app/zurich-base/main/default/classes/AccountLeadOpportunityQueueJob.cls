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
    * Método TODO: finalizar descripción
    * *
    * @author overes | 08-31-2023
    * @param accountRecord
    * @param offerRecord
    * @param policyRecord
    * @param postalCode
    **/
    public static void processOpportunityAndPolicy(Account accountRecord, Opportunity offerRecord, Policy__c policyRecord, String postalCode) {
        List<Opportunity> listOffer = new List<Opportunity>();
        // TODO: 1. Inicializa las variables auxiliares   --->> offerToInsertUpdate = offerRecord -------------> ¿qué variables se espera inicializar?
        Opportunity offerToInsertUpdate = new Opportunity();

        //FIXME: 2. Construye una query sobre Opportunity para obtener registros duplicados de la Oferta a procesar

        //FIXME: 2.1. Si offerRecord.InfoQuoteNumber__c == null:
        if (offerRecord.InfoQuoteNumber__c == null) {
            listOffer = [SELECT Id, SessionId__c, InfoQuoteNumber__c, StageName FROM Opportunity

            WHERE SessionId__c = :offerRecord.SessionId__c

            OR (AccountId = :offerRecord.InfoQuoteNumber__c AND CarRegistration__c = :offerRecord.CarRegistration__c AND PersonLeadSource__c = :offerRecord.PersonLeadSource__c)

            ORDER BY CreatedDate DESC];
        } else {
            listOffer = [SELECT Id, SessionId__c, InfoQuoteNumber__c, StageName FROM Opportunity

            WHERE SessionId__c = :offerRecord.SessionId__c

            OR InfoQuoteNumber__c = :offerRecord.InfoQuoteNumber__c

            OR (AccountId = :offerRecord.InfoQuoteNumber__c AND CarRegistration__c = :offerRecord.CarRegistration__c AND PersonLeadSource__c = :offerRecord.PersonLeadSource__c)

            ORDER BY CreatedDate DESC];
        }

        // FIXME: 3. Ejecuta la query obtenida en el paso anterior y recorre los registros obtenidos, y para cada uno offerQuery
        for (Opportunity offerQuery : listOffer) {
            //3.1. Se debe finalizar el proceso si es alguno de los escenarios de integración 2 o 3 y existe una Oferta cerrada con el mismo QuoteNumber de INFO, o si es el escenario de integración 1 y existe una Oferta ya registrada para la misma Sesión del Asistente.
            //TODO: minimizar la cantidad de condiciones
            if ((offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c && (offerQuery.StageName == 'Cerrada-Ganada' || offerQuery.StageName == 'Cerrada-Perdida'))  || (offerRecord.InfoQuoteNumber__c == null && offerQuery.SessionId__c == offerRecord.SessionId__c)) {
                offerToInsertUpdate = null;
                break;
            //3.2. Se debe actualizar la Oferta offerQuery si es alguno de los escenarios de integración 2 o 3 y existe una Oferta abierta con el mismo QuoteNumber de INFO.
            } else if (offerRecord.InfoQuoteNumber__c != null && offerQuery.InfoQuoteNumber__c == offerRecord.InfoQuoteNumber__c) {
                offerToInsertUpdate.Id = offerQuery.Id;
            //3.3. Se debe actualizar la Oferta offerQuery si no se cumple la condición anterior pero sí existe una Oferta abierta sin QuoteNumber de INFO para la misma Cuenta, Matrícula y Origen.
            } else if (offerToInsertUpdate.Id == null && offerQuery.InfoQuoteNumber__c == null) {
                offerToInsertUpdate.Id = offerQuery.Id;
            }
        }

        //FIXME: 5. Si offerToInsertUpdate != null && offerToInsertUpdate.Id == null: insertar registro offerToInsertUpdate

        // FIXME: 6. Si offerToInsertUpdate != null && offerToInsertUpdate.Id != null: actualizar registro offerToInsertUpdate

        // FIXME: 7. Si policyRecord != null: insertar registro policyRecord con las siguientes asignaciones previas
        if (policyRecord != null) {
            policyRecord.OpportunityName__c= offerToInsertUpdate.Id;
            policyRecord.InfoQuoteNumber__c = offerToInsertUpdate.InfoQuoteNumber__c;
            // pol.IntermediaryId__c = [SELECT Id FROM Account WHERE INFOIntermediaryCode__c = :offerToInsertUpdate.IntermediaryCode__c];
            // pol.Intermediary_Code__c = offerToInsertUpdate.IntermediaryCode__c; 


        }

    }

}