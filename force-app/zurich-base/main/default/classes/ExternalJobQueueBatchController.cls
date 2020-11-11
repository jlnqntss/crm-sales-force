public class ExternalJobQueueBatchController
{
    /**
     * Comprobar si hay external request pendientes de procesar y ejecutar el ExternalJobQueueBatch en caso afirmativo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    public static void checkExternalJobQueueBatch()
    {
        //try
        //{
        // 1 - Comprobar si hay external request de INFO pendientes
        if( !new ExternalRequestsSelector().setLimit(1).selectByOrigin(new Set<String> {'INFO'}).isEmpty() )
        {
            // 1.1 - Ejecutar el batch en caso de no estar en ejecución
            if ( new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueBatch'}).isEmpty() )
            {
                database.executeBatch(new ExternalJobQueueBatch('INFO'), 200);
            }
        }

        //}
        //catch (Exception e)
        //{
        //    ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'checkExternalJobQueueBatch');
        //}
    }
}