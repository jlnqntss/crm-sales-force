/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class CommunitiesLoginController
{

    global CommunitiesLoginController ()
    {}

    // Code we will invoke on page load.
    global PageReference forwardToAuthPage()
    {
        try 
        {
            String startUrl = System.currentPageReference().getParameters().get('startURL');

            if(startUrl != null && String.isNotEmpty(startUrl))
            {
                String displayType = System.currentPageReference().getParameters().get('display');
                return Network.forwardToAuthPage(startUrl, displayType);
            }
        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ex, 'CommunitiesLoginController');
        }
        
        return null;
    }
}