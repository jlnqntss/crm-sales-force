/**
 * Clase para la consultas sobre el objeto SendDocCUInfo__c
 * 
 * @author mario.navarro@seidor.com
 * @date 28/05/2024
 */
public with sharing class SendDocCUInfosSelector extends RecordsSelector
{

    /**
     * Constructor por defecto que inicializa el objeto baseQuery
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    public SendDocCUInfosSelector()
    {
        super( SendDocCUInfo__c.getSObjectType() );
    }

    /**
     * Construye la query para eliminar registros por la retencion definida para el objeto
     * en la CMDT de configuracion global. La query devolvera aquellos registros cuya fecha de
     * modificacion sea anterior al numero de dias proporcionados
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     * @param days dias de retencion
     * @return el String con la query construida
     */
    public String getQueryToDeleteObjectsByRetention(Integer days)
    {
        Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
        {
            SendDocCUInfo__c.Id
        };
        String query = this.baseQuery
                        .selectFields(fieldsToRetrieve)
                        .addConditionLt(SendDocCUInfo__c.CreatedDate, Query.LAST_N_DAYS(days))
                        .toQueryString();
        return query;
    }

}