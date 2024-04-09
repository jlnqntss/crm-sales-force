/**
 Proceso recursivo que realiza los movimientos dmls de Batch_ProcessIntermediaryOrAccountChange
 * 
 * @author dmunoz
 * @date 04/04/2024
 **/
global with sharing class Batch_IntermediaryOrAccountChangeDMLs implements Database.Batchable<sObject>, Database.Stateful {

    private static final String CLASS_NAME = 'Batch_IntermediaryOrAccountChangeDMLs';

    private List<sObject> recordsToProcess;
    private List<AccountTeamMember> atmsToDelete;
    private List<AccountTeamMember> atmsToInsert;
    private Integer numDMLs;
    private Boolean stopRecordProcess;

    public Batch_IntermediaryOrAccountChangeDMLs(List<sObject> recordsToProcess, List<AccountTeamMember> atmsToDelete, List<AccountTeamMember> atmsToInsert, Integer numDMLs) {
        this.recordsToProcess = recordsToProcess;
        this.atmsToDelete = atmsToDelete;
        this.atmsToInsert = atmsToInsert;
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
            return null;
        }    
    }

    /**
     * Este proceso solo se encarga de iniciar el proceso por lo que el método execute está vacío para enviar la información y calcularlo de manera individual de forma controlada
     * @author dmunoz
     * @date 04/04/2024
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {

            // delete recursivo

            // inserts recursivo
            
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

    //#region Métodos auxiliares batch

    /**
     * Método que una vez calculados los registros a borrar y a insertar de atm llama al proceso batch de dmls
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processDMLs() {        

        if (!stopRecordProcess && ((atmsToDelete != null && !atmsToDelete.isEmpty()) || (atmsToInsert != null && !atmsToInsert.isEmpty()))) {
            Database.executeBatch(new Batch_IntermediaryOrAccountChangeDMLs(recordsToProcess, atmsToDelete, atmsToInsert, numDMLs), numDMLs);
        } else if (!recordsToProcess.isEmpty()) {
            Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(recordsToProcess, numDMLs), numDMLs);
        } 
    }




}