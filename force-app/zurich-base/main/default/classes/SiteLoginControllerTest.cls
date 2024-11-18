/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest
global with sharing class SiteLoginControllerTest
{
    @IsTest
    global static void testSiteLoginController()
    {
        String username = TestDataFactory.getRandomUsername();
        String password = TestDataFactory.getRandomString(6);
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController();
        controller.username = username;
        controller.password = password;

        System.assertEquals(controller.login(), null);
    }
}