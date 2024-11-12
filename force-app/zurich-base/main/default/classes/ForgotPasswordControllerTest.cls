/**
 * An apex page controller that exposes the site forgot password functionality
 */
@IsTest
public with sharing class ForgotPasswordControllerTest
{
    @IsTest
    public static void testForgotPasswordController()
    {
        String username = TestDataFactory.getRandomUsername();
        // Instantiate a new controller with all parameters in the page
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = username;

        System.assertEquals(controller.forgotPassword(), null);
    }
}