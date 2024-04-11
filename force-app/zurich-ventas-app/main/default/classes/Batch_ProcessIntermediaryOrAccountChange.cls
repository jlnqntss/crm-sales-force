/**
 Proceso recursivo que calcula para cada cabio de mediador o cliente los atms a borrar e insertar para los usuarios que tienen visibilidad
 * 
 * @author dmunoz
 * @date 04/04/2024
 **/

global with sharing class Batch_ProcessIntermediaryOrAccountChange implements Database.Batchable<sObject>, Database.Stateful {

    private static final String CLASS_NAME = 'Batch_ProcessIntermediaryOrAccountChange';

    private static final String EXISTE_CLIENTE_EN_MEDIADOR = 'Existe cliente en mediador';
    private static final String EXISTE_CLIENTE_EN_AGRUPACION = 'Existe cliente en agrupacion';
    
    private List<sObject> recordsToProcess;
    private List<AccountTeamMember> atmsToDelete;
    private List<AccountTeamMember> atmsToInsert;
    private Integer numDMLs = 5000;
    private Boolean stopRecordProcess;
    
    public Batch_ProcessIntermediaryOrAccountChange(List<sObject> recordsToProcess, Integer numDMLs) { 
        this.recordsToProcess = recordsToProcess;
        this.atmsToDelete = new List<AccountTeamMember>();
        this.atmsToInsert = new List<AccountTeamMember>();
        this.numDMLs = numDMLs;
        this.stopRecordProcess = false;  
    }

    //#region Métodos Batch 
    /**
     * Obtenemos la información de pólizas y ofertas que han cambiado de tomador o mediador en las últimas 24 horas y no se han reprocesado más de 3 veces
     * @author dmunoz
     * @date 04/04/2024
     */
    public List<sObject> start(Database.BatchableContext bc) {

        if (!recordsToProcess.isEmpty()) {
            return recordsToProcess;
        } else {
            return new List<sObject>();
        }
    
    }

    /**
     * Este proceso solo se encarga de iniciar el proceso por lo que el método execute está vacío para enviar la información y calcularlo de manera individual de forma controlada
     * @author dmunoz
     * @date 04/04/2024
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {

            ZRMEnum.ZRMMovementType movementType = getRecordMovement(scope);

            switch on movementType {
                when OFFER_INTERMEDIARY_CHANGE {
                    processOfferIntermediaryChange(scope);

                } when OFFER_ACCOUNT_CHANGE {
                    processOfferAccountChange(scope);

                } when POLICY_INTERMEDIARY_CHANGE {
                    processPolicyIntermediaryChange(scope);

                } when POLICY_ACCOUNT_CHANGE {
                    processPolicyAccountChange(scope);

                } when else { // toma el valor de error en caso que el tipo de movimiento no se haya identificado correctamente
                    throw new HandledException(CLASS_NAME + ' El tipo de movimiento no se ha podido determinar para el registro ' + scope.get(0).Id);                    
                }
            }
            
        } catch (Exception e) {
            // Si hay error actualizamos el registro para que se procese al día siguiente y eliminamos ese registro de la cola del procesamiento
            stopRecordProcess = true;
            Batch_IntermediaryOrAccountChangeUtil.updateRecordWithProcessKO(recordsToProcess, CLASS_NAME);
            recordsToProcess.remove(0); // elimino de la lista el elemento que ha fallado para que se pueda seguir con el siguiente si hay
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }


    global void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            processDMLs();
        }
    }


    //#regionMétodos Auxiliares Batch

    /**
     * Método que identifica el tipo de movimiento que se ha producido en el registro a calcular su visibilidad
     * @author dmunoz
     * @date 04/04/2024
     */
    private ZRMEnum.ZRMMovementType getRecordMovement(List<sObject> scope) {

        ZRMEnum.ZRMMovementType result = ZRMEnum.ZRMMovementType.ERROR;

        if (scope != null && !scope.isEmpty()) {
            sObject record = scope.get(0);
    
            Schema.SObjectType offerObject = Schema.Opportunity.getSObjectType();
            Schema.SObjectType policyObject = Schema.Policy__c.getSObjectType();
            Schema.SObjectType recordObject = record.getsobjecttype();
    
            if (offerObject == recordObject) { // oferta
                if (Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR.equals(String.valueOf(record.get(Schema.Opportunity.ZRMMovementType__c)))) { // cambio mediador
                    result = ZRMEnum.ZRMMovementType.OFFER_INTERMEDIARY_CHANGE; 
             
                } else if (Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE.equals(String.valueOf(record.get(Schema.Opportunity.ZRMMovementType__c)))) { // cambio cliente
                    result = ZRMEnum.ZRMMovementType.OFFER_ACCOUNT_CHANGE;    
                }

            } else if (policyObject == recordObject) { // poliza
                if (Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR.equals(String.valueOf(record.get(Schema.Policy__c.ZRMMovementType__c)))) { // cambio mediador
                    result = ZRMEnum.ZRMMovementType.POLICY_INTERMEDIARY_CHANGE;
             
                } else if (Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE.equals(String.valueOf(record.get(Schema.Policy__c.ZRMMovementType__c)))) { // cambio cliente
                    result = ZRMEnum.ZRMMovementType.POLICY_ACCOUNT_CHANGE;    
                }
            } 
        } 
        return result;
    }

    /**
     * Método que una vez calculados los registros a borrar y a insertar de atm llama al proceso batch de dmls
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processDMLs() {
        
        // si al terminar la ejecución del registro no hay ningun elemento a borrar o insertar, pasamos al siguiente si hubiera
        if (!stopRecordProcess && atmsToDelete != null && atmsToDelete.isEmpty() && atmsToInsert != null && atmsToInsert.isEmpty() && !recordsToProcess.isEmpty()) {
            Batch_IntermediaryOrAccountChangeUtil.updateRecordWithProcessOK(recordsToProcess, CLASS_NAME);
            recordsToProcess.remove(0);
        }

        // si no hay error y hay elementos a hacer dml invoco al ultimo flujo
        if (!stopRecordProcess && ((atmsToDelete != null && !atmsToDelete.isEmpty()) || (atmsToInsert != null && !atmsToInsert.isEmpty()))) {
            Database.executeBatch(new Batch_IntermediaryOrAccountChangeDMLs(recordsToProcess, atmsToDelete, atmsToInsert, numDMLs), numDMLs);
        } else if (!recordsToProcess.isEmpty()) {
            Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(recordsToProcess, numDMLs), numDMLs);
        } 
    }



    //#region Cambio mediador oferta

    /**
     * Método que realiza los cálculos cuando una oferta cambia de mediador
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processOfferIntermediaryChange(List<sObject> scope) {
        if (scope != null && !scope.isEmpty())  {
            Opportunity opportunity = (Opportunity) scope.get(0);

            // 1º Calcular para el mediador antiguo si tengo que eliminar los atms de sus usuarios nominales y los AGR de la agrupación (si tuviera)
            atmsToDelete = getOfferIntermediaryChangeAtMsToDelete(opportunity);

            // 2º Generar los atms a insertar para los usuarios del nuevo mediador y los usuarios AGR de la agrupación (si tuviera)
            atmsToInsert = getATMsToInsert(opportunity.AccountId, opportunity.IntermediaryId__c);
        }
    }

    /**
     * Método que obtiene los atms a borrar (si procede) del mediador saliente para el cliente de la oportunidad
     * @author dmunoz
     * @date 04/04/2024
     */
    private List<AccountTeamMember> getOfferIntermediaryChangeAtMsToDelete(Opportunity opportunity) {

        AccountsSelector accountSelector = new AccountsSelector();

        // 1º Obtengo el mediador antiguo de la oportunidad y su agrupación (si tuviera)
        List<Account> intermediaryOldList = accountSelector.findIntermediaryGroupByIntermediaries(new Set<String> {opportunity.LastAccountId__c});

        if (intermediaryOldList != null && !intermediaryOldList.isEmpty()) {
            // 2º Recupero alguna otra oferta/póliza para dicho cliente y mediador saliente (si hay resultado no hacer nada más). Devuelve un mapa con dos claves: 'Existe cliente en mediador' y 'Existe cliente en agrupacion'
            Map<String, Boolean> oldIntermediaryHasOtherAccountPoliciesOrOffersMap = intermediaryHasOtherAccountPoliciesOrOffers(opportunity.AccountId, intermediaryOldList, opportunity.Id);    

            // 3º Compruebo los dos flags y recupero los usuarios agr y/o nominales a los que borraremos los atm para el cliente de la oferta
            List<User> usersToDeleteATM = getUsersToDeleteATM(intermediaryOldList.get(0), oldIntermediaryHasOtherAccountPoliciesOrOffersMap);
            // 4º Obtener los atms para la lista de usuarios y cliente
            atmsToDelete = (new AccountTeamMemberSelector()).getZRMATMByAccountAndUser(new Set<String>{opportunity.AccountId}, usersToDeleteATM);    
        }

        return atmsToDelete;
    }

   


    //#region Cambio cliente oferta
    /**
     * Método que realiza los cálculos cuando una oferta cambia de cliente
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processOfferAccountChange(List<sObject> scope) {
        if (scope != null && !scope.isEmpty()) {
            Opportunity opportunity = (Opportunity) scope.get(0);
                
            // 3º Busco atms para borrar
            atmsToDelete =  getOfferAccountChangeAtMsToDelete(opportunity);

            // 2º Generar los atms a insertar para los usuarios del nuevo mediador y los usuarios AGR de la agrupación (si tuviera)
            atmsToInsert = getATMsToInsert(opportunity.AccountId, opportunity.IntermediaryId__c);
        }
    }


    /**
     * Método que obtiene los atms a borrar (si procede) del mediador saliente para el cliente de la oportunidad
     * @author dmunoz
     * @date 04/04/2024
     */
    private List<AccountTeamMember> getOfferAccountChangeAtMsToDelete(Opportunity opportunity) {
        AccountsSelector accountSelector = new AccountsSelector();

        // 1º Obtengo el mediador antiguo de la oportunidad y su agrupación (si tuviera)
        List<Account> intermediaryList = accountSelector.findIntermediaryGroupByIntermediaries(new Set<String> {opportunity.IntermediaryId__c});

        if (intermediaryList != null && !intermediaryList.isEmpty()) {
            // 2º Recupero alguna otra oferta/póliza para dicho cliente y mediador saliente (si hay resultado no hacer nada más). Devuelve un mapa con dos claves: 'Existe cliente en mediador' y 'Existe cliente en agrupacion'
            Map<String, Boolean> oldIntermediaryHasOtherAccountPoliciesOrOffersMap = intermediaryHasOtherAccountPoliciesOrOffers(opportunity.LastAccountId__c, intermediaryList, opportunity.Id);    

            // 3º Compruebo los dos flags y recupero los usuarios agr y/o nominales a los que borraremos los atm para el cliente de la oferta
            List<User> usersToDeleteATM = getUsersToDeleteATM(intermediaryList.get(0), oldIntermediaryHasOtherAccountPoliciesOrOffersMap);
            // 4º Obtener los atms para la lista de usuarios y cliente
            atmsToDelete = (new AccountTeamMemberSelector()).getZRMATMByAccountAndUser(new Set<String>{opportunity.LastAccountId__c}, usersToDeleteATM);    
        }

        return atmsToDelete;        
    }


    //#region Cambio mediador poliza
    /**
     * Método que realiza los cálculos cuando una poliza cambia de mediador
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processPolicyIntermediaryChange(List<sObject> scope) {
        if (scope != null && !scope.isEmpty())  {
            Policy__c policy = (Policy__c) scope.get(0);

            // 1º Calcular para el mediador antiguo si tengo que eliminar los atms de sus usuarios nominales y los AGR de la agrupación (si tuviera)
            atmsToDelete = getPolicyIntermediaryChangeAtMsToDelete(policy);

            // 2º Generar los atms a insertar para los usuarios del nuevo mediador y los usuarios AGR de la agrupación (si tuviera)
            atmsToInsert = getATMsToInsert(policy.PolicyHolder__c, policy.IntermediaryId__c);
        }
    }


    /**
     * Método que obtiene los atms a borrar (si procede) del mediador saliente para el cliente de la oportunidad
     * @author dmunoz
     * @date 04/04/2024
     */
    private List<AccountTeamMember> getPolicyIntermediaryChangeAtMsToDelete(Policy__c policy) {

        AccountsSelector accountSelector = new AccountsSelector();

        // 1º Obtengo el mediador antiguo de la oportunidad y su agrupación (si tuviera)
        List<Account> intermediaryOldList = accountSelector.findIntermediaryGroupByIntermediaries(new Set<String> {policy.LastAccountId__c});

        if (intermediaryOldList != null && !intermediaryOldList.isEmpty()) {
            // 2º Recupero alguna otra oferta/póliza para dicho cliente y mediador saliente (si hay resultado no hacer nada más). Devuelve un mapa con dos claves: 'Existe cliente en mediador' y 'Existe cliente en agrupacion'
            Map<String, Boolean> oldIntermediaryHasOtherAccountPoliciesOrOffersMap = intermediaryHasOtherAccountPoliciesOrOffers(policy.PolicyHolder__c, intermediaryOldList, policy.Id);    

            // 3º Compruebo los dos flags y recupero los usuarios agr y/o nominales a los que borraremos los atm para el cliente de la oferta
            List<User> usersToDeleteATM = getUsersToDeleteATM(intermediaryOldList.get(0), oldIntermediaryHasOtherAccountPoliciesOrOffersMap);
            // 4º Obtener los atms para la lista de usuarios y cliente
            atmsToDelete = (new AccountTeamMemberSelector()).getZRMATMByAccountAndUser(new Set<String>{policy.PolicyHolder__c}, usersToDeleteATM);    
        }

        return atmsToDelete;
    }


    //#region Cambio cliente poliza
    /**
     * Método que realiza los cálculos cuando una poliza cambia de mediador
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processPolicyAccountChange(List<sObject> scope) {
        if (scope != null && !scope.isEmpty()) {
            Policy__c policy = (Policy__c) scope.get(0);

            // 1º Calcular para el mediador antiguo si tengo que eliminar los atms de sus usuarios nominales y los AGR de la agrupación (si tuviera)
            atmsToDelete = getPolicyAccountChangeAtMsToDelete(policy);

            // 2º Generar los atms a insertar para los usuarios del nuevo mediador y los usuarios AGR de la agrupación (si tuviera)
            atmsToInsert = getATMsToInsert(policy.PolicyHolder__c, policy.IntermediaryId__c);
        }
    }


    /**
     * Método que obtiene los atms a borrar (si procede) del mediador saliente para el cliente de la oportunidad
     * @author dmunoz
     * @date 04/04/2024
     */
    private List<AccountTeamMember> getPolicyAccountChangeAtMsToDelete(Policy__c policy) {
        AccountsSelector accountSelector = new AccountsSelector();

        // 1º Obtengo el mediador antiguo de la oportunidad y su agrupación (si tuviera)
        List<Account> intermediaryList = accountSelector.findIntermediaryGroupByIntermediaries(new Set<String> {policy.IntermediaryId__c});

        if (intermediaryList != null && !intermediaryList.isEmpty()) {
            // 2º Recupero alguna otra oferta/póliza para dicho cliente y mediador saliente (si hay resultado no hacer nada más). Devuelve un mapa con dos claves: 'Existe cliente en mediador' y 'Existe cliente en agrupacion'
            Map<String, Boolean> oldIntermediaryHasOtherAccountPoliciesOrOffersMap = intermediaryHasOtherAccountPoliciesOrOffers(policy.LastAccountId__c, intermediaryList, policy.Id);    

            // 3º Compruebo los dos flags y recupero los usuarios agr y/o nominales a los que borraremos los atm para el cliente de la oferta
            List<User> usersToDeleteATM = getUsersToDeleteATM(intermediaryList.get(0), oldIntermediaryHasOtherAccountPoliciesOrOffersMap);
            // 4º Obtener los atms para la lista de usuarios y cliente
            atmsToDelete = (new AccountTeamMemberSelector()).getZRMATMByAccountAndUser(new Set<String>{policy.LastAccountId__c}, usersToDeleteATM);    
        }

        return atmsToDelete;        
    }


    //#region Métodos comunes

     /**
     * Método que comprueba si para un cliente y un mediador tiene póliza u oferta sin contar el registro que se está procesando
     * Devuelve un mapa con dos claves: 'Existe cliente en mediador' y 'Existe cliente en agrupacion'
     * @author dmunoz
     * @date 04/04/2024
     */
    private Map<String, Boolean> intermediaryHasOtherAccountPoliciesOrOffers(String accountId, List<Account> intermediaryList, String idNotToSearch) {
        Map<String, Boolean> result = new Map<String, Boolean>();    

        List<Policy__c> policiesQuery = new List<Policy__c>();
        List<Opportunity> opportunityQuery = new List<Opportunity>();
        Account intermediary = intermediaryList.get(0);

        
        // Genero la lista de id de agrupacion cuando el mediador tiene el campo informado
        Set<String> intermediaryGroupIdSet = new Set<String>();
        if (intermediary.IntermediaryGroup__c != null && String.isNotEmpty(intermediary.IntermediaryGroup__c)) {
            intermediaryGroupIdSet.add(intermediary.IntermediaryGroup__c);
        }

        // Obtengo las polizas que apuntan a al cliente
        policiesQuery = (new PoliciesSelector()).selectByIntermediaryAndIntermediaryGroupExcludingPolicies(new Set<String>{intermediary.Id}, intermediaryGroupIdSet, new Set<String>{accountId}, new Set<String> {idNotToSearch});
        
        // si no encuentra resultado busco en ofertas
        if (policiesQuery != null && policiesQuery.isEmpty()) {
            opportunityQuery = (new OpportunitiesSelector()).selectByIntermediaryAndIntermediaryGroupExcludingOffers(new Set<String>{intermediary.Id}, intermediaryGroupIdSet, new Set<String>{accountId}, new Set<String> {idNotToSearch});
        }        

        // informo el resultado del mapa
        result = intermediaryHasClientVisibility(result, policiesQuery, opportunityQuery, intermediary.Id);
        result = intermediaryGroupHasClientVisibility(result, policiesQuery, opportunityQuery, intermediary.IntermediaryGroup__c);        

        return result;
    }

    /**
     * Método que comprueba si existe alguna poliza u oferta para el cliente y mediador encontradas. Ya que busco todas las del cliente y mediador compruebo que exista al menos 1 
     * @author dmunoz
     * @date 04/04/2024
     */
    private Map<String, Boolean> intermediaryHasClientVisibility(Map<String, Boolean> result, List<Policy__c> policiesQuery, List<Opportunity> opportunityQuery, String intermediaryId) {

        Boolean intermediaryHasClient = false; // indica si en mediador sigue teniendo visibilidad para ese cliente

        // recorro cada poliza para ver si el mediador seguirá con acceso a dicho cliente
        for (Policy__c policy: policiesQuery) {
            if (intermediaryId != null && intermediaryId.equals(policy.IntermediaryId__c)) {
                intermediaryHasClient = true;
                break;
            }
        }

        // si no he encontrado 
        if (intermediaryHasClient == false) {
            for (Opportunity offer: opportunityQuery) {
                if (intermediaryId != null && intermediaryId.equals(offer.IntermediaryId__c)) {
                    intermediaryHasClient = true;
                    break;
                }
            } 
        }

        result.put(EXISTE_CLIENTE_EN_MEDIADOR, intermediaryHasClient);

        return result;
    }


    /**
     * Método que comprueba si existe alguna poliza u oferta para el cliente y mediador encontradas
     * @author dmunoz
     * @date 04/04/2024
     */
    private Map<String, Boolean> intermediaryGroupHasClientVisibility(Map<String, Boolean> result, List<Policy__c> policiesQuery, List<Opportunity> opportunityQuery, String intermediaryGroupId) {

        Boolean intermediaryGroupHasClient = false; // Indica si la agrupación sigue teniendo visibilidad para ese cliente (Usuarios AGR)

        // recorro cada poliza para ver si la agrupacion seguirá con acceso a dicho cliente. Solo usuarios AGR
        for (Policy__c policy: policiesQuery) {
            if (intermediaryGroupId != null && intermediaryGroupId.equals(policy.IntermediaryId__r.IntermediaryGroup__c)) {
                intermediaryGroupHasClient = true;
                break;
            }
        }

        // si no he encontrado 
        if (intermediaryGroupHasClient == false) {
            for (Opportunity offer: opportunityQuery) {
                if (intermediaryGroupId != null && intermediaryGroupId.equals(offer.IntermediaryId__r.IntermediaryGroup__c)) {
                    intermediaryGroupHasClient = true;
                    break;
                }
            } 
        }

        result.put(EXISTE_CLIENTE_EN_AGRUPACION, intermediaryGroupHasClient);

        return result;
    }


    /**
     * Método que devuelve la lista de usuarios a los que borraremos ATM
     * @author dmunoz
     * @date 04/04/2024
     */
    private List<User> getUsersToDeleteATM(Account intermediary, Map<String, Boolean> oldIntermediaryHasOtherAccountPoliciesOrOffersMap) {

        List<User> result = new List<User>();
        UsersSelector selector = new UsersSelector();

        // Genero la lista de id de agrupacion cuando el mediador tiene el campo informado
        Set<String> intermediaryGroupIdSet = new Set<String>();
        if (intermediary.IntermediaryGroup__c != null && String.isNotEmpty(intermediary.IntermediaryGroup__c)) {
            intermediaryGroupIdSet.add(intermediary.IntermediaryGroup__c);
        }
        
        List<User> usersQuery = selector.findZRMActiveUsersFromIntermediaryAndAGRFromGroup(new Set<String>{intermediary.Id}, new List<String>(intermediaryGroupIdSet)); 
        
        // recorro los usuarios, para los nominales veo si el mediador no tiene más visibilidad lo añado a la lista para borrar su atm con el cliente del registro que está procesando
        for (User user: usersQuery) {

            if (ProfilesSelector.PROFILE_AGENTE_VENTAS.equals(user.Profile.Name) && oldIntermediaryHasOtherAccountPoliciesOrOffersMap.get(EXISTE_CLIENTE_EN_MEDIADOR) == false) {
                result.add(user);
            } else if (ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR.equals(user.Profile.Name) && oldIntermediaryHasOtherAccountPoliciesOrOffersMap.get(EXISTE_CLIENTE_EN_AGRUPACION) == false) {
                result.add(user);
            }            
        }

        return result;
    }

    private List<AccountTeamMember> getATMsToInsert(String accountId, String intermediaryId) {

        List<Account> intermediaryAccList = (new AccountsSelector()).findIntermediaryGroupByIntermediaries(new Set<String> {intermediaryId});

        if (intermediaryAccList.isEmpty())
        {
            return atmsToInsert; // devuelve la lista vacia inicializada en el constructor
        }

        Account intermediary = intermediaryAccList[0];

        Set<String> intermediaryGroupIdSet = new Set<String>();
        List<String> intermediaryGroupIdList = new List<String>();

        if (intermediary.IntermediaryGroup__c != null && String.isNotEmpty(intermediary.IntermediaryGroup__c)) {
            intermediaryGroupIdSet.add(intermediary.IntermediaryGroup__c);
        }

        intermediaryGroupIdList.addAll(intermediaryGroupIdSet);


        // 1. Obtenemos los usuarios del mediador y los agr si hubiera
        List<User> userList = (new UsersSelector()).findZRMActiveUsersFromIntermediaryAndAGRFromGroup(new Set<String>{intermediary.Id}, intermediaryGroupIdList);

        // 2. Generamos los atms a insertar
        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
        atmsToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(accountId, userList));

        return atmsToInsert;
    }
}