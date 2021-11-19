/**
 * @description       : Controlador del componente de cancelación de Call Me Backs ubicado en la página de registro de Account.
 * @author            : Kevin Rueda
 * @group             : 
 * @last modified on  : 19-11-2021
 * @last modified by  : jjuaristi
 * @last modified by  : jjuaristi
**/
public with sharing class CallMeBackListController
{
    /**
     * Función que permite la consulra de registros Contact Request, es invocada desde el componente LWC CallMeBackList
     * @see CallMeBackList.js
     * @author rpolvera
     * @date 17/11/2021
     * @param whatId Identificador del registro de cuenta (Account) relacionada con las Contact Request a cancelar.
     * @return Lista de Contact Request.
     */
    @AuraEnabled(cacheable = true)
    public static List<ContactRequest> getContactRequestsByCustomerId(String whoId)
    {
        List<ContactRequest> contactRequests;

        try
        {
            contactRequests = new ContactRequestSelector().findByCustomerId(whoId);
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }

        return contactRequests;
    }
}