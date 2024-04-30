/**
 * Clase Batch que se lanzará a diario para cerrar los casos de ZRM que no figuren con estado Cerrado y que su
 * fecha de vencimiento haya pasado más de 2 meses
 * Este proceso pertenece al módulo de 'Retenciones' dentro de ZRM para operar con la entidad Caso
 * @author nikola.cobian@seidor.com
 * @date 22/04/2024
 */
public with sharing class Batch_CloseZRMExpiredCases implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    //Atributo 'query' que se encargará de recoger la información de los Casos a operar en el selector
    public String query;
    //Recogemos la información necesaria a través de la metadata para operar con los datos que nos interesan
    //MESES EN LOS QUE DEBE DE CERRARSE UN CASO EN LA COMUNIDAD ZRM
    private static final String CASE_MONTHS_TO_RETRIEVE = 'BatchCasesUpdateLastNMonths';
    private static final AdminSetupParameter__mdt monthsToQueryCases = AdminSetupParameter__mdt.getInstance(CASE_MONTHS_TO_RETRIEVE);
    //RECORD TYPE DEL CASO EN LA COMUNIDAD ZRM
    private static final String ZRM_CASE_RECORD_TYPE_TO_RETRIEVE = 'BatchCasesUpdateZRMRecordType';
    private static final AdminSetupParameter__mdt recordTypeToQueryZRMCases = AdminSetupParameter__mdt.getInstance(ZRM_CASE_RECORD_TYPE_TO_RETRIEVE);

    public Batch_CloseZRMExpiredCases()
    {}

    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        if(query == null || String.isEmpty(query))
        {
            query = new CasesSelector().getQueryStringZRMExpiredAndNotClosedCasesWithPolicy(recordTypeToQueryZRMCases.Value__c, monthsToQueryCases.Value__c);
        }
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_CloseZRMExpiredCases(), 10);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            // Se convierte el Scope en casos
            List<Case> givenCases = (List<Case>) scope;
            try
            {
                // Método que asigna los valores a actualizar de los casos obtenidos en la query
                List<Case> casesToUpdate = CaseUtil.updateZRMExpiredCases(givenCases);

                // Si hay algún caso a actualizar
                if(casesToUpdate != null && !casesToUpdate.isEmpty())
                {
                    // Se actualizan los registros
                    update casesToUpdate;
                }
            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'Batch_CloseZRMExpiredCases');
            }
        }
    }

    public void finish(Database.BatchableContext bc)
    {}


    /* Código para programar como 'Scheduled Apex' este batch desde la 
    *  ventana de ejecución anónima en la Developer Console.
    *  El valor del parámetro 'cron' es para lanzarlo a diario a las 10:00 AM
    *
    Batch_CloseZRMExpiredCases batchToSchedule = new Batch_CloseZRMExpiredCases();
    String sch = '0 0 10 1/1 * ? *';
    String jobID = System.schedule('Batch Limpieza de Casos abiertos en ZRM', sch, batchToSchedule);
    */
}