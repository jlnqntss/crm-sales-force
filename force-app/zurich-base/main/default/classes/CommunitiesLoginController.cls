/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class CommunitiesLoginController
{
    public static final List<String> trustedDomains = new List<String>
    {
        'zurich-es--qa.sandbox.my.salesforce-sites.com',
        'zurich-es--qa.sandbox.my.site.com',
        'zurich-es.my.salesforce-sites.com',
        'zurich-es.my.site.com'
    };

    global CommunitiesLoginController ()
    {}

    // Code we will invoke on page load.
    global PageReference forwardToAuthPage()
    {
        try 
        {
            String startUrl = System.currentPageReference().getParameters().get('startURL');
            Set<String> trustedDomainsSet = new Set<String>(trustedDomains);

            if(startUrl != null && String.isNotEmpty(startUrl))
            {
                if(trustedDomainsSet.contains(startUrl))
                {
                    String displayType = System.currentPageReference().getParameters().get('display');
                    return Network.forwardToAuthPage(startUrl, displayType);
                }
            }
        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ex, 'CommunitiesLoginController');
        }
        
        return null;
    }
}