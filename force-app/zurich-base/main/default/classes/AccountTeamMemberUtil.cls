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
}