public class DeleteRecordsEventUtil
{
    /** LIMITADO a un evento por transacción
     * 1- Comprueba que aún no se ha llegado a LaunchedCount__c = 10
     * 2- Obtiene registros del sobject indicado y con el where indicado
     * con límite de cuántos se podrán borrar en la DML
     * 3- Si se obtienen registros:
     *    Se borran
     * 4- Se comprueba si aún quedan registros por borrar (solo se pueden borrar 10.000 cada transacción)
     * 5- si aún quedan se publica de nuevo el Evento, sumando 1 al contador y con los mismos parámetros
     * para que empiece una nueva transacción y saltarse los límites
     *
     * @date 26/02/2021
     * @param {List<DeleteRecordsEvent__e>} lista de eventos
     */
    public static void handleEvents(List<DeleteRecordsEvent__e> events)
    {
        //Tamaño de lista de eventos para luego restar del límite de DMLs
        Integer numEvents = events.size();

        //1º evento de la lista que se va a procesar en esta iteración
        DeleteRecordsEvent__e eventToProcess = events[0];

        //Relanzar los eventos que se quedan sin procesar
        if(events.size()>1)
        {
            //Los registros son read-only en trigger after, hay que recrearlos para lanzarlos
            List<DeleteRecordsEvent__e> clonedEvents = new List<DeleteRecordsEvent__e>();
            clonedEvents = events.clone();
            clonedEvents.remove(0); //quitar el que ya se va a procesar (no se puede quitar de la lista original porque es read-only)
            List<DeleteRecordsEvent__e> relaunchEvents = new List<DeleteRecordsEvent__e>();
            //evitar DML statment cannot operate on trigger.new or trigger.old
            for(DeleteRecordsEvent__e oldEvent: clonedEvents)
            {
                DeleteRecordsEvent__e newEvent = new DeleteRecordsEvent__e();
                newEvent.LaunchedCount__c = oldEvent.LaunchedCount__c;
                newEvent.ObjectName__c = oldEvent.ObjectName__c;
                newEvent.Criteria__c = oldEvent.Criteria__c;
                relaunchEvents.add(newEvent);
            }
            try{
                EventBus.publish(relaunchEvents);
            }
            catch(Exception e){
                ErrorLogUtil.commitError(e, 'DeleteRecordsEventUtil', 'handleEvents - republish events');
            }
        }

        //2º Comprobar que aún no se ha llegado a LaunchedCount__c = 10 para no entrar en bucle
        //si es así, no se hace nada y se deja pasar el evento para la siguiente vez que se re-schedule el flow
        if(eventToProcess.LaunchedCount__c < 10)
        {
            //Preparar la query a realizar
            String objectName = eventToProcess.ObjectName__c;
            String whereClause = '';
            String limitClause = 'LIMIT 0';

            //WHERE
            if(String.isNotBlank(eventToProcess.Criteria__c))
            {
                whereClause = 'WHERE ' + eventToProcess.Criteria__c;
            }

            //LIMIT
            Integer remainingRows = Limits.getLimitDmlRows() - Limits.getDmlRows() - numEvents - 1;
            if(remainingRows > 0)
            {
                limitClause = 'LIMIT '+String.valueOf(remainingRows);
            }

            //QUERY
            String query = String.format('SELECT Id FROM {0} {1} {2}', new List<String>{objectName, whereClause, limitClause});

            List<SObject> recordsToDelete = new List<SObject>();
            recordsToDelete = Database.query(query);

            //3º Si se han recuperado registros
            if(recordsToDelete.size() > 0)
            {
                //Se borran
                try{
                   Database.delete(recordsToDelete, false);
                }
                catch(Exception e){
                    ErrorLogUtil.commitError(e, 'DeleteRecordsEventUtil', 'handleEvents - delete records');
                }

                //4º Averiguar si aún quedan registros por borrar
                List<SObject> remainingRecords = new List<SObject>();
                remainingRecords = Database.query(query);

                //5º Relanzar el evento para los que aún quedan por borrar
                if(remainingRecords.size() > 0)
                {
                    try{ //Sumar 1 al contador (el registro es read-only en un trigger after)
                        DeleteRecordsEvent__e relaunchEvent = new DeleteRecordsEvent__e();
                        relaunchEvent.LaunchedCount__c = eventToProcess.LaunchedCount__c + 1;
                        relaunchEvent.ObjectName__c = eventToProcess.ObjectName__c;
                        relaunchEvent.Criteria__c = eventToProcess.Criteria__c;

                        EventBus.publish(relaunchEvent);
                    }
                    catch(Exception e){
                        ErrorLogUtil.commitError(e, 'DeleteRecordsEventUtil', 'handleEvents - republish same event');
                    }
                }
            }
        }
    }
}
