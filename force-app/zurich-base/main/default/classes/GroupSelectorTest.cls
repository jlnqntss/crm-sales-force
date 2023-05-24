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
        Group queue = new Group (Name = 'Grupo_De_Prueba',Type = 'Queue' );
        insert queue;
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
}