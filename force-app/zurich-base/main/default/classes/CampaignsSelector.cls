public with sharing class CampaignsSelector extends BaseSelector
{
    //#region Contructores
    public CampaignsSelector()
    {}

    public CampaignsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Campaign';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca campañas a partir del Name
     *
     * @author rlopez
     * @date 01/12/2020
     * @param  names    Listado de nombres. Válido cualquier formato
     * @return          Listado de Campaigns sobre los que se ha realizado match
     */
    public List<Campaign> selectByName(Set<String> names)
    {
        if(names != null)
        {
            String query = String.format(
                'SELECT {0} FROM Campaign ' +
                'WHERE Name IN : names ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Campaign>) Database.query(query);
        }
        else
        {
            return new List<Campaign>();
        }
    }
}