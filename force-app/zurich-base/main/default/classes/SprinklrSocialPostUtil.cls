/**
 * @description       : Clase Util para el objeto spr_sf__SocialPost__c
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : aberuete
**/
public with sharing class SprinklrSocialPostUtil 
{
    public static List<Case> casesToUpdate = new List<Case>();

    /**
     * Método que obtiene una lista de los casos relacionados al social post para actualizar
     * enlazando la social persona asociada al social post. 
     * 
     * @author aberuete
     * @date 13/02/2024
     * 
     * @param {List<spr_sf__SocialPost__c> socialPosts} Lista de social post para obtener 
     *                                                  los casos relacionados a actualizar
     */
    public static void updateCaseToLinkSocialPerson(List<spr_sf__SocialPost__c> socialPosts)
    {
        Map<Id, Case> casesLinkToSocialPost = new Map<Id, Case>();
        Set<String> caseIds = new Set<String>();
        List<spr_sf__SocialPost__c> socialPostsToUpdateCase = new List<spr_sf__SocialPost__c> ();

        if (Trigger.isAfter && Trigger.isInsert)
        {
            for (spr_sf__SocialPost__c socialPost : socialPosts)
            {
                if (socialPost.spr_sf__Case__c != null && socialPost.spr_sf__SocialPersona__c != null )
                {
                    caseIds.add(socialPost.spr_sf__Case__c);
                    socialPostsToUpdateCase.add(socialPost);   
                }
            }
    
            casesLinkToSocialPost = new Map<Id,Case> (new CasesSelector().findAllDataById(caseIds));
    
            for (spr_sf__SocialPost__c socialPostToUpdateCase : socialPostsToUpdateCase)
            {
                Case caseToUpdate = casesLinkToSocialPost.get(socialPostToUpdateCase.spr_sf__Case__c);
                
                if (caseToUpdate.SprinklrSocialPersona__c == null)
                {
                    caseToUpdate.SprinklrSocialPersona__c = socialPostToUpdateCase.spr_sf__SocialPersona__c;
                    casesToUpdate.add(caseToUpdate);
                }
            }
        }
    }

    /**
     * Método que actualiza los casos relacionados con los social post para enlazar la social persona. 
     * 
     * @author aberuete
     * @date 13/02/2024
     * 
     */
    public static void updateCasesRelatedToSocialPost()
    {
        List<String> msgErrores = new List<String>();

        if( !casesToUpdate.isEmpty() )
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(casesToUpdate, false);
                
                for (Database.SaveResult result: resultList )
                {
                    if(!result.isSuccess())
                    {
                        for (Database.Error error :result.getErrors())
                        {
                            msgErrores.add(error.getStatusCode() + ': ' + error.getMessage());
                        }
                    }
                }   
                if (!msgErrores.isEmpty())
                {
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando los casos relacionados con los social post',SprinklrSocialPostUtil.class.getName(),(String.join(msgErrores,'\n')));
                } 
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError(e, SprinklrSocialPostUtil.class.getName());
            }
        }
    }

}