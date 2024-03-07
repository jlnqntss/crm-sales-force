/**
 * @description       : Clase selectora para el objeto Sprinklr Social Persona
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : aberuete
**/
public with sharing class SprinklrSocialPersonaSelector extends RecordsSelector 
{
    public SprinklrSocialPersonaSelector() 
    {
        super(spr_sf__SocialPersona__c.getSObjectType());
    }

    /**
     * Método que obtiene una lista de perfiles sociales filtradas por id
     * @author aberuete
     * @param Set<String> sprSocialPersonaIds : Conjunto de ids de perfiles sociales para obtener sus datos
     * @date 06/03/2024
    */
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