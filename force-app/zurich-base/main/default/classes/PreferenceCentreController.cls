/**
 * @Description: Class that is invoked by the LWC PreferenceCentre.
 *
 *               The lead or customer arrives through the unsubscribe link to the site.
 *
 *               From there, the lead or customer can subscribe or unsubscribe from
 *               device and mobility communications or life communications.
 *
 * @Author: Enara Etxaniz
 **/
public with sharing class PreferenceCentreController {
  //#Region Constructor
  public PreferenceCentreController() {
  }
  //#endregion

  // Name of the static resource for the normal logo
  @testvisible
  private static final string ZURICH_LOGO_RESOURCE = 'zurich_klinc_logo'; 
  private static final string CONFIG_LOGO_KEY = 'KlincLogo';

  //#Region public classes

  public class CampaignStatus {
    @AuraEnabled
    public String idCampaign { get; set; }
    @AuraEnabled
    public String campaignName { get; set; }
    @AuraEnabled
    public String campaignDesc { get; set; }
    @AuraEnabled
    public String campaignPictureURL { get; set; }
    @AuraEnabled
    public Boolean contactSubscribed { get; set; }

    public CampaignStatus(
      String idCampaign,
      String campaignName,
      String campaignDesc,
      String campaignPictureURL,
      Boolean contactSubscribed
    ) {
      this.idCampaign = idCampaign;
      this.campaignName = campaignName;
      this.campaignDesc = campaignDesc;
      this.campaignPictureURL = campaignPictureURL;
      this.contactSubscribed = contactSubscribed;
    }

    public CampaignStatus() {
    }
  }

  /**
   * Get the logo url for the Country of the Contact given the contact hash
   * 
   * @author nts (agonzalezisasi)
   * @date 26/12/2021
   * @param {String hashedId} the hash id representing the contact
   * @return {string} the url of the logo as a static resource
   */
  @AuraEnabled(cacheable=true)
  public static string getLogoUrl(String hashedId)
  {
    string result = null;
    
    string other_logo = null;
    string logo = null;

    // Get all the configured logos
    Map<string, string> mapLogos = new Map<string, string>();
    List<AdminSetupParameter__mdt> settings = [
        SELECT KeyName__c, Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c LIKE :CONFIG_LOGO_KEY + '%'
    ];
    // put it in a map
    for(Integer i=0,j=settings.size();i<j;i++) {
        mapLogos.put(settings[i].KeyName__c, settings[i].Value__c);
    }

    // Get the contact to get the country
    Contact contact = getContactData(hashedId);
    if( contact != null ) {  // If found
        string keyToSearch = null;
        if( String.isNotBlank(contact.Partner__c) ) { // logos for PARTNERS
            // get the name of the logo for that partner. example: "KlincLogoOrange Seguros"
            keyToSearch = CONFIG_LOGO_KEY + contact.Partner__c;
        } else if(String.isNotBlank(contact.SourceCountry__c)) { // logos for COUNTRIES
            // get the name of the logo for that country. example: "KlincLogoGermany"
            keyToSearch = CONFIG_LOGO_KEY + contact.SourceCountry__c;
        }

        if( keyToSearch != null ) {
          if( mapLogos.containsKey(keyToSearch) ) {
            other_logo = mapLogos.get(keyToSearch);
          }
        }
    }

    // check if the is a country logo
    if( other_logo != null ) {
        logo = other_logo;
    } else { // if there is not
        // check the default logo
        if( mapLogos.containsKey(CONFIG_LOGO_KEY) ) {
            logo = mapLogos.get(CONFIG_LOGO_KEY);
        }    
    }

    // if there is a logo, get the static resouce
    if( logo != null ) {
        Pagereference page = PageReference.forResource(logo);
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
   * @Description: Metodo que obtiene la información del contacto a través del hashedId
   *
   * @Author: Enara Etxaniz
   * 
   * @change nts (agonzalezisasi) - 27/01/2021 - Use the PreferenceCentreProcessController class to see the contacts
   **/
  public static Contact getContactData(String hashedId) {
    
    Contact contact = new Contact();

    Contact c = PreferenceCentreProcessController.getContactData(hashedId);
    if( c != null ) {
      contact = c;
    } else {
      ErrorLogUtil.commitError( 
        ErrorLogUtil.ERROR_LEVEL_WARNING, 'Contact not found with hash id: ' + hashedId, 'PreferenceCentreController' 
      );
    }

    return contact;
  }

  /**
   * @Description: Metodo que obtiene todas las campanyas de tipo Suscripcion en las que el contacto está suscrito y las que no
   *
   * @Author: Enara Etxaniz
   **/
  @AuraEnabled(cacheable=true)
  public static List<CampaignStatus> getAllCampaigns(
    String hashedId,
    String language
  ) {
    

    List<Campaign> suscriptionCampaigns = new List<Campaign>();
    List<CampaignStatus> allCampaigns = new List<CampaignStatus>();

    try {
      if (!String.isBlank(hashedId)) {
        //Se localiza el Contacto a través del hash
        Contact contact = getContactData(hashedId);

        //Se obtienen las campnayas en las que el contacto está suscrito
        List<Campaign> contactCampaigns = [
          SELECT Id, Name, Description, PictureURL__c
          FROM Campaign
          WHERE
            Campaign.IsActive = TRUE
            AND Campaign.Type = 'Suscripcion'
            AND Id IN (
              SELECT CampaignId
              FROM CampaignMember
              WHERE ContactId = :contact.Id
            )
        ];

        

        allCampaigns.addAll(
          translateCampaigns(contactCampaigns, language, true)
        );

        Set<Id> idsCampaign = new Set<Id>();

        //Se rellena la lista de las campañas con el campo contactSubscribed a true
        for (Campaign campaignContact : contactCampaigns) {
          idsCampaign.add(campaignContact.Id);
        }

        //Se obtienen el resto de campañas que sean de tipo Suscripcion pero que el contacto no está suscrito
        suscriptionCampaigns = getSuscriptionCampaigns(
          idsCampaign,
          contact.LegalEntity__c,
          contact.SourceCountry__c
        );

        

        //Se rellena la lista de las campañas con el campo contactSubscribed a false
        allCampaigns.addAll(
          translateCampaigns(suscriptionCampaigns, language, false)
        );

        
      } else {
        ErrorLogUtil.commitError( ' ', 'El hashedId es vacío', 'PreferenceCentreController' );
      }
    } catch (Exception e) {
      ErrorLogUtil.commitError( e, 'PreferenceCentreController: HashedId: ' + hashedId );
    }

    return allCampaigns;
  }

  private static List<CampaignStatus> translateCampaigns(
    List<Campaign> campaignList,
    String language,
    Boolean contactSubscribed
  ) {
    

    

    List<CampaignStatus> campaignStatusList = new List<CampaignStatus>();

    Map<String, List<String>> nameAndLabelNames = new Map<String, List<String>>();
    List<String> labelsToTranslate = new List<String>();

    for (Campaign campaignItem : campaignList) {
      String name = campaignItem.Name;
      name = name.replace(' ', '_');
      name = name.replace('á', '_');
      name = name.replace('Á', '_');
      name = name.replace('é', '_');
      name = name.replace('É', '_');
      name = name.replace('í', '_');
      name = name.replace('Í', '_');
      name = name.replace('ó', '_');
      name = name.replace('Ó', '_');
      name = name.replace('ú', '_');
      name = name.replace('Ú', '_');
      name = name.replace('ñ', '_');
      name = name.replace('Ñ', '_');

      String campaignName = name + '_Name';
      String campaignDescription = name + '_Description';

      
      
      

      labelsToTranslate.add(campaignName);
      labelsToTranslate.add(campaignDescription);

      nameAndLabelNames.put(
        campaignItem.Name,
        new List<String>{ campaignName, campaignDescription }
      );
    }

    List<Label_Translations__mdt> labelTranslationList = [
      SELECT
        MasterLabel,
        DeveloperName,
        English__c,
        French__c,
        German__c,
        Italian__c,
        Japanese__c,
        PortugueseBrazil__c,
        Spanish__c,
        SpanishMexico__c
      FROM Label_Translations__mdt
      WHERE DeveloperName IN :labelsToTranslate
    ];

    

    Map<String, String> labelTranslationsMap = new Map<String, String>();

    for (Label_Translations__mdt labelItem : labelTranslationList) {
      labelTranslationsMap.put(
        labelItem.DeveloperName,
        switchLanguage(labelItem, language)
      );
    }

    

    for (Campaign campaignItem : campaignList) {
      List<String> labelNames = nameAndLabelNames.get(campaignItem.Name);

      String name = campaignItem.Name;
      String description = campaignItem.Description;

      if (labelNames.size() > 1) {
        if (labelTranslationsMap.containsKey(labelNames.get(0)))
          name = labelTranslationsMap.get(labelNames.get(0));

        if (labelTranslationsMap.containsKey(labelNames.get(1)))
          description = labelTranslationsMap.get(labelNames.get(1));
      }

      
      

      campaignStatusList.add(
        new CampaignStatus(
          campaignItem.Id,
          name,
          description,
          campaignItem.PictureURL__c,
          contactSubscribed
        )
      );
    }

    return campaignStatusList;
  }

  private static String switchLanguage(
    Label_Translations__mdt labelItem,
    String language
  ) {
    String translatedLabelItem = '';
    switch on language {
      when 'fr' {
        translatedLabelItem = labelItem.French__c != null ? labelItem.French__c : '';
      }
      when 'en_US' {
        translatedLabelItem = labelItem.English__c != null ? labelItem.English__c : '';
      }
      when 'de' {
        translatedLabelItem = labelItem.German__c != null ? labelItem.German__c : '';
      }
      when 'it' {
        translatedLabelItem = labelItem.Italian__c != null ? labelItem.Italian__c : ''; 
      }
      when 'ja' {
        translatedLabelItem = labelItem.Japanese__c != null ? labelItem.Japanese__c : ''; 
      }
      when 'es_MX' {
        translatedLabelItem = labelItem.SpanishMexico__c != null ? labelItem.SpanishMexico__c : '';
      }
      when 'pt_BR' {
        translatedLabelItem = labelItem.PortugueseBrazil__c != null ? labelItem.PortugueseBrazil__c : '';
      }
      when else {
        translatedLabelItem = labelItem.Spanish__c != null ? labelItem.Spanish__c : '';
      }
    }
    return translatedLabelItem;
  }

  /**
   * @Description: Metodo que obtiene todas las campañas de tipo suscripción y que no estén incluidas las que el contacto ya esté suscrito
   *
   * @Author: Enara Etxaniz
   **/
  public static List<Campaign> getSuscriptionCampaigns(
    Set<Id> contactIdCampaigns,
    String legalEntity,
    String country
  ) {
    return [
      SELECT Id, Name, Description, PictureURL__c
      FROM Campaign
      WHERE
        IsActive = TRUE
        AND Type = 'Suscripcion'
        AND LegalEntity__c = :legalEntity
        AND Id NOT IN :contactIdCampaigns
        AND Available_countries__c INCLUDES (:country)
    ];
  }

  /**
   * @Description: Metodo que aplica la logica de subscribe o unsubscribe (hasOptedOutOfEmail y campañas) del contancto
   *              que se recibe en la url hasheado
   *
   * @Author: Enara Etxaniz
   **/
  @AuraEnabled
  public static void processRequest(
    String hashedId,
    Boolean hasOptedOutOfEmail,
    List<CampaignStatus> campaigns
  ) {
    
    
    

    try {
      // Ahora se intenta actualizar las preferencias del cliente
      if (!String.isBlank(hashedId)) {
        Contact contact = getContactData(hashedId);

        

        if (contact != null) {
          // Se actualiza el contacto si los parametros cambian con respecto a los valores actuales en el contacto
          updateHasOptedOutOfEmail(contact, hasOptedOutOfEmail);

          //Se actualizan las campañas correspondientes
          //Si el usuario se ha desucrito de alguna campaña a la que estaba suscrito, deja de ser miembro de esa campaña
          //Si el usuario se ha suscrito a alguna campaña de la que no estaba suscrito, pasa a ser miembro de esa campaña
          updateCampaigns(contact, campaigns);
        }
      } else {
        ErrorLogUtil.commitError( ' ', 'El hashedId es vacío', 'PreferenceCentreController' );
      }
    } catch (Exception e) {
      ErrorLogUtil.commitError( e, 'PreferenceCentreProcessController: HashedId: ' + hashedId + ' HasOptedOutOfEmail: ' + hasOptedOutOfEmail + ' Campaigns: ' + campaigns );
    }
  }

  /**
   * @Description: Método que devuelve las traducciones de las etiquetas al componente Lightning de Preference Centre
   *
   * @Author: Enara Etxaniz
   */
  @AuraEnabled(cacheable=true)
  public static String getLabelTranslation(String language) {
    List<String> labelList = new List<String>{
      'PreferenceCentreTitle',
      'PreferenceCentreSubtitle',
      'CampaignCheckbox',
      'EmailOptOutCheckbox',
      'EmailOptOutText',
      'EmailOptOutButton',
      'PreferenceCentreSave'
    };
    List<Label_Translations__mdt> labelTranslationList = [
      SELECT
        MasterLabel,
        English__c,
        French__c,
        German__c,
        Italian__c,
        Japanese__c,
        PortugueseBrazil__c,
        Spanish__c,
        SpanishMexico__c
      FROM Label_Translations__mdt
      WHERE label IN :labelList
    ];

    List<PreferenceCentreController.TranslatedLabel> translatedLabelList = new List<TranslatedLabel>();

    for (Label_Translations__mdt labelItem : labelTranslationList) {
      PreferenceCentreController.TranslatedLabel translatedLabelItem = new TranslatedLabel();
      translatedLabelItem.masterLabel = labelItem.MasterLabel;
      translatedLabelItem.defaultValue = labelItem.Spanish__c;
      translatedLabelItem.value = switchLanguage(labelItem, language);

      translatedLabelList.add(translatedLabelItem);
    }

    return JSON.serialize(translatedLabelList);
  }

  //#endregion

  //#Region private classes
  /**
   * @Description: Metodo que actualiza la suscripción del contacto
   *
   * @Author: Enara Etxaniz
   **/
  private static void updateHasOptedOutOfEmail(
    Contact contact,
    Boolean hasOptedOutOfEmail
  )
  {
    Contact contactUpdate;

    // Se comprueba si la suscripción a comunicaciones ha cambiado
    if (hasOptedOutOfEmail) {
      if (contact.HasOptedOutOfEmail == false) {
        //Se rellenan los campos de contacto a actualizar
        if (contactUpdate == null) {
          contactUpdate = contact;
        }
        contactUpdate.HasOptedOutOfEmail = true;
        contactUpdate.UnsubscribedDate__c = DateTime.now();
        contactUpdate.UnsubscribedSource__c = 'Centro de preferencias';
      }
    }

    if (contactUpdate != null) {
      //Se actualza el contacto
      PreferenceCentreProcessController.doUpdate(contactUpdate);
    }
  }

  /**
   * @Description: Metodo que aplica la logica de subscribe o unsubscribe de las campañas
   *
   * @Author: Enara Etxaniz
   **/
  private static void updateCampaigns(
    Contact contact,
    List<CampaignStatus> campaigns
  ) {

    if (campaigns != null & campaigns.size() > 0) {
      //Se comprueba qué relación tiene el contacto con esas campañas (miembro de la campaña o no) Id = Campagign Id
      Map<Id, Boolean> mapContactStatus = getContactSuscriptionStatus(
        contact,
        campaigns
      );

      List<CampaignMember> memberToInsertList = new List<CampaignMember>();
      Set<Id> campaignIdToDeleteList = new Set<Id>();

      for (CampaignStatus campaign : campaigns) {
        if (mapContactStatus.containsKey(campaign.idCampaign)) {
          //se obtiene lo que el cliente ha marcado en la página
          Boolean subscribed = campaign.contactSubscribed;

          //Se obtiene si el contacto está suscrito actualmente o no
          Boolean subscribedBefore = mapContactStatus.get(campaign.idCampaign);

          //Si ha decidido suscribirse y no estaba suscrito, se le añade como miembro de campaña
          if (subscribed & !subscribedBefore) {
            CampaignMember campaignMember = new CampaignMember();

            campaignMember.ContactId = contact.Id;
            campaignMember.CampaignId = campaign.idCampaign;
            campaignMember.Status = 'Suscrito';

            memberToInsertList.add(campaignMember);
          } else if (!subscribed & subscribedBefore) {
            //Si ha decidido desuscribirse y estaba suscrito, se le quita como miembro de campaña
            campaignIdToDeleteList.add(campaign.idCampaign);
          }

          //En cualquier otro caso, no se hace nada
        }
      }

      //Añadir el contacto como miembro de campaña
      if (memberToInsertList != null && !memberToInsertList.isEmpty()) {
        //Se realiza la inserción
        PreferenceCentreProcessController.doInsert(memberToInsertList);
      }

      //Borrar el contacto como miembro de la campaña
      if (campaignIdToDeleteList != null && !campaignIdToDeleteList.isEmpty()) {
        deleteCampaignMember(contact, campaignIdToDeleteList);
      }
    }
  }

  /**
   * @Description: Metodo que obtiene las campañas (Id) en las que el contacto está suscrito
   *
   * @Author: Enara Etxaniz
   **/
  private static Map<Id, Boolean> getContactSuscriptionStatus(
    Contact contact,
    List<CampaignStatus> campaigns
  ) {
    //Se obtiene los miembros de campaña en las que el contacto está suscrito
    List<Campaign> campaignsContactBefore = [
      SELECT Id
      FROM Campaign
      WHERE
        Campaign.IsActive = TRUE
        AND Campaign.Type = 'Suscripcion'
        AND Id IN (
          SELECT CampaignId
          FROM CampaignMember
          WHERE ContactId = :contact.Id
        )
    ];

    Map<Id, Boolean> mapContactSuscriptionStatus = new Map<Id, Boolean>();

    Set<Id> idsCampaign = new Set<Id>();
    for (Campaign c : campaignsContactBefore) {
      idsCampaign.add(c.Id);
    }

    for (CampaignStatus campaign : campaigns) {
      //Sí está el id de la campaña en la lista de ids contactos suscritos
      if (idsCampaign.contains(campaign.idCampaign)) {
        if (!mapContactSuscriptionStatus.containsKey(campaign.idCampaign)) {
          mapContactSuscriptionStatus.put(campaign.idCampaign, true);
        }
      } else {
        //no está el id de la campaña en la lista de ids contactos suscritos
        if (!mapContactSuscriptionStatus.containsKey(campaign.idCampaign)) {
          mapContactSuscriptionStatus.put(campaign.idCampaign, false);
        }
      }
    }

    return mapContactSuscriptionStatus;
  }

  /**
   * @Description: Metodo que elimina el contacto como miembro de esa campaña de la que se ha desuscrito
   *
   * @Author: Enara Etxaniz
   **/
  public static void deleteCampaignMember(
    Contact contact,
    Set<Id> campaignIdToDeleteList
  ) {
    List<CampaignMember> membersList = new List<CampaignMember>(
      [
        SELECT Id
        FROM CampaignMember
        WHERE CampaignId IN :campaignIdToDeleteList AND ContactId = :contact.Id
      ]
    );

    if (membersList != null && !membersList.isEmpty()) {
      //Se realiza el borrado
      PreferenceCentreProcessController.doDelete(membersList);
    }
  }

  public class TranslatedLabel {
    String masterLabel;
    String defaultValue;
    String value;
  }
  //#endregion
}