/**
 * @description       : Clase de test para la acción FindGroupIdByEmailAndGroupNameAction
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class FindGroupIdByEmailAndGroupNameActionTest 
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
     * Comprueba que la acción invocable recupera correctamente el group id del grupo al que pertenece el usuario
     * 
     * @author aberuete
     * @date 25/10/2023
     */
    @isTest
    static void findGroupIdByEmailAndGroupName() 
    {
        List<String> emailList = new List<String> ();
        User userTest= [Select id, email from User where IsActive = true and name like '%testUser%' limit 1];
        Group groupTest = [Select id from Group where name = 'Grupo_De_Prueba' limit 1];
        emailList.add(userTest.email);

        // Crear caso
        Case caseTest = new Case (Subject = 'Caso prueba');
        insert caseTest;

        Test.startTest();
        List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest> groupRequests = new List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest>();
        FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest groupRequest = new FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest();
        groupRequest.caseId = caseTest.id;
        groupRequest.groupName = 'Grupo_De_Prueba';
        groupRequest.userEmail = emailList;
        groupRequests.add(groupRequest);
        List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameResponse> groupIds = FindGroupIdByEmailAndGroupNameAction.findGroupIdByEmailAndGroupName(groupRequests);
        Test.stopTest();

        System.assertEquals(groupTest.id, groupIds[0].groupId, 'El group id devuelto no es correcto');
    }

    /**
     * Comprueba que la acción invocable devuelve el group id como vacío en caso que el usuario no pertenezca al grupo
     * 
     * @author aberuete
     * @date 25/10/2023
     */
    @isTest
    static void notFindGroupIdByEmailAndGroupName() 
    {
        List<String> emailList = new List<String> ();
        User userTest= [Select id, email from User where IsActive = true and name like '%testNotInGroup%' limit 1];
        emailList.add(userTest.email);

        // Crear caso
        Case caseTest = new Case (Subject = 'Caso prueba');
        insert caseTest;

        Test.startTest();
        List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest> groupRequests = new List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest>();
        FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest groupRequest = new FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameRequest();
        groupRequest.caseId = caseTest.id;
        groupRequest.groupName = 'Grupo_De_Prueba';
        groupRequest.userEmail = emailList;
        groupRequests.add(groupRequest);
        List<FindGroupIdByEmailAndGroupNameAction.FindGroupIdByEmailAndGroupNameResponse> groupIds = FindGroupIdByEmailAndGroupNameAction.findGroupIdByEmailAndGroupName(groupRequests);
        Test.stopTest();

        System.assertEquals(true, String.isEmpty(groupIds[0].groupId), 'El group id debería estar vacío');
    }
    
}