/**
 * @description       : Clase de test para la clase selectora del objeto Sprinklr Social Persona
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : aberuete
**/
@isTest
private with sharing class SprinklrSocialPersonaSelectorTest 
{
    /*
     * Test del método que comprueba que obtiene correctamente los perfiles sociales filtrados por id
     * @author aberuete
     * @date 06/03/2024
     */
    @isTest
    private static void test_findAllDataById()
    {
        spr_sf__SocialPersona__c sprSocialPersona = new spr_sf__SocialPersona__c (Name = 'prueba social persona1');
        insert sprSocialPersona;
        
        Test.startTest();
        List<spr_sf__SocialPersona__c> sprSocialPersonaReturn = new SprinklrSocialPersonaSelector().findAllDataById(new Set<String> {sprSocialPersona.id});
        Test.stopTest();

        System.assertEquals (1, sprSocialPersonaReturn.size(), 'La lista debería contener un social persona');
        System.assertEquals ('prueba social persona1', sprSocialPersonaReturn[0].Name, 'El nombre de la social persona no es correcto');
    } 

    /*
     * Test del método que comprueba que al darle una lista vacía para obtener los perfiles sociales filtrados por id devuelve otra lista vacía
     * @author aberuete
     * @date 06/03/2024
     */
    @isTest
    private static void test_findAllDataByIdNull()
    {
        Test.startTest();
        List<spr_sf__SocialPersona__c> sprSocialPersonaReturn = new SprinklrSocialPersonaSelector().findAllDataById(new Set<String> {});
        Test.stopTest();

        System.assertEquals (true, sprSocialPersonaReturn.isEmpty(), 'La lista debería estar vacía');
    }    
}