global class DeletedCampaignMemberSchedulableJob implements Schedulable
{
    global void execute(SchedulableContext SC)
    {
        CampaignMemberUtil.deleteMembers();
    }
}