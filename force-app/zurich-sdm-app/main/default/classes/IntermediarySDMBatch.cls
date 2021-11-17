/**
 * Batch que se encarga de relizar los siguientes automatismos para los Mediadores del proyecto SDM (Sales Digital 
 * Management):
 * - Agrupaciones Mediador: calculo de la cuenta de Agrupacion para un medidador
 * - Equipos de cuenta: calculo del equipo de cuenta de un mediador segun sus campos de email rellenados
 * - Relacion de contactos: calculo de las relaciones de contactos de un mediador segun sus campos de email rellenados
 * 
 * @author nts (agonzalezisasi)
 * @date 05/07/2021
 *
 */
global class IntermediarySDMBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    private static final String CLASS_NAME = 'IntermediarySDMBatch';
    private String query;
    private IntermediarySDM sdm;
    private Integer checkLastNHours;
    
    @testvisible
    private List<SDMAccountTeamRole__mdt> testSettingsATM;
    @testvisible
    private List<SDMAccountContactRelation__mdt> testSettingsACR;
    @testvisible
    private Boolean testUnknownError;
    @testvisible
    private Boolean testUnknownErrorFinish;

    /**
     * Constructor
     */
    global IntermediarySDMBatch()
    {
        sdm = new IntermediarySDM();
    }

    
    /**
     * Constructor. Use a custom query
     */
    global IntermediarySDMBatch(String p_query)
    {
        this();

        query = p_query;
    }

    //------------------------------------------------------------------------- batchable methods

    /**
     * Start. Execute the query locator for the batch
     */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if( String.isBlank(query) ) {
            // Listamos todos los campos de Mediador que vamos a necesitar
            Set<String> intermediaryFields = new Set<String>{
                'Name',
                'NationalId__c',
                'ParentId',
                'StatusIntermediary__c',
                'MainMobilePhone__c'
            };
            
            if( Test.isRunningTest() ) {
                // Configuracion de test para el calculo de los equipos de cuenta (Account Team Member)
                if( this.testSettingsATM != null && !this.testSettingsATM.isEmpty() ) {
                    sdm.SettingsATM.clear();
                    sdm.SettingsATM.addAll(this.testSettingsATM);
                }
                // Configuracion de test para el calculo de las relaciones de contacto (Account Contact Relation)
                if( this.testSettingsACR != null && !this.testSettingsACR.isEmpty() ) {
                    sdm.SettingsACR.clear();
                    sdm.SettingsACR.addAll(this.testSettingsACR);
                }
            }
            // Para el calculo de los equipos de cuenta (Account Team Member)
            intermediaryFields.addAll(sdm.SettingsATMFields);
            if( String.isNotBlank(sdm.rnFieldNoATM) ) intermediaryFields.add(sdm.rnFieldNoATM);
            // Para el calculo de las relaciones de contacto (Account Contact Relation)
            intermediaryFields.addAll(sdm.SettingsACRFields);

            // Selector de Mediadores
            AccountsSelector accSel = new AccountsSelector();
            accSel.baseQuery.selectfields(intermediaryFields);
            // Cuentas de tipo Mediador
            accSel.baseQuery.addConditionEq(Account.RecordTypeId, accSel.rtIntermediaryId);
            // Actualizados en las ultimas 24 horas
            if( checkLastNHours == null ) checkLastNHours = -24;
            accSel.baseQuery.addConditionGt(Account.LastModifiedDate, System.now().addHours(checkLastNHours));
            
            return accSel.baseQuery.getQueryLocator();
        } else {
            return Database.getQueryLocator(query);
        }        
    }

    /**
     * Execute. The method for each batch
     */
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() ) {
            try {
                // System.debug('------ BEFORE => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );

                if( Test.isRunningTest() && testUnknownError != null && testUnknownError ) 
                    throw new IntermediarySDMBatchException('Unknown Error');
                    
                List<Account> intermediaries = (List<Account>)scope;

                // Calculo de las Agrupaciones de Mediadores
                sdm.assignIntermediaryAgrupation(intermediaries);

                // Calculo de los Equipos de Cuenta
                sdm.assignIntermediaryAccountTeam(intermediaries);

                // Calculo de las Relaciones de Contactos
                sdm.assignIntermediaryContactRelation(intermediaries);

                // System.debug('------ AFTER => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );
            } catch (Exception e) {
                ErrorLogUtil.commitError(e, CLASS_NAME);
            }
        }
    }

    /**
     * Finish. The postprocesing method
     */
    global void finish(Database.BatchableContext BC)
    {
        try {
            // System.debug('------ BEFORE => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );

            if( Test.isRunningTest() && testUnknownErrorFinish != null && testUnknownErrorFinish ) 
                throw new IntermediarySDMBatchException('Unknown Error in the Finish method');

            // Calculo de los Equipos de Cuenta para las agrupaciones
            sdm.assignAgrupationAccountTeam(sdm.listAgrupationCIFs);

            // Se comprueba si algun rol se ha inhabilitado para borrar los ATMs que tuviera
            sdm.removeATMsForInactiveRoles();

            // Finalmente, se envia la notificacion a los usuarios de que la visibilidad de sus mediadores ha cambiado
            sdm.sendNotification(sdm.listUserIdsToNotify);
            
            // Eliminar planes comerciales anuales de usuarios que les ha cambiado el panel de mediadores
            PlanComercialSDM plan = new PlanComercialSDM();
            plan.removeAnnualPlans(sdm.listDeletedAtms);

            // System.debug('------ AFTER => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    
    //------------------------------------------------------------------------- schedulable methods

    public static String createStandardSchedule(String jobName, String timeExpression, String query)
    {
        if( String.isBlank(jobName) ) jobName = 'SDM Automatismos Mediadores';
        if( Test.isRunningTest() ) jobName = 'Test ' + jobName;

        if( String.isBlank(timeExpression) ) timeExpression = '0 0 06 * * ?';
        
        return System.schedule(jobName, timeExpression, new IntermediarySDMBatch(query));
    }

    /**
     * Execute. The method for the scheduled batch
     */
    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new IntermediarySDMBatch(query), 200);
    }

    private class IntermediarySDMBatchException extends Exception {}
}