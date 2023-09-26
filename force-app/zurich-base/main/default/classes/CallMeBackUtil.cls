/**
 * @description       : Clase de utilidad para trabajar sobre CallMeBacks
 * @author            : amiranda
 * @date              : 22-09-2023
 * @last modified on  : 22-09-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   20-09-2023   amiranda   Initial Version
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
    public static String insertCallMeBack(CallMeBack requestCallMeBack, String queueName, String businessHoursName)
    {
        if (queueName == null)
        {
            throw new CallMeBackException('Genesys \'queueName\' can not be null');
        }

        List<purecloud__PureCloud_Queue__c> genesysQueue = [SELECT Id, purecloud__PureCloud_Queue_ID__c
                                                            FROM purecloud__PureCloud_Queue__c
                                                            WHERE Name = :queueName];

        if ( genesysQueue == null || genesysQueue.isEmpty() )
        {
            throw new CallMeBackException('Genesys ' + queueName + ' queue does not exist');
        }

        List<Account> customers = AccountSearchService.findCustomersByPhoneNumber(new List<String> {requestCallMeBack.phone},
                                                                                  RecordsSelector.Scope.VENTAS,
                                                                                  RecordsSelector.LegalEntity.ALL,
                                                                                  null,
                                                                                  null);
        String contactRequestId;

        try
        {
            ContactRequest contactRequest = new ContactRequest();
            contactRequest.PreferredContactDatetime__c = SystemUtil.getContactDatetime(requestCallMeBack.bestTimeFrom, businessHoursName);
            contactRequest.PreferredPhone = requestCallMeBack.phone;
            contactRequest.WebName__c = requestCallMeBack.name;
            contactRequest.WebIdentifier__c = requestCallMeBack.webIdentifier;
            contactRequest.BusinessCode__c = requestCallMeBack.businessCode;
            contactRequest.GenesysCloudQueueId__c = genesysQueue[0].Id;

            if( !customers.isEmpty() )
            {
                contactRequest.WhoId = customers.get(0).PersonContactId;
            }

            insert contactRequest;

            contactRequestId = String.valueOf(contactRequest.Id);
        }
        catch(Exception ex)
        {
            throw new CallMeBackException(ex);
        }

        return contactRequestId;
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
     * Clase interna que representa un error que se produce dentro de la clase
     * CallMeBackUtil
     */
    public class CallMeBackException extends Exception
    {}
}