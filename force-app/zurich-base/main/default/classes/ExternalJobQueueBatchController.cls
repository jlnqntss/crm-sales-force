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
        try
        {
            List<AsyncApexJob> queuedJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueJob'});
            List<AsyncApexJob> executingJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueBatch'});

            if( queuedJobs.isEmpty() && executingJobs.isEmpty() )
            {
                System.enqueueJob( new ExternalJobQueueJob('INFO') );
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'checkExternalJobQueueBatch');
        }
    }

    /**
     * Comprobar si hay external request pendientes de procesar y ejecutar el ExternalJobQueueBatch en caso afirmativo
     *
     * @author adelgado
     * @date 19/11/2020
     */
    public static List<String> getChunkQueries(String origin)
    {
        Integer availableJobs = Integer.valueOf(SystemUtil.getAdminSetupMetadata().ExternalJobQueueBatchJobs__c);
        Long firstNameClause;
        Long lastNameClause;
        Long chunkSize;

        try
        {
            Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(origin).getRecordTypeId();

            List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC');

            if( !firstPendingExtReq.isEmpty() )
            {
                List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC');

                Long firstAutoNumber = Long.valueOf( firstPendingExtReq.get(0).Name.substringAfter('ER') );
                Long lastAutoNumber = Long.valueOf( lastPendingExtReq.get(0).Name.substringAfter('ER') );

                if( (lastAutoNumber - firstAutoNumber) < 1000 )
                {
                    availableJobs = 1;
                }
                else
                {
                    chunkSize = (lastAutoNumber - firstAutoNumber) / availableJobs;
                }

                List<String> queries = new List<String>();

                for(Integer i = 1; i <= availableJobs; i++)
                {
                    firstNameClause = (i == 1) ? firstAutoNumber : lastNameClause + 1;
                    lastNameClause = (i == availableJobs) ? lastAutoNumber : firstNameClause + chunksize;

                    queries.add('SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\' AND Name >= \'ER' + firstNameClause + '\' AND Name <= \'ER' + lastNameClause + '\' AND Processed__c = false');
                }

                return queries;
            }

            return null;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'getChunkQueries');
        }

        return null;
    }






}