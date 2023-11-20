/**
 * @description       : Clase controladora utilizada en el componente LWC 
 * 'intermAddCampaignMember'
 * 
 * @author            : amiranda
 * @date              : 20-11-2023
 * @last modified on  : 20-11-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   20-11-2023   amiranda   Initial Version
**/
public with sharing class IntermAddCampaignMemberController
{
    private static final String CLASS_NAME = 'IntermAddCampaignMemberController';
    private static final String CAMPAIGNID_MESSAGE_EXCEPTION = System.Label.ZRM_IntermAddCampMember_CampaignIdExceptionMessage;

    /**
     * @description Método que recupera los contactos relacionados con cuentas 
     * de tipo 'Customer' y 'BusinessCustomer' sobre los que un usuario tiene acceso
     * y la cuenta relacionada con el contacto no tiene ningún otro contacto relacionado
     * con un registro de 'CampaignMember'.
     *
     * @author amiranda
     * @date 10-10-2023
     * @param campaignId Id de la Campaña sobre la que se comprueba que las cuentas
     * recuperadas no tienen registro de `CampaignMember'
     * @return List<Contact> Lista de contactos recuperados
     * @where LWC IntermAddCampaignMember
     **/
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(Id campaignId)
    {
        List<Contact> contacts;

        try
        {
            Set<Id> accountIds = getAccountIdsRelatedToCampaignMembers(campaignId);
            List<Contact> contactsRetrieved = new ContactsSelector().selectByRelatedAccountRecordTypeAndNotInAccountIds(new List<String> { AccountsSelector.RT_NAME_CUSTOMER,
                                                                                                                                  AccountsSelector.RT_NAME_BUSINESSCUSTOMER}, accountIds);

            // Se eliminan los contactos adicionales (de forma aleatoria) que cuelgan de una misma cuenta
            Map<Id, Contact> contactByAccountId = new Map<Id, Contact>();
            for (Contact contact : contactsRetrieved) 
            {
                contactByAccountId.put(contact.AccountId, contact);
            }       

            contacts = contactByAccountId.values();
        }
        catch (Exception ex)
        {
            throw new AuraHandledException( ex.getMessage() );
        }

        return contacts;
    }

    /**
     * @description Método que se encarga de insertar los miembros de campaña
     * que se pasan por parámetro.
     *
     * Se ha acordado con Jon Ander no realizar ningún control a nivel de seguridad
     * puesto que para que un usuario tenga permisos sobre el objeto 'CampaignMember'
     * no es suficiente con que disponga de permisos a nivel de objeto (por ejemplo
     * a través de un PS), sino que debe tener marcado el checkbox 'Marketing User'
     * 
     * @author amiranda
     * @date 18-10-2023
     * @param campaignMembers Lista con los miembros de campaña a insertar
     * @where LWC IntermAddCampaignMember
     **/
    @AuraEnabled
    public static void insertCampaignMembers(List<CampaignMember> campaignMembers)
    {
        try
        {
            insert campaignMembers;
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException( ex.getMessage() );
        }
    }

    /**
     * @description Método que recupera los Ids de las cuentas relacionadas con los
     * contactos que a su vez están relacionados con los registros de 'CampaignMember' de una campañana.
     *
     * @author amiranda
     * @date 10-10-2023
     * @param campaignId Id de la Campaña sobre la que se extraen los Ids de las cuentas
     * @return Set<Id> Conjunto de Ids de las cuentas relacionadas con los registros
     * 'CampaignMember'
     **/
    @TestVisible
    private static Set<Id> getAccountIdsRelatedToCampaignMembers(Id campaignId)
    {
        // Se buscan los miembros de campaña
        List<CampaignMember> campaignMembers = new CampaignMembersSelector.ProperCampaignMembersSelector().selectByCampaignId(campaignId);

        // Se obtienen los Ids de las cuentas relacionadas con los contactos que a su vez están relacionados con los miembros de campaña
        Set<Id> campaignMembersAccountIds = new Set<Id>();

        for (CampaignMember campaignMember : campaignMembers)
        {
            campaignMembersAccountIds.add(campaignMember.Contact.AccountId);
        }

        return campaignMembersAccountIds;
    }

}