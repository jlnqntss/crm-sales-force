/**
 * @description       : Clase test para la clase TaskUtil
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-03-2023
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class TaskUtilTest
{
    @testSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        Account portalAccount = new Account();
        portalAccount.Name = 'TestAccount';
        accounts.add(portalAccount);
        insert accounts;

        Contact contactPortal = new Contact ();
        contactPortal.FirstName = 'Test';
        contactPortal.LastName = 'McTesty';
        contactPortal.AccountId = portalAccount.Id;
        insert contactPortal;

        Profile profile = [SELECT Id FROM Profile WHERE Name='OCS Community User' LIMIT 1];
        String profileId= profile.Id;
        List<User> ocsUser =TestDataFactory.generateUsersByProfile(profileId, 1);
        ocsUser[0].ContactId = contactPortal.Id;
        insert ocsUser;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        insert campaigns;

        List<Account> personAccounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null AND Name != 'TestAccount']);
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(personAccounts, campaigns, 'Subscribed');
        insert campaignMembers;
    }

    /*
     * Test que comprueba que al crear una tarea cuyo owner sea un usuario de la comunidad de ocs se crea con el valor public a true
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_createTaskOwnerCommunity()
    {
        User userCommunity = [Select id from User where profile.name = 'OCS Community User' and isActive = true limit 1 ];
        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        taskToCreate.OwnerId = userCommunity.Id;

        Test.startTest();
        insert taskToCreate;
        Test.stopTest();

        Task taskAfterInsert = [Select id, IsVisibleInSelfService from Task where id =: taskToCreate.id ];
        System.assertEquals(true, taskAfterInsert.IsVisibleInSelfService, 'No se ha actualizado el valor public de la tarea correctamente');
    }

    /*
     * Test que comprueba que al actualizar una tarea cuyo owner sea un usuario de la comunidad de ocs se crea con el valor public a true
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_updateTaskOwnerCommunity()
    {
        User userCommunity = [Select id from User where profile.name = 'OCS Community User' and isActive = true limit 1 ];

        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        insert taskToCreate;

        Task taskAfterInsert = [Select id, IsVisibleInSelfService, OwnerId from Task where id =: taskToCreate.id ];
        System.assertEquals(false, taskAfterInsert.IsVisibleInSelfService, 'El valor public de la tarea debería ser falso');

        Test.startTest();
        taskToCreate.OwnerId = userCommunity.Id;
        update taskToCreate;
        Test.stopTest();

        Task taskAfterUpdate = [Select id, IsVisibleInSelfService, OwnerId from Task where id =: taskToCreate.id ];
        System.assertEquals(true, taskAfterUpdate.IsVisibleInSelfService, 'El valor public de la tarea debería ser verdadero');
    }

    /*
     * Test que comprueba que se borra una tarea correctamente
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_deleteTask()
    {
        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        insert taskToCreate;

        Test.startTest();
        delete taskToCreate;
        Test.stopTest();

        List<Task> taskAfterDelete = [Select id from Task];
        System.assertEquals(0, taskAfterDelete.size(), 'La tarea no debería existir');
    }
}