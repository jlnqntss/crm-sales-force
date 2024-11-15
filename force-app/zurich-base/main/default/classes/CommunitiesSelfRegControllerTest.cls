/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@IsTest public with sharing class CommunitiesSelfRegControllerTest
{
    @IsTest
    public static void testCommunitiesSelfRegController()
    {
        String firstName = TestDataFactory.getRandomString(9);
        String lastName = TestDataFactory.getRandomString(9);
        String email = TestDataFactory.getRandomUsername();
        String nickname = TestDataFactory.getRandomString(4);
        
        String password1 = TestDataFactory.getRandomString(6);
        String password2 = TestDataFactory.getRandomString(5);
        
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = firstName;
        controller.lastName = lastName;
        controller.email = email;
        controller.communityNickname = nickname;

        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert (controller.registerUser() == null);

        controller.password = password1;
        controller.confirmPassword = password2;
        System.assert (controller.registerUser() == null);
    }
}