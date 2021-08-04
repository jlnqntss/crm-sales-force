/**
 * Clases de test para CampaignMemberUtilTest
 **
 * @author rlopez
 * @date 21/12/2020
 */
@isTest(SeeAllData=false)
private with sharing class CampaignMemberUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        insert campaigns;

        List<CampaignMemberStatus> newStatuses = new List<CampaignMemberStatus>();
        for(Campaign campaign: campaigns)
        {
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='New',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=5
                    )
                );
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='Delete',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=6
                    )
                );
        }

        insert newStatuses;

        // hotfix: obtener cuentas de tipo personales con el campo PersonContactId relleno
        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);

        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaigns, 'New');
        insert campaignMembers;

        Profile readOnlyProfile = [SELECT Id FROM Profile WHERE Name = 'Read Only'];
        List<User> users = TestDataFactory.generateUsersByProfile(readOnlyProfile.Id, 1);
        insert users;
    }

    /**
     * Método que comprueba que se eliminan todos los miembros de campaña con Status = Delete
     * al llamar a CampaignMemberUtil.deleteMembers
     *
     * @author rlopez
     * @date 21/12/2020
     */
    @isTest
    static void test_deleteMembers_bulk_ok()
    {
        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        for(CampaignMember member: campaignMembersToUpdate)
        {
            member.Status = 'Delete';
        }

        update campaignMembersToUpdate;

        Test.startTest();
        CampaignMemberUtil.deleteMembers();
        Test.stopTest();

        //Comprobamos que se han eliminado todos los miembros de campaña
        List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
        System.assertEquals(true, deletedMembers.isEmpty(), 'There should not be any CampaignMember with status "Delete"');

        //Comprobamos que hemos borrado todos los miembros de campaña
        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(true, currentCampaignMembers.isEmpty(), 'List should be empty');
    }

    /**
     * Método que comprueba que se eliminan todos los miembros de campaña con Status = Delete
     * al llamar a CampaignMemberUtil.deleteMembers
     *
     * @author rlopez
     * @date 21/12/2020
     */
    @isTest
    static void test_deleteMembers_ok()
    {
        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        campaignMembersToUpdate.get(0).Status = 'Delete';

        update campaignMembersToUpdate;

        Test.startTest();
        CampaignMemberUtil.deleteMembers();
        Test.stopTest();

        //Comprobamos que se han eliminado todos los miembros de campaña
        List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
        System.assertEquals(true, deletedMembers.isEmpty(), 'There should not be any CampaignMember with status "Delete"');

        //Comprobamos que SOLO hemos borrado un miembro de campaña
        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');
    }

    /**
     * Método que comprueba que se eliminan todos los miembros de campaña con Status = Delete
     * al llamar a CampaignMemberUtil.deleteMembers
     *
     * @author rlopez
     * @date 22/12/2020
     */
    @isTest
    static void test_deleteMembers_ko()
    {
        //Recuperamos el usuario Read Only para ejecutar el borrado y que falle
        Profile readOnlyProfile = [SELECT Id FROM Profile WHERE Name = 'Read Only'];
        List<User> userList  = [SELECT Id FROM User WHERE ProfileId =: readOnlyProfile.Id];
        System.assertEquals(false, userList.isEmpty(), 'List should NOT be empty');

        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        campaignMembersToUpdate.get(0).Status = 'Delete';
        update campaignMembersToUpdate;

        //Actualizamos la campaña del miembro que acabamos de actualizar
        //para que el owner sea el usuario Read Only y pueda encontrarlo en la query
        List<Campaign> campaignsToUpdate = [SELECT Id, OwnerId FROM Campaign WHERE Id =:campaignMembersToUpdate.get(0).CampaignId];
        System.assertEquals(false, campaignsToUpdate.isEmpty(), 'List should NOT be empty');

        campaignsToUpdate.get(0).OwnerId = userList.get(0).Id;
        update campaignsToUpdate;

        //Ejecutamos el test con el usuario Read Only
        System.runAs( userList.get(0) )
        {
            Test.startTest();
            CampaignMemberUtil.deleteMembers();
            Test.stopTest();

            //Comprobamos que NO se han eliminado todos los miembros de campaña
            List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
            System.assertEquals(false, deletedMembers.isEmpty(), 'There should be CampaignMembers with status "Delete"');

            //Comprobamos que se ha generado un registro de error
            List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
            System.assertEquals(false, errors.isEmpty(), 'List should NOT be empty');
        }
    }
}