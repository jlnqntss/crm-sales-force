/**
 * Batch recursivo que se encarga de realizar todos los dmls calculados en Batch_RecalcVisibilityIntermediary. Tenemos un numero máximo de dmls a realizar por parámetro. 
 * En caso que haya más operaciones que el límite se llamará a si mismo hasta completar todos los dmls para dicho mediador. 
 * 
 * @author nts (dmunoz)
 * @date 18/03/2024
 *
 */
global with sharing class Batch_RecalcVisibilityIntermediaryDMLs implements Database.Batchable<sObject> {

    private static final String CLASS_NAME = 'Batch_RecalcVisibilityIntermediaryDMLs';

    private List<Account> intermediariesToProcess;
    private List<AccountTeamMember> atmsToDML; // dml para los primeros 5k operaciones
    private List<AccountTeamMember> atmsToDelete;
    private List<AccountTeamMember> atmsToInsert;
    private Set<String> intermediaryAccountIdsSet; // clientes del mediador que se está procesando
    private Integer numDMLs = 5000; 
    private String batchType;
    
    // Constructor only DML/Constructor recursivo
    public Batch_RecalcVisibilityIntermediaryDMLs(List<Account> intermediariesToProcess, List<AccountTeamMember> atmsToDelete, List<AccountTeamMember> atmsToInsert, Integer numDMLs, String batchType) {
        this.intermediariesToProcess = intermediariesToProcess;
        this.intermediaryAccountIdsSet = new Set<String>();
        this.atmsToDML = new List<AccountTeamMember>();
        this.atmsToDelete = atmsToDelete;
        this.atmsToInsert = atmsToInsert;
        this.numDMLs = numDMLs;
        this.batchType = batchType;
    }

    // Constructor principal calculo de nueva agrupacion
    public Batch_RecalcVisibilityIntermediaryDMLs(List<Account> intermediariesToProcess, Set<String> intermediaryAccountIdsSet, List<AccountTeamMember> atmsToDelete, List<AccountTeamMember> atmsToInsert, Integer numDMLs, String batchType) {
        this.intermediariesToProcess = intermediariesToProcess;
        this.intermediaryAccountIdsSet = intermediaryAccountIdsSet;
        this.atmsToDML = new List<AccountTeamMember>();
        this.atmsToDelete = atmsToDelete;
        this.atmsToInsert = atmsToInsert;
        this.numDMLs = numDMLs;
        this.batchType = batchType;
    }


    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch. Compruebo si el mediador tiene 
     * @param bc: batch context
     * @return List ofertas a modificar
     * @author dmunoz
     * @date 18/03/2024
     */
    global List<sObject> start(Database.BatchableContext bc) { 

        switch on batchType {
            when  'CALCULATE' {
                return intermediariesToProcess;
            } when 'DELETE' {
                if (!atmsToDelete.isEmpty()) {
                    return atmsToDelete;
                } else {
                    return null;
                }
            } when 'INSERT' {
                if (!atmsToInsert.isEmpty()) {
                    return atmsToInsert;
                } else {
                    return null;
                }
            } when else {
                return null;
            }
        } 
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Opportunity procedentes del método start
     * @return void
     * @author dmunoz
     * @date 18/03/2024
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope) {

        try {

            if ('CALCULATE'.equals(batchType)) { 
                calculateIntermediaryAGR(scope);

            } else if ('DELETE'.equals(batchType) || 'INSERT'.equals(batchType)) {
                processDML(scope);
            }
            
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }


    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 18/03/2024
     */
    global void finish(Database.BatchableContext bc) {
        recursiveBatch();        
    }

    /**
     * Metodo que calcula los account team para los usuarios agr del mediador que ha sufrido un cambio/baja mediador y tiene usuario agr asociado
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void calculateIntermediaryAGR(List<sObject> scope) {

        Account intermediary = (Account) scope.get(0);

        List<User> agrUser = (new UsersSelector()).getIntermediaryZRMAGRUsers(intermediary.Id);

        if (agrUser != null && !agrUser.isEmpty()) {
            // Obtener account team members que no deben ver, para ello obtenemos los account team distintos a la lista de clientes que llegan en el contructor del batch
            atmsToDelete.addAll((new AccountTeamMemberSelector()).getZRMATMUserAndOtherAccounts(intermediaryAccountIdsSet, agrUser));
    
            // Obtener la lista de polizas y ofertas de la agrupacion destino (solo cambio agrupacion) sin contar los clientes que ya ve el mediador
            if (String.isNotEmpty(intermediary.IntermediaryGroup__c)) {
                Set<String> newPolicyHolderIdsSet = getNewPolicyHolderIds(intermediary);
        
                Set<String> newOfferAccountIdsSet = getNewOfferAccountIdsSet(newPolicyHolderIdsSet, intermediary);
        
                // genero los account team para los usuarios 
                getATMToInsert(newPolicyHolderIdsSet, newOfferAccountIdsSet, agrUser);
            }
        }
    }


    /**
     * Metodo que consulta las polizas de la agrupación de destino sin contar los clientes que ya ve
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getNewPolicyHolderIds(Account intermediary) {

        Set<String> result = new Set<String>();

        List<Policy__c> policiesList = (new PoliciesSelector()).policiesHoldersFromIntermediaryGroupExcludePolicyHolders(intermediaryAccountIdsSet, intermediary.IntermediaryGroup__c);

        for (Policy__c policy: policiesList) {
            result.add(policy.PolicyHolder__c);
        }

        return result;
    }


    /**
     * Metodo que consulta las ofertas de la agrupación de destino sin contar los clientes que ya ve y los que ha encontrado en la consulta de polizas
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getNewOfferAccountIdsSet(Set<String> newPolicyHolderIdsSet, Account intermediary) {

        Set<String> result = new Set<String>();

        // Primero añado al conjunto intermediaryAccountIdsSet todos los clientes que ya han sido encontrados con polizas
        intermediaryAccountIdsSet.addAll(newPolicyHolderIdsSet);

        List<Opportunity> offerList = (new OpportunitiesSelector()).offersClientsFromIntermediaryGroupExcludeAccountIds(intermediaryAccountIdsSet, intermediary.IntermediaryGroup__c);

        for (Opportunity offer: offerList) {
            result.add(offer.AccountId);
        }        

        return result;

    }


    /**
     * Metodo que obtiene los nuevos account team que un usuario agrupacion debe poder ver en una agrupación
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void getATMToInsert(Set<String> newPolicyHolderIdsSet, Set<String> newOfferAccountIdsSet, List<User> agrUser) {

        for (String policyHolderId: newPolicyHolderIdsSet) {
            atmsToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(policyHolderId, agrUser));
        }  
        
        for (String offerAccountId: newOfferAccountIdsSet) {
            atmsToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(offerAccountId, agrUser));
        } 
    }


    /**
     * Metodo que procesa dmls y prepara futuros paquetes de dml en caso de haber mas registros del limite indicado
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void processDML(List<sObject> scope) {      
        if ('DELETE'.equals(batchType)) {
            processDelete(scope);

        } else if ('INSERT'.equals(batchType)) {
            processInsert(scope);
        }
    }

    /**
     * Metodo que procesa el borrado y prepara los paquetes futuros
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void processDelete(List<sObject> scope) {

        List<AccountTeamMember> atmsFutureBatch = new List<AccountTeamMember>();        

        Integer contador = 0;

        atmsToDML.clear();
        for (AccountTeamMember atm: (List<AccountTeamMember>) scope) {
            if (contador < numDMLs) {
                atmsToDML.add(atm);
                contador++;
            } else {
                atmsFutureBatch.add(atm);
            }
        }

        delete atmsToDML;
        atmsToDelete.clear();

        if (!atmsFutureBatch.isEmpty()) {
            atmsToDelete.addAll(atmsFutureBatch);
        }
    }


    /**
     * Metodo que procesa la inserción y prepara los paquetes futuros
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void processInsert(List<sObject> scope) {

        List<AccountTeamMember> atmsFutureBatch = new List<AccountTeamMember>();   

        Integer contador = 0;
        atmsToDML.clear();

        for (AccountTeamMember atm: (List<AccountTeamMember>) scope) {
            if (contador < numDMLs) {
                atmsToDML.add(atm);
                contador++;
            } else {
                atmsFutureBatch.add(atm);
            }
        }

        insert atmsToDML;
        atmsToInsert.clear(); // limpio la lista de atm a insertar y le añado el sobrante si hay

        if (!atmsFutureBatch.isEmpty()) {
            atmsToInsert.addAll(atmsFutureBatch);
        }
    }


    /**
     * Metodo que controla la llamada recursiva al batch para seguir procesando los dmls una vez hecho los calculos o si solo ha hecho los dmls
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void recursiveBatch() {

        if (!atmsToDelete.isEmpty()) {
            Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, atmsToDelete, atmsToInsert, numDMLs, 'DELETE'), numDMLs);

        } else if (atmsToDelete.isEmpty() && !atmsToInsert.isEmpty()) {
            Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, atmsToDelete, atmsToInsert, numDMLs, 'INSERT'), numDMLs);

        } else if (atmsToDelete.isEmpty() && atmsToInsert.isEmpty() && !intermediariesToProcess.isEmpty()) { 
            // una vez terminado de procesar los account team elimino el primer mediador a procesar y si hay mediadores a procesar vuelvo a llamar al batch Batch_RecalcVisibilityIntermediary
            intermediariesToProcess.remove(0);

            if (!intermediariesToProcess.isEmpty()) {
                Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediariesToProcess, false, numDMLs), numDMLs); 
            }
        }
    }
}