public with sharing class ContactPointEmailsSelector
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
    public ContactPointEmailsSelector()
    {}

    public ContactPointEmailsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca ContactPointEmails a partir del ScopeId y excluyendo una lista de ContactPointEmailIds
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  scopeIds                     Listado de identificadores de Scope__c. Válido cualquier formato
     * @param  isPrimary                    Indica el valor de IsPrimary que queremos recuperar
     * @param  contactPointEmailsToExclude  Lista de ContactPointEmails que queremos excluir en la query.
     *                                      (Enviar lista vacia si unicamente queremos buscar por ScopeId)
     *
     * @return                              Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointEmail> selectByScopeIdAndIsPrimary(Set<Id> scopeIds, Boolean isPrimary, List<ContactPointEmail> contactPointEmailsToExclude)
    {
        if(scopeIds != null && isPrimary != null)
        {
            if(contactPointEmailsToExclude == null)
            {
                contactPointEmailsToExclude = new List<ContactPointEmail>();
            }

            this.sObjectToQuery = 'ContactPointEmail';
            String query = String.format(
                'SELECT {0} FROM ContactPointEmail ' +
                'WHERE ScopeId__c IN : scopeIds AND IsPrimary =: isPrimary AND Id NOT IN: contactPointEmailsToExclude',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointEmail>) Database.query(query);
        }
        else
        {
            return new List<ContactPointEmail>();
        }
    }

    /**
     * Busca ContactPointEmails a partir del campo IsPrimary
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  isPrimary  Indica el valor de IsPrimary que queremos recuperar
     * @return            Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointEmail> selectByIsPrimary(Boolean isPrimary)
    {
        if(isPrimary != null)
        {
            this.sObjectToQuery = 'ContactPointEmail';
            String query = String.format(
                'SELECT {0} FROM ContactPointEmail ' +
                'WHERE IsPrimary =: isPrimary',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointEmail>) Database.query(query);
        }
        else
        {
            return new List<ContactPointEmail>();
        }
    }

    /**
     * Busca ContactPointEmails a partir del campo IsPrimary
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  scopeIds        Listado de identificadores de Scope__c. Válido cualquier formato
     * @param  emailAddress    Correo electrónico a buscar
     * @return                 Listado de scopes sobre los que se ha realizado match
     */
    public List<ContactPointEmail> selectByScopeIdAndEmailAddress(Set<Id> scopeIds, String emailAddress)
    {
        if( scopeIds != null && String.isNotBlank(emailAddress) )
        {
            this.sObjectToQuery = 'ContactPointEmail';
            String query = String.format(
                'SELECT {0} FROM ContactPointEmail ' +
                'WHERE ScopeId__c IN : scopeIds AND EmailAddress =: emailAddress',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<ContactPointEmail>) Database.query(query);
        }
        else
        {
            return new List<ContactPointEmail>();
        }
    }
}