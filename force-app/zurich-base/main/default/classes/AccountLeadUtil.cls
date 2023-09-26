/**
 * @description       :
 * @author            : overes
 * @group             :
 * @last modified on  : 10-09-2023
 * @last modified by  : overes
 **/
public class AccountLeadUtil
{
    public static final String LEAD = 'Lead';

    /**
     * Método que comprueba que se lance la validación sólo se lance desde los dos perfiles indicados
     * @author overes
     * @date 08/08/2023
     */
    public static void checkLeadDuplicates(List<Account> newList)
    {
        if (ProfilesSelector.getLoggedUserProfile() == Label.Profile_Ventas_User || ProfilesSelector.getLoggedUserProfile() == Label.Profile_Agente_Ventas)
        {
            checkLeads(newList);
        }
    }

    /**
     * Método que mustra el mensaje en caso que se encuentre otro registro igual
     * @author overes
     * @date 08/08/2023
     *
     * @change amiranda 04/09/2023 Se cambia el mensaje a mostrar. En vez de utilizar
     * el campo 'Name', se concatena el campo 'FirstName' + 'LastName'.
     */
    public static List<Account> checkLeads(List<Account> newList)
    {
        List<Account> accList = newList;
        for (Account acc : accList)
        {
            if (Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(acc.RecordTypeId).getName() == LEAD)
            {
                Account newAcc = new Account();
                newAcc = leadDuplicatesControl(acc.NationalId__c, acc.Phone);
                if (newAcc != null)
                {
                    String errorMsg = Label.Lead_Duplicates_Control_Error + ': ';
                    if ( !String.isBlank(newAcc.FirstName) )
                    {
                        errorMsg += +newAcc.FirstName + ' ';
                    }
                    if ( !String.isBlank(newAcc.LastName) )
                    {
                        errorMsg += newAcc.LastName + ' ';
                    }
                    acc.addError(errorMsg + '(' +  newAcc.Id + ')');
                }
            }
        }
        return accList;
    }

    /**
     * Método que evuelve la Cuenta de tipo Cliente o de tipo Lead localizada, en el caso de que se localice alguna.
     * @author overes
     * @date 08/08/2023
     * @return acc
     */
    public static Account leadDuplicatesControl(String documentID, String phone)
    {
        Account acc = new Account();
        AccountSelectorWithoutSharing accountsSelectorWS = new AccountSelectorWithoutSharing();
        if (documentID != null)
        {
            List<Account> accList = accountsSelectorWS.findByNationalIdAndRcTypeCustAndBC(new List<String> {documentID});
            if ( !accList.isEmpty() )
            {
                acc = accList.get(0);
            }
            else
            {
                List<Account> accLeadList = accountsSelectorWS.findByNationalIdAndRcTypeLead(new List<String> {documentID});
                if ( !accLeadList.isEmpty() )
                {
                    acc = accLeadList.get(0);
                }
                else
                {
                    acc = null;
                }
            }
        }
        else
        {
            if(phone != null)
            {
                acc = checkLeadDuplicatePhone(phone, accountsSelectorWS);
            }
            else
            {
                acc = null;
            }
        }
        return acc;
    }

    /**
     * @description Funcionalidad para conseguir el Id de usuario del agente intermediario
     *              al que se le debe asignar la cuenta de Lead. A partir de los parametros
     *              recibidos se realizará una búsqueda del agente mediante la configuración
     *              de metadatos.
     * @param       Account - acc
     *              Un registro de cuenta
     * @param       String - intermediaryCode
     *              Código de intermediario del agente
     * @param       String - origin
     *              Origen desde donde proviene la información a gestionar
     * @param       String - language
     *              Idioma a utilizar para asignar el agente que le corresponde
     * @param       String - portalCode
     *              Código postal con el que se puede obtener el agente
     * @return      String
     *              Puede devolver el Id del Agente si se encuentra la configuración correcta.
     *              Si no puede que devuelva el Id del usuario por defecto o el valor 'CONTACT_CENTER'
     */
    public static Map<String, Account> leadAssignment(Account acc, String intermediaryCode, String origin, String language, String postalCode)
    {
        if( String.isNotBlank(intermediaryCode) )
        {
            return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode).getAssignmentAsMap();
        }

        if(acc != null)
        {
            if( String.isNotBlank(acc.Intermediary_Name__c) )
            {
                intermediaryCode = acc.Intermediary_Name__r.INFOIntermediaryCode__c;
            }

            return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode).getAssignmentAsMap();
        }

        if(String.isNotBlank(language) && language != 'ES')
        {
            return AccountLeadAssignment.getAssignedUserIdByLanguage(language).getAssignmentAsMap();
        }

        return AccountLeadAssignment.getAssignedUserIdByAssignmentType(origin, postalCode).getAssignmentAsMap();
    }

    /**
     * Método que evuelve la Cuenta de tipo Cliente o de tipo Lead localizada, en el caso de que se localice alguna con el phone indicado
     * @author overes
     * @date 25/08/2023
     * @return acc
     */
    public static Account checkLeadDuplicatePhone(String phone, AccountSelectorWithoutSharing accountsSelectorWS)
    {
        Account acc = new Account();
        List<Account> accPhoneList = accountsSelectorWS.findByPhoneAndRcTypeLead(new List<String> {phone});
        if ( !accPhoneList.isEmpty() )
        {
            acc = accPhoneList.get(0);
        }
        else
        {
            acc = null;
        }
        return acc;
    }
}