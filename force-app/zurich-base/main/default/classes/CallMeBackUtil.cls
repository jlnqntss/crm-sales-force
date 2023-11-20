/**
 * @description       : Clase de utilidad para trabajar sobre CallMeBacks
 * @author            : amiranda
 * @date              : 29-09-2023
 * @last modified on  : 20-11-2023
 * @last modified by  : arcortazar
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   20-09-2023   amiranda   Initial Version
 * 2.0   20-11-2023   arcortazar   Bulkified Version
 **/
public with sharing class CallMeBackUtil
{
    /**
     * @description Método que se encarga de insertar un registro de ContactRequest.
     * Necesita una cola de Genesys.
     *
     * @author amiranda
     * @date 20-09-2023
     * @param requestCallMeBack con el formato esperado de CallMeBack
     * @param queueName nombre de la cola de Genesys
     * @param businesHoursName nombre de las Business Hours a tener en cuenta
     * @param businessCode código de negocio
     * @return String Id de SF del ContactRequest
     * @throws CallMeBackException
     **/
    public static List<String> insertCallMeBack(List<CallMeBackFull> lstRequests)
    {
        List<String> returningCallMeBackId = new List<String>();
        List<ContactRequest> contactRequestToInsert = new List<ContactRequest>();

        List<String> lstPhones = new List<String>();
        List<String> lstQueueNames = new List<String>();

        for(CallMeBackFull cmbf : lstRequests) 
        {
            lstPhones.add(cmbf.request.phone);
            lstQueueNames.add(cmbf.queueName);
        }

        Map<String, purecloud__PureCloud_Queue__c> mapGenesysQueue = obtainGenesysQueues(lstQueueNames);
        Map<String, Account> mapAccounts = obtainAccountsByPhone(lstPhones);

        for(CallMeBackFull obj : lstRequests)
        {
            CallMeBack requestCallMeBack = obj.request;
            String queueName = obj.queueName;
            String businessHoursName = obj.businessHoursName;
            
            ContactRequest contactRequest = new ContactRequest();
            contactRequest.PreferredContactDatetime__c = SystemUtil.getContactDatetime(requestCallMeBack.bestTimeFrom, businessHoursName);
            contactRequest.PreferredPhone = requestCallMeBack.phone;
            contactRequest.WebName__c = requestCallMeBack.name;
            contactRequest.WebIdentifier__c = requestCallMeBack.webIdentifier;
            contactRequest.BusinessCode__c = requestCallMeBack.businessCode;

            // Obtenemos la cola de genesys entre las buscadas
            if(queueName != '' && mapGenesysQueue.keyset().contains(queueName))
            {
                contactRequest.GenesysCloudQueueId__c = mapGenesysQueue.get(queueName).id;
            }
            else if (!mapGenesysQueue.keyset().contains(queueName))
            {
                throw new CallMeBackException('Genesys ' + queueName + ' queue does not exist');
            }

            // Buscamos el contacto entre los obtenidos
            if( mapAccounts.keyset().contains(requestCallMeBack.phone))
            {
                contactRequest.WhatId = mapAccounts.get(requestCallMeBack.phone).id;
            }

            contactRequestToInsert.add(contactRequest);        
        }
        
        if (!contactRequestToInsert.isEmpty())
        {
            Database.SaveResult[] srResults = Database.insert(contactRequestToInsert, false);
            for (Database.SaveResult sr : srResults)
            {
                if(!sr.isSuccess())
                {
                    ErrorLogUtil.commitError('ERROR', 'No se pudo insertar el CallMeBack: ' + sr.getErrors()[0].getMessage(), 'CallMeBackUtil');

                }
            }

            for(ContactRequest cr : contactRequestToInsert)
            {
                returningCallMeBackId.add(cr.id);
            }
        }

        return returningCallMeBackId;
    }

    /**
     * @description Método que obtiene toda la información relativa a las colas que le indicamos
     *
     * @author arcortazar
     * @date 20-11-2023
     * @param lstQueueNames Lista de Strings con los nombres de las colas que se desean buscar 
     * @return Map<String, purecloud__PureCloud_Queue__c> Mapa con las colas encontradas, identificadas por ID de la cola
     * @throws CallMeBackException
     **/
    private static Map<String, purecloud__PureCloud_Queue__c> obtainGenesysQueues(List<String> lstQueueNames)
    {
        Map<String, purecloud__PureCloud_Queue__c> mapGenesysQueue = new Map<String, purecloud__PureCloud_Queue__c>();
        // Comprobamos las colas
        if (!lstQueueNames.isEmpty())
        {
            List<purecloud__PureCloud_Queue__c> genesysQueue = [SELECT Id, Name, purecloud__PureCloud_Queue_ID__c
                                                                FROM purecloud__PureCloud_Queue__c
                                                                WHERE Name IN : lstQueueNames];

            if(genesysQueue.isEmpty())
            {
                throw new CallMeBackException('Genesys \'queueName\' can not be null');    
            }
            else
            {
                for(purecloud__PureCloud_Queue__c q : genesysQueue)
                {
                    mapGenesysQueue.put(q.Name, q);
                }
            }
        }
        else 
        {
            throw new CallMeBackException('Genesys \'queueName\' can not be null');    
        }

        return mapGenesysQueue;
    }

    /**
     * @description Método que obtiene las cuentas en base al número de teléfono
     *
     * @author arcortazar
     * @date 20-11-2023
     * @param phones Lista de Strings con los números de teléfonos a buscar
     * @return Map<String, Account> Mapa con cuentas encontradas, identificadas por el teléfono
     **/
    private static Map<String, Account> obtainAccountsByPhone(List<String> phones)
    {
        // Buscamos los teléfonos por el contact point phone
        List<Account> customers = AccountSearchService.findCustomersByPhoneNumber(phones, RecordsSelector.Scope.VENTAS, RecordsSelector.LegalEntity.ALL, null, null);
        Map<String, Account> mapaAccount = new Map<String, Account>();
        for(Account a : customers)
        {
            mapaAccount.put(a.phone, a);
        }

        // Comprobamos si hemos encontrado todos los teléfonos
        List<String> notFound = new List<String>();
        for(String p : phones)
        {
            if(!mapaAccount.keyset().contains(p))
            {
                notFound.add(p);
            }
        }

        // Si hay teléfonos que no hayamos encontrado, los buscamos en 
        if(!notFound.isEmpty())
        {
            List<Account> accounts = [SELECT Id, phone FROM Account WHERE Phone IN : notFound];
            if(!accounts.isEmpty())
            {
                for(Account a : accounts)
                {
                    mapaAccount.put(a.phone, a);
                }
            }
        }

        return mapaAccount;
    }

    /**
     * Clase interna que representa una solicitud de Call Me Back
     */
    public class CallMeBack
    {
        public String name {get; set;}
        public String phone {get; set;}
        public Datetime bestTimeFrom {get; set;}
        public Datetime bestTimeUntil {get; set;}
        public String webIdentifier {get; set;}
        public String businessCode {get; set;}
    }

    /**
     * Clase interna que representa una solicitud de Call Me Back junto con los datos asociados
     */
    public class CallMeBackFull
    {
        public CallMeBack request {get; set;}
        public String queueName {get; set;}
        public String businessHoursName {get; set;}
    }

    /**
     * Clase interna que representa un error que se produce dentro de la clase
     * CallMeBackUtil
     */
    public class CallMeBackException extends Exception
    {}
}