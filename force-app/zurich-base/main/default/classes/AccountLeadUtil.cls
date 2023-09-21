/**
 * @description       :
 * @author            : overes
 * @group             :
 * @last modified on  : 21/09/2023
 * @last modified by  : jgallaga
**/
public with sharing class AccountLeadUtil
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
    public static List<Account> checkLeads(List<Account> newList){
        List<Account> accList = newList;
        AccountsSelector accSelector = new AccountsSelector();
        for (Account acc : accList)
        {
            if (Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(acc.RecordTypeId).getName() == LEAD)
            {
                Account newAcc = new Account();
                newAcc = leadDuplicatesControl(acc.NationalId__c, acc.Phone);
                if (newAcc != null)
                {
                    acc.addError(Label.Lead_Duplicates_Control_Error + ' (' + accSelector.findAccountNameById(new List<String>{(String)newAcc.Id}).get(0).Name + ' ' + newAcc.Id + ')');
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
     * *
     * @modification    Se crea un método privado para buscar el lead a partir del identificador del documento
     * @author          jgallaga
     * @date            21/09/2023
     */
    public static Account leadDuplicatesControl(String documentID, String phone)
    {
        Account acc = null;

        if (String.isNotBlank(documentID))
        {
            acc = checkLeadCuplicateByDocumentID(documentID);
        }

        if(acc != null)
        {
            return acc;
        }

        if(String.isNotBlank(phone))
        {
            acc = checkLeadDuplicatePhone(phone);
        }

        return acc;
    }

    /**
     * @description Funcionalidad para conseguir el Id de usuario del agente intermediario
     *              al que se le debe asignar la cuenta de Lead. A partir de los parametros
     *              recibidos se realizará una búsqueda del agente mediante la configuración
     *              de metadatos.
     * @author      jgallaga
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

    /**
     * @description Método para buscar una cuenta de tipo Lead asociada al documento de identificación facilitado
     * @author  jgallaga
     * @date    21/09/2023
     */
    private static Account checkLeadCuplicateByDocumentID(String documentId)
    {
        Account acc = null;
        AccountsSelector accountsSelector = new AccountsSelector();

        if(String.isBlank(documentId))
        {
            return acc;
        }

        List<Account> accList = accountsSelector.findByNationalIdAndRcTypeCustAndBC(new List<String>{documentID});

        if (!accList.isEmpty())
        {
            acc = accList.get(0);
        }
        else
        {
            List<Account> accLeadList = accountsSelector.findByNationalIdAndRcTypeLead(new List<String>{documentID});

            if (!accLeadList.isEmpty())
            {
                acc = accLeadList.get(0);
            }
        }

        return acc;
    }

    /**
     * Método que devuelve la Cuenta de tipo Cliente o de tipo Lead localizada, en el caso de que se localice alguna con el phone indicado
     * @author overes
     * @date 25/08/2023
     * @return acc
     * *
     * @modification    Se adapta la lógica de selección de Lead teniendo en cuenta el Scope__c y ContactPointPhone
     * @author          jgallaga
     * @date            21/09/2023
     */
    public static Account checkLeadDuplicatePhone(String phone)
    {
        Account acc = null;

        if(String.isBlank(phone))
        {
            return acc;
        }

        Map<Id,List<ContactPointPhone>> scopeByAccountId = new Map<Id,List<ContactPointPhone>>();

        // TODO - Selector Scope
        List<ContactPointPhone> scopesWithPhone =  [SELECT Scope__c,ScopeId__c, ScopeId__r.AccountId__c, ScopeId__r.AccountId__r.Createddate FROM ContactPointPhone WHERE TelephoneNumber = :phone AND ScopeId__r.AccountId__r.RecordType.DeveloperName = 'Lead'];

        // Ordenamos los scopes por cuenta para ver si hay varias cuentas con el mismo teléfono
        for(ContactPointPhone currentScope : scopesWithPhone)
        {
            if(! scopeByAccountId.containsKey(currentScope.ScopeId__r.AccountId__c))
            {
                scopeByAccountId.put(currentScope.ScopeId__r.AccountId__c, new List<ContactPointPhone>());
            }

            scopeByAccountId.get(currentScope.ScopeId__r.AccountId__c).Add(currentScope);
        }

        // Si existe un scope o varios para una misma cuenta, devolver esa cuenta.

        if(scopeByAccountId.isEmpty())
        {
            return null;
        }

        if(scopeByAccountId.size() == 1)
        {
            Id foundAccount = new List<Id>(scopeByAccountId.keySet()).get(0);
            return [SELECT Id FROM Account WHERE Id = :foundAccount];
        }

        ContactPointPhone targetAccountCPP = getMostRecentAccountFromContactPointPhones(scopeByAccountId.values());

        if(targetAccountCPP == null)
        {
            return null;
        }

        // TODO - Selector
        return [SELECT Id FROM Account WHERE id = :targetAccountCPP.ScopeId__r.AccountId__c];
    }

    private static ContactPointPhone getMostRecentAccountFromContactPointPhones(List<List<ContactPointPhone>> cpps)
    {

        Boolean accountLeadFound = false;
        ContactPointPhone targetAccountCPP = null;

        for(List<ContactPointPhone> currentCPPGroup : cpps)
        {
            for(ContactPointPhone currentCPP : currentCPPGroup)
            {
                // El primero siempre sirve
                if(targetAccountCPP == null)
                {
                    targetAccountCPP = currentCPP;
                    continue;
                }

                // Si ya tenemos una cuenta del scope de ventas, no hace falta mirar el resto
                if(currentCPP.ScopeId__r.Scope__c != 'Ventas' && accountLeadFound)
                {
                    continue;
                }

                // Si la cuenta del scope es mas reciente, nos lo quedamos, si ademas es de ventas, ponemos a true que tenemos al menos uno
                if(targetAccountCPP.ScopeId__r.AccountId__r.CreatedDate > currentCPP.ScopeId__r.AccountId__r.CreatedDate)
                {
                    targetAccountCPP = currentCPP;
                    accountLeadFound = currentCPP.ScopeId__r.Scope__c == 'Ventas';
                }
            }
        }

        return targetAccountCPP;
    }
}