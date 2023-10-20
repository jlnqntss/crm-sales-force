/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 16/10/2023
 * @last modified by  : jgallaga
**/
public with sharing class GDPRPropagateBlockedFieldScheduler implements  Schedulable
{
    private static final String GDPR_BLOCK_PROPAGATION_JOB_NAME = 'GDPR Blocking Propagation';
    private static final String GDPR_ANONYMIZE_PROPAGATION_JOB_NAME = 'GDPR Anonymizing Propagation';

    private Boolean isAnonymizeMode;

    public static Id scheduleGDPRPropagationBatch(String cronExpresion, Boolean isAnonymize)
    {
        if(String.isBlank(cronExpresion))
        {
            cronExpresion = '0 0 22 ? * * *';
        }

        if(isAnonymize == null)
        {
            isAnonymize = true;
        }

        String jobName = IsAnonymize ?  GDPR_BLOCK_PROPAGATION_JOB_NAME : GDPR_ANONYMIZE_PROPAGATION_JOB_NAME;

        return System.schedule(jobName, cronExpresion, new GDPRPropagateBlockedFieldScheduler(isAnonymize));
    }

    public GDPRPropagateBlockedFieldScheduler(Boolean isAnonymize)
    {
        isAnonymizeMode = isAnonymize;
    }

    public void execute(System.SchedulableContext sc)
    {
        Database.executeBatch(new GDPRPropagateBlockedFieldBatch(isAnonymizeMode));
    }
}