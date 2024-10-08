/**
 * @description       :
 * @author            : jnavarro
 * @group             :
 * @last modified on  : 07-10-2024
 **/
public with sharing class CompetitorsSelector extends RecordsSelector
{

    //#region Contructores
    public CompetitorsSelector()
    {
        super( Opportunity.getSObjectType() );
    }

    //#endregion

    /**
     * Busca Opportunities a partir del Ids de cuentas, las competencias vinculadas a ellas
     *
     * @author jnavarro
     * @date 07/10/2024
     * @param  AccountIds   Lista con identificadores de cuentas
     *
     * @return              Listado de comptetencias con Id de Cuentas indicadas
     */
    public List<Competitor__c> getCompetitorsRelatedWithAccauntIds(List<String> accountIds)
    {
        List<Competitor__c> result = new List<Competitor__c>();

        if( accountIds != null && !accountIds.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Competitor__c.Id,
                Competitor__c.Account__c
            })
            .addCondition( Query.conditionIn(Competitor__c.Account__c, accountIds) );

            result = (List<Competitor__c>) this.baseQuery.run();
        }

        return result; 

    }
}