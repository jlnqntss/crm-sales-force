/**
 * Class that is invoked by the LWC PreferenceCentreZE.
 *
 * The client (Personal Account -> Scope) arrives through the unsubscribe link to the site.
 *
 * From there, the client can subscribe or unsubscribe from
 * device and mobility communications or life communications.
 * 
 * This Class started from a copy of PreferenceCentreController class developed for Klinc
 *
 * @author nts (agonzalezisasi)
 * @date 15/12/2020
 * 
 */
public with sharing class PreferenceCentreZEController {  
    //#Region public classes
    
    // Constants
    private static final String UNSUBSCRIBED_SOURCE = 'Centro de preferencias';
    private static final String CONFIG_LOGO_KEY = 'PreferenceLogo';
    private static final String DEFAULT_LOGO_RESOURCE = 'zurich_ze_logo';

    /**
     * Get the logo url for the given scope
     * 
     * @author nts (agonzalezisasi)
     * @date 02/03/2021
     * @param {String scope} the scope
     * @return {string} the url of the logo as a static resource
     */
    @AuraEnabled(cacheable=true)
    public static String getLogoUrl( String scope )
    {
        String result = null;
        String logoResource = DEFAULT_LOGO_RESOURCE;

        // if there is an scope...
        if( String.isNotBlank(scope)) {
            // Get the key name composed by a fixed part (PreferenceLogo) and another part dependant from the scope
            String logoConfig = CONFIG_LOGO_KEY + scope.toUpperCase();

            // Get the name of the static resource configured for that scope
            List<AdminSetupParameter__mdt> settings = [
                SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :logoConfig
            ];
            if( !settings.isEmpty() ) {
                logoResource = settings[0].Value__c;
            }
        }

        // if there is a logo, get the static resouce
        if( String.isNotBlank(logoResource) ) {
            Pagereference page = PageReference.forResource(logoResource);
            if( page != null ) {
                result = page.getUrl();
                if( result.contains('?') ) {
                    result = result.subString(0, result.indexOf('?'));
                }
                result = Url.getSalesforceBaseUrl().toExternalForm() + result;
            }
        }

        return result;
    }
  
    /**
     * Get the order from the user to unsubscribe him from the Scope, represented by the hash id
     *
     * @author nts (agonzalezisasi)
     */
    @AuraEnabled
    public static void processRequest( String hashedId, Boolean hasOptedOutOfEmail ) 
    {
        // System.debug('- - - - - PreferenceCentreZEController.processRequest - - - - - ');
      
        // System.Debug('processRequest#hashedId: ' + hashedId);
        // System.Debug('processRequest#hasOptedOutOfEmail: ' + hasOptedOutOfEmail);
    
        // Ahora se intenta actualizar las preferencias del cliente
        if( String.isNotBlank(hashedId) ) {
            Scope__c scope = PreferenceCentreProcessController.getScopeData(hashedId);
    
            // System.Debug('scope:' + scope);
    
            if (scope != null) {
                // Se comprueba si la suscripción a comunicaciones ha cambiado
                if( hasOptedOutOfEmail && scope.HasOptedOutOfEmail__c == false ) {
                    //Se rellenan los campos de contacto a actualizar
                    Scope__c scopeUpdate = new Scope__c(Id= scope.Id);
                    scopeUpdate.HasOptedOutOfEmail__c = true;
                    // todo: this fields doesnt exist yet
                    //scopeUpdate.UnsubscribedDate__c = DateTime.now();
                    //scopeUpdate.UnsubscribedSource__c = UNSUBSCRIBED_SOURCE;

                    //Se actualza el contacto
                    ScopeUtil su = new ScopeUtil();
                    su.doUpdate(new List<Scope__c>{scopeUpdate});
                }
            }
        } else {
            ErrorLogUtil.commitError( ErrorLogUtil.ERROR_LEVEL_ERROR, 'El hashedId es vacío', 'PreferenceCentreZEController' );
        }
    }

    /**
     * This method get the labels for the lwc page.
     *
     * @author Enara Etxaniz
     */
    @AuraEnabled(cacheable=true)
    public static String getLabels() 
    {
        // System.debug('- - - - - PreferenceCentreZEController.getLabels - - - - - ');

        AppLabels labels = new AppLabels();

        labels.PreferenceCentreTitleLabel = Label.PreferenceCentreTitle;
        labels.PreferenceCentreSubtitleLabel = Label.PreferenceCentreSubtitle;
        labels.EmailOptOutCheckboxLabel = Label.EmailOptOutCheckboxOCS;
        labels.EmailOptOutTextLabel = Label.EmailOptOutTextOCS;
        labels.EmailOptOutButtonLabel = Label.EmailOptOutButton;
        labels.PreferenceCentreSaveLabel = Label.PreferenceCentreSave;
        labels.PreferenceCentreRedirect = Label.PreferenceCentreRedirect;
    
        return JSON.serialize(labels);
    }
  
    //#endregion
  
    //#Region private classes
  
    /**
     * Helper class for the labels used by the lwc
     * 
     * @author nts (agonzalezisasi)
     */
    public class AppLabels
    {
        String PreferenceCentreTitleLabel;
        String PreferenceCentreSubtitleLabel;
        String EmailOptOutCheckboxLabel;
        String EmailOptOutTextLabel;
        String EmailOptOutButtonLabel;
        String PreferenceCentreSaveLabel;
        String PreferenceCentreRedirect;

        public AppLabels() 
        {
            PreferenceCentreTitleLabel = 'label not found';
            PreferenceCentreSubtitleLabel = 'label not found';
            EmailOptOutCheckboxLabel = 'label not found';
            EmailOptOutTextLabel = 'label not found';
            EmailOptOutButtonLabel = 'label not found';
            PreferenceCentreSaveLabel = 'label not found';
            PreferenceCentreRedirect = '';
        }
    }
    //#endregion
  }