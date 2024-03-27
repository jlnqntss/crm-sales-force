/**
 * Batch recursivo que se ejecuta para el recálculo de agrupación de un mediador zrm o en caso de que se pulse el botón de recálculo de visibilidad
 * 
 * @author nts (dmunoz)
 * @date 18/03/2024
 *
 */
global with sharing class Batch_RecalcVisibilityIntermediary implements Database.Batchable<sObject>, Database.Stateful {
    
    private static final String CLASS_NAME = 'Batch_RecalcVisibilityIntermediary';

    private Integer numDMLs = 5000;
    private List<Account> intermediariesToProcess;
    private List<AccountTeamMember> atmsToDelete;
    private List<AccountTeamMember> atmsToInsert;
    private Boolean intermediaryRecalcButton;
    private Set<String> allClients;
    private Boolean stopRecursive; // en caso que se produzca una excepcion para el proceso

    public Batch_RecalcVisibilityIntermediary(List<Account> intermediariesToProcess, Boolean intermediaryRecalcButton, Integer numDMLs) {
        this.intermediariesToProcess = intermediariesToProcess;
        this.atmsToDelete = new List<AccountTeamMember>();
        this.atmsToInsert = new List<AccountTeamMember>();
        this.numDMLs = numDMLs;
        this.intermediaryRecalcButton = intermediaryRecalcButton;
        this.allClients = new Set<String>();
        this.stopRecursive = false;
    }


    /**
     * @description Clase wrapper para el metodo invocable
     * @author fpalomo
     */
    public class Requests
    {
        @InvocableVariable public String intermediaryId;
        @InvocableVariable public Integer numDMLs;
    }

    /**
     * @description Metodo invocable para lanzar el batch desde un flow
     * @param requests List<Requests>
     * @author fpalomo
     */
    @InvocableMethod
    public static void invocableExecuteBatch(List<Requests> requests)
    {
         if (requests == null || requests.isEmpty())
        {
            return;
        }

        if (requests[0].intermediaryId != null && String.isNotEmpty(requests[0].intermediaryId))
        {
            List<Account> intermediaryAccount = [SELECT Id, IntermediaryGroup__c  
                                        FROM Account
                                        WHERE Id = :requests[0].intermediaryId]; 
                                        
            Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediaryAccount, true, requests[0].numDMLs), requests[0].numDMLs);
        }
    }


    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de ofertas a las que hay que modificar la etapa y motivo de cierre
     * @param bc: batch context
     * @return List ofertas a modificar
     * @author dmunoz
     * @date 18/03/2024
     */
    global Database.QueryLocator start(Database.BatchableContext bc) { 

        // Obtengo el primer elemento de la lista de mediadores a procesar para obtener todas sus pólizas
        if (intermediariesToProcess != null && !intermediariesToProcess.isEmpty()) {
            String query = (new PoliciesSelector()).getIntermediaryPoliciesToRecalculateZRMVisibility(intermediariesToProcess);
            return Database.getQueryLocator(query);
        } else {
            return null;
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
    global void execute(Database.BatchableContext bc, List<Policy__c> scope) {

        try {
            Account intermediary = intermediariesToProcess.get(0);
            
            // 1º Recorro las polizas obtenidas para guardar los ids de los clientes
            Set<String> policyHolderIdsSet = getPolicyHolderIdsSet(scope); 
    
            // 2º Obtengo para ese mediador las ofertas que no sean ninguno de los clientes de las polizas
            Set<String> offerAccountIdsSet = getofferAccountIdsSet(policyHolderIdsSet, intermediary);

            // añado todos los clientes del mediador a la variable global allClients
            allClients.addAll(policyHolderIdsSet);
            allClients.addAll(offerAccountIdsSet);
       
            // 3º Compruebo el escenario en el que estoy
            // 3a Nuevo mediador en una agrupacion -> generar los atm de clientes del paso 1 y 2 para los agr de la agrupación nueva

            //3b Si el mediador es un cambio de agrupación/baja de agrupación tengo que comprobar en la antigua si los usuarios agr deben mantener visibilidad sobre los clientes del mediador que se ha ido
            // obtener los usuarios agr de la agrupación nueva e insertar atms de los clientes del paso 1 y 2 de ese mediador
    
            // 3c Si se trata de un recálculo de la visibilidad de un mediador eliminamos los atm asociados a dicho usuario y volvemos a insertar para los usuarios del mediador para los clientes obtenidos en el paso 1 y 2
            calculateVisibility(intermediary);    
    
            // Una vez terminado los cálculos elimino el mediador de la lista a procesar para calcular el siguiente en la próxima iteración de este batch recursivo

        } catch (Exception e) {
            stopRecursive = true;
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
        if (!Test.isRunningTest() && !stopRecursive) {      
            callDMLBatch();
        }      
    }


    /******************************************************************************************* Métodos auxiliares ************************************************************************************************/

    /**
     * Metodo que obtiene la lista de clientes que tienen polizas con el mediador
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getPolicyHolderIdsSet(List<Policy__c> scope) {
        Set<String> result = new Set<String>();

        for (Policy__c policy: scope) {
            result.add(policy.PolicyHolder__c);
        }

        return result;
    }

    /**
     * Metodo que obtiene la lista de clientes asociados a sus ofertas, eliminando aquellos que tienen poliza. De esta manera solo obtengo aquellos extra que no tienen alguna poliza como leads o clientes potenciales
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getofferAccountIdsSet(Set<String> policyHolderIdsSet, Account intermediary) {

        Set<String> result = new Set<String>();
        List<Opportunity> intermediaryOffers = (new OpportunitiesSelector()).getIntermediaryOtherOffers(policyHolderIdsSet, intermediary);

        for (Opportunity offer: intermediaryOffers) {
            result.add(offer.AccountId);
        }
        return result;
    }

    /**
     * Metodo que obtiene el escenario que se está lanzando
     * - Alta Mediador Agrupación
     * - Cambio / Baja Mediador Agrupación
     * - Recálculo de visibilidad mediador lanzado desde el botón de recalculo en la pagina detalle de mediador
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void calculateVisibility(Account intermediary) {        

        // Recálculo desde botón
        if (intermediaryRecalcButton) {
            recalcIntermediaryVisibilityButton(intermediary);
        } else if (String.isEmpty(intermediary.LastIntermediaryGroup__c) && String.isNotEmpty(intermediary.IntermediaryGroup__c)) { // alta mediador en agrupacion
            newIntermediaryInIntermediaryGroup(intermediary);
        } else if (String.isNotEmpty(intermediary.LastIntermediaryGroup__c)) { // cambio/baja mediador agrupacion
            intermediaryChangeIntermediaryGroup(intermediary);
        }
    }


    /**
     * Metodo que recalcula por completo la visibilidad de un mediador y de los usuarios que cuelgan de ese mediador
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void recalcIntermediaryVisibilityButton(Account intermediary) {

        // Añado el mediador de la lista intermediariesToProcess. Al ser el botón solo llegará un elemento
        List<String> intermediaryIdList = new List<String>();
        intermediaryIdList.add(intermediary.Id);

        // 1º Obtener los usuarios de dicho mediador (desde el botón la lista solo tendrá un elemento)
        List<User> intermediaryUsers = (new UsersSelector()).findZRMActiveUsersByIntermediaryId(intermediaryIdList);

        // 2º Si el mediador tiene usuarios eliminamos todos sus account team
        if (!intermediaryUsers.isEmpty()) {            
            atmsToDelete.addAll((new AccountTeamMemberSelector().findZRMATMsByUser(intermediaryUsers)));

        // si el mediador tiene usuarios obtengo los usuarios agr de su agrupacion
        } if (String.isNotEmpty(intermediary.IntermediaryGroup__c)) { 
            intermediaryUsers.addAll((new UsersSelector()).getOtherZRMAGRUsers(intermediary.Id, intermediary.IntermediaryGroup__c));
        }

        // 3º Generar los account team para sus usuarios y allClients (todos los clientes de sus ofertas y polizas)
        for (String accountId: allClients) {
            atmsToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(accountId, intermediaryUsers));
        }
    }

   
    /**
     * Nuevo mediador en una agrupacion -> generar los atm de clientes a partir de los clientes y los usuarios agr de la agrupación destino. 
     * Un mediador que se ha dado de alta cuando previamente no tenia agrupación todos sus usuarios deberán ser de tipo nominal ya que en otro caso,
     * no verían sus datos correctamente. Este método solo tiene en cuenta esta casuística
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void newIntermediaryInIntermediaryGroup(Account intermediary) {

        // 1º Obtener los usuarios con perfil agr para la nueva agrupación que cuelguen de otros mediadores
        List<User> usersToCreateATM = (new UsersSelector()).getOtherZRMAGRUsers(intermediary.Id, intermediary.IntermediaryGroup__c);

        // Genero los atm de los clientes obtenidos en el metodo execute
        for (String accountId: allClients) {
            atmsToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(accountId, usersToCreateATM));
        }
    }

    /**
     * Si el mediador es un cambio de agrupación/baja de agrupación tengo que comprobar en la antigua si los usuarios agr deben mantener visibilidad sobre los clientes del mediador que se ha ido
        obtener los usuarios agr de la agrupación nueva e insertar atms de los clientes del paso 1 y 2 de ese mediador
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void intermediaryChangeIntermediaryGroup(Account intermediary) {

        // Recalcular antigua agrupacion
        calculateOldIntermediaryGroup(intermediary);

        // Añadir atm para los usuarios agr de la nueva agrupación en caso que sea un cambio, si es baja no hay que insertar nada.
        // Si el mediador que se ha movido tiene algun usuario agr se calcula su visibilidad en el batch Batch_RecalcVisibilityIntermediaryDMLs
        if (String.isNotEmpty(intermediary.IntermediaryGroup__c)) {
            newIntermediaryInIntermediaryGroup(intermediary);
        }
    }


    /**
     * Revisar en la agrupación antigua si hay que eliminar algún atm para los usuarios agr
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void calculateOldIntermediaryGroup(Account intermediary) {        

        // Query policy, compruebo si hay alguna poliza para la agrupación antigua
        Set<String> policiesWithClientsIdsInGroupSet = getIntermediaryGroupPoliciesByAllClients(allClients, intermediary);
 
        // Query offer (sin contar los resultados de la query de poliza) en la agrupación antigua
        Set<String> offersWithClientsIdsInGroupSet = getIntermediaryGroupOffersByAllClients(allClients, policiesWithClientsIdsInGroupSet, intermediary);

        // Eliminamos los clientes encontrados en la agrupacion antigua para quedarnos solo con aquellos que no están en la antigua agrupación y a partir de ahi eliminar aquellos atm
        allClients.removeAll(policiesWithClientsIdsInGroupSet);
        allClients.removeAll(offersWithClientsIdsInGroupSet);

        // Obtenemos los accountteam a borrar y los guarda en atmToDelete
        getAccountTeamToDelete(intermediary, allClients);
    }


    /**
     * Revisar en la agrupación antigua si hay que eliminar algún atm para los usuarios agr
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getIntermediaryGroupPoliciesByAllClients(Set<String> allClients, Account intermediary) {

        Set<String> result = new Set<String>();

        List<Policy__c> policiesList = (new PoliciesSelector()).policiesHoldersFromIntermediaryGroup(allClients, intermediary.LastIntermediaryGroup__c);

        for (Policy__c policy: policiesList) {
            result.add(policy.PolicyHolder__c);
        }

        return result;
    }


    /**
     * Revisar en la agrupación antigua si hay que eliminar algún atm para los usuarios agr
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private Set<String> getIntermediaryGroupOffersByAllClients(Set<String> allClients, Set<String> policiesWithClientsIdsSet, Account intermediary) {

        Set<String> result = new Set<String>();

        // Primero elimino del conjunto allClients todos los clientes que ya han sido encontrados con polizas
        allClients.removeAll(policiesWithClientsIdsSet);

        List<Opportunity> offerList = (new OpportunitiesSelector()).offersClientsFromIntermediaryGroup(allClients, intermediary.LastIntermediaryGroup__c);

        for (Opportunity offer: offerList) {
            result.add(offer.AccountId);
        }        

        return result;
    }


    /**
     * A partir de los clientes del mediador y de la agrupacion antigua se calculan los atm a eliminar de los usuarios agr 
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void getAccountTeamToDelete(Account intermediary, Set<String> accountIdsSet) {        

        // si hay que eliminar elementos 
        if (!accountIdsSet.isEmpty()) {
            // Me quedo con los clientes que no tiene ya visibilidad en la agrupacion antigua para eliminar los atm de los usuarios agr
            List<User> usersToDeleteATM = (new UsersSelector()).getOtherZRMAGRUsers(intermediary.Id, intermediary.LastIntermediaryGroup__c);

            atmsToDelete.addAll(new AccountTeamMemberSelector().getZRMATMByAccountAndUser(accountIdsSet, usersToDeleteATM));
        }
    }

    
    /**
     * Lanzamos el ultimo batch de la cadena para terminar los calculos o hacer los dmls
     * 
     * @author dmunoz
     * @date 18/03/2024
     */
    private void callDMLBatch() {

        Account intermediary = intermediariesToProcess.get(0);

        // si el mediador tiene usuarios agr calculamos la visibilidad en el siguiente batch
        List<User> agrUser = (new UsersSelector()).getIntermediaryZRMAGRUsers(intermediary.Id);        

        if (agrUser != null && !agrUser.isEmpty()) { // calcular la visibilidad del usuario que se ha dado de baja o ha cambiado de agrupacion si tiene algún usuario agrupacion
            Database.executeBatch(new Batch_RecalcVisibilityIntermediaryDMLs(intermediariesToProcess, allClients, atmsToDelete, atmsToInsert, numDMLs, 'CALCULATE'), numDMLs);
        } else if (!atmsToDelete.isEmpty()) {
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