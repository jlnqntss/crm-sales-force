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
     * @author fpalomo
     * @date 10/04/2024
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {

            // Escenario 1:
            // - Nos llegan ATMs para borrar e insertar

            if (!atmsToDelete.isEmpty() && !atmsToInsert.isEmpty())
            {
                // Escenario 1A:
                // - Tenemos que ejecutar una cantidad de DMLs MENOR a lo permitido por cada ejecución de batch (variable numDMLs)
                // > Realizamos todos los DMLs a la vez

                if ((atmsToDelete.size() + atmsToInsert.size()) <= numDMLs)
                {
                    doDelete();
                    doInsert();
                }

                // Escenario 1B:
                // - Tenemos que ejecutar una cantidad de DMLs MAYOR a lo permitido por cada ejecución de batch (variable numDMLs)
                // > Realizamos solo el borrado de ATMs, se ejecutarán un máximo de <numDMLs> y el sobrante (si hubiese) volverá a enviarse a este mismo batch

                else if (!atmsToDelete.isEmpty())
                {
                    doDelete();
                }
            }
            
            // Escenario 2:
            // - Nos vienen ATMs para BORRAR pero no para insertar
            // > Realizamos el borrado de ATMs, se ejecutarán un máximo de <numDMLs> y el sobrante (si hubiese) volverá a enviarse a este mismo batch

            else if (!atmsToDelete.isEmpty())
            {
                doDelete();
            }
            
            // Escenario 3:
            // - Nos vienen ATMs para INSERTAR pero no para borrar
            // > Insertamos los ATMs, se ejecutarán un máximo de <numDMLs> y el sobrante (si hubiese) volverá a enviarse a este mismo batch
            
            else if (!atmsToInsert.isEmpty())
            {
                doInsert();
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

    //#region Métodos auxiliares batch

    /**
     * Método que una vez calculados los registros a borrar y a insertar de atm llama al proceso batch de dmls
     * @author dmunoz
     * @date 04/04/2024
     */
    private void processDMLs() {    
        
        // si al terminar la ejecución del registro no hay ningun elemento a borrar o insertar, pasamos al siguiente si hubiera
        if (!stopRecordProcess && (atmsToDelete != null && atmsToDelete.isEmpty()) || (atmsToInsert != null && atmsToInsert.isEmpty()) && !recordsToProcess.isEmpty()) {
            Batch_IntermediaryOrAccountChangeUtil.updateRecordWithProcessOK(recordsToProcess, CLASS_NAME);
            recordsToProcess.remove(0);
        }

        if (!stopRecordProcess && ((atmsToDelete != null && !atmsToDelete.isEmpty()) || (atmsToInsert != null && !atmsToInsert.isEmpty()))) {
            Database.executeBatch(new Batch_IntermediaryOrAccountChangeDMLs(recordsToProcess, atmsToDelete, atmsToInsert, numDMLs), numDMLs);
        } else if (!recordsToProcess.isEmpty()) {
            Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(recordsToProcess, numDMLs), numDMLs);
        } 
    }

    /**
     * Metodo que procesa la inserción y prepara los paquetes futuros
     * 
     * @author fpalomo
     * @date 10/04/2024
     */
    private void doInsert() {
        List<AccountTeamMember> toInsert = new List<AccountTeamMember>();
        Set<AccountTeamMember> toFuture = new Set<AccountTeamMember>();

        // Dividimos los ATMs que recibe el metodo en 2:
        // 1. Lote de ATMs "toInsert" son los que mandaremos al DML
        // 2. Lote de ATMs "toFuture" son los que mandaremos al Batch de nuevo para que los vuelva a procesar
        Integer contador = 0;
        for (AccountTeamMember atm: atmsToInsert) {
            if (contador < numDMLs) {
                toInsert.add(atm);
                contador++;
            } else {
                toFuture.add(atm);
            }
        } 

        // Insertamos los ATMs que entran en el lote que acaba de procesarse
        insert toInsert;
        
        // Nos aseguramos que no haya nada en la lista de ATMs pendientes y añadimos los que se insertarán en la siguiente tanda
        atmsToInsert.clear();
        atmsToInsert = new List<AccountTeamMember>(toFuture);
    }

    /**
     * Metodo que procesa la inserción y prepara los paquetes futuros
     * 
     * @author fpalomo
     * @date 10/04/2024
     */
    private void doDelete() {
        List<AccountTeamMember> toDelete = new List<AccountTeamMember>();
        Set<AccountTeamMember> toFuture = new Set<AccountTeamMember>();

        // Dividimos los ATMs que recibe el metodo en 2:
        // 1. Lote de ATMs "toDelete" son los que mandaremos al DML
        // 2. Lote de ATMs "toFuture" son los que mandaremos al Batch de nuevo para que los vuelva a procesar
        Integer contador = 0;
        for (AccountTeamMember atm: atmsToDelete) {
            if (contador < numDMLs) {
                toDelete.add(atm);
                contador++;
            } else {
                toFuture.add(atm);
            }
        }

        // Borramos los ATMs que entran en el lote que acaba de procesarse
        delete toDelete;
        
        // Nos aseguramos que no haya nada en la lista de ATMs pendientes y añadimos los que se insertarán en la siguiente tanda
        atmsToInsert.clear();
        atmsToInsert = new List<AccountTeamMember>(toFuture);
    }
}