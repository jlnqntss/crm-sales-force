/**
 * @author overes
 * @date 09/08/2023
 */

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
     */
    public static List<Account> checkLeads(List<Account> newList){
        List<Account> accList = newList;
        for (Account acc : accList)
        {
            if (acc.RecordType.DeveloperName == LEAD)
            {
                Account newAcc = new Account();
                newAcc = leadDuplicatesControl(acc.NationalId__c, acc.Phone);
                if (newAcc != null)
                {
                    acc.addError( Label.Lead_Duplicates_Control_Error + ' (' + newAcc.Name + ' ' + newAcc.Id + ')');
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
}