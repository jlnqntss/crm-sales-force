public with sharing class ScopesSelector extends BaseSelector
{
    //#region Contructores
    public ScopesSelector()
    {}

    public ScopesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Scope__c';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca scpes a partir del Id
     *
     * @author rlopez
     * @date 23/11/2020
     * @param  ids   Listado de identificadores. Válido cualquier formato
     * @return       Listado de scopes sobre los que se ha realizado match
     */
    public List<Scope__c> selectById(Set<Id> ids)
    {
        if(ids != null)
        {
            String query = String.format(
                'SELECT {0} FROM Scope__c ' +
                'WHERE Id IN : ids ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Scope__c>) Database.query(query);
        }
        else
        {
            return new List<Scope__c>();
        }
    }

    /**
     * Busca scpes a partir del AccountId
     *
     * @author rlopez
     * @date 26/11/2020
     * @param  ids   Listado de identificadores. Válido cualquier formato
     * @return       Listado de scopes sobre los que se ha realizado match
     */
    public List<Scope__c> selectByAccountId(Set<Id> ids)
    {
        if(ids != null)
        {
            String query = String.format(
                'SELECT {0} FROM Scope__c ' +
                'WHERE AccountId__c IN : ids ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Scope__c>) Database.query(query);
        }
        else
        {
            return new List<Scope__c>();
        }
    }

    /**
     * Busca scpes a partir del AccountId y del valor de Scope
     *
     * @author rlopez
     * @date 26/11/2020
     * @param  ids      Listado de identificadores. Válido cualquier formato
     * @param  scope    Valor del Scope a buscar
     * @return          Listado de scopes sobre los que se ha realizado match
     */
    public List<Scope__c> selectByAccountIdAndScope(Set<Id> ids, String scope)
    {
        if(ids != null)
        {
            String query = String.format(
                'SELECT {0} FROM Scope__c ' +
                'WHERE AccountId__c IN : ids AND Scope__c = : scope',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Scope__c>) Database.query(query);
        }
        else
        {
            return new List<Scope__c>();
        }
    }
}