/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 04-03-2024
 * @last modified by  : aberuete
**/
public with sharing class SprinklrSocialPersonaSelector extends RecordsSelector 
{
    public SprinklrSocialPersonaSelector() 
    {
        super(spr_sf__SocialPersona__c.getSObjectType());
    }

    public List<spr_sf__SocialPersona__c> findAllDataById(Set<String> sprSocialPersonaIds)
    {
        if (sprSocialPersonaIds != null && !sprSocialPersonaIds.isEmpty())
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionIn(spr_sf__SocialPersona__c.Id,sprSocialPersonaIds);
            return (List<spr_sf__SocialPersona__c>) this.baseQuery.run(); 
        } 
        else
        {
            return new List<spr_sf__SocialPersona__c>();   
        }
    }
}