/**
 * @description       : Trigger para el objeto Social Post
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : aberuete
**/
trigger SprinklrSocialPostTrigger on spr_sf__SocialPost__c (after insert, before insert, after update, before update, after delete, before delete) 
{
    TriggerFactory.createHandler(spr_sf__SocialPost__c.sObjectType);
}