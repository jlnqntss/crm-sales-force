public class ExternalJobQueueJob implements Queueable
{
    private String origin;
    private Integer index;

    public ExternalJobQueueJob(String origin)
    {
        this.origin = origin;
        // Si no llega índice se empieza desde el principio
        this.index = 1;
    }

    /**
     * Constructor con índice para la entidad
     * @author jjuaristi@seidor.es
     * @date 11/04/2023
     */
    public ExternalJobQueueJob(String origin, Integer index)
    {
        this.origin = origin;
        this.index = index;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<AsyncApexJob> queuedJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueJob'});
            List<AsyncApexJob> executingJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueBatch'});

            if( queuedJobs.size() <= 1 && executingJobs.isEmpty() )
            {
                List<String> queries = ExternalJobQueueBatchController.getChunkQueries(origin, index);

                if( queries != null && !queries.isEmpty() )
                {
                    for(String query : queries)
                    {
                        database.executeBatch(new ExternalJobQueueBatch(origin, query), 200);
                    }
                }
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueJob', 'execute');
        }
    }
}