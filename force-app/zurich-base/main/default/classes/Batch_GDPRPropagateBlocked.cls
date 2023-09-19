/**
 * @description     : Batch para propagar los campos Blocked/Anonymized a toda la jerarquía
 * @author          : amunoz
 * @group:
 * @last modified on:
 * @last modified by:
 */
global class Batch_GDPRPropagateBlocked implements Database.Batchable<sObject>, Schedulable
{
    global String initialSobject, currentSobject, nextSobject, whatAction;
    private static Map<Integer,Map<Integer,String>> mapOrderBlock;
    
    global Batch_GDPRPropagateBlocked(String initialSobject, String currentSobject, String nextSobject, String whatAction) 
    {

        if (!String.isBlank(initialSobject))
        {
            this.initialSobject = initialSobject;
        }

        if(!String.isBlank(whatAction))
        {
            this.whatAction = whatAction;
        }

        if (mapOrderBlock == null)
        {
            mapOrderBlock = GDPRComplianceUtil.loadSetting(initialSobject);        
        }

        if (!String.isBlank(currentSobject))
        {
            this.currentSobject = currentSobject;
        }else
        {
            this.currentSobject = GDPRComplianceUtil.getLastObject(mapOrderBlock);
        }

        if (!String.isBlank(nextSobject))
        {
            this.nextSobject = nextSobject;
        }else
        {
            String siguiente = GDPRComplianceUtil.getNextObject(mapOrderBlock, this.currentSobject);
            this.nextSobject = siguiente;
        }

    }
    
    /**
     * @description Método execute del scheduler
     */
    global void execute(SchedulableContext sc)
    {
        database.executeBatch( new Batch_GDPRPropagateBlocked(initialSobject, currentSobject, nextSobject, whatAction), 200 );
    }

    /**
     * @description Método start del Batch, obtiene todas las cuentas con el campo blocked a True
     */
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String query;
        query = GDPRComplianceUtil.getQuery(initialSobject, currentSobject, whatAction);
        return Database.getQueryLocator(query);
    }

    

    /**
     * @description Método execute del Batch
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        //El metodo process se encargará de recorrer el scope teniendo en cuenta el currentSobject actual del batch
        GDPRComplianceUtil.process(scope, currentSobject, whatAction);
        
    }

    /**
     * @description Método finish del Batch, programa la siguiente ejecución del Batch.
     */
    global void finish(Database.BatchableContext bc)
    {
        //Futuro CurrentObject y Futuro NextObject
        String futureNextObject = null;
        String futureCurrentObject = nextSobject;

        //Comprobamos si el nextSObject es igual que el Initial(Account/Opportunity) en ese caso no se recupera nada
        //Ya que se acabaría el bacth para esta rama
        if(initialSobject != nextSobject){
            futureNextObject = GDPRComplianceUtil.getNextObject(GDPRComplianceUtil.loadSetting(initialSobject), futureCurrentObject);
            GDPRComplianceUtil.postProcess(initialSObject, futureCurrentObject, futureNextObject, whatAction);
        }else if(initialSobject == nextSobject && whatAction=='Anonimizar'){
            System.debug('Lanzamiento batch de borrado');
        }
    }

}