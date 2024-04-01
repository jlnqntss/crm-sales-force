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
    // Map of Genesys Queues by Typology
    private Map<CaseUtil.CaseTypology, purecloud__PureCloud_Queue__c> mapGenesysQueueByTypology;
    // List of email message to be considered
    @testvisible
    private List<EmailMessage> emailMessageToCheck;

    Map<String,String> mapRouteTypeDestinatario = getEmailRouteTypeList();
    @testvisible
    private static final Id uspRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
    @testvisible
    private static final Id ocsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();

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


    public void checkNewCaseFromClosedCase(List<EmailMessage> emailList)
    {
        Set<String> idsCasosPadre = new Set<String>();
        Map<Id, Case> mapaCasosPadre = new Map<Id, Case>();
        Map<Integer, Id> mapaPosiciones = new Map<Integer, Id>(); //Relaciona un caso con la posicion en la lista del email que entra
        Map<Integer, Case> mapaCasosHijos = new Map<Integer, Case>(); //Relaciona un caso hijo con la posicion en la lista del email que entra

        // Obtenemos los casos asociados a los emails que están llegando
        for(EmailMessage email : emailList)
        {
            if(email.Incoming && String.isNotBlank(email.ParentId))
            {
                idsCasosPadre.add(email.ParentId); 
                mapaPosiciones.put(emailList.indexOf(email), email.ParentId);
            }
        }

        List<Case> listaCasosPadre = new CasesSelector().findAllDataById(idsCasosPadre);
        for(Case c : listaCasosPadre)
        {
            mapaCasosPadre.put(c.Id, c);
        }

        mapaCasosHijos = checkIfCaseCloseCreateChildCase (mapaPosiciones, emailList, mapaCasosPadre );
        
        // Mediante el orden de llegada del email (la posición en la lista), sustituímos las referencias a los casos en los emails
        for (Integer posicion : mapaCasosHijos.keySet())
        {
            EmailMessage email = emailList.get(posicion);
            Case casoHijo = mapaCasosHijos.get(posicion);
            Case casoPadre = mapaCasosPadre.get(casoHijo.ParentId);

            // Creamos las referencias de los casos padre e hijo
            String caseThreadIDpadreOld = getCaseReference(casoPadre.Id, true); 
            String caseThreadIDpadreNew = getCaseReference(casoPadre.Id, false);
            
            if(email.HtmlBody.contains(caseThreadIDpadreOld))
            {
                String caseThreadIDhijo = getCaseReference(casoHijo.id, false);

                // Actualizamos las referencias en el email
                email.HtmlBody = email.HtmlBody.replace(caseThreadIDpadreOld, caseThreadIDhijo);
                email.TextBody = email.TextBody.replace(caseThreadIDpadreOld, caseThreadIDhijo);

                email.ThreadIdentifier = '';
            }

            else if(email.HtmlBody.contains(caseThreadIDpadreNew))
            {
                String caseThreadIDhijo = getCaseReference(casoHijo.id, false);

                // Actualizamos las referencias en el email
                email.HtmlBody = email.HtmlBody.replace(caseThreadIDpadreNew, caseThreadIDhijo);
                email.TextBody = email.TextBody.replace(caseThreadIDpadreNew, caseThreadIDhijo);

                email.ThreadIdentifier = '';
            }
            
            email.ParentId = casoHijo.Id;
            email.RelatedToId = casoHijo.Id;
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
            SELECT Id, Name, CallCenter__c, GenesysFlowId__c, SalesforceRecipientEmail__c,RecordTypeInfo__c 
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
            SELECT Id, Name, CallCenter__c, GenesysFlowId__c, Industry__c, RecordTypeInfo__c
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
     * Get from the Genesys configuration de data for the Genesys Queues and flows bases on the Case Types
     * 
     * @author nts (jfherrero)
     * @date 22/02/2024
     */
    public void getGenesysQueuesByTypology()
    {
        if( mapGenesysQueueByTypology == null ) {
            mapGenesysQueueByTypology = new Map<CaseUtil.CaseTypology, purecloud__PureCloud_Queue__c>();
        }

        //Necesitamos obtener los nombres de las colas a través del metadato.
        List<Case_Queue_override_by_type__mdt> caseQueueOverrideByType = Case_Queue_override_by_type__mdt.getAll().values();
        
        Map<CaseUtil.CaseTypology, String> mapGenesysQueueNamesByTypology = new Map<CaseUtil.CaseTypology, String>();
        List<String> genesysQueueNames = new List<String>();

        if (caseQueueOverrideByType?.size()>0)
        {
            for (Case_Queue_override_by_type__mdt queueOverride : caseQueueOverrideByType)
            {
                genesysQueueNames.add(queueOverride.Destino__c.trim().toLowerCase());
                mapGenesysQueueNamesByTypology.put(new CaseUtil.CaseTypology(queueOverride.Type__c.trim().toLowerCase(),
                                                                        queueOverride.Subtype__c.trim().toLowerCase(),
                                                                        queueOverride.TypeN3__c.trim().toLowerCase()),
                                              			queueOverride.Destino__c);
            }
        }
        
        GenesysQueueSelector genesysQueueSelector = new GenesysQueueSelector();
        Map<String, purecloud__PureCloud_Queue__c> queuesMapByName = new Map<String, purecloud__PureCloud_Queue__c>();
        
        for(purecloud__PureCloud_Queue__c queue : genesysQueueSelector.getQueuesByName(genesysQueueNames))
        {
            queuesMapByName.put(queue.Name, queue);
        }
        
        for (CaseUtil.CaseTypology typology : mapGenesysQueueNamesByTypology.keyset())
        {
            mapGenesysQueueByTypology.put(typology, queuesMapByName.get(mapGenesysQueueNamesByTypology.get(typology)));
        }
        
    }
    
    /**
     * Devuelve un listado con los registros de los tipos de enrutado para cada dirección de email
     * 
     * @author nts (mfernandezcarrera)
     * @date 04/08/2022
     */

    public Map<String,String>  getEmailRouteTypeList()
    {
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
                // Incluímos la búsqueda por tipología
                this.getGenesysQueuesByTypology();

                if( (mapGenesysQueueByEmail != null && !mapGenesysQueueByEmail.isEmpty()) ||
                    (mapGenesysQueueByTypology != null && !mapGenesysQueueByTypology.isEmpty()))
                {
                    this.getEmailRouteTypeList();
                    // For each EmailMessage...
                    for(EmailMessage em: this.emailMessageToCheck) {
                        // Find the Genesys queue data from the emails of the EmailMessage object
                        purecloud__PureCloud_Queue__c genesysQueue = findGenesysQueue(em);
                        
                        if( genesysQueue != null )
                        {
                            // copy the following data to the EmailMessage
                            if (genesysQueue.GenesysFlowId__c != null)
                            {
                                em.GenesysFlowID__c = genesysQueue.GenesysFlowId__c;
                            }
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
     * Método que marca a public la tarea relacionada con el emailMessage cuando es creado. 
     * 
     * @author aberuete
     * @date 26/07/2023
     * 
     * @param {Map<Id, EmailMessage> newMap} Mapa de nuevos emailMessage creados
     */
    public void markPublicActivity(Map<Id, EmailMessage> newMap)
    {
        Set<Id> activityIds = new Set<Id>();

        for (EmailMessage email : newMap.values()) 
        {
            if (email.IsExternallyVisible == true && email.ActivityId != null)
            {
                activityIds.add(email.ActivityId);   
            }
        }

        List<Task> tasksList = ActivitySelector.selectTasksById (activityIds);
        
        if (tasksList != null && !tasksList.isEmpty()) 
        {
            for (Task taskToUpdate : tasksList)
            {
                taskToUpdate.IsVisibleInSelfService = true;
            }
        }

        update tasksList;
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
     * 
     * * modificaciones 
     * @author mfernandezcarrera 
     * @date 27/09/2022 
     * @descripción Se modifica el comportamiento para que añada las direcciones de correo tanto del TO como del CC, cuando están separadas con comas.
     * 
     * * * modificaciones 
     * @author arcortazar 
     * @date 03/11/2022 
     * @descripción Revertimos el cambio anterior, ya que se ha visto que el problema venia del EmailToOpportunityService, donde se concatenan las direcciones con comas
     * 
     * * * * modificaciones 
     * @author aberuete 
     * @date 20/11/2023 
     * @descripción Refactorizar el método y añadir que los casos de tipo USP , si el campo industry viene un correo, buscar la cola de enrutar a genesys por email
     * 
     * * * * modificaciones 
     * @author jfherrero 
     * @date 27/02/2024 
     * @descripción Buscar si la cola se tiene que asignar por tipología a otros centros (inicialmente para GSS)
     */
    private purecloud__PureCloud_Queue__c findGenesysQueue(EmailMessage em)
    {
        purecloud__PureCloud_Queue__c genesysQueue;
                    
        if( em != null )
        {
            try
            {
                // List of emails to check
                String industryGeneric= 'Generico';

                // list of related cases
                Set<String> idCaso = new Set<String>();
        
                // Obtenemos el caso asociado al email que esta llegando
                if(em.Incoming && String.isNotBlank(em.ParentId)) idCaso.add(em.ParentId); 
                List<Case> listaCaso = new CasesSelector().findAllDataById(idCaso);

                if (!listaCaso.isEmpty())
                {      
                    if( (mapGenesysQueueByTypology != null && !mapGenesysQueueByTypology.isEmpty()) &&
                        listaCaso[0].Type != null && listaCaso[0].Subtype__c != null && listaCaso[0].TypeN3__c != null)
                    {
                        // Buscamos si la tipología del caso coincide con alguna de las del mapa
                        CaseUtil.CaseTypology myCaseTyplogy = new CaseUtil.CaseTypology(listaCaso[0].Type.trim().toLowerCase(),
                                                                        				listaCaso[0].Subtype__c.trim().toLowerCase(),
                                                                        				listaCaso[0].TypeN3__c.trim().toLowerCase());
                        
                        for(CaseUtil.CaseTypology tipologia: mapGenesysQueueByTypology.keyset())
                        {
                            if (tipologia.type == myCaseTyplogy.type && tipologia.subtype == myCaseTyplogy.subtype &&
                                tipologia.typeN3 == myCaseTyplogy.typeN3)
                            {
                                genesysQueue = this.mapGenesysQueueByTypology.get(tipologia);
                                return genesysQueue;
                            }
                        }
                    }
                    
                    if(em.Industry__c != null && em.Industry__c.contains('@') &&
                           (mapGenesysQueueByEmail != null && !mapGenesysQueueByEmail.isEmpty()))
                    {
                        genesysQueue = this.findGenesysQueueByEmail(em.Industry__c.trim().toLowerCase());  
    
                        if (genesysQueue == null && listaCaso.get(0).RecordTypeId == uspRecordTypeId )
                        {
                            genesysQueue=this.findGenesysQueueByIndustry(industryGeneric.trim().toLowerCase());
                            return genesysQueue;
                        }
                    }
                }       
                
                if ((mapGenesysQueueByEmail != null && !mapGenesysQueueByEmail.isEmpty()))
                {
                    genesysQueue = getQueueWhenIndustryNotEmail(em, genesysQueue, listaCaso);
                }
                                
            } catch (Exception e) {
                    
                ErrorLogUtil.commitError(e, 'Fallo');
            }       
        }

        // Return the result, can be null (no match was found)
        return genesysQueue;
    }

    /**
     * Obtiene la cola de genesys cuando en el campo industry no viene informado un correo electrónico
     * 
     * @author aberuete
     * @date 20/11/2023
     * 
     * @param {EmailMessage em} EmailMessage
     * @param {purecloud__PureCloud_Queue__c genesysQueue} Cola de genesys
     * @param {List<Case> listaCaso} Caso asociado al email message
     */
    private purecloud__PureCloud_Queue__c getQueueWhenIndustryNotEmail (EmailMessage em, purecloud__PureCloud_Queue__c genesysQueue, List<Case> listaCaso)
    {
        List<String> emailsToCheck = new List<String>();

        // Add the emails from the ToAddress field
        if( String.isNotBlank(em.ToAddress) ) emailsToCheck.addAll(em.ToAddress.split(';'));
        // Add the emails from the CcAddress field
        if( String.isNotBlank(em.CcAddress) ) emailsToCheck.addAll(em.CcAddress.split(';'));
        
        // if any...
        if( !emailsToCheck.isEmpty() ) 
        {
            // Check each email in the list with the map of Genesys Queue data objects by email receipt
            Integer i = 0;
            
            while( genesysQueue == null && i < emailsToCheck.size()  ) 
            {
                String routingType;
            
                routingType = getEmailRouteType(emailsToCheck[i]);
                 
                switch on routingType 
                {
                    when 'Industry' 
                    {
                        genesysQueue = getQueueWhenRoutingTypeIndustry (em, genesysQueue, listaCaso);
                    }
                    when else 
                    {
                        genesysQueue = getQueueWhenRoutingTypeNotIndustry (emailsToCheck,genesysQueue, listaCaso, i);
                    }
                }

                i++;
            }

            genesysQueue = setGenesysQueueWhenIsNull (em, genesysQueue, listaCaso);
        } 
        
        return genesysQueue;
    }

    /**
     * Obtiene la cola de genesys cuando en el campo industry no viene informado un correo electrónico y el tipo de enrutado es industry
     * 
     * @author aberuete
     * @date 20/11/2023
     * 
     * @param {EmailMessage em} EmailMessage
     * @param {purecloud__PureCloud_Queue__c genesysQueue} Cola de genesys
     * @param {List<Case> listaCaso} Caso asociado al email message
     */
    private purecloud__PureCloud_Queue__c getQueueWhenRoutingTypeIndustry (EmailMessage em, purecloud__PureCloud_Queue__c genesysQueue, List<Case> listaCaso)
    {
        String industryGeneric= 'Generico';

        if(!listaCaso.isEmpty() && listaCaso.get(0).RecordTypeId == uspRecordTypeId)
        {
            if (em.Industry__c != null)
            {
                genesysQueue = this.findGenesysQueueByIndustry(em.Industry__c.trim().toLowerCase());
            }
            
            if(em.Industry__c==null || genesysQueue==null)
            {
                genesysQueue=this.findGenesysQueueByIndustry(industryGeneric.trim().toLowerCase());
            }
        }  
        
        return genesysQueue;
    }

    /**
     * Obtiene la cola de genesys cuando en el campo industry no viene informado un correo electrónico y el tipo de enrutado no es industry
     * 
     * @author aberuete
     * @date 20/11/2023
     * 
     * @param {List<String> emailsToCheck} Lista de emails que contiene el to y el cc del correo
     * @param {purecloud__PureCloud_Queue__c genesysQueue} Cola de genesys
     * @param {List<Case> listaCaso} Caso asociado al email message
     * @param {Integer index} Indice de la lista de emails a chequear
     */
    private purecloud__PureCloud_Queue__c getQueueWhenRoutingTypeNotIndustry (List<String> emailsToCheck,purecloud__PureCloud_Queue__c genesysQueue, List<Case> listaCaso, Integer index)
    {
        genesysQueue = this.findGenesysQueueByEmail(emailsToCheck[index].trim().toLowerCase());

        if((!listaCaso.isEmpty() && genesysQueue != null) && (listaCaso.get(0).RecordTypeId == uspRecordTypeId) && (genesysQueue.RecordTypeInfo__c!='USPInquiry'))
        {
            genesysQueue=null;
        }
        
        else if((!listaCaso.isEmpty() && genesysQueue != null) && (listaCaso.get(0).RecordTypeId == ocsRecordTypeId) && (genesysQueue.RecordTypeInfo__c!='OCSInquiry'))
        {
            genesysQueue=null;
        }
        
        return genesysQueue;
    }

    /**
     * En caso de que la cola esté vacía y el tipo de caso sea USP,
     * busca la cola de genesys por el campo industry en el caso que de que el campo esté informado, en caso contrario devuelve la cola genérica.
     * 
     * @author aberuete
     * @date 20/11/2023
     * 
     * @param {EmailMessage em} EmailMessage
     * @param {purecloud__PureCloud_Queue__c genesysQueue} Cola de genesys
     * @param {List<Case> listaCaso} Caso asociado al email message
     */
    private purecloud__PureCloud_Queue__c setGenesysQueueWhenIsNull (EmailMessage em, purecloud__PureCloud_Queue__c genesysQueue, List<Case> listaCaso)
    {
        String industryGeneric= 'Generico';
        String industryDefault;

        if(!listaCaso.isEmpty() && (listaCaso.get(0).RecordTypeId == uspRecordTypeId) && (genesysQueue==null) && em.Industry__c != null)
        {   
            industryDefault=em.Industry__c;
            
            genesysQueue=this.findGenesysQueueByIndustry(industryDefault.trim().toLowerCase());
            
            if((genesysQueue==null) || (genesysQueue.RecordTypeInfo__c!='USPInquiry'))
            {   
                genesysQueue=this.findGenesysQueueByIndustry(industryGeneric.trim().toLowerCase());

            }
        } 

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

    /**
     * Crea el thread ID a partir del ID de un caso
     * 
     * @author nts (arcortazar)
     * @date 18/11/2022
     * @param String el ID del caso
     * @return String 
     */
    private String getCaseReference(String caseId, Boolean oldFormat)
    {
        String threadID;

        if(caseId != null)
        {
            if(oldFormat)
            {
                threadID = 'ref:_' + UserInfo.getOrganizationId().left(5) + UserInfo.getOrganizationId().mid(11,4) + '._' + caseId.left(5) + caseId.mid(10,5) + ':ref';
            }
            else
            {
                threadID = 'ref:!' + UserInfo.getOrganizationId().left(6) + UserInfo.getOrganizationId().mid(11,4) + '.!' + caseId.left(6) + caseId.mid(10,5) + ':ref';
            }
        }

        return threadID;
    }

    /**
     * Obtener el owner del caso hijo
     * 
     * @author aberuete
     * @date 26/06/2023
     * @param Case padre : caso padre
     * @param Case casoHijo : caso hijo
     * 
     * modificaciones
     * @author nts - jfherrero
     * @date 31/01/2024
     * @descripción Verificar que el propietario del caso padre esté activo. Si no, intentar asignar la cola de Genesys
    */
    private Case getOwnerOfChildCase (Case padre, Case casoHijo, EmailMessage email)
    {
        Id integratorUserId;
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {'OCS Community User'});

        if (UserInfo.getProfileId() != listaPerfiles.keySet().iterator().next())
        {
            integratorUserId = [Select Id FROM User WHERE Profile.Name like :Label.IntegratorUser].get(0).Id;
        }

        if (padre.CallCenter__c == 'TWW Retención')
        {
            getOwnerOfChildCaseForTranscom (padre, casoHijo);
        }
        else if(padre.RecordTypeId==uspRecordTypeId && padre.OwnerId!=null)
        { 
            if (CaseUtil.validCaseOwner(padre.OwnerId))
            {
                casoHijo.OwnerId = padre.OwnerId; //Asignamos como propietario del caso Hijo el mismo que el caso Padre
            }
            else
            {
                casohijo.OwnerId = getEmailGenesisQueueId(email, integratorUserId);
            }
        }
        else
        {
            casoHijo.OwnerId = integratorUserId; // Asignamos Integrator como el Owner del caso
        }
        return casoHijo;
    }

    /**
     * Obtener el owner del caso hijo en los casos en que el call center sea TWW Retención
     * 
     * @author aberuete
     * @date 26/06/2023
     * @param Case padre : caso padre
     * @param Case casoHijo : caso hijo
    */
    private Case getOwnerOfChildCaseForTranscom (Case padre, Case casoHijo)
    {
        if (String.valueof(padre.OwnerId).startsWith('00G') ) 
        {
            casoHijo.OwnerId = padre.OwnerId;
        }
        
        else 
        {
            // buscar en el caso history la cola más reciente   
            List<CaseHistory> historyCase = new CaseHistorySelector().findByCaseIdAndFieldAndDatType (padre.Id,'Owner', 'EntityId');
            Integer i = 0;

            if (!historyCase.isEmpty())
            {
                while ( !String.valueOf(historyCase[i].OldValue).startsWith('00G') && i < historyCase.size() - 1)
                {
                    i++;
                }
                
                if ( String.valueOf(historyCase[i].OldValue).startsWith('00G'))
                {
                    casoHijo.OwnerId = String.valueOf(historyCase[i].OldValue);
                }
            }
        } 
        return casoHijo;
    }

    /**
     * Crear caso hijo en caso de que el caso este cerrado y sea de OCS o USP
     * 
     * @author 
     * @date 26/06/2023
     * @param Map<Integer, Id> mapaPosiciones : Mapa que relaciona un caso con la posición del email entrante
     * @param List<EmailMessage> emailList : Lista de email message
     * @param Map<Id, Case> mapaCasosPadre : Mapa de id del caso padre y el caso padre 
     * @change aberuete - Refactorización del método checkNewCaseFromClosedCase
    */
    private Map<Integer,Case> checkIfCaseCloseCreateChildCase (Map<Integer, Id> mapaPosiciones, List<EmailMessage> emailList, Map<Id, Case> mapaCasosPadre ) 
    {
        Map<Integer, Case> mapaCasosHijos = new Map<Integer, Case>(); //Relaciona un caso hijo con la posicion en la lista del email que entra

        // Para cada email que ha llegado, comprobamos si el caso asociado está cerrado y si el RT es el adecuado (OCS o USP). En caso afirmativo, creamos el caso hijo
        for (Integer posicion : mapaPosiciones.keyset())
        {
            Case padre = mapaCasosPadre.get(mapaPosiciones.get(posicion));  

            if(padre?.IsClosed && (padre?.RecordTypeId == ocsRecordTypeId || padre?.RecordTypeId == uspRecordTypeId ))
            {
                EmailMessage email = emailList.get(posicion);
                // Comprobamos si ha de heredarse la tipificación del caso padre
                Boolean tipificacionCorrecta = CaseUtil.checkTypification(padre);
                Boolean heredamosTipificacion = (padre?.RecordTypeId == ocsRecordTypeId && (padre?.CallCenter__c == 'CC Service' || padre?.CallCenter__c == 'TWW Retención') ); // Corregimos para que solo herede la tipificación en los casos que corresponde
                
                Case casoHijo = CaseUtil.createCaseFromParent(padre, email, (tipificacionCorrecta && heredamosTipificacion)); 
                casoHijo = getOwnerOfChildCase (padre, casoHijo, email); // Asignamos el owner del caso
                casoHijo.SuppliedEmail = email.FromAddress; // Asignamos el from del email que general el caso hijo como SuppliedEmail
                mapaCasosHijos.put(posicion, casoHijo);
            }
        }
        insert mapaCasosHijos.values();
        return mapaCasosHijos;
    }

    /**
     * Determina si el email tiene buzones de apertura de caso sólo en CcAddress y no en ToAddress
     * Para aquellos en los que así sea habrá que cerrar el caso creado
     * 
     * @author jfherrero
     * @date 22/01/2024
     * 
     * @last modified on  : 22-03-2024
     * @last modified by  : jfherrero
     * 
     * @param List<EmailMessage> emailList : Lista de email message
    */
    public void checkIfMailOnlyInCc (List<EmailMessage> emailList)
    {
        // Rescatamos los buzones
        List<CloseOnCcMailboxList__mdt> closeOnCcMailboxList = CloseOnCcMailboxList__mdt.getAll().values();
        List<String> mailboxes = new List<String>();
        
        if (!closeOnCcMailboxList.isEmpty())
        {
            // Si la lista de buzones a cerrar no está vacía, obtenemos los emails
            for (CloseOnCcMailboxList__mdt mailbox : closeOnCcMailboxList)
            {
                mailboxes.add(mailbox.Email__c);
            }

            List<EmailMessage> emailListRecentlyCreated = new List<EmailMessage>();

            for (EmailMessage em : emailList)
            {
                if (em.CreatedDate >= Datetime.now().addMinutes(-1))
                {
                    emailListRecentlyCreated.add(em);
                }
            }

            // Vemos si los buzones están en el CC pero no en ToAddress y los guardamos
            List<EmailMessage> mailsToCloseRelatedCase = checkIfMailboxesOnlyInCc (emailListRecentlyCreated, mailboxes);//new List<EmailMessage>();

            Set<String> caseIds = new Set<String>();

            for (EmailMessage mailToClose: mailsToCloseRelatedCase)
            {
                caseIds.add(mailToClose.ParentId);
            }

            // Seleccionamos todos los casos que cumplen el criterio
            
            List<Case> casesForAutoClose = new CasesSelector().findAllDataById(caseIds);
            
            // y que sean de reciente creación
            List<Case> onlyNewCases = new List<Case>();

            for (Case c : casesForAutoClose)
            {
                if (c.CreatedDate >= Datetime.now().addMinutes(-1))
                {
                    onlyNewCases.add(c);
                }
            }

            //Cierre de los casos que cumplen el criterio
        	this.closeCasesOnlyInCc(onlyNewCases);
        }
    }

    /**
     * Determina si el email tiene buzones de apertura de caso sólo en CcAddress y no en ToAddress
     * Para aquellos en los que así sea habrá que establecer un email por defecto cuando el agente conteste un caso
     * Cuando el email unicamente cuente con alguna de las direcciones en TO desactivara esta dirección por defecto
     * 
     * @author lrodriguez
     * @date 27/03/2024
     * 
     * @param List<EmailMessage> emailList : Lista de email message
    */
    public void checkMailCc (List<EmailMessage> emailList)
    {
        // Rescatamos los buzones
        List<EmailFromByDefaultCC__mdt> emailByDefaultCcMailboxList = EmailFromByDefaultCC__mdt.getAll().values();
        List<String> mailboxes = new List<String>();
        
        if (!emailByDefaultCcMailboxList.isEmpty())
        {
            // Si la lista de buzones a cerrar no está vacía, obtenemos los emails
            for (EmailFromByDefaultCC__mdt mailbox : emailByDefaultCcMailboxList)
            {
                mailboxes.add(mailbox.Email__c);
            }
        }
        
        List<EmailMessage> emailCC= new List<EmailMessage>();
        List<EmailMessage> emailNoCC= new List<EmailMessage>();

        //Separamos aquellos email que tengan direcciones en cc de los que no
        for(EmailMessage e:emailList)
        {
            if(e.ccAddress!=null)
            {
                emailCC.add(e);
            }
            else{
                emailNoCC.add(e);
            }
        }
        
        //Email con direcciones en cc
        if(emailCC!=null)
        {
            List<EmailMessage> mailsToCloseRelatedCase = checkIfMailboxesOnlyInCc (emailList, mailboxes);
            Set<String> caseIds = new Set<String>();

            for (EmailMessage mailToClose: mailsToCloseRelatedCase)
            {
                caseIds.add(mailToClose.ParentId);
            }

            // Seleccionamos todos los casos que cumplen el criterio
            List<Case> casesEmailDefault = new CasesSelector().findByIdControlCC(caseIds);

            //Cierre de los casos que cumplen el criterio
        	this.casesControlEmailCC(casesEmailDefault);

        }
        //Email sin direcciones en cc
        if(emailNoCC!=null)
        {   
            Set<String> caseIdsDesactivate = new Set<String>();

            for (EmailMessage mailToClose: emailNoCC)
            {
                caseIdsDesactivate.add(mailToClose.ParentId);
            }

            // Seleccionamos todos los casos que cumplen el criterio
            
            List<Case> caseEmailNotDefault = new CasesSelector().findByIdControlCC(caseIdsDesactivate);
            this.casesControlEmailCCDesactivate(caseEmailNotDefault);
        }
        
    }

    /**
     * Devuelve los emails que tienen las los buzones indicados en CcAddress pero no en ToAddress
     * 
     * @author jfherrero
     * @date 22/01/2024
     * @param List<EmailMessage> emailList : Lista de email message
     * @param List<Email> mailboxes : Mapa de id del caso padre y el caso padre 
    */
    private List<EmailMessage> checkIfMailboxesOnlyInCc (List<EmailMessage> emailList, List<String> mailboxes) 
    {
        List<EmailMessage> selectedMails = new List<EmailMessage>();

        for (EmailMessage emailMessage : emailList)
        {
            if (emailMessage.ParentId != null && emailMessage.CcAddress != null && emailMessage.ToAddress != null)
            {
                selectedMails=this.checkEmails(emailMessage,mailboxes);
            }
        }

        return selectedMails;
    }

    private List<EmailMessage> checkEmails (EmailMessage emailMessage, List<String> mailboxes) 
    {
        List<EmailMessage> selectedMails = new List<EmailMessage>();

        if(checkIfMailboxesInCc(emailMessage, mailboxes) && checkIfMailboxesInTo(emailMessage, mailboxes))
            {
                // Opta para cierre
                selectedMails.add(emailMessage);
            }
        
            return selectedMails;
    }

    /**
     * Si el alguno de los buzones está en CcAddress pasa a buscar en ToAddress
     * 
     * @author jfherrero
     * @date 22/01/2024
     * @param EmailMessage emailMessage : correo a verificar si está en CcAddress
     * @param List<Email> mailboxes : Mapa de id del caso padre y el caso padre 
    */
    private Boolean checkIfMailboxesInCc (EmailMessage emailMessage, List<String> mailboxes) 
    {
        Boolean closeThisCase = false;
        
        for (String mailboxCc : mailboxes)
        {             
            if (emailMessage.CcAddress.contains(mailboxCc))
            {
                closeThisCase = true;
                break;
            }
        }
        return closeThisCase;
    }
    
    /**
     * Devuelve true si alguno de los buzones está en ToAddress
     * 
     * @author jfherrero
     * @date 22/01/2024
     * @param EmailMessage emailMessage : correo a verificar si está en ToAddress
     * @param List<Email> mailboxes : Mapa de id del caso padre y el caso padre 
    */
    private Boolean checkIfMailboxesInTo (EmailMessage emailMessage, List<String> mailboxes) 
    {
        Boolean closeThisCase = true;
        
        for (String mailboxTo : mailboxes)
        {
            if (emailMessage.ToAddress.contains(mailboxTo))
            {
                closeThisCase = false;
                break;
            }
        }
        
        return closeThisCase;
    }

    /**
     * Pasa los casos selecionados al estado 'Closed'
     * 
     * @author jfherrero
     * @date 22/01/2024
     * @param List<Case> casesToClose : Lista de casos para cerrar
    */
    private void closeCasesOnlyInCc (List<Case> casesToClose) 
    {
        List<Case> openCases = new List<Case>();
        
        for (Case caseToClose : casesToClose)
        {
            if(caseToClose.Status != 'Closed')
            {
                caseToClose.Status = 'Closed';
                caseToClose.CloseDetail__c = 'Buzón centro en copia';
                caseToClose.CloseResult__c = 'No Realizado';
                caseToClose.PendingBy__c = null;
                openCases.add(caseToClose);
            }
        }
        
        if(!openCases.isEmpty())
        {
            update openCases;
        }
    }

    /**
     * Pasa los casos selecionados al ControlEmailCC__c TRUE
     * 
     * @author lrodriguez 
     * @date 27/03/2024
     * @param List<Case> casesToActivate : Lista de casos para activar
    */
    private void casesControlEmailCC (List<Case> casesToActivate) 
    {
        List<Case> updateCases = new List<Case>();
        
        for (Case caseToClose : casesToActivate)
        {
            if(caseToClose.ControlEmailCC__c !=true)
            {
                caseToClose.ControlEmailCC__c =true;
                updateCases.add(caseToClose);
            }
        }
        
        if(!updateCases.isEmpty())
        {
            update updateCases;
        }
    }

     /**
     * Pasa los casos selecionados al ControlEmailCC__c FALSE
     * 
     * @author lrodriguez
     * @date 27/03/2024
     * @param List<Case> casesToDesactivate : Lista de casos para desactivar
    */
    private void casesControlEmailCCDesactivate (List<Case> casesToDesactivate) 
    {
        List<Case> updateCases = new List<Case>();
        
        for (Case caseToClose : casesToDesactivate)
        {
            if(caseToClose.ControlEmailCC__c !=false)
            {
                caseToClose.ControlEmailCC__c =false;
                updateCases.add(caseToClose);
            }
        }
        
        if(!updateCases.isEmpty())
        {
            update updateCases;
        }
    }

    /**
     * Obtener la cola a la que está asignada un correo para devolver su Id. Si no, devuelve el usuario
     * o cola indicado como fallback.
     * 
     * @author aberuete
     * @date 31/01/2024
     * @param EmailMessage email : email para el cual vamos a buscaer la cola
     * @param Id defaultOwnerOnFallback : usuario por defecto en caso de no encontrar la cola
    */
    @TestVisible
    private Id getEmailGenesisQueueId (EmailMessage email, Id defaultOwnerOnFallback)
    {
        if (String.isNotBlank(email?.GenesysQueueName__c))
        {
            List<Group> myQueue = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName = : email.GenesysQueueName__c];

            if (myQueue.size()>0)
            {
                return myQueue[0].Id;
            }
            else
            {
                return defaultOwnerOnFallback;
            }
        }
        else
        {
            return defaultOwnerOnFallback;
        }
    }

    private class EmailMessagesUtilException extends Exception {}
}