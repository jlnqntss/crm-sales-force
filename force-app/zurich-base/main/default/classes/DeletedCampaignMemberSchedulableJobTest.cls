/**
 * Clases de test para DeletedCampaignMemberSchedulableJob
 * @author rlopez
 * @date 21/12/2020
 */
@isTest(SeeAllData=false)
private with sharing class DeletedCampaignMemberSchedulableJobTest
{
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        insert campaigns;

        List<CampaignMemberStatus> currentStatuses = [SELECT Id, Label, SortOrder FROM CampaignMemberStatus];

        List<CampaignMemberStatus> newStatuses = new List<CampaignMemberStatus>();
        for(Campaign campaign: campaigns)
        {
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='New',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=4
                    )
                );
            newStatuses.add(
                new CampaignMemberStatus(
                    CampaignID=campaign.Id,
                    Label='Delete',
                    IsDefault=false,
                    HasResponded=false,
                    SortOrder=5
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
    static void test_execute_bulk_ok()
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
        String jobId = System.schedule(
            'ScheduledApexTest',
            CRON_EXP,
            new DeletedCampaignMemberSchedulableJob()
            );
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
    static void test_execute_ok()
    {
        //Recuperamos CampaignMembers para marcarlos con Status = Delete
        List<CampaignMember> campaignMembersToUpdate = [SELECT Id, Status, CampaignId FROM CampaignMember];
        System.assertEquals(false, campaignMembersToUpdate.isEmpty(), 'List should NOT be empty');

        campaignMembersToUpdate.get(0).Status = 'Delete';

        update campaignMembersToUpdate;

        Test.startTest();
        String jobId = System.schedule(
            'ScheduledApexTest',
            CRON_EXP,
            new DeletedCampaignMemberSchedulableJob()
            );
        Test.stopTest();

        //Comprobamos que se han eliminado todos los miembros de campaña
        List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
        System.assertEquals(true, deletedMembers.isEmpty(), 'There should not be any CampaignMember with status "Delete"');

        //Comprobamos que SOLO hemos borrado un miembro de campaña
        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');
    }
}