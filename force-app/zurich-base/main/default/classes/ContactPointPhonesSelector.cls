public with sharing class ContactPointPhonesSelector
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
    public ContactPointPhonesSelector()
    {}

    public ContactPointPhonesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca ContactPointPhones a partir del ScopeId y excluyendo una lista de ContactPointPhoneIds
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  scopeIds                     Listado de identificadores de Scope__c. Válido cualquier formato
     * @param  isPrimary                    Indica el valor de IsPrimary que queremos recuperar
     * @param  ContactPointPhonesToExclude  Lista de ContactPointPhones que queremos excluir en la query.
     *                                      (Enviar lista vacia si unicamente queremos buscar por ScopeId)
     *
     * @return                              Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointPhone> selectByScopeIdAndIsPrimary(Set<Id> scopeIds, Boolean isPrimary, List<ContactPointPhone> ContactPointPhonesToExclude)
    {
        if(scopeIds != null && isPrimary != null)
        {
            if(ContactPointPhonesToExclude == null)
            {
                ContactPointPhonesToExclude = new List<ContactPointPhone>();
            }

            this.sObjectToQuery = 'ContactPointPhone';
            String query = String.format(
                'SELECT {0} FROM ContactPointPhone ' +
                'WHERE ScopeId__c IN : scopeIds AND IsPrimary =: isPrimary AND Id NOT IN: ContactPointPhonesToExclude',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointPhone>) Database.query(query);
        }
        else
        {
            return new List<ContactPointPhone>();
        }
    }

    /**
     * Busca ContactPointPhones a partir del campo IsPrimary
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  isPrimary  Indica el valor de IsPrimary que queremos recuperar
     * @return            Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointPhone> selectByIsPrimary(Boolean isPrimary)
    {
        if(isPrimary != null)
        {
            this.sObjectToQuery = 'ContactPointPhone';
            String query = String.format(
                'SELECT {0} FROM ContactPointPhone ' +
                'WHERE IsPrimary =: isPrimary',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointPhone>) Database.query(query);
        }
        else
        {
            return new List<ContactPointPhone>();
        }
    }

    /**
     * Busca ContactPointPhones a partir del campo IsPrimary
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  scopeIds           Listado de identificadores de Scope__c. Válido cualquier formato
     * @param  telephoneNumber    Número de teléfono a buscar
     * @return            Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointPhone> selectByScopeIdAndTelephoneNumber(Set<Id> scopeIds, String telephoneNumber)
    {
        if( scopeIds != null && String.isNotBlank(telephoneNumber) )
        {
            this.sObjectToQuery = 'ContactPointPhone';
            String query = String.format(
                'SELECT {0} FROM ContactPointPhone ' +
                'WHERE ScopeId__c IN : scopeIds AND TelephoneNumber =: telephoneNumber',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointPhone>) Database.query(query);
        }
        else
        {
            return new List<ContactPointPhone>();
        }
    }
}