/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-13-2023
 * @last modified by  : aberuete
**/
public with sharing class UsersSelector extends RecordsSelector 
{
    public UsersSelector() 
    {
        super(User.getSObjectType());
    }

    public List<User> findById (Set<Id> userIds)
    {
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                User.Id,
                User.NotifyType__c,
                User.NotifyDate__c,
                User.Notified__c
            }
        );

        return (List<User>) this.baseQuery.byId(userIds).run();
    }
}