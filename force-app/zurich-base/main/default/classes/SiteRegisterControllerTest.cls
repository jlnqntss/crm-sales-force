/**
 * Class containing tests for SiteRegisterController
 */
@IsTest
public with sharing class SiteRegisterControllerTest
{
    @IsTest
    static void testRegistration()
    {
        String username = TestDataFactory.getRandomUsername();
        String nickname = TestDataFactory.getRandomString(4);
        String password = TestDataFactory.getRandomString(6);
        String confirmPassword = TestDataFactory.getRandomString(5);
        
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = username;
        controller.email = username;
        controller.communityNickname = nickname;
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert (controller.registerUser() == null);

        controller.password = password;
        controller.confirmPassword = confirmPassword;
        System.assert (controller.registerUser() == null);
    }
}