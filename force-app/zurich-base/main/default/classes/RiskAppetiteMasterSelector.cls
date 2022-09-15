public with sharing class RiskAppetiteMasterSelector extends RecordsSelector
{
    public RiskAppetiteMasterSelector() 
    {
        super(MaestroApetito__c.getSObjectType());
    }

    public List<MaestroApetito__c> findAllMasters()
    {
        this.baseQuery.selectReadableFields();

        this.baseQuery.orderBy('SIC__c');
        return (List<MaestroApetito__c>) this.baseQuery.run();
    }

    public List<MaestroApetito__c> findProductsBySicCode(String SICcode)
    {
        if(String.isNotBlank(SICcode))
        {
            this.baseQuery.selectReadableFields();
            // Solo filtramos por código, el nombre iría en Subfamilia__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.SIC__c, SICcode);

            this.baseQuery.orderBy('NombreProducto__c', 'DESC');

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }

    public List<MaestroApetito__c> findCommercialActivitiesByProductCode (String sicCode, String ProductCode)
    {
        if(String.isNotBlank(ProductCode) && String.isNotBlank(sicCode))
        {
            this.baseQuery.selectReadableFields();

            // Solo filtramos por código, el nombre iría en NombreProducto__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.CodigoProducto__c, ProductCode)
            .addConditionEq(MaestroApetito__c.SIC__c, sicCode);

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }

    public List<MaestroApetito__c> findTechPolicyByCommercialActivity(String sicCode, String ProductCode, String commercialActivity)
    {
        if(String.isNotBlank(commercialActivity))
        {
            // We need to show as much information as we can, so we query all the readable fields.
            this.baseQuery.selectReadableFields();

            // Solo filtramos por código, el nombre iría en NombreActividad__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.CodigoProducto__c, ProductCode)
            .addConditionEq(MaestroApetito__c.SIC__c, sicCode)
            .addConditionEq(MaestroApetito__c.CodigoActividad__c, commercialActivity);

            return (List<MaestroApetito__c>) this.baseQuery.run();
        }
        else
        {
            return new List<MaestroApetito__c>();
        }
    }
}