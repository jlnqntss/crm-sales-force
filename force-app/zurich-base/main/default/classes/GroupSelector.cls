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
        super(Group.getSObjectType());
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
}