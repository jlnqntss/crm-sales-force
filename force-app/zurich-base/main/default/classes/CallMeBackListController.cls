/**
 * @description       : Controlador del componente de cancelación de Call Me Backs ubicado en la página de registro de Account.
 * @author            : Kevin Rueda
 * @group             : 
 * modified on        : 19-11-2021
 * modified by        : jjuaristi
 * 
 * @last modified on  : 20-01-2022
 * @last modified by  : arcortazar
**/
public with sharing class CallMeBackListController
{
    /**
     * Función que permite la consulra de registros Contact Request, es invocada desde el componente LWC CallMeBackList
     * @see CallMeBackList.js
     * @author rpolvera
     * @date 17/11/2021
     * @last modified by  : arcortazar@nts-solutions.com
     * @param whatId Identificador del registro de cuenta (Account) relacionada con las Contact Request a cancelar.
     * @param name Nombre de la cuenta (Account) relacionada con las Contact Request (Añadido por arcortazar - 20/01/2022: Fix del componente CallMeBack)
     * @return Lista de Contact Request.
     */
    @AuraEnabled(cacheable = true)
    public static List<ContactRequest> getContactRequestsByCustomerId(String whoId, String name)
    {
        List<ContactRequest> contactRequests;

        try
        {
            contactRequests = new ContactRequestSelector().findByCustomerId(whoId, name);
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }

        return contactRequests;
    }
}