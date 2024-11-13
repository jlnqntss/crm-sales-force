/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class CommunitiesLoginControllerTest
{
    @IsTest
    global static void testCommunitiesLoginController ()
    {
        PageReference page = Page.CommunitiesLogin;
        page.getParameters().put('startURL', TestDataFactory.getRandomString(4));
        
        Test.startTest();
        CommunitiesLoginController controller = new CommunitiesLoginController();
        
        PageReference result1 = controller.forwardToAuthPage();
        
        Test.setCurrentPage(page);
        
        PageReference result2 = controller.forwardToAuthPage();
        
        Test.stopTest();
        
        System.assertEquals( null, result1 );
        System.assertEquals( null, result2 );
    }
}