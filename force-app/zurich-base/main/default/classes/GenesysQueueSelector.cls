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
        super( purecloud__PureCloud_Queue__c.getSObjectType() );
    }

    public List<purecloud__PureCloud_Queue__c> getAllQueues()
    {
        List<purecloud__PureCloud_Queue__c> result = new List<purecloud__PureCloud_Queue__c>();

        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            purecloud__PureCloud_Queue__c.fields.Name,
            purecloud__PureCloud_Queue__c.fields.Id,
            purecloud__PureCloud_Queue__c.fields.IsSurveyable__c
        })
        .orderBy(purecloud__PureCloud_Queue__c.fields.Name.getDescribe().getName(), 'DESC');

        result = (List<purecloud__PureCloud_Queue__c>) this.baseQuery.run();
        return result;
    }

    public List<purecloud__PureCloud_Queue__c> getQueuesByName(List<String> names)
    {
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
        {
            purecloud__PureCloud_Queue__c.fields.Name,
            purecloud__PureCloud_Queue__c.fields.Id,
            purecloud__PureCloud_Queue__c.fields.CallCenter__c, 
            purecloud__PureCloud_Queue__c.fields.GenesysFlowId__c 
        };

        if (names?.size() > 0)
        {
            this.baseQuery.selectFields(fieldList)
            .addConditionIn(purecloud__PureCloud_Queue__c.fields.Name, names);
            return (List<purecloud__PureCloud_Queue__c>) this.baseQuery.run();
        }

        return new List<purecloud__PureCloud_Queue__c>();
    }
}