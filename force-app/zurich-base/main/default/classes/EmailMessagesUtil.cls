/**
 * Clase de utilidad para el proyecto de OCS (One Customer Service)
 * 
 * Presenta los metodos de ayuda necesarios para gestionar el SObject EmailMessage
 *
 * @author nts (agonzalezisasi)
 * @date 01/12/20201
 */
public with sharing class EmailMessagesUtil
{
    private static final List<String> excludedSubjects = new List<String> {
        '[ERROR LOG] Se ha producido un error que debe ser revisado'
    };
    private static final String CLASS_NAME = 'EmailMessagesUtil';
    @testvisible
    private Boolean isTestUnknownError = false;

    // List of Hegeo emails
    private List<String> listHegeoEmails;
    @testvisible
    private List<Robot_Hegeo_Setting__mdt> testHegeoSettings;

    // List of Email routing types
    private List<String> listRoutingTypes;
    @testvisible
    private List<EmailRoutingType__mdt> emailRoutingTypeList;

    // Map of Genesys Queues by email receipt
    private Map<String, purecloud__PureCloud_Queue__c> mapGenesysQueueByEmail;
    // Map of Genesys Queues by Industry
    private Map<String, purecloud__PureCloud_Queue__c> mapGenesysQueueByIndustry;
    // List of email message to be considered
    @testvisible
    private List<EmailMessage> emailMessageToCheck;

    Map<String,String> mapRouteTypeDestinatario = getEmailRouteTypeList();

    /**
     * Get from the metadata configuration the list of emails configured for the Hegeo robot
     * 
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     */
    public void getHegeoEmailList()
    {
        List<Robot_Hegeo_Setting__mdt> hegeoSettings = [SELECT RoutingAddresses__c FROM Robot_Hegeo_Setting__mdt WHERE RoutingAddresses__c != null];

        if( Test.isRunningTest() && testHegeoSettings != null && !testHegeoSettings.isEmpty() ) {
            hegeoSettings = testHegeoSettings;
            
        }
       
        if( !hegeoSettings.isEmpty() ) {
            this.listHegeoEmails = new List<String>();
            for(Robot_Hegeo_Setting__mdt setting: hegeoSettings) {
                if( String.isNotBlank(setting.RoutingAddresses__c) ) {
                    this.listHegeoEmails.add(setting.RoutingAddresses__c);
                    
                }
            }
        }
    }

    /**
     * Check all the email message that will be processed to assign the Genesys Queue data.
     * On insert trigger we will check if the addresses (To,Cc) of the emails are in the hegeo email list configured 
     * in the metadata
     * 
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     * 
     * @param {List<EmailMessage> emailMessages} List of EmailMessage
     * @param {Boolean checkHegeoEMails} check hegeo emails (true) or not (false)
     */
    public void checkEmailMessageForGenesysRouting(List<EmailMessage> emailMessages, Boolean checkHegeoEmails)
    {
        
        if( emailMessages != null && !emailMessages.isEmpty() ) {
            if( this.emailMessageToCheck == null ) this.emailMessageToCheck = new List<EmailMessage>();

            // For each email message...
            for(EmailMessage em: emailMessages) {
                // Check if it should be included to be processed
                Boolean includeEmail = false;

                // First check: Routed is false and not is not from an excluded subject list
                if( em.RoutedToGenesys__c == false && !excludedSubjects.contains(em.Subject) && em.Incoming) {
                    includeEmail = true;

                    if( checkHegeoEmails ) {
                        // Only do this if we pass the first check and we need to check hegeo emails. And only one time
                        if( this.listHegeoEmails == null ) this.getHegeoEmailList();
                        
                        // if Hegeo email list exists, check the emails that are not inclueded in any of hegeo email receipts
                        if( this.listHegeoEmails != null && !this.listHegeoEmails.isEmpty() ) {
                            Integer i = 0;
                            // for each hegeo email...
                            while( includeEmail && i < this.listHegeoEmails.size() ) {
                                String hegeoEmail = this.listHegeoEmails[i].trim().toLowerCase();

                                // List of emails to check
                                List<String> emailsToCheck = new List<String>();
                                // Add the emails from the ToAddress field
                                if( String.isNotBlank(em.ToAddress) ) emailsToCheck.addAll(em.ToAddress.split(';'));
                                // Add the emails from the CcAddress field
                                if( String.isNotBlank(em.CcAddress) ) emailsToCheck.addAll(em.CcAddress.split(';'));

                                // check both ToAddress and CcAddress fields of the EmailMessage
                                if( emailsToCheck.contains(hegeoEmail) ) {
                                    includeEmail = false;
                                }
                                i++;
                            }
                        }
                    }
                }

                if( includeEmail ) this.emailMessageToCheck.add(em);
            }
        }
    }

    /**
     * Get from the Genesys configuration de data for the Genesys Queues and flows
     * 
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     */
    public void getGenesysQueuesByEmails()
    {
        if( mapGenesysQueueByEmail == null ) {
            mapGenesysQueueByEmail = new Map<String, purecloud__PureCloud_Queue__c>();
        }

        for(purecloud__PureCloud_Queue__c genesysQueue: [
            SELECT Id, Name, CallCenter__c, GenesysFlowId__c, SalesforceRecipientEmail__c 
            FROM purecloud__PureCloud_Queue__c
            WHERE SalesforceRecipientEmail__c != null
        ]) {
            String emailReceipt = genesysQueue.SalesforceRecipientEmail__c;
            if( String.isNotBlank(emailReceipt) ) {
                mapGenesysQueueByEmail.put(emailReceipt.trim().toLowerCase(), genesysQueue);
            }
        }
    }

       /**
     * Get from the Genesys configuration de data for the Genesys Queues and flows
     * 
     * @author nts (mfernandezcarrera)
     * @date 12/08/2022
     */
    public void getGenesysQueuesByIndustry()
    {
        if( mapGenesysQueueByIndustry == null ) {
            mapGenesysQueueByIndustry = new Map<String, purecloud__PureCloud_Queue__c>();
        }

        for(purecloud__PureCloud_Queue__c genesysQueue: [
            SELECT Id, Name, CallCenter__c, GenesysFlowId__c, Industry__c 
            FROM purecloud__PureCloud_Queue__c
            WHERE Industry__c != null
        ]) {
            String queueIndustry = genesysQueue.Industry__c;
            if( String.isNotBlank(queueIndustry) ) {
                mapGenesysQueueByIndustry.put(queueIndustry.trim().toLowerCase(), genesysQueue);
                
            }
        }
    }

    
    /**
     * Devuelve un listado con los registros de los tipos de enrutado para cada dirección de email
     * 
     * @author nts (mfernandezcarrera)
     * @date 04/08/2022
     */

    public Map<String,String>  getEmailRouteTypeList(){

        
        Map<String,String> mapRouteType= new Map<String,String>() ;
        emailRoutingTypeList = EmailRoutingType__mdt.getAll().values();
      
        

        if( !emailRoutingTypeList.isEmpty() )
        {
            for (EmailRoutingType__mdt emailRoutingType: emailRoutingTypeList)
            {
                if (emailRoutingType.Activo__c == true && emailRoutingType.RoutingType__c != null)
                {  
                    mapRouteType.put(emailRoutingType.EmailAddress__c, emailRoutingType.RoutingType__c);
                }
            }
        }
        
        return mapRouteType;
    }


     /**
     * Recibe un destinatario y devuelve un tipo de enrutado
     * 
     * @author nts (mfernandezcarrera)
     * @date 04/08/2022
     */

    public String getEmailRouteType( String destinatario ){

       return mapRouteTypeDestinatario.get(destinatario);
        
    }


    /**
     * Check a list of EmailMessage and find the Genesys Queue data by the email in the toAddress or ccAddress fields
     * 
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     * 
     * *
     * @author mfernandezcarrera
     * @date 12/08/2022
     * @descripción se recibe un mapa que se utilizará para buscar la cola correspondiente según el contenido del email
     */
    public void assignGenesysRoutingFields()
    {
        try {
            if( Test.isRunningTest() && isTestUnknownError )
                throw new EmailMessagesUtilException('Unknown Error');

            // If there is any email message to be checked
            if( this.emailMessageToCheck != null && !this.emailMessageToCheck.isEmpty() ) {
                // Map of Genesys Queues by email receipt
                this.getGenesysQueuesByEmails();
                this.getGenesysQueuesByIndustry();

                if( mapGenesysQueueByEmail != null && !mapGenesysQueueByEmail.isEmpty() ) {
                    this.getEmailRouteTypeList();
                    // For each EmailMessage...
                    for(EmailMessage em: this.emailMessageToCheck) {
                        // Find the Genesys queue data from the emails of the EmailMessage object
                        purecloud__PureCloud_Queue__c genesysQueue = findGenesysQueue(em);
                        
                        if( genesysQueue != null ) {
                            // copy the following data to the EmailMessage
                            em.GenesysFlowID__c = genesysQueue.GenesysFlowId__c;
                            em.GenesysQueueName__c = genesysQueue.Name;
                        
                        }
                    }
                }
            }
        } catch(Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Search for the Genesys Queue data by any of the emails in the toAddress and ccAddress fields of the EmailMessage
     * The first one that match is the one used
     * 
     * @author nts (agonzalezisasi)
     * @date 01/12/2021
     * 
     * @param {EmailMessage em} The EmailMessage object
     * @return {purecloud__PureCloud_Queue__c} The Genesys Queue data
     * 
     * * modificaciones
     * @author mfernandezcarrera
     * @date 12/08/2022
     * @descripción Se modifica el comportamiento para poder permitir un enrutamiento basado en criterios adicionales al destinatario. En este caso Industria
     */
    private purecloud__PureCloud_Queue__c findGenesysQueue(EmailMessage em)
    {
        purecloud__PureCloud_Queue__c genesysQueue;
                    
        if( em != null ) 
        {
            try 
            {
                // List of emails to check
                List<String> emailsToCheck = new List<String>();
                // Add the emails from the ToAddress field
                if( String.isNotBlank(em.ToAddress) ) emailsToCheck.addAll(em.ToAddress.split(';'));
                // Add the emails from the CcAddress field
                if( String.isNotBlank(em.CcAddress) ) emailsToCheck.addAll(em.CcAddress.split(';'));
            
                // if any...
                if( !emailsToCheck.isEmpty() ) {
                    // Check each email in the list with the map of Genesys Queue data objects by email receipt
                    Integer i = 0;
                    
                    while( genesysQueue == null && i < emailsToCheck.size()  ) {
                        String routingType;
                     
                        routingType = getEmailRouteType(emailsToCheck[i]);
                                               
                        switch on routingType {
                            when 'Industry' {
                                if (em.Industry__c != null)
                                {
                                    genesysQueue = this.findGenesysQueueByIndustry(em.Industry__c.trim().toLowerCase());
                                }
                            }
                            when else {
                                genesysQueue = this.findGenesysQueueByEmail(emailsToCheck[i].trim().toLowerCase());                          
                            }
                        }
                        
                        i++;
                    }
                } 
            } catch (Exception e) {
                    
                ErrorLogUtil.commitError(e, 'Fallo');
            }    
               
        }

        // Return the result, can be null (no match was found)
        return genesysQueue;
    }
    
    private purecloud__PureCloud_Queue__c findGenesysQueueByEmail(String destinatario)
    {
        purecloud__PureCloud_Queue__c genesysQueue;
        
        if(destinatario != null) 
        {
            genesysQueue = mapGenesysQueueByEmail?.get(destinatario);
                // Check each email in the list with the map of Genesys Queue data objects by email receipt
        }
        else
        {
            throw new SystemUtil.SystemUtilException('Bloquear proceso');
        }
        // Return the result, can be null (no match was found)
        return genesysQueue;
    }

    private purecloud__PureCloud_Queue__c findGenesysQueueByIndustry(String industry)
    {
        purecloud__PureCloud_Queue__c genesysQueue;
    
        if(industry != null) {            
            genesysQueue = mapGenesysQueueByIndustry?.get(industry);
        }
        else
        {
            throw new SystemUtil.SystemUtilException('Bloquear proceso');
        }
        
        // Return the result, can be null (no match was found)
        return genesysQueue;
    }


    private class EmailMessagesUtilException extends Exception {}
}