/**
 * Clase con utilidades genéricas
 * @author      : almunoz
 * @date        : 
*/

public class GDPRComplianceUtil 
{
    String initialObject, currentObject, origin;
    public static Boolean errorIsTrue = false;

    /**
     * Método que carga en un mapa los objetos para propagar el Bloqueo/Borrado
     * @param String typeObject: nombre del objeto que inicia el proceso
     * @author almunoz
     * @return Mapa de Bloqueo/Borrado
     * 
    */
 
    public static Map<Integer, Map<Integer, String>> loadSetting(String typeObject)
    {
        List<GDPR_DeleteOrderSettings__mdt> blockOrder = GDPR_DeleteOrderSettings__mdt.getAll().values();
        Map<Integer, Map<Integer, String>> orderSettingsByLevel = new Map<Integer, Map<Integer, String>>();

        if (orderSettingsByLevel == null || orderSettingsByLevel.isEmpty())
        {
            Map <Integer, String> orderSettingsByOrder;

            for (GDPR_DeleteOrderSettings__mdt order : blockOrder)
            {
                
                if (order.Initial_Object__c == typeObject)
                {               
                    if (!orderSettingsByLevel.containsKey(Integer.valueOf(order.Level__c)))
                    {
                        orderSettingsByOrder = new Map<Integer,String>();

                        orderSettingsByOrder.put(Integer.valueOf(order.Order__c), order.ObjectToDelete__c);

                        orderSettingsByLevel.put(Integer.valueOf(order.Level__c), orderSettingsByOrder);
                    } 
                    else 
                    {
                        orderSettingsByOrder = orderSettingsByLevel.get(Integer.valueOf(order.Level__c));

                        if (!orderSettingsByOrder.containsKey(Integer.valueOf(order.Order__c))) 
                        {
                            orderSettingsByOrder.put(Integer.valueOf(order.Order__c), order.ObjectToDelete__c);
                        }

                        orderSettingsByLevel.put(Integer.valueOf(order.Level__c), orderSettingsByOrder);
                    }
                }
            }
        }
         
        return orderSettingsByLevel;
    }
 
    public GDPRComplianceUtil() 
    {

    }

    public static String getQuery (String initialSobject, String currentSobject, String whatAction)
    {
        return queryFactory(initialSobject, currentSobject, whatAction);
    }
 
    /**
      * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que borrar
      * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
      * @param String currentSobject :nombre del objeto que se está bloqueando 
      * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
      * @author almunoz
      * @return La query
      * @date 068/08/2022
    **/
    private static String queryFactory (String initialSobject, String currentSobject, String whatAction)
    {
        String query = null;
        System.debug('Entra en el Switch: ' +currentSobject);
        switch on currentSobject 
        {
            when 'Task'  
            {
                query = queryFactoryTask(initialSobject, whatAction);
            }
            when 'EmailMessage'  
            {
                query = queryFactoryEmailMessage(initialSobject, whatAction);
            }
            when 'Case'  
            {
                query = queryFactoryCase(initialSobject, whatAction);
            }
            when 'Claim__c'  
            {
                query = queryFactoryClaim(initialSobject, whatAction);
            }
            when 'Policy__c'  
            {
                query = queryFactoryPolicy(initialSobject, whatAction);
            }
            when 'CampaignMember'  
            {
                query = queryFactoryCampaignMember(whatAction);
            }
            when 'Contact'  
            {
                query = queryFactoryContact(whatAction);
            }
            when 'Opportunity'  
            {
                query = queryFactoryOpportunity(whatAction);
            }
            when else 
            {
                throw new IllegalArgumentException('No se puede obtener la query para el objeto: ' + currentSobject);
            }
        }
        return query;
 
    }
 
    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
     * @param String currentSobject :nombre del objeto que se está bloqueando
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryTask (String initialSobject, String whatAction)
    {
        String query;

        if(whatAction=='Bloquear')
        {
            Set<Id> caseIDs = new Set<Id>();
            for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Blocked__c=true)]){
                caseIDs.add(cases.Id);
            }
            String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
            query = 'SELECT Id, Blocked__c FROM Task WHERE WhatId IN (' + caseIDString + ') AND Blocked__c = false';
        }else if(whatAction=='Anonimizar')
        {
            Set<Id> caseIDs = new Set<Id>();
            for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                caseIDs.add(cases.Id);
            }
            String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
            query = 'SELECT Id, Anonymized__c FROM Task WHERE WhatId IN (' + caseIDString + ') AND Anonymized__c = false';
        }
         
        return query;
    }
 
    /**
      * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
      * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
      * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
      * @author amunoz
      * @return La query
      * @date 00/07/2023
    **/
    private static String queryFactoryEmailMessage (String initialSobject, String whatAction)
    {
        String query;
         
        if(whatAction=='Bloquear')
        {
            Set<Id> caseIDs = new Set<Id>();
            for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Blocked__c=true)]){
                caseIDs.add(cases.Id);
            }
            String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
            query = 'SELECT Id, Blocked__c FROM EmailMessage WHERE RelatedToId IN (' + caseIDString + ') AND Blocked__c = false';
        }else if(whatAction=='Anonimizar')
        {
            Set<Id> caseIDs = new Set<Id>();
            for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                caseIDs.add(cases.Id);
            }
            String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
            query = 'SELECT Id, Anonymized__c FROM EmailMessage WHERE RelatedToId IN (' + caseIDString + ') AND Anonymized__c = false';
        }
         
        return query;
    }
 
    /**
      * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
      * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
      * @author amunoz
      * @return La query
      * @date 00/07/2023
    **/
    private static String queryFactoryCampaignMember (String whatAction)
    {   
        String query;

        if(whatAction=='Bloquear')
        {
            //Primero hay que sacar los Ids de los Contact Relacionados a Accounts con el Blocked a true
            Set<Id> contactIDs = new Set<Id>();
            for(Contact cont : [SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Blocked__c=true)]){
                contactIDs.add(cont.Id);
            }
            String contactIDString = '\'' + String.join(new List<Id>(contactIDs), '\',\'') + '\'';
            query = 'SELECT Id, Blocked__c FROM CampaignMember WHERE ContactId IN (' + contactIDString + ') AND Blocked__c = false';
        }else if(whatAction=='Anonimizar')
        {
            //Primero hay que sacar los Ids de los Contact Relacionados a Accounts con el Anonymized a true
            Set<Id> contactIDs = new Set<Id>();
            for(Contact cont : [SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                contactIDs.add(cont.Id);
            }
            String contactIDString = '\'' + String.join(new List<Id>(contactIDs), '\',\'') + '\'';
            query = 'SELECT Id, Anonymized__c FROM CampaignMember WHERE ContactId IN (' + contactIDString + ') AND Anonymized__c = false';
        }
     
        return query;
    }
 
    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryContact(String whatAction)
    {
        String query;

        if(whatAction=='Bloquear')
        {
            query = 'SELECT Id, Blocked__c FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Blocked__c = true) AND Blocked__c = false ';
        }else if(whatAction=='Anonimizar'){
            query = 'SELECT Id, Anonymized__c FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c = true) AND Anonymized__c = false ';
        }
        
        return query;
    }

    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryOpportunity(String whatAction)
    {
        String query;
        if(whatAction=='Bloquear')
        {
            query = 'SELECT Id, Blocked__c FROM Opportunity WHERE AccountId IN (SELECT Id FROM Account WHERE Blocked__c = true) AND Blocked__c = false ';
        }else if(whatAction=='Anonimizar')
        {
            query = 'SELECT Id, Anonymized__c FROM Opportunity WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c = true) AND Anonymized__c = false ';
        }
        
        return query;
    }
 
    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
     * @param String currentSobject :nombre del objeto que se está bloqueando
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryCase(String initialSobject, String whatAction)
    {
        String query;

        if(whatAction=='Bloquear')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject=='Account')
            {
                query = 'SELECT Id, Blocked__c FROM Case WHERE AccountId IN (SELECT Id FROM Account Where Blocked__c = true) AND Blocked__c = false';
            }else{  
                query = 'SELECT Id, Blocked__c FROM Case WHERE OfferId__c IN (SELECT Id FROM Opportunity WHERE Blocked__c = true) AND Blocked__c = false ';
            }
        }else if(whatAction=='Anonimizar')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject=='Account')
            {
                query = 'SELECT Id, Anonymized__c FROM Case WHERE AccountId IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = false';
            }else{  
                query = 'SELECT Id, Anonymized__c FROM Case WHERE OfferId__c IN (SELECT Id FROM Opportunity WHERE Anonymized__c = true) AND Anonymized__c = false ';
            }
        }
        
        return query;
    }
     
    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
     * @param String currentSobject :nombre del objeto que se está bloqueando
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryPolicy(String initialSobject, String whatAction)
    {
        String query;

        if(whatAction=='Bloquear')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject=='Account')
            {
                query = 'SELECT Id, Blocked__c FROM Policy__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Blocked__c = true) AND Blocked__c = false';
            }else{
                query = 'SELECT Id, Blocked__c FROM Policy__c WHERE OpportunityName__c IN (SELECT Id FROM Opportunity WHERE Blocked__c = true) AND Blocked__c = false ';
            }
        }else if(whatAction=='Anonimizar')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject=='Account')
            {
                query = 'SELECT Id, Anonymized__c FROM Policy__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = false';
            }else{
                query = 'SELECT Id, Anonymized__c FROM Policy__c WHERE OpportunityName__c IN (SELECT Id FROM Opportunity WHERE Anonymized__c = true) AND Anonymized__c = false ';
            }
        }
        
        return query;
    }
 
    /**
     * Método que obtiene la query para obtener la lista de registros del objeto currentSobject que hay que bloquear del proceso de bloqueo
     * @param String initialSobject :nombre del objeto que ha iniciado el proceso de bloqueo
     * @param String currentSobject :nombre del objeto que se está bloqueando
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author amunoz
     * @return La query
     * @date 00/07/2023
    **/
    private static String queryFactoryClaim(String initialSobject, String whatAction)
    {
        String query;

        if(whatAction=='Bloquear')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject == 'Account')
            {
                query = 'SELECT Id, Blocked__c FROM Claim__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Blocked__c = true) AND Blocked__c = false';
            }else{
                Set<Id> policiesOfferBlocked = new Set<Id>();
                for(Policy__c pol : [SELECT Id FROM Policy__c WHERE OpportunityName__c IN (SELECT Id FROM Opportunity WHERE Blocked__c= true)]){
                    policiesOfferBlocked.add(pol.Id);
                }
                String polIDString = '\'' + String.join(new List<Id>(policiesOfferBlocked), '\',\'') + '\'';
                query = 'SELECT Id, Blocked__c FROM Claim__c WHERE Policy__c IN ('+polIDString+') AND Blocked__c = false ';
            }
        }else if(whatAction=='Anonimizar')
        {
            //Dependiendo de si es Opportunity o Account se obtiene una query diferente.
            if(initialSobject == 'Account')
            {
                query = 'SELECT Id, Anonymized__c FROM Claim__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = false';
            }else{
                Set<Id> policiesOfferBlocked = new Set<Id>();
                for(Policy__c pol : [SELECT Id FROM Policy__c WHERE OpportunityName__c IN (SELECT Id FROM Opportunity WHERE Anonymized__c= true)]){
                    policiesOfferBlocked.add(pol.Id);
                }
                String polIDString = '\'' + String.join(new List<Id>(policiesOfferBlocked), '\',\'') + '\'';
                query = 'SELECT Id, Anonymized__c FROM Claim__c WHERE Policy__c IN ('+polIDString+') AND Anonymized__c = false ';
            }
        }
        
        return query;
    }

    /**
     * Metodo que obtiene el ultimo elemento del mapa de Bloqueo
    */
    public static String getLastObject(Map<Integer,Map<Integer,String>> mapOrderBlock)
    {
        Integer lastIndex = mapOrderBlock.size() -1;
        Integer lastSubIndex = mapOrderBlock.get(lastIndex).size();
        String lastObject = mapOrderBlock.get(lastIndex).get(lastSubIndex);
        return lastObject;
    }
 
    /**
     * Metodo que obtiene el siguiente objeto de la jerarquía en base al que se le pasa por parámetro
    */
    public static String getNextObject(Map<Integer,Map<Integer,String>> mapOrderBlock, String currentObject){
        
        Integer indiceExterno = -1;
        Integer indiceInterno = -1;
        String nextObject;
        for (Integer i : mapOrderBlock.keySet()) {
            Map<Integer, String> subMapa = mapOrderBlock.get(i);
            for (Integer j : subMapa.keySet()) {
                if (subMapa.get(j).equals(currentObject)) { //Cambiar por objeto pasado al metodo
                    indiceExterno = i;
                    indiceInterno = j;
                    break;
                }
            }
        }
        
        if(indiceInterno-1==0){
            if(indiceExterno>0){
                indiceExterno--;
                indiceInterno = mapOrderBlock.get(indiceExterno).size();
                nextObject = mapOrderBlock.get(indiceExterno).get(indiceInterno);
            }else{
                nextObject = mapOrderBlock.get(indiceExterno).get(indiceInterno);
            }
        }else{
            indiceInterno--;
            nextObject = mapOrderBlock.get(indiceExterno).get(indiceInterno);
        }
        
        return nextObject;
    }

    /**
     * Método que se usa para procesar el Scope en función del currentSobject que esté tratando el Batch
    */
    public static void process(List<sObject> scope, String currentObject, String whatAction)
    {
        System.debug('Entra en el process');
        switch on currentObject {
            when  'Task' {
                //Procesar el Scope como task
                System.debug(scope);
                List<Task> currentList = (List<Task>)scope;
                for (Task ct : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        ct.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        ct.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }
            when 'EmailMessage'  
            {
                //Procesar el Scope como EmailMessage
                List<EmailMessage> currentList = (List<EmailMessage>)scope;
                for (EmailMessage cem : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        cem.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        cem.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }
            when 'Case'  
            {
                //Procesar el Scope como Case
                List<Case> currentList = (List<Case>)scope;
                for (Case cc : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        cc.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        cc.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }
            when 'Claim__c'  
            {
                //Procesar el Scope como Claim
                List<Claim__c> currentList = (List<Claim__c>)scope;
                for (Claim__c ccla : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        ccla.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        ccla.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }
            when 'Policy__c'  
            {
                //Procesar el Scope como Policy
                List<Policy__c> currentList = (List<Policy__c>)scope;
                for (Policy__c cpol : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        cpol.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        cpol.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
                
            }
            when 'CampaignMember'  
            {
                //Procesar el Scope como CompaignMember
                List<CampaignMember> currentList = (List<CampaignMember>)scope;
                for (CampaignMember ccm : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        ccm.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        ccm.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
                
            }
            when 'Contact'  
            {
                //Procesar el Scope como Contact
                List<Contact> currentList = (List<Contact>)scope;
                for (Contact ccon : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        ccon.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        ccon.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }
            when 'Opportunity'  
            {
                //Procesar el Scope como Opportunity
                List<Opportunity> currentList = (List<Opportunity>)scope;
                for (Opportunity copp : currentList) {
                    if(whatAction=='Bloquear')
                    {
                        copp.Blocked__c = true;
                    }else if(whatAction=='Anonimizar')
                    {
                        copp.Anonymized__c = true;
                    }
                }
                Database.update(currentList);
            }   
            when else {
                
            }
        }
    }

    /**
     * Método que lanza el batch para el siguiente objeto a bloquear de la jerarquía.
     * @param String initialSobject: nombre del objeto que inicia el proceso de bloqueo
     * @param String futureCurrentObject : nombre del siguiente objeto a bloquear
     * @param String futureNextObject : nombre de la continuación del siguiente objeto a bloquear
     * @param String whatAction     :accion que está llevando a cabo el batch, Bloquear o Anonimizar
     * @author almunoz
     * @date 00/07/2023
    **/
    public static void postProcess(String initialSObject, String futureCurrentObject, String futureNextObject, String whatAction)
    {
        Batch_GDPRPropagateBlocked b = new Batch_GDPRPropagateBlocked(initialSObject, futureCurrentObject, futureNextObject, whatAction);
        database.executeBatch(b, 200);
    }

    /**
     * Método que devuelve las querys para el borrado.
     * @param String currentSobject : Nombre del objeto actual en la jerarquía.
     */
    public static String queryFactoryBorrado (String currentSobject)
    {
        String query;
        switch on currentSobject {
            when 'Task'  
            {
                //Obtener todos las Task con el Anonymized a True
                Set<Id> caseIDs = new Set<Id>();
                for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                    caseIDs.add(cases.Id);
                }
                String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
                query = 'SELECT Id FROM Task WHERE WhatId IN (' + caseIDString + ') AND Anonymized__c = true';
            }
            when 'EmailMessage'  
            {
                //Obtener todos los EmailMessage con el Anonymized a True
                Set<Id> caseIDs = new Set<Id>();
                for(Case cases : [SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                    caseIDs.add(cases.Id);
                }
                String caseIDString = '\'' + String.join(new List<Id>(caseIDs), '\',\'') + '\'';
                query = 'SELECT Id FROM EmailMessage WHERE RelatedToId IN (' + caseIDString + ') AND Anonymized__c = true';
            }
            when 'Case'  
            {
                //Obtener todos los Case con el Anonymized a True
                query = 'SELECT Id FROM Case WHERE AccountId IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = true';
            }
            when 'Claim__c'  
            {
                //Obtener todos los Claim con el Anonymized a True
                query = 'SELECT Id FROM Claim__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = true';
            }
            when 'Policy__c'  
            {
                //Obtener todos las Polizas con el Anonymized a True
                query = 'SELECT Id FROM Policy__c WHERE PolicyHolder__c IN (SELECT Id FROM Account Where Anonymized__c = true) AND Anonymized__c = true';
            }
            when 'CampaignMember'  
            {
                //Obtener todos los CampaignMember con el Anonymized a True
                Set<Id> contactIDs = new Set<Id>();
                for(Contact cont : [SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c=true)]){
                    contactIDs.add(cont.Id);
                }
                String contactIDString = '\'' + String.join(new List<Id>(contactIDs), '\',\'') + '\'';
                query = 'SELECT Id FROM CampaignMember WHERE ContactId IN (' + contactIDString + ') AND Anonymized__c = true';

            }
            when 'Contact'  
            {
                //Obtener todos los Contact con el Anonymized a True
                query = 'SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c = true) AND Account.isPersonAccount = false AND Anonymized__c = true';
            }
            when 'Opportunity'  
            {
                //Obtener todos las Oportunidades con el Anonymized a True
                query = 'SELECT Id FROM Opportunity WHERE AccountId IN (SELECT Id FROM Account WHERE Anonymized__c = true) AND Anonymized__c = true';

            }
            when 'Account'
            {
                //Obetener todas las Account con el Anonymized a True
                query = 'SELECT Id FROM Account WHERE Anonymized__c = true';
            }
            when else 
            {
                throw new IllegalArgumentException('No se puede obtener la query para el objeto: ' + currentSobject);
            }
        }
        return query;
    }

    /**
     * Método encargado de realizar el borrado de lo obtenido en las querys del start del batch
     */
    public static void processAnonimizar(List<sObject> scope, String currentObject)
    {
        switch on currentObject {
            when  'Task' {
                //Procesar el Scope como task
                System.debug('Process Anonimizar Task');
                List<Task> currentList = (List<Task>)scope;
                Database.delete(currentList);
            }
            when 'EmailMessage'  
            {
                //Procesar el Scope como EmailMessage
                System.debug('Process Anonimizar EmailMessage');
                List<EmailMessage> currentList = (List<EmailMessage>)scope;
                Database.delete(currentList);
            }
            when 'Case'  
            {
                //Procesar el Scope como Case
                System.debug('Process Anonimizar Case');
                List<Case> currentList = (List<Case>)scope;
                Database.delete(currentList);
            }
            when 'Claim__c'  
            {
                //Procesar el Scope como Claim
                System.debug('Process Anonimizar Claim__c');
                List<Claim__c> currentList = (List<Claim__c>)scope;
                Database.delete(currentList);
            }
            when 'Policy__c'  
            {
                //Procesar el Scope como Policy
                System.debug('Process Anonimizar Policy__c');
                List<Policy__c> currentList = (List<Policy__c>)scope;
                Database.delete(currentList);
                
            }
            when 'CampaignMember'  
            {
                //Procesar el Scope como CompaignMember
                System.debug('Process Anonimizar CampaignMember');
                List<CampaignMember> currentList = (List<CampaignMember>)scope;
                Database.delete(currentList);
                
            }
            when 'Contact'  
            {
                //Procesar el Scope como Contact
                System.debug('Process Anonimizar Contact');
                List<Contact> currentList = (List<Contact>)scope;
                Database.delete(currentList);
            }
            when 'Opportunity'  
            {
                //Procesar el Scope como Opportunity
                System.debug('Process Anonimizar Opportunity');
                List<Opportunity> currentList = (List<Opportunity>)scope;
                Database.delete(currentList);
            }   
            when 'Account'{
                //Procesar el Scope como Opportunity
                System.debug('Process Anonimizar Account');
                List<Account> currentList = (List<Account>)scope;
                Database.delete(currentList);
            }
            when else {
                
            }
        }
    }

    /**
     * Método que relanza el Batch de borrado para que continue con los objetos de la jerarquía.
     * @param String futureCurrentObject : nombre del siguiente objeto a borrar
     * @param String futureNextObject : nombre de la continuación del siguiente objeto a borrar
     * @author almunoz
     * @date 00/07/2023
    **/
    public static void postProcessAnonymized(String futureCurrentObject, String futureNextObject)
    {
        Batch_GDPRAnonymized b = new Batch_GDPRAnonymized(futureCurrentObject, futureNextObject);
        database.executeBatch(b, 200);
    }
}