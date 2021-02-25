trigger SurveyResponseTrigger on SurveyResponse__c (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(SurveyResponse__c.sObjectType);
}