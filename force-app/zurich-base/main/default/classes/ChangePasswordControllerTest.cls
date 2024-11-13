/**
 * An apex page controller that exposes the change password functionality
 */
@IsTest
public with sharing class ChangePasswordControllerTest
{
    @IsTest
    public static void testChangePasswordController()
    {
        // Instantiate a new controller with all parameters in the page
        String newPassword = TestDataFactory.getRandomString(6);
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = TestDataFactory.getRandomString(6);
        controller.newPassword = newPassword;
        controller.verifyNewPassword = newPassword;

        System.assertEquals(controller.changePassword(), null);
    }
}