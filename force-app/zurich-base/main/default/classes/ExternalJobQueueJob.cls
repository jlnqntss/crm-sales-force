public class ExternalJobQueueJob implements Queueable
{
    private String origin;


    public ExternalJobQueueJob(String origin)
    {
        this.origin = origin;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<AsyncApexJob> queuedJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueJob'});
            List<AsyncApexJob> executingJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueBatch'});

            if( queuedJobs.size() <= 1 && executingJobs.isEmpty() )
            {
                List<String> queries = ExternalJobQueueBatchController.getChunkQueries(origin);

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