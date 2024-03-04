/**
 * @description       : Clase de test para la clase selectora del sobject Group
 * @author            : aberuete
 * @group             :
 * @last modified on  : 05-10-2023
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class GroupSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Group> groupToInsert = new List<Group>();
        Group queue = new Group (Name = 'Grupo_De_Prueba',Type = 'Queue' );
        Group regularGroup = new Group (Name = 'Grupo_De_Prueba2',Type = 'regular' );

        groupToInsert.add(queue);
        groupToInsert.add(regularGroup);
        insert groupToInsert;
    }

    /**
     * Test que comprueba que se obtiene correctamente el grupo por su nombre
     */
    @isTest
    static void test_findByName()
    {
        Group queueQuery = [Select id from Group where Name = 'Grupo_De_Prueba'];

        Test.startTest();
        List<Group> queueResult = new GroupSelector().findByName ('Grupo_De_Prueba');
        List<Group> queueResultNull = new GroupSelector().findByName(null);
        Test.stopTest();

        System.assertEquals(queueQuery.Id, queueResult[0].Id, 'Ambas ids deben ser iguales');
        System.assertEquals(false, queueResult.isEmpty(), 'Debería haber encontrado al menos una cola');
        System.assertEquals(true, queueResultNull.isEmpty(), 'Debería ser una lista vacía');
    }

    @isTest
    static void testFindPublicGroupByDeveloperName()
    {
        List<Group> queryList = new List<Group>([
                                                    SELECT Id, DeveloperName FROM Group WHERE type = 'regular' LIMIT 1
                                                ]);

        if ( !queryList.isEmpty() )
        {
            List<String> groupsDeveloperName = new List<String>();
            groupsDeveloperName.add(queryList.get(0).DeveloperName);
            Map<Id, Group> result = new GroupSelector().findPublicGroupByDeveloperName(groupsDeveloperName);

            System.assertEquals(true, !result.isEmpty(), 'Debe encontrar resultados');
        }
    }


    @isTest
    static void testFindUserNotQueueGroupsNotInMetadata()
    {
        List<Group> queryList = new List<Group>([
                                                    SELECT Id FROM Group WHERE type = 'Queue' LIMIT 1
                                                ]);

        if ( !queryList.isEmpty() )
        {
            User u = [SELECT Id FROM User LIMIT 1];
            List<Id> groupIdList = new List<Id>();
            groupIdList.add(queryList.get(0).Id);

            List<GroupMember> result = new GroupSelector().findUserNotQueueGroupsNotInMetadata(u.Id, groupIdList);

            System.assertEquals(true, result.isEmpty(), 'No debe encontrar resultados');
        }
    }


    @isTest
    static void testfindUserNotQueueGroups()
    {

        User u = [SELECT Id FROM User LIMIT 1];

        List<GroupMember> result = new GroupSelector().findUserNotQueueGroups(u.Id);

        System.assertEquals(true, result.isEmpty(), 'No debe encontrar resultados');

    }

    /**
     * Prueba para recuperar un grupo o grupos a partir de una lista de Ids
     * @author nts - jfherrero
     * @date 30/01/2024
     */
    @isTest
    static void testFindById()
    {

        List<Group> queryGroups = [SELECT Id FROM Group];
        List<Id> groupIds = new List<Id>();

        for (Group queue : queryGroups)
        {
            groupIds.add(queue.Id);
        }

        Test.startTest();

        List<Group> queueResult = new GroupSelector().findById(groupIds);
        List<Group> queueResultNull = new GroupSelector().findById( new List<Id>() );
        Test.stopTest();

        queueResult.sort();
        queryGroups.sort();

        System.assertEquals(queryGroups[0].Id, queueResult[0].Id, 'Ambas ids deben ser iguales');
        System.assertEquals(false, queueResult.isEmpty(), 'Debería haber encontrado al menos una cola');
        System.assertEquals(true, queueResultNull.isEmpty(), 'Debería ser una lista vacía');

    }
}