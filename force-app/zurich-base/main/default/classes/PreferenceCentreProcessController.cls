public without sharing class PreferenceCentreProcessController
{
    /**
     * @Description: Metodo que actualiza el contacto
     *
     * @Author: iortega 2020-06-04
     */
    public static void doUpdate(Contact contact)
    {
        try
        {
            update contact;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError( e, 'PreferenceCentreProcessController', contact.Id );
        }
    }

    /**
     * @Description: Metodo que inserta un miebro de campaña
     *
     * @Author: iortega 2020-06-04
     */
    public static void doInsert(List<CampaignMember> memberToInsertList)
    {
        try
        {
            insert memberToInsertList;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError( e, 'PreferenceCentreProcessController', memberToInsertList[0].ContactId );
        }
    }

    /**
     * @Description: Metodo que elimina un miebro de campaña
     *
     * @Author: iortega 2020-06-04
     */
    public static void doDelete(List<CampaignMember> membersToDeleteList)
    {
        try
        {
            delete membersToDeleteList;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError( e, 'PreferenceCentreProcessController', membersToDeleteList[0].ContactId );
        }
    }

    /**
     * Get the contact by the hashedId
     * Executes the select with permission to see the contacts. Selector not used because of the permissions issue.
     * 
     * @author nts (agonzalezisasi)
     * @date 27/01/2021
     */
    public static Contact getContactData(String hashedId) 
    {
        Contact contact = null;

        if( String.isNotBlank(hashedId) ) {
            List<Contact> contacts = [
                SELECT Id, Name, LegalEntity__c, HasOptedOutOfEmail, SourceCountry__c, HashedId__c
                FROM Contact
                WHERE HashedId__c = :hashedId
            ];

            if( !contacts.isEmpty() ) {
                contact = contacts[0];
            }
        }

        return contact;
    }

    /**
     * This method executes the select with permission to see the scopes. Selector not used because of the permissions
     * issue.
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2020
     */
    public static Scope__c getScopeData(String hashedId) {
        System.debug('- - - - - PreferenceCentreProcessController.getScopeData - - - - - ');

        Scope__c scope = null;

        // Get the scope by the given hash id
        //! The condition for "Id" should be removed in the future
        List<Scope__c> scopes = [SELECT Id, HasOptedOutOfEmail__c FROM Scope__c WHERE Id = :hashedId OR HashedId__c = :hashedId];
        if( !scopes.isEmpty() ) {
            scope = scopes[0];
        }
    
        return scope;
    }
}