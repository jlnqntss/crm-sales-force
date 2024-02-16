/**
 * @description       : Test para la clase SprinklrSocialPostUtil
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : aberuete
**/
@isTest
private with sharing class SprinklrSocialPostUtilTest 
{
    @testSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        //se crea 1 caso para cada cuenta
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        spr_sf__SocialPersona__c socialPersona = new spr_sf__SocialPersona__c (Name = 'SocialPersonaEjemplo');
        insert socialPersona;        
    }

     /**
     * Test que comprueba que se actualiza correctamente el caso asociado al social post enlazando la social persona
     * @author aberuete
     * @date 13/02/2024
     */
    @isTest 
    private static void test_updateCaseToLinkSocialPerson()
    {
        List<Case> listCases = [Select id,SprinklrSocialPersona__c from Case limit 1];
        System.assertEquals (null, listCases[0].SprinklrSocialPersona__c, 'El caso no debería tener ningun social persona asociado');
        spr_sf__SocialPersona__c socialPersonaToCase = [Select id from spr_sf__SocialPersona__c where name = 'SocialPersonaEjemplo' ];

        Test.startTest();
        spr_sf__SocialPost__c socialPost = new spr_sf__SocialPost__c 
        (
            spr_sf__Case__c = listCases[0].id,
            spr_sf__SocialPersona__c = socialPersonaToCase.id
        );
        insert socialPost;
        Test.stopTest();

        Case caseUpdated = [Select id,SprinklrSocialPersona__c from Case where id =:listCases[0].id ];

        System.assertEquals(socialPersonaToCase.id ,SprinklrSocialPostUtil.casesToUpdate[0].SprinklrSocialPersona__c, 'La social persona asociada al caso no es correcta');
        System.assertEquals(listCases[0].id , SprinklrSocialPostUtil.casesToUpdate[0].id, 'El caso ha actualizar no es correcto');
        System.assertEquals (caseUpdated.SprinklrSocialPersona__c, socialPersonaToCase.id, 'El caso no se ha actualizado correctamente' );
    }

     /**
     * Test que comprueba que se borra correctamente un social post
     * @author aberuete
     * @date 13/02/2024
     */
    @isTest 
    private static void test_deleteSocialPost()
    {
        List<Case> listCases = [Select id from Case limit 1];
        spr_sf__SocialPost__c socialPost = new spr_sf__SocialPost__c 
        (
            spr_sf__Case__c = listCases[0].id
        );
        insert socialPost;

        String idSocialPost = socialPost.id;

        Test.startTest();
        delete socialPost;
        Test.stopTest();

        List<spr_sf__SocialPost__c> socialPostDeleted = [Select id from spr_sf__SocialPost__c where id =:idSocialPost];

        System.assertEquals(0, socialPostDeleted.size(), 'El social post no debería existir');
    }

    /**
     * Test que comprueba que se actualiza correctamente un social post
     * @author aberuete
     * @date 13/02/2024
     */
    @isTest 
    private static void test_updateSocialPost()
    {
        List<Case> listCases = [Select id from Case limit 1];
        spr_sf__SocialPersona__c socialPersonaToCase = [Select id from spr_sf__SocialPersona__c where name = 'SocialPersonaEjemplo' ];
        
        spr_sf__SocialPost__c socialPost = new spr_sf__SocialPost__c 
        (
            spr_sf__Case__c = listCases[0].id
        );
        insert socialPost;


        Test.startTest();
        socialPost.spr_sf__SocialPersona__c = socialPersonaToCase.id;
        update socialPost;
        Test.stopTest();

        List<spr_sf__SocialPost__c> socialPostUpdated = [Select id,spr_sf__SocialPersona__c from spr_sf__SocialPost__c where id =:socialPost.id];

        System.assertEquals(socialPersonaToCase.id, socialPostUpdated[0].spr_sf__SocialPersona__c, 'El social post no se ha actualizado correctamente');
    }
}