public with sharing class ClaimsSelector extends BaseSelector
{
    //#region Contructores
    public ClaimsSelector() {}

    public ClaimsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Claim__c';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion
}
