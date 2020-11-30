public with sharing class ProductsSelector
{
    //Esta propiedad indica el objeto Salesforce del que vamos a extraer los campos necesarios en la query
    //Si no se indica el objeto, solo se recupera el Id del objeto Salesforce
    public String sObjectToQuery {get; set;}
    public Set<String> fieldsToQuery
    {
        get
        {
            if( String.isNotBlank(this.sObjectToQuery) )
            {
                SObjectType currentObjectType = Schema.getGlobalDescribe().get(this.sObjectToQuery);
                Map<String,Schema.SObjectField> currentTypeFields = currentObjectType.getDescribe().fields.getMap();

                if( fieldsToQuery == null || fieldsToQuery.isEmpty() )
                {
                    fieldsToQuery = new Set<String>();

                    //Recuperamos los required y externalIds
                    for( Schema.SObjectField sObjectField: currentTypeFields.values() )
                    {
                        //Si el campo es requerido o externalId, lo incluimos en el Set de campos a recuperar en la query
                        if(sObjectField.getDescribe().isNillable() != true || sObjectField.getDescribe().isExternalId() == true)
                        {
                            fieldsToQuery.add( sObjectField.getDescribe().getName() );
                        }
                    }
                }
                else
                {
                    //Comprobamos que los campos existen en los campos del objeto, si alguno no existe lo eliminamos del Set
                    for(String field: fieldsToQuery)
                    {
                        if( !currentTypeFields.containsKey(field) )
                        {
                            fieldsToQuery.remove(field);
                        }
                    }

                    if( fieldsToQuery.isEmpty() )
                    {
                        fieldsToQuery.add('Id');
                    }
                }

                return fieldsToQuery;
            }
            else
            {
                return new Set<String> {'Id'};
            }
        }
        set;
    }


    //#region Contructores
    public ProductsSelector()
    {}

    public ProductsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca Products a partir del Commercial Product Code
     *
     * @author rlopez
     * @date 25/11/2020
     * @param  commercialProductCodes     Listado de Commercial Product Codes
     * @param  technicalProductCodes     Listado de Technical Product Codes
     *
     * @return                            Listado de Product2 sobre los que se ha realizado match
     */
    public List<Product2> selectByCommercialPCAndTechnicalPC(Set<String> commercialProductCodes, Set<String> technicalProductCodes)
    {
        if(commercialProductCodes != null && technicalProductCodes != null)
        {
            this.sObjectToQuery = 'Product2';
            String query = String.format(
                'SELECT {0} FROM Product2 ' +
                'WHERE CommercialCode__c IN : commercialProductCodes AND TechnicalCode__c IN : technicalProductCodes',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Product2>) Database.query(query);
        }
        else
        {
            return new List<Product2>();
        }
    }
}