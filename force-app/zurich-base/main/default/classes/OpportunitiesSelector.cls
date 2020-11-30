public with sharing class OpportunitiesSelector
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
    public OpportunitiesSelector()
    {}

    public OpportunitiesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca Opportunities a partir del Id de cuenta y de un conjunto de Ids de Scopes
     *
     * @author rlopez
     * @date 30/11/2020
     * @param  accountId    Id de la cuenta para la que queremos buscar ofertas
     * @param  scopesIds    Conjunto de Ids de Scope por los que queremos buscar ofertas
     *
     * @return              Listado de opportunies sobre los que se ha realizado match
     */
    public List<Opportunity> selectByAccountIdAndScopes(Id accountId, Set<Id> scopeIds)
    {
        if(accountId != null && scopeIds != null)
        {
            this.sObjectToQuery = 'Opportunity';
            String query = String.format(
                'SELECT {0} FROM Opportunity ' +
                'WHERE AccountId = : accountId AND ScopeId__c IN : scopeIds ' +
                'ORDER BY createdDate DESC ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Opportunity>) Database.query(query);
        }
        else
        {
            return new List<Opportunity>();
        }
    }
}