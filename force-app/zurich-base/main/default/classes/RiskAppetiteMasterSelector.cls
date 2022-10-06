/**
 * Clase Selector para el objeto MaestroApetito__c
 * @author jjuaristi@seidor.es
 * @date 05/10/2022
 */
public with sharing class RiskAppetiteMasterSelector extends RecordsSelector
{
    public RiskAppetiteMasterSelector() 
    {
        super(MaestroApetito__c.getSObjectType());
    }

    /**
     * Método que recupera todos los registros
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    public List<MaestroApetito__c> findAllMasters()
    {
        this.baseQuery.selectReadableFields();

        this.baseQuery.orderBy('SIC__c');
        return (List<MaestroApetito__c>) this.baseQuery.run();
    }

    /**
     * Método que recupera todos los registros filtrados por SIC
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    public List<MaestroApetito__c> findProductsBySicCode(String sicCode)
    {
        if(String.isNotBlank(sicCode))
        {
            this.baseQuery.selectReadableFields();
            // Solo filtramos por código, el nombre iría en Subfamilia__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.SIC__c, sicCode);

            this.baseQuery.orderBy('NombreProducto__c', 'DESC');

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }

    /**
     * Método que recupera todos los registros filtrados por SIC y ramo
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    public List<MaestroApetito__c> findCommercialActivitiesByProductCode (String sicCode, String productCode)
    {
        if(String.isNotBlank(productCode) && String.isNotBlank(sicCode))
        {
            this.baseQuery.selectReadableFields();

            // Solo filtramos por código, el nombre iría en NombreProducto__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.CodigoProducto__c, productCode)
            .addConditionEq(MaestroApetito__c.SIC__c, sicCode);

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }

    /**
     * Método que recupera todos los registros filtrados por SIC, ramo y actividad comercial
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    public List<MaestroApetito__c> findTechPolicyByCommercialActivity(String sicCode, String productCode, String commercialActivity)
    {
        if(String.isNotBlank(commercialActivity))
        {
            // We need to show as much information as we can, so we query all the readable fields.
            this.baseQuery.selectReadableFields();

            // Solo filtramos por código, el nombre iría en NombreActividad__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.CodigoProducto__c, productCode)
            .addConditionEq(MaestroApetito__c.SIC__c, sicCode)
            .addConditionEq(MaestroApetito__c.CodigoActividad__c, commercialActivity);

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }

    /**
     * Método que recupera la política técnica fijada
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    public MaestroApetito__c getQueryFindTechnicalPolicy(MaestroApetito__c auxRecord, List<String> fields)
    {
        if(auxRecord != null && fields != null && !fields.isEmpty())
        {
            // We need to show as much information as we can, so we query all the readable fields.
            this.baseQuery.selectReadableFields();
            
            for(String field : fields)
            {
                this.baseQuery.addConditionEq(field, auxRecord.get(field));
            }
            this.baseQuery.setLimit(1);

            List<MaestroApetito__c> recordList = this.baseQuery.run();
            return recordList[0];
        }
        else 
        {
            return new MaestroApetito__c();    
        }
    }
}