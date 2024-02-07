/**
 * @description       : Clase selectora para el sobject Group
 * @author            : aberuete
 * @group             :
 * @last modified on  : 05-10-2023
 * @last modified by  : aberuete
 **/
public with sharing class GroupSelector extends RecordsSelector
{
    public GroupSelector()
    {
        super( Group.getSObjectType() );
    }

    /**
     * Método que recupera los grupos cuyo nombre coincida con uno dado
     *
     * @author aberuete
     * @date 10/05/2023
     *
     * @param {String nameGroup} nombre del grupo a filtrar
     */
    public List<Group> findByName (String nameGroup)
    {
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
        {
            Group.fields.Id
        };
        if (nameGroup != null)
        {
            this.baseQuery.selectFields(fieldList)
            .addConditionEq(Group.fields.Name, nameGroup);
            return (List<Group>) this.baseQuery.run();
        }

        return new List<Group>();
    }


    /**
     * Método que recupera los grupos cuyo nombre coincida con el developer name
     *
     * @author dmunoz
     * @date 12/06/2023
     *
     * @param {String nameGroup} nombre del grupo a filtrar
     */
    public Map<Id, Group> findPublicGroupByDeveloperName(List<String> groupsDeveloperName)
    {

        Map<Id, Group> result = new Map<Id, Group>();

        if( groupsDeveloperName != null && !groupsDeveloperName.isEmpty() )
        {
            result = new Map<Id, Group>([
                                            SELECT Id FROM Group WHERE DeveloperName IN: groupsDeveloperName AND type = 'regular'
                                        ]);
        }
        return result;
    }

    /**
     * Método que recupera los miembros de grupo de un usuario con excepción de aquellos con tipo Queue y los que indica la metadata, si hay resultados se eliminarán
     *
     * @author dmunoz
     * @date 12/06/2023
     *
     * @param {String nameGroup} nombre del grupo a filtrar
     */
    public List<GroupMember> findUserNotQueueGroupsNotInMetadata(Id userId, List<Id> mtdGroupIds)
    {

        List<GroupMember> result = new List<GroupMember>();

        result = new List<GroupMember>([
                                           SELECT GroupId FROM GroupMember WHERE GroupId != null AND userOrGroupId = : userId AND Group.Type != 'Queue' AND GroupId NOT IN: mtdGroupIds
                                       ]);

        return result;
    }

    /**
     * Método que recupera los miembros de grupo de un usuario con excepción de aquellos con tipo Queue, se usa en login comunidad para insertar nuevos grupos si es necesario
     *
     * @author dmunoz
     * @date 12/06/2023
     *
     * @param {String nameGroup} nombre del grupo a filtrar
     */
    public List<GroupMember> findUserNotQueueGroups(Id userId)
    {

        List<GroupMember> result = new List<GroupMember>();

        result = new List<GroupMember>([
                                           SELECT GroupId FROM GroupMember WHERE GroupId != null AND userOrGroupId = : userId AND Group.Type != 'Queue'
                                       ]);

        return result;
    }

    /**
     * Método que recupera un grupo o grupos a partir de una lista de Ids
     * @author nts - jfherrero
     * @date 30/01/2024
     * @param {String groupId} Ids de los grupos a recuperar
     */
    public List<Group> findById(List<Id> groupId)
    {
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
        {
            Group.fields.Id,
            Group.fields.Type,
            Group.fields.Name,
            Group.fields.DeveloperName
        };

        if (groupId?.size() > 0)
        {
            this.baseQuery.selectFields(fieldList)
            .addConditionIn(Group.fields.Id, groupId);

            return (List<Group>) this.baseQuery.run();
        }

        return new List<Group>();
    }
}