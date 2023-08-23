/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 22/08/2023
 * @last modified by  : jgallaga
**/
public class AccountLeadUtil
{
    public static final String VENTAS_USER = 'Ventas User';
    public static final String AGENTE_VENTAS = 'Agente Ventas';
    public static final String ERROR_MESSAGE = 'Ya existe una Cuenta con el mismo Documento de identidad o Teléfono';
    public static final String LEAD = 'Lead';

    /**
     * Método que comprueba que se lance la validación sólo se lance desde los dos perfiles indicados
     * @author overes
     * @date 08/08/2023
     */
    public static void checkLeadDuplicates(List<Account> newList)
    {
        if (ProfilesSelector.getLoggedUserProfile() == VENTAS_USER || ProfilesSelector.getLoggedUserProfile() == AGENTE_VENTAS)
        {
            checkLeads(newList);
        }
    }

    /**
     * Método que mustra el mensaje en caso que se encuentre otro registro igual
     * @author overes
     * @date 08/08/2023
     */
    public static List<Account> checkLeads(List<Account> newList){
        List<Account> accList = newList;
        for (Account acc : accList)
        {
            Account newAcc = new Account();
            newAcc = leadDuplicatesControl(acc.NationalId__c, acc.Phone);
            if ((newAcc != null) && (newAcc.RecordType.DeveloperName == LEAD))
            {
                acc.addError( ERROR_MESSAGE + ' (' + newAcc.Name + ' ' + newAcc.Id + ')');
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
        AccountsSelector accountsSelector = new AccountsSelector();
        if (documentID != null)
        {
            List<Account> accList = accountsSelector.findByNationalIdAndRcTypeCustAndBC(new List<String>{documentID});
            if (!accList.isEmpty())
            {
                acc = accList.get(0);
            } else
            {
                List<Account> accLeadList = accountsSelector.findByNationalIdAndRcTypeLead(new List<String>{documentID});
                if (!accLeadList.isEmpty())
                {
                    acc = accLeadList.get(0);
                }
            }
        } else
        {
            if(phone != null)
            {
                List<Account> accPhoneList = accountsSelector.findByPhoneAndRcTypeLead(new List<String>{phone});
                if (!accPhoneList.isEmpty())
                {
                    acc = accPhoneList.get(0);
                }
            } else
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
        if(String.isNotBlank(intermediaryCode))
        {
            return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode).getAssignmentAsMap();
        }

        if(acc != null)
        {
            if(String.isNotBlank(acc.Intermediary_Name__c))
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

}