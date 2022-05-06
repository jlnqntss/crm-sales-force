/**
 * @author aberuete
 * Batch para actualizar encuestas
 * @date 24/05/2022
 */
global class Batch_UpdateSurvey implements Database.Batchable<sObject>, Schedulable
{
    global String query;
    private static final String JOB_NAME_SCHEDULE = 'OCS Mark Survey To Be Deleted';
    private static final String TIME_EXPRESION_SCHEDULE = '0 0 4 * * ?';
    private static final String SURVEY_NUMBER_DAYS_RETENTION_LABEL = 'SurveyNumberDaysRetention';
    private static final AdminSetupParameter__mdt valueAdminSetupParameter = AdminSetupParameter__mdt.getInstance(SURVEY_NUMBER_DAYS_RETENTION_LABEL);
    private static Integer daysRetentionSurvey;

    global Batch_UpdateSurvey()
    {
        checkMetadata();
    }

    global Batch_UpdateSurvey(String query)
    {
        checkMetadata();
        if ( !String.isBlank(query) )
        {
            this.query = query;
        }
    }
    
    private static void checkMetadata()
    {
        if(valueAdminSetupParameter.Value__c != null )
        {
            daysRetentionSurvey = integer.valueof(valueAdminSetupParameter.Value__c);
        }
        else 
        {
            throw new SystemUtil.SystemUtilException('There are not any value of AdminSetupParameter__mdt defined in the System that contain Survey Retention Days');
        }
    }

    static 
    {
        checkMetadata();
    }
    
    /**
     * Programacion de la actualización de encuestas 
     *
     * @author aberuete
     * @date 04/05/2022
     */
    public static String scheduleSurveyUpdateOCS()
    {
        String query = new SurveySelector().getQueryLastModifiedDateAfterThan(daysRetentionSurvey);
        return scheduleSurveyUpdate(JOB_NAME_SCHEDULE, TIME_EXPRESION_SCHEDULE, query);
    }

    private static String scheduleSurveyUpdate(String jobName, String timeExpression, String query)
    {
        if ( String.isBlank(query) )
        {
            query = new SurveySelector().getQueryLastModifiedDateAfterThan(daysRetentionSurvey);
        }

        if( String.isNotBlank(jobName) && Test.isRunningTest() ) jobName += ' Test';

        return System.schedule
               (
            String.isBlank(jobName) ? JOB_NAME_SCHEDULE : jobName,
            String.isBlank(timeExpression) ? TIME_EXPRESION_SCHEDULE : timeExpression,
            new Batch_UpdateSurvey(query)
               );
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if ( String.isBlank(query) )
        {
            query = new SurveySelector().getQueryLastModifiedDateAfterThan(daysRetentionSurvey);
        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        database.executeBatch( new Batch_UpdateSurvey(query), 2000 );
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try
        {
            List<Survey__c> surveys = (List<Survey__c>) scope;
            List<String> msgErrores = new List<String>();

            if (scope != null)
            {
                for (Survey__c s : surveys)
                {
                    s.CanBeRemoved__c = true;
                }

                Database.SaveResult[] srResults = Database.update(surveys, false);
                
                for (Database.SaveResult sr:srResults)
                {
                    if(!sr.isSuccess())
                    {
                        for (Database.Error err :sr.getErrors())
                        {
                            msgErrores.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
                if (!msgErrores.isEmpty())
                {
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando las encuestas para ser borradas',Batch_UpdateSurvey.class.getName(),(String.join(msgErrores,'\n')));
                }
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e,Batch_UpdateSurvey.class.getName());
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        Integer numSurveyToUpdate = new SurveySelector().count(daysRetentionSurvey,null);
        
        if(numSurveyToUpdate != 0 )
        {
             query = new SurveySelector().getQueryLastModifiedDateAfterThan(daysRetentionSurvey);
             database.executeBatch( new Batch_UpdateSurvey(query), 2000 );
        }

    }
}