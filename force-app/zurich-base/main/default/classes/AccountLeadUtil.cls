/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11/08/2023
 * @last modified by  : jgallaga
**/
public with sharing class AccountLeadUtil
{
    private static Id defaultUserId;

    public static String leadAssignment(Account acc, String intermediaryCode, String origin, String language, String postalCode)
    {
        String assignedUserId;

        if(String.isNotBlank(intermediaryCode))
        {
            assignedUserId = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode);
            return assignedUserId;
        }

        if(acc != null)
        {
            assignedUserId = acc.Intermediary_Name__r.INFOIntermediaryCode__c;
            return assignedUserId;
        }

        if(String.isNotBlank(language) && language != 'ES')
        {
            assignedUserId = AccountLeadAssignment.getAssignedUserIdByLanguage(language);
            return assignedUserId;
        }

        assignedUserId = AccountLeadAssignment.getAssignedUserIdByAssignmentType(origin, postalCode);

        return assignedUserId;
    }

}