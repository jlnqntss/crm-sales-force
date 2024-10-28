/**
 * @description       : Batch que borra los Leads más antiguos en base a una serie de criterios
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 25/04/2024
 * @last modified by  : rserrano
**/
global with sharing class Batch_DeleteOldLeads implements Database.Batchable<sObject>, Schedulable {
    
    private static final String CLASS_NAME = 'Batch_DeleteOldLeads';
    @TestVisible 
    private static final Integer DAYS = 90;
    @TestVisible
    private static final String OFFER_STATUS_LEGIT_LEAD = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Stage_Name_Legit_Lead');
    private static final String OFFER_SCOPE_VENTAS = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Scope_Ventas');

    public Batch_DeleteOldLeads() 
    {

    }

    //#region Batch Methods

    /**
    * @description          : Método start del batch, devuelve la lista de Leads que se borran en el execute 
    * @author rserrano | 09/04/2024 
    * @param bc             : Batch context
    * @return List<Account> : Lista de Leads que se borrarán
    **/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(new OpportunitiesSelector().getVentasOpportunitiesWithLeads(DAYS, OFFER_STATUS_LEGIT_LEAD, OFFER_SCOPE_VENTAS));        
    }

    /**
    * @description : Método execute del batch, selecciona aquellas cuentas que tienen solo una oportunidad y las borra
    * @author rserrano | 09/04/2024 dmunoz 24/10/2024
    * @param bc    : Batch context
    * @param scope : Lista de Leads procedentes del método start
    **/
    global void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        try {
            // de las ofertas recuperadas obtenemos información de los leads como el resto de sus ofertas y si tuvieran un caso
            List<Account> leadList = getLeadsInformation(scope);

            // Obtenemos la lista de los leads que cumplen los requisitos para borrarse
            List<Account> leadsToDeleteList = getLeadsToDelete(leadList);

            // eliminamos la lista de elementos recuperados en scope
            deleteOffers(scope);
    
            // De los leads que vamos a borrar, eliminamos sus registros de competencia
            deleteCompetitorsRecords(leadsToDeleteList);
    
            // Finalmente eliminamos los registros de leads
            deleteLeads(leadsToDeleteList);

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_DeleteOldLeads(), 1000);               
    }

    global void finish(Database.BatchableContext bc)
    {
        // do nothing
    }

    // #endregion

    // #region Metodos Lead A Borrar

    /**
    * @description : Metodo que recupera los leads de la lista de oportunidades y obtiene 
    * todas las ofertas relacionadas (Excepto las ofertas obtenidas en scope ya que esas se van a borrar) y sus casos (limit 1)
    * @author dmunoz | 24/10/2024 
    * @param scope : Lista de Oportunidades procedentes del método start
    **/
    private List<Account> getLeadsInformation(List<Opportunity> scope) {
        List<Account> result = new List<Account>();
        List<Id> leadsIdsToQuery = new List<Id>();

        // Obtengo la lista de ids de leads de las ofertas para recuperar a continuación sus otras ofertas
        for (Opportunity opportunityScope: scope) {
            leadsIdsToQuery.add(opportunityScope.AccountId);
        }

        result = new AccountsSelector().findLeadsWithOpportunitiesAndCaseFiltered(leadsIdsToQuery, scope);
        
        return result;
    }

    /**
    * @description : Metodo contiene la lógica para seleccionar aquellas cuentas de leads que se han de borrar, para ello se toman los siguientes criterios:
    * 1º Si una cuenta lead tiene algún caso debido a la restricción estándar de salesforce no podemos permitir borrar dichos leads
    * 2º Si un lead solo tiene ofertas de ventas/zrm y todas tienen fecha de creación más antigua que la variable "DAYS" (90 dias) se puede eliminar el lead
    * 3º Si un lead tiene alguna oferta que no sea de zrm NO se podrá eliminar 
    * todas las ofertas relacionadas (Excepto las ofertas obtenidas en scope ya que esas se van a borrar) y sus casos (limit 1)
    * @author dmunoz | 24/10/2024 
    * @param leadList : Lista de Leads con ofertas y un caso (si tuviera) procedentes de las ofertas del método start
    * @param scope : Lista de Oportunidades procedentes del método start
    **/
    private List<Account> getLeadsToDelete(List<Account> leadList) {

        List<Account> result = new List<Account>();

        // recorremos la lista de leads obtenida
        for (Account lead: leadList) {
            // consultamos si tiene algun caso y pasamos al siguiente
            if (lead.Cases.size() > 0) {
                break;

                // si el lead no tiene ninguna otra oportunidad (recordando que se filtran las del scope porque se van a eliminar)
            } else if (lead.Opportunities.size() == 0) {
                result.add(lead);

            // en caso que el lead si tenga otras oportunidades comprobamos que no tenga otra oportunidad que no sea de zrm
            } else if (lead.Opportunities.size() > 0) {
                result = checkLeadOpportunity(lead, result);
            }
        }
        
        return result;
    }

    /**
    * @description : Recorremos el resto de ofertas que tiene el lead y si todas son de Ventas/ZRM lo marcamos para borrar
    * todas las ofertas relacionadas (Excepto las ofertas obtenidas en scope ya que esas se van a borrar) y sus casos (limit 1)
    * @author dmunoz | 24/10/2024 
    * @param scope : Lista de Oportunidades procedentes del método start
    **/
    private List<Account> checkLeadOpportunity(Account lead, List<Account> result) {

        Boolean decision = true;

        // Recorro las ofertas del lead, de nuevo con la excepción de las ofertas de scope que se van a eliminar
        for (Opportunity leadOpportunity: lead.Opportunities) {
                    
            // Verificamos que las demás ofertas del lead sean de ze, ni estén alguna en legit lead o haya otra oferta de zrm menos a 90 dias de creación. En caso contrario eliminamos el lead
            if (isZRMOffer(leadOpportunity) || isZEOffer(leadOpportunity) || isNotLegitLead(leadOpportunity)) {
                decision = false; // Si alguna oferta no cumple las condiciones, no se puede borrar
                break;            
            }
        }

        if (decision) {
            result.add(lead);
        }

        return result;
    }


    /**
    * @description : compruebo si la oferta de zrm permite eliminar el lead
    * @author dmunoz | 24/10/2024 
    * @param leadOpportunity : oferta a comprobar
    **/
    private Boolean isZRMOffer(Opportunity leadOpportunity) {
        return (OFFER_SCOPE_VENTAS.equals(leadOpportunity.Scope__c) || String.isBlank(leadOpportunity.BusinessCode__c)) &&
                leadOpportunity.createdDate > (Date.today() - DAYS);
    }

    /**
    * @description : compruebo si la oferta es de ze -> no eliminar el lead
    * @author dmunoz | 24/10/2024 
    * @param leadOpportunity : oferta a comprobar
    **/
    private Boolean isZEOffer(Opportunity leadOpportunity) {
        return !OFFER_SCOPE_VENTAS.equals(leadOpportunity.Scope__c) && String.isNotBlank(leadOpportunity.BusinessCode__c);
    }

    /**
    * @description : compruebo si la oferta está en etapa distinta a legit lead -> no eliminar el lead
    * @author dmunoz | 24/10/2024 
    * @param leadOpportunity : oferta a comprobar
    **/
    private Boolean isNotLegitLead(Opportunity leadOpportunity) {
        return !OFFER_STATUS_LEGIT_LEAD.equals(leadOpportunity.StageName);
    }


    /**
     * Elimina los registros que no dan error de leads
     *
     * @author dmunoz
     * @date 22/10/2024
     * @param  leadsToDelete   Lista de cuentas las cuales se van a eliminar sus registros de competencia
     *
     */
    private void deleteLeads(List<Account> leadsToDelete)
    {   
        if (!leadsToDelete.isEmpty()) {
            delete leadsToDelete;
        }     
    }

    // #endregion
    
    // #region Metodos Borrado Oferta

    /**
     * Elimina los registros recuperados en el metodo start
     *
     * @author dmunoz
     * @date 24/10/2024
     * @param  leadsToDelete   Lista de cuentas las cuales se van a eliminar sus registros de competencia
     *
     */
    private void deleteOffers(List<Opportunity> scope) {
        if (!scope.isEmpty()) {
            delete scope;
        }
    }

    // #endregion

    // #region Metodos Competencias

    /**
     * Obtiene la lista de competencias y las elimina
     *
     * @author dmunoz
     * @date 22/10/2024
     * @param  leadsToDelete   Lista de cuentas las cuales se van a eliminar sus registros de competencia
     *
     */
    private void deleteCompetitorsRecords(List<Account> leadsToDelete)
    {   
        // Obtengo la lista de ids de leads
        List<String> leadsIds = new List<String>();

        for(Account acc : leadsToDelete)
        {
            leadsIds.add(acc.Id);
        }

        // Obtener los registros de competencia relacionados
        List<Competitor__c> leadsCompetitorsList = (new CompetitorsSelector()).getCompetitorsRelatedWithAccauntIds(leadsIds);
        
        if (!leadsCompetitorsList.isEmpty()) {
            delete leadsCompetitorsList;        
        }        
    }   

    // #endregion
}