/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 05-24-2023
 * @last modified by  : aberuete
**/
public class ExternalJobQueueJob implements Queueable
{
    private Integer index;

    public ExternalJobQueueJob()
    {
        // Si no llega índice se empieza desde el principio
        this.index = 1;
    }
    /**
     * Constructor con índice para la entidad
     * @author jjuaristi@seidor.es
     * @date 11/04/2023
     */
    public ExternalJobQueueJob(Integer index)
    {
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
                Map<String, List<String>> queriesByOrigin = ExternalJobQueueBatchController.getChunkQueries(index);
            
                if (queriesByOrigin != null && !queriesByOrigin.isEmpty())
                {
                    for (String origin : queriesByOrigin.keySet())
                    {
                        for(String query : queriesByOrigin.get(origin)) 
                        { 
                            database.executeBatch(new ExternalJobQueueBatch(origin, query), 200);     
                        } 
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