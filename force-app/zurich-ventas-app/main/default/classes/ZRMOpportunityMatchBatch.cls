public with sharing class ZRMOpportunityMatchBatch implements Database.Batchable<sObject>
{
    // #region Instance properties

    private String query
    {
        get
        {
            return OpportunitiesSelector.getQueryStringPotentialMatchOpportunities();
        }
        set;
    }

    // #endregion

    // #region Constructors

    public ZRMOpportunityMatchBatch()
    {}

    public ZRMOpportunityMatchBatch(String query)
    {
        if( !String.isBlank(query) )
        {
            this.query = query;
        }
    }

    // #endregion

    // #region Batchable interface implemented methods

    /**
     * @description Método que se encarga de recupara los registros que serán
     * tratados en el método execute.
     * @author amiranda
     * @date 10-04-2024
     * @param bc Referencia del objeto que implementa la interfaz Database.BatchableContext.
     * @return Database.QueryLocator Conjunto de registros devueltos por 'Database.getQueryLocator'.
     **/
    public Database.QueryLocator start(Dabase.BatchableContext bc)
    {
        return Database.getQueryLocator(query);
    }

    /**
     * @description Método que se encarga del procesamiento de los registros recuperados
     * en el método start.
     * @author amiranda
     * @date 10-04-2024
     * @param bc Referencia del objeto que implementa la interfaz Database.BatchableContext.
     * @param opportunities Conjunto de registros del objeto Opportunity que se han recuperado
     * en el método start.
     **/
    public void execute(Database.BatchableContext bc, List<Opportunity> oportunities)
    {}

    /**
     * @description Método que se ejecuta al finalizar el batch.
     * @author amiranda
     * @date 10-04-2022
     * @param bc Referencia del objeto que implementa la inetrfaz Database.BatchableContext.
     **/
    public void finish(Database.BatchableContext bc)
    {}

    // #endregion
}