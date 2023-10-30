/**
 * @description       : Clase de test para la clase selectora del sobject GroupMember
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : aberuete
**/
@isTest
private class GroupMemberSelectorTest 
{
    @TestSetup
    public static void createScenario()
    {
        //Crear Usuarios 
        List<Profile> profileUSP = [SELECT Id FROM Profile WHERE Name = 'USP User'];
        List<User> usersUSP = TestDataFactory.generateUsersByProfile(profileUSP[0].Id, 2);
        usersUSP[0].FirstName = 'testUser';
        usersUSP[0].IsActive = true;
        usersUSP[1].FirstName = 'testNotInGroup';
        usersUSP[1].IsActive = true;
        insert usersUSP;  

        // Crear grupo cola 
        Group queue = new Group (Name = 'Grupo_De_Prueba',Type = 'Queue' );
        insert queue;

        // Crear miembro del grupo
        GroupMember member = new GroupMember (GroupId =queue.id, UserOrGroupId = usersUSP[0].id );
        insert member;
    }

     /**
     * Test del metodo que comprueba que se obtiene correctamente el miembro de un grupo dado el email de usuario y el nombre del grupo
     * 
     * @author aberuete
     * @date 25/10/2023
     */
    @isTest
    static void findByGroupNameAndEmailUser() 
    {
        User testUSer = [Select id,email from User where name like '%testUser%' limit 1];
        User testNotInGroup = [Select id,email from User where name like '%testNotInGroup%' limit 1];
        Group groupTest = [Select id from Group where name = 'Grupo_De_Prueba' limit 1];
        List<String> emailList = new List<String>();
        emailList.add(testUSer.email);
        emailList.add(testNotInGroup.email);

        Test.startTest();
        List<GroupMember> groupMembers = new GroupMemberSelector().findByGroupNameAndEmailUser(new List<String>{'Grupo_De_Prueba'}, emailList);
        Test.stopTest();

        System.assertEquals(1,groupMembers.size(),'El número de miembros del grupo no es correcto');
        System.assertEquals(groupTest.id,groupMembers[0].groupId, 'La id del grupo no es correcta');
        System.assertEquals(testUSer.id,groupMembers[0].UserOrGroupId, 'El usuario del grupo no es correcto');
    }
}