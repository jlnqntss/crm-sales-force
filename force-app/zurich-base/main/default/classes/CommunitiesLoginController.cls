/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class CommunitiesLoginController
{

    //Se pueden ir ampliando las URLs de confianza para blindar más la recogida de datos.
    //En caso necesario consultar con cliente
    global static final String VALID_URLS = 'zurich';
    global static final String MESSAGE_ERROR = 'Las URLs de redirección deben ser enlaces admitidos';

    global CommunitiesLoginController ()
    {}

    // Code we will invoke on page load.
    global PageReference forwardToAuthPage()
    {
        if(System.currentPageReference().getParameters().get('startURL').contains(VALID_URLS))
        {
            String startUrl = System.currentPageReference().getParameters().get('startURL');
            String displayType = System.currentPageReference().getParameters().get('display');    
            
            return Network.forwardToAuthPage(startUrl, displayType);
        }
        else
        {
            throw new AuthPageException(MESSAGE_ERROR);
        }           
    }

    private class AuthPageException extends Exception{}
}