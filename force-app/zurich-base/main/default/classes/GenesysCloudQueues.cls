public with sharing class GenesysCloudQueues {

    @AuraEnabled(cacheable = true)
    public static List<purecloud__PureCloud_Queue__c> getSurveyableQueue()
    {
        List<pureCloud__PureCloud_Queue__C> queueToSurvey = [SELECT Name, Id, IsSurveyable__c 
                                                            FROM pureCloud__PureCloud_Queue__C];

        //hacer selector 
        return queueToSurvey;
    }
}
