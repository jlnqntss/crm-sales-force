/**
 * @description       : Clase selectora del sobject group member
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : aberuete
**/
public with sharing class GroupMemberSelector extends RecordsSelector 
{
    public GroupMemberSelector() 
    {
        super(GroupMember.getSObjectType());
    }

    public static final String FIELD_GROUP_NAME = 'GroupMember.Group.DeveloperName';

     /**
     * Recupera los miembros de grupo que coindica el usuario con un email dado para un grupo dado
     *
     * @author aberuete
     * @date 25/10/2023
     *
     * @param {List<String> nameGroup} Lista de nombre de grupos
     * @param {List<String> emailUser} Lista de emails de usuario
     * @return {List<GroupMember>} lista de miembros de grupo
     */
    public List<GroupMember> findByGroupNameAndEmailUser (List<String> nameGroup, List<String> emailUser)
    {
        Query subquery = new Query (User.getSObjectType());
        subquery.selectFields((new List<Schema.SObjectField> {
            User.Id
        }));
        subquery.addConditionIn(User.Email, emailUser);

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
        {
            GroupMember.GroupId,
            GroupMember.UserOrGroupId
        }
        )
        .selectFields('Group.DeveloperName')
        .addConditionIn(FIELD_GROUP_NAME, nameGroup)
        .addConditionIn(GroupMember.UserOrGroupId, subquery)
        .enforceSecurity(true);

        return (List<GroupMember>) this.baseQuery.run();
    }
}