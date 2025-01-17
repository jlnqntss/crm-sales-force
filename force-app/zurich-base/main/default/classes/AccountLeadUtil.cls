/**
 * @description       :
 * @author            : overes
 * @group             :
 * @last modified on  : 28-09-2023
 * @last modified by  : overes
 **/
public with sharing class AccountLeadUtil
{
    public static final String LEAD = 'Lead';

    // #region Check Duplicates Public

    /**
     * Método que comprueba que se lance la validación sólo se lance desde los dos perfiles indicados
     * @author overes
     * @date 08/08/2023
     */
    public static void checkLeadDuplicates(List<Account> newList)
    {
        String profileAGR = GlobalConfigUtil.getGlobalConfigurationValue('Profile_Name_Agente_Ventas_AGR');
        String profileNameUserLogged = ProfilesSelector.getLoggedUserProfile();
        if (Label.Profile_Ventas_User.equals(profileNameUserLogged) || Label.Profile_Agente_Ventas.equals(profileNameUserLogged) || profileAGR?.equals(profileNameUserLogged))
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
                    AccountSelectorWithoutSharing accountsSelectorWS = new AccountSelectorWithoutSharing();
                    acc.addError(Label.Lead_Duplicates_Control_Error + ': ' + accountsSelectorWS.findAccountNameById(newAcc.Id).get(0).Name + ' (' +  newAcc.Id + ')');
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

        if ( String.isNotBlank(documentID) )
        {
            acc = checkLeadCuplicateByDocumentID(documentID);
        }

        if(acc != null)
        {
            return acc;
        }

        if( String.isNotBlank(phone) )
        {
            acc = checkLeadDuplicatePhone(phone);
        }

        return acc;
    }

    // #endregion

    // #region LeadAssignment Public

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
        if( String.isNotBlank(intermediaryCode) )
        {
            return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode).getAssignmentAsMap();
        }

        if(acc != null)
        {
            // reutilizo la variable de entrada ya que solo entra aquí si está vacía
            intermediaryCode = leadAssignmentWhenAccountExists(acc, origin, language, postalCode);

            if (String.isNotEmpty(intermediaryCode)) {
                return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode).getAssignmentAsMap();
            } else {
                return leadAssignmentWhenAccountNotExists(origin, language, postalCode);
            }

        } else {
            return leadAssignmentWhenAccountNotExists(origin, language, postalCode);
        }        
    }    

    // #endregion

    // #region CheckDuplicates Private

    /**
     * @description Método para buscar una cuenta de tipo Lead asociada al documento de identificación facilitado
     * @author  jgallaga
     * @date    21/09/2023
     */
    private static Account checkLeadCuplicateByDocumentID(String documentId)
    {
        Account acc = null;
        AccountsSelector accountsSelector = new AccountsSelector();
        AccountSelectorWithoutSharing accountsSelectorWS = new AccountSelectorWithoutSharing();

        if( String.isBlank(documentId) )
        {
            return acc;
        }

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

        if( String.isBlank(phone) )
        {
            return acc;
        }

        // Del teléfono recibido calculo sus variantes con y sin código de país para consultarlo en los lead
        List<String> phonesList = getVariantsPhones(phone);
        Map<Id,List<ContactPointPhone> > scopeByAccountId = getContactPointPhonesByLeadAccountId(phonesList);

        // Si no hay contact point phones -> nulo
        if( scopeByAccountId.isEmpty() )
        {
            return acc;
        }

        // Si solo hay una cuenta, devolver ese
        if(scopeByAccountId.size() == 1)
        {
            Id foundAccount = new List<Id>( scopeByAccountId.keySet() ).get(0);
            return ( new AccountSelectorWithoutSharing() ).findAccountById(foundAccount);
        }

        // En el resto, buscar la cuenta mas reciente, con preferencia a los de RecordType Lead
        String targetAccountId = getMostRecentAccountFromContactPointPhones( scopeByAccountId.values() );

        if( String.isBlank(targetAccountId) )
        {
            return null;
        }

        return ( new AccountSelectorWithoutSharing() ).findAccountById(targetAccountId);
    }

    private static Map<Id, List<ContactPointPhone> > getContactPointPhonesByLeadAccountId(List<String> phonesList)
    {
        Map<Id,List<ContactPointPhone> > scopeByAccountId = new Map<Id,List<ContactPointPhone> >();

        AccountSelectorWithoutSharing cppSelector = new AccountSelectorWithoutSharing();
        List<ContactPointPhone> scopesWithPhone = cppSelector.selectByAccountScopeLead(phonesList);

        // Ordenamos los scopes por cuenta para ver si hay varias cuentas con el mismo teléfono
        for(ContactPointPhone currentScope : scopesWithPhone)
        {
            if( !scopeByAccountId.containsKey(currentScope.ScopeId__r.AccountId__c) )
            {
                scopeByAccountId.put( currentScope.ScopeId__r.AccountId__c, new List<ContactPointPhone>() );
            }

            scopeByAccountId.get(currentScope.ScopeId__r.AccountId__c).Add(currentScope);
        }

        return scopeByAccountId;
    }

    private static String getMostRecentAccountFromContactPointPhones(List<List<ContactPointPhone> > cpps)
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

                // Si ya se ha encontrado al menos una cuenta del scope de ventas, no hace falta mirar el resto de scopes
                if(currentCPP.ScopeId__r.Scope__c != 'Ventas' && accountLeadFound)
                {
                    continue;
                }

                // Si la cuenta del scope es mas reciente, nos lo quedamos, si ademas es de ventas, ponemos a true que tenemos al menos uno
                if(targetAccountCPP.ScopeId__r.AccountId__r.LastModifiedDate > currentCPP.ScopeId__r.AccountId__r.LastModifiedDate)
                {
                    targetAccountCPP = currentCPP;
                    accountLeadFound = currentCPP.ScopeId__r.Scope__c == 'Ventas';
                }
            }
        }

        return targetAccountCPP.ScopeId__r.AccountId__c;
    }

    // #endregion

    // #region LeadAssignment Private

    /**
     * @description Metodo que contiene el flujo de asignacion cuando existe una cuenta customer o business customer
     * @author      dmunoz
     * @return      String
     *              Devuelve el código de mediador sobre el cual se debe asignar la oferta del lead cuando ha encontrado un cliente
     */
    private static String leadAssignmentWhenAccountExists(Account acc, String origin, String language, String postalCode) {

        String intermediaryCode = '';

        String customerRTDeveloperName = GlobalConfigUtil.getGlobalConfigurationValue('Account_RecordType_Customer');
        String businessCustomerRTDeveloperName = GlobalConfigUtil.getGlobalConfigurationValue('Account_RecordType_BusinessCustomer');

        String rtName = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName();
        
        if((rtName.equals(customerRTDeveloperName) || rtName.equals(businessCustomerRTDeveloperName)))
        {
            
            intermediaryCode = getIntermediaryFromMostRecentPolicy(acc.Id);

            if (String.isEmpty(intermediaryCode)) {
                intermediaryCode = getIntermediaryFromMostRecentOffer(acc.Id);
            }

            // en lugar de poner este if bajo la consulta al metodo getIntermediaryFromMostRecentOffer y dentro de otro if, para no incrementar la complejidad ciclomatica.
            // de esta forma si no encuentra ni póliza ni oferta, ejecutaremos la lógica de asignacion de leads, es decir el método "leadAssignmentWhenAccountNotExists"
            if (String.isEmpty(intermediaryCode)) {
                leadAssignmentWhenAccountNotExists(origin, language, postalCode);
            }
        }
        return intermediaryCode;
    }


    /**
     * @description Metodo que contiene el flujo de asignacion cuando existe no cuenta customer o business customer o en caso que exista no se ha podido encontrar póliza u oferta asociada
     * @author      dmunoz
     * @return      String
     *              Devuelve el código de mediador sobre el cual se debe asignar la oferta del lead cuando ha encontrado un cliente
     */
    private static Map<String, Account> leadAssignmentWhenAccountNotExists(String origin, String language, String postalCode) {
        if(String.isNotBlank(language) && language != 'ES')
        {
            return AccountLeadAssignment.getAssignedUserIdByLanguage(language).getAssignmentAsMap(); 
        }

        return AccountLeadAssignment.getAssignedUserIdByAssignmentType(origin, postalCode).getAssignmentAsMap();
    }


    /**
     * @description Metodo que devuelve si existe el código de mediador de la póliza mas reciente para un cliente dado
     * @author      dmunoz
     * @return      String
     *              Devuelve el código de mediador de la póliza más reciente que tenga asociada el cliente
     */
    private static String getIntermediaryFromMostRecentPolicy(String idAccount) {
        String intermediaryCode = '';

        List<Policy__c> mostRecentPolicy = new PoliciesSelector().getMostRecentlyPolicieByAccountId(idAccount);

        if(!mostRecentPolicy.isEmpty()) {
            intermediaryCode = mostRecentPolicy.get(0).Intermediary_Code__c; 
        }

        return intermediaryCode;
    }

    private static String getIntermediaryFromMostRecentOffer(String idAccount) {
        String intermediaryCode = '';

        List<Opportunity> mostRecentOffer = new OpportunitiesSelector().getMostRecentlyOfferByAccountId(idAccount); 

        if(!mostRecentOffer.isEmpty()) {
            intermediaryCode = mostRecentOffer.get(0).IntermediaryId__r.INFOIntermediaryCode__c; 
        }

        return intermediaryCode;
    }

    // #endregion

    // #region Scopes

    /** */

    public static void createScopesForVentaLeads(List<Account> accounts, Map<Id,Account> oldAccounts)
    {
        List<Id> allCandidateAccounts = getLeadAccountsForCrossScope(accounts, oldAccounts);

        Set<Id> accountIdsWithoutScope = new Set<Id>();
        Set<Id> accountIdsWithScope = new Set<Id>();

        ScopesSelector scopeS = new ScopesSelector();

        if(!allCandidateAccounts.isEmpty())
        {
            for( Scope__c currentCPP : scopeS.selectByAccountIdAndVentasScope(allCandidateAccounts) )
            {
                accountIdsWithScope.add(currentCPP.AccountId__c);
            }
        }

        for(Id currentAccountId : allCandidateAccounts)
        {
            if( !accountIdsWithScope.contains(currentAccountId) )
            {
                accountIdsWithoutScope.add(currentAccountId);
            }
        }

        if( accountIdsWithoutScope.isEmpty() )
        {
            return;
        }

        List<Scope__c> scopesToInsert = new List<Scope__c>();

        Map<Id,Account> accountsById = new Map<Id,Account>(accounts);
        for(Id currentAccountWithoutScope : accountIdsWithoutScope)
        {
            Account currentAccount = accountsById.get(currentAccountWithoutScope);
            scopesToInsert.add( new Scope__c(
                                    AccountId__c = currentAccount.Id,
                                    PrimaryPhone__c = currentAccount.Phone,
                                    Scope__c = 'Ventas',
                                    Name = 'Zurich Ventas'
                                    ) );
        }

        insert scopesToInsert;

        List<ContactPointPhone> contactPointsForScopes = new List<ContactPointPhone>();

        for(Scope__c currentScope : scopesToInsert)
        {
            contactPointsForScopes.add( new ContactPointPhone(
                                            ScopeId__c = currentScope.Id,
                                            Scope__c = 'Ventas',
                                            ParentId = currentScope.AccountId__c,
                                            TelephoneNumber = currentScope.PrimaryPhone__c
                                            ) );
        }

        insert contactPointsForScopes;
    }

    public static List<Id> getLeadAccountsForCrossScope(List<Account> accountList, Map<Id,Account> oldAccounts)
    {
        List<Id> result = new List<Id>();

        if(accountList == null)
        {
            return result;
        }

        Id accountLeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Lead').getRecordTypeId();

        for(Account nextAccount : accountList)
        {
            if(nextAccount.RecordTypeId != accountLeadRecordTypeId)
            {
                continue;
            }

            if( oldAccounts != null && !oldAccounts.isEmpty() )
            {
                if( String.isNotblank(nextAccount.Phone) && String.IsBlank(oldAccounts.get(nextAccount.Id).Phone) )
                {
                    result.add(nextAccount.Id);
                }
            }
            else
            {
                if( String.isNotBlank(nextAccount.Phone) )
                {
                    result.add(nextAccount.Id);
                }
            }
        }

        return result;
    }

    /**
     * A partir de un telefono calculo sus 3 variantes +34600000000, 34600000000, 600000000
     * @author dmunoz
     * @date 04/10/2023
     */
    @TestVisible
    private static List<String> getVariantsPhones(String phone) {
        List<String> result = new List<String>();
        result.add(phone);

        String newFormat1 = '';
        String newFormat2 = '';

        // si llega un teléfono con tamaño 9 (600000000) añado a la lista 34600000000 y +34600000000
        if (phone.length() == 9) {
            newFormat1 = '+34' + phone;
            newFormat2 = '34' + phone;

        } else if (phone.startsWith('+')) { // si llega un teléfono que empieza por + (+34600000000) añado a la lista 34600000000 y 600000000
            newFormat1 = phone.right(11);
            newFormat2 = phone.right(9);

        } else if (phone.startsWith('34')) {
            newFormat1 = '+' + phone;
            newFormat2 = phone.right(9);
        }

        if (String.isNotEmpty(newFormat1) && String.isNotEmpty(newFormat2)) {
            result.add(newFormat1);
            result.add(newFormat2);
        }

        return result;
    }
}