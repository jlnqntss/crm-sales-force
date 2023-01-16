global class DeletedCampaignMemberSchedulableJob implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        CampaignMemberUtil.deleteMembers();
    }
}