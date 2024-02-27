/**
**
* @author lrodriguez
* @date 07/03/2023
*/
public with sharing class AccountTeamMemberUtil 
{
    /**
     * Método que actualiza el intermedario relacionado con el Account Team Member, según su Rol
     * @author lrodriguez6@seidor.es
     * @date 07/03/2023
     * @param AccountTeamMembers + @param String + @param User 
     */

    public static void updateIntermediaryWithAccountTeamMembersName(Account intermediary,String fieldToUpdate, User u)
    {
        intermediary.put(fieldToUpdate,u.Name);
    }

    /**
     * Método que vacia el campo del intermediario relacionado con el Account Team Member, según su rol
     * @author lrodriguez6@seidor.es
     * @date 07/03/2023
     * @param Account Team Members + @param String
     */

    public static void emptyIntermediaryWithAccountTeamMembersName(Account intermediary,String fieldToUpdate)
    {
        intermediary.put(fieldToUpdate,null);
    }


    /**
     * Método que crea una lista de registros de atm para un n usuarios y un account
     * @author dmunoz
     * @date 12/02/2024
     * 
     */
    public static List<AccountTeamMember> createATMZRMRecordList(Id accountId, List<User> userList) {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        AccountTeamMember atm;

        if (userList != null && !userList.isEmpty()) {
            for (User user: userList) {
                atm = new AccountTeamMember();
                atm.AccountId = accountId;
                atm.UserId = user.Id;
                atm.TeamMemberRole = 'MediadorZRM';
                atm.AccountAccessLevel = 'Edit';
                atm.ContactAccessLevel = 'Read';
                atm.OpportunityAccessLevel = 'None';
                atm.CaseAccessLevel = 'None';
                result.add(atm);    
            }
        }

        return result;
    }


    /**
     * Método que crea una lista de registros de atm para un n usuarios y un account
     * @author dmunoz
     * @date 12/02/2024
     * 
     */
    public static List<AccountTeamMember> createATMZRMRecordList(Id accountId, List<String> userList) {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        AccountTeamMember atm;

        if (userList != null && !userList.isEmpty()) {
            for (String userId: userList) {
                atm = new AccountTeamMember();
                atm.AccountId = accountId;
                atm.UserId = userId;
                atm.TeamMemberRole = 'MediadorZRM';
                atm.AccountAccessLevel = 'Edit';
                atm.ContactAccessLevel = 'Read';
                atm.OpportunityAccessLevel = 'None';
                atm.CaseAccessLevel = 'None';
                result.add(atm);    
            }
        }
        return result;
    }

    /**
     * Método que a partir de una lista de atm, le cambia el user id para clonar
     * @author dmunoz
     * @date 12/02/2024
     * 
     */
    public static List<AccountTeamMember> cloneUserATMZRMRecordList(List<AccountTeamMember> atmToClone, String userId) {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        AccountTeamMember atmCloned;

        if (atmToClone != null && !atmToClone.isEmpty() && String.isEmpty(userId)) {
            for (AccountTeamMember atm: atmToClone) {
                atmCloned = new AccountTeamMember();
                atmCloned.AccountId = atm.AccountId;
                atmCloned.UserId = userId;
                atmCloned.TeamMemberRole = 'MediadorZRM';
                atmCloned.AccountAccessLevel = 'Edit';
                atmCloned.ContactAccessLevel = 'Read';
                atmCloned.OpportunityAccessLevel = 'None';
                atmCloned.CaseAccessLevel = 'None';
                result.add(atmCloned);    
            }
        }
        return result;
    }

    /**
     * Método que crea atm para un usuario y un account de ZRM
     * @author dmunoz
     * @date 12/02/2024
     * 
     */
    public static AccountTeamMember createATMZRMRecord(String accountId, String userId) {
        AccountTeamMember result = new AccountTeamMember();

        if (String.isNotEmpty(accountId) && String.isNotEmpty(userId)) {
            
            result.AccountId = accountId;
            result.UserId = userId;
            result.TeamMemberRole = 'MediadorZRM';
            result.AccountAccessLevel = 'Edit';
            result.ContactAccessLevel = 'Read';
            result.OpportunityAccessLevel = 'None';
            result.CaseAccessLevel = 'None';
        }
        
        return result;
    }

}