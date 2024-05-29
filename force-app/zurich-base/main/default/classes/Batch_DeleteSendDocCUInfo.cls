/**
 * Clase para el purgado mediante batch del objeto SendDocCUInfo
 * 
 * @author mario.navarro@seidor.com
 * @date 28/05/2024
 */
public with sharing class Batch_DeleteSendDocCUInfo implements Database.Batchable<sObject>
{
    private String query;
    private static final String EXECUTE_METHOD_NAME = 'execute';

    /**
     * Constructor por defecto. Construye la query para obtener los registros a borrar
     * en base a los dias de retencion definidos en la CMDT
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public Batch_DeleteSendDocCUInfo()
    {
        Integer retention = GlobalConfigUtil.getDefaultObjectRetention(SendDocCUInfo__c.getSObjectType().toString());
        query = new SendDocCUInfosSelector().getQueryToDeleteObjectsByRetention(retention);
    }

    /**
     * Constructor para poder llamar al batch especificandole la query utilizada para obtener
     * los registros a borrar
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public Batch_DeleteSendDocCUInfo(String q)
    {
        if (String.isNotBlank(q))
        {
            this.query = q;
        }
    }

    /**
     * Prepara el scope de registros a procesar en la ejecucion del batch
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(this.query);
    }

    /**
     * Realiza las acciones propias del proceso batch, en este caso, eliminar
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        Database.DeleteResult[] deleteResult = Database.delete(scope, false);

        for(Database.DeleteResult dr : deleteResult) 
        {
            if (!dr.isSuccess())
            {
                ErrorLogUtil.commitError(dr, Batch_DeleteSendDocCUInfo.class.getName(), EXECUTE_METHOD_NAME, SendDocCUInfo__c.getSObjectType().toString());
            }
        }
    }
 
    /**
     * Finaliza el proceso batch
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public void finish(Database.BatchableContext bc)
    {}
}