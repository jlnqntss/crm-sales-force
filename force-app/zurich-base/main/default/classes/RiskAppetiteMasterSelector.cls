public with sharing class RiskAppetiteMasterSelector extends RecordsSelector
{
    public RiskAppetiteMasterSelector() 
    {
        super(MaestroApetito__c.getSObjectType());
    }

    public List<MaestroApetito__c> findAllMasters()
    {
        // Seleccionamos los campos necesarios para mostrar en el componente 
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                MaestroApetito__c.Id,
                MaestroApetito__c.SIC__c,
                MaestroApetito__c.Subfamilia__c
            }
        );

        this.baseQuery.orderBy('SIC__c');
        return (List<MaestroApetito__c>) this.baseQuery.run();
    }

    public List<MaestroApetito__c> findProductsBySicCode(String SICcode)
    {
        if(String.isNotBlank(SICcode))
        {
            // Seleccionamos los campos necesarios para mostrar en el componente 
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    MaestroApetito__c.Id,
                    MaestroApetito__c.SIC__c,
                    MaestroApetito__c.Subfamilia__c,
                    MaestroApetito__c.CodigoProducto__c,
                    MaestroApetito__c.NombreProducto__c
                }
            );
            // Solo filtramos por código, el nombre iría en Subfamilia__c pero solo lo queremos para pintarlo en el breadcrumb
            this.baseQuery.addConditionEq(MaestroApetito__c.SIC__c, SICcode);

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
            // Seleccionamos los campos necesarios para mostrar en el componente 
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    MaestroApetito__c.Id,
                    MaestroApetito__c.SIC__c,
                    MaestroApetito__c.Subfamilia__c,
                    MaestroApetito__c.CodigoProducto__c,
                    MaestroApetito__c.NombreProducto__c,
                    MaestroApetito__c.CodigoActividad__c,
                    MaestroApetito__c.ObservacionesActividad__c,
                    MaestroApetito__c.ApetitoRiesgo__c,
                    MaestroApetito__c.DyO__c,
                    MaestroApetito__c.Ciber__c
                }
            );

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