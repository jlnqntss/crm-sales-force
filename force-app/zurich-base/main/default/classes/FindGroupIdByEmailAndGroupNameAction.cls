/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : aberuete
**/
public class FindGroupIdByEmailAndGroupNameAction 
{
    public static Map<String,String> mapGroupNameAndGroupId = new Map<String,String>();

    @InvocableMethod
    (
        label='Find GroupId By Email And Group Name'
        description='Busca si el usuario es miembro del grupo dado y en caso afirmativo devuelve la id del grupo'
        category='Group'
    )

    public static List<FindGroupIdByEmailAndGroupNameResponse> findGroupIdByEmailAndGroupName (List<FindGroupIdByEmailAndGroupNameRequest> groupRequests)
    {
        List<FindGroupIdByEmailAndGroupNameResponse> results = new List<FindGroupIdByEmailAndGroupNameResponse>();

        List<GroupMember> groupMembers = new List<GroupMember>();
        List<String> groupNames = new List<String>();
        List<String> usersEmails = new List<String>();
        Map<String, Map<String,String>> mapCaseByUserEmailAndGroupName = new Map<String, Map<String,String>> ();

        if (groupRequests != null && !groupRequests.isEmpty())
        {
            for (FindGroupIdByEmailAndGroupNameRequest groupRequest :groupRequests)
            {
                Map<String,String> mapUserbyGroup = new Map<String,String> ();
                mapUserbyGroup.put(groupRequest.userEmail[0],groupRequest.groupName);
                groupNames.add(groupRequest.groupName);
                usersEmails.add(groupRequest.userEmail[0]);
                mapCaseByUserEmailAndGroupName.put (groupRequest.caseId,mapUserbyGroup);
            }

            groupMembers = new GroupMemberSelector().findByGroupNameAndEmailUser(groupNames, usersEmails);
            List<User> users = new UsersSelector().findByEmails(usersEmails);
            Map<String, List<String>> mapUserEmailAndGroupName = getmapUserEmailAndGroupName (users, groupMembers);
                
            for (String idCaso : mapCaseByUserEmailAndGroupName.keySet() )
            {
                FindGroupIdByEmailAndGroupNameResponse response = new FindGroupIdByEmailAndGroupNameResponse();
                String userEmailFromMapCase = mapCaseByUserEmailAndGroupName.get(idCaso).keySet().iterator().next(); 
                String groupNameFromMapCase = mapCaseByUserEmailAndGroupName.get(idCaso).get(userEmailFromMapCase);

                if (mapUserEmailAndGroupName.containsKey(userEmailFromMapCase) && mapUserEmailAndGroupName.get(userEmailFromMapCase).contains(groupNameFromMapCase) && mapGroupNameAndGroupId.containsKey(groupNameFromMapCase))
                {
                    response.groupId = mapGroupNameAndGroupId.get(groupNameFromMapCase);
                }
                else 
                {
                    response.groupId = '';
                }
                results.add(response);
            }
        }

        return results;
    }

    private static Map<String, List<String>>  getmapUserEmailAndGroupName (List<User> users,  List<GroupMember> groupMembers )
    {
        Map<String, List<String>> mapUserEmailAndGroupName = new Map<String, List<String>>();

        for (User user:users)
        {
            for (GroupMember groupMember :groupMembers)
            {
                if( !mapGroupNameAndGroupId.containsKey(groupMember.Group.DeveloperName) )
                {
                     mapGroupNameAndGroupId.put (groupMember.Group.DeveloperName, groupMember.GroupId);   
                }

                if (user.id == groupMember.UserOrGroupId )
                {
                    if( mapUserEmailAndGroupName.containsKey(user.Email) ) 
                    {
                        mapUserEmailAndGroupName.get(user.Email).add(groupMember.Group.DeveloperName);
                    } 
                    else 
                    {
                        mapUserEmailAndGroupName.put(user.Email,new List<String>{groupMember.Group.DeveloperName});
                    }
                }
            }
        }

        return mapUserEmailAndGroupName;
    }

    public class FindGroupIdByEmailAndGroupNameRequest 
    {
        @InvocableVariable (label = 'Case Id' description = 'Id del caso')
        public String caseId;

        @InvocableVariable (label = 'Group Name' description = 'Nombre del grupo')
        public String groupName;

        @InvocableVariable (label = 'User Email' description = 'Email del usuario')
        public List<String> userEmail;
    }

    public class FindGroupIdByEmailAndGroupNameResponse 
    {
        @InvocableVariable(label='Group Id' description='')
        public String groupId ;
    } 
}