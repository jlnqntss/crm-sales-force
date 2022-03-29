/**
 * 
 * @author jgarciamartinez@nts-solutions.com
 * @date 29/03/2022
 * Clase selectora para las colas relacionadas con Genesys Cloud
 */
public with sharing class GenesysQueueSelector extends RecordsSelector
{
    public GenesysQueueSelector() 
    {
        super(purecloud__PureCloud_Queue__c.getSObjectType());
    }

    public List<purecloud__PureCloud_Queue__c> getAllQueues()
    {
        List<purecloud__PureCloud_Queue__c> result = new List<purecloud__PureCloud_Queue__c>();

        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            purecloud__PureCloud_Queue__c.fields.Name,
            purecloud__PureCloud_Queue__c.fields.Id,
            purecloud__PureCloud_Queue__c.fields.IsSurveyable__c
        })
        .orderBy(purecloud__PureCloud_Queue__c.fields.Name.getDescribe().getName(), 'DESC');

        result = (List<purecloud__PureCloud_Queue__c>) this.baseQuery.run();
        return result;
    }
}
