/**
 * Clase de utilidad para la entidad CampaignMember
 * @author rlopez
 * @date 21/12/2020
 */
public with sharing class CampaignMemberUtil
{
    /**
     * Método que recupera y elimina los miembros de campaña marcados con Status = "Delete"
     *
     * Se llama desde: DeletedCampaignMemberSchedulableJob
     *
     * @author rlopez
     * @date 21/12/2020
     */
    public static void deleteMembers()
    {
        try
        {
            List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
            if( !deletedMembers.isEmpty() )
            {
                delete deletedMembers;
            }
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_CRITICAL, ex.getMessage(), 'CampaignMemberUtil');
        }
    }
}