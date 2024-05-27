public class PolicyUtil
{
    private static final string CLASS_NAME = 'PolicyUtil';
    private static final string AGENTEVENTA_PROFILE = 'Agente Ventas';
    private static final string AGENTEVENTAAGR_PROFILE = 'Agente Ventas - AGR';
    public static Map<String, String> mapBusinessCodes; // Mapa que va a contener la relación entre los Business codes y los scopes de las Polizas
    private static final string ZRM_SCOPE = 'Ventas'; //Scope de las polizas de ZRM
    private static final string ZDA_SCOPE = 'ZDA'; 

    public static List<Account> accountsToMarkClientZDA = new List<Account>();

    /**
     * Método que rellena el mapa que contiene la relación entre Business Code y Scopes
     *
     * @author Iván García
     * @date 08/04/2024
     */
    public static void fillMapBusinessCode ()
    {
        mapBusinessCodes = new Map<String, String>();
        List<Scope_Setting__mdt> scopeSettingsMapping = Scope_Setting__mdt.getAll().values();

        for(Scope_Setting__mdt scope : scopeSettingsMapping)
        {
            mapBusinessCodes.put(scope.BusinessCode__c, scope.Scope__c);
        }
    }

    /**
     * @description Método que marca la poliza para ser revisada por un
     * proceso asíncrono en busca de coincidencias, siempre y cuando pertenezca a ZRM.
     *
     * @author igarcia
     * @date 09-04-2024
     * @param List<Policy> Lista de polizas que van a ser insertadas
     **/
    public static void identifyPotentialMatches(List<Policy__c> newList)
    {
        for (Policy__c policy : newList)
        {

            //Se comprueba que el registro pertenece al aplicativo ZRM y no tenga ninguna oferta enlazada
            if ( String.isBlank(policy.OpportunityName__c) &&
                 ( mapBusinessCodes?.get(policy.BusinessCode__c) == (ZRM_SCOPE) || String.isBlank(policy.BusinessCode__c) ) )
            {
                policy.PotentialMatch__c = true;
            }
        }
    }

    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para pólizas que provengan de INFO
     *
     * @author adelgado
     * @date 08/01/2021
     *
     * @change 10/05/2021 - nts (agonzalezisasi) - OCS-1798 - Se incluye el calculo de la cuenta Partner de la poliza
     *         como evento.
     */
    public static void generateScope(List<Policy__c> newList)
    {
        List<Policy__c> polToGenerateScope = new List<Policy__c>();
        List<Policy__c> polToGeneratePartner = new List<Policy__c>();

        for(Policy__c policy : newList)
        {
            if( String.isNotBlank(policy.InfoPolicyNumber__c) && policy.ScopeId__c == null && policy.PolicyHolder__c != null)
            {
                polToGenerateScope.add(policy);
            }

            if( String.isNotBlank(policy.BusinessCode__c) && policy.Partner__c == null )
            {
                polToGeneratePartner.add(policy);
            }
        }

        if( !polToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('PolicyHolder__c', 'BusinessCode__c', polToGenerateScope);
        }

        if( !polToGeneratePartner.isEmpty() )
        {
            GenerateScopeUtil.generatePartnerEvents(
                Policy__c.BusinessCode__c.getDescribe().getName(),
                Policy__c.Partner__c.getDescribe().getName(),
                Account.getSObjectType().getDescribe().getName(),
                Account.INFOBusinessCode__c.getDescribe().getName(),
                polToGeneratePartner
                );
        }
    }

    /**
     * Informa los siguientes campos para pólizas en las que se haya cambiado el mediador o cliente
     *
     * @author fpalomo
     * @date 08/04/2024
     */
    public static void handlePolicyHolderOrIntermediaryChange(List<Policy__c> newList, Map<Id, Policy__c> oldMap)
    {
        for(Policy__c policyNew : newList)
        {   
            if (String.isNotEmpty(policyNew.IntermediaryId__c) && String.isNotEmpty(policyNew.PolicyHolder__c) &&
                    ( 'A'.equals(policyNew.PolicyStatus__c) || 'V'.equals(policyNew.PolicyStatus__c) )
                    && !policyNew.Blocked__c && !policyNew.Anonymized__c) // solo procesamos cambios sobre polizas no bloqueadas y en vigor o anuladas que tengan mediador y cliente
            {
                Policy__c policyOld = oldMap.get(policyNew.Id);
    
                // AccountId
                if (policyNew.PolicyHolder__c != policyOld.PolicyHolder__c)
                {
                    policyNew.ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE;
                    policyNew.LastAccountId__c = policyOld.PolicyHolder__c;
                }
    
                // Mediador
                else if (policyOld.IntermediaryId__c != policyNew.IntermediaryId__c)
                {
                    policyNew.ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR;
                    policyNew.LastAccountId__c = policyOld.IntermediaryId__c; 
                }
    
                // Estos dos campos se rellenan de la misma forma para cualquiera de los dos casos posibles
                if (policyOld.LastAccountId__c != policyNew.LastAccountId__c)
                {
                    policyNew.LastDateIntermediaryOrAccountChange__c = System.today();
                    policyNew.VisibilityRetry__c = 1; // Inicializo el numero de reintentos en 1 ya que el 0 es para identificar ok
                }                
            }
        }
    }
    
    /******************************* Métodos principales Visibilidad ZRM ******************************************************/

    /**
     * Metodo que genera atm cuando llega una nueva poliza en vigor o anulada para los usuarios ZRM
     *
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static void zrmVisibilityNewPolicy(List<Policy__c> newList)
    {

        try
        {
            // 1º obtener los mediadores y clientes de las polizas en vigor <IntermdiaryId__c, List<PolicyHolder__c>>
            Map<String, Set<String> > policyHoldersByIntermediaryMap = ZRMPolicyVisibilityUtil.getPolicyHoldersByIntermediaryMap(newList);

            if ( policyHoldersByIntermediaryMap != null && !policyHoldersByIntermediaryMap.isEmpty() )
            {
                // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
                Map<String, String> intermediaryWithIntermediariesGroupsIdMap = ZRMPolicyVisibilityUtil.getIntermediaryGroupIdMap( policyHoldersByIntermediaryMap.keySet() );

                // 3º Obtener los usuarios de los mediadores <IntermediaryId, List<UserId>
                Map<String, List<String> > intermediariesWithUsers = ZRMPolicyVisibilityUtil.getIntermediariesUsers(policyHoldersByIntermediaryMap.keySet(), intermediaryWithIntermediariesGroupsIdMap);

                // 4º Insertar atm y activar registros de competencia y cuentas relacionadas
                ZRMPolicyVisibilityUtil.newPolicyInsertATMs(policyHoldersByIntermediaryMap, intermediariesWithUsers);
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
    * @description Método que obtiene las cuentas para marcar a true que una cuenta es de ZDA 
    * en caso de que la póliza pertenezca a ZDA.Es decir, que su business code sea de ZDA. 
    *
    * @author aberuete
    * @date 16-05-2024 
    * @param List<Policy__c> newPolicies : Lista de pólizas que van a ser insertadas o actualizas
    **/
    public static void getAccountsZDA(List<Policy__c> newPolicies)
    {
        Set<String> accountsRelatedToPoliciesZDA = new Set<String> ();

        for (Policy__c newPolicy : newPolicies)
        {
            if (newPolicy.PolicyHolder__c != null && newPolicy.BusinessCode__c != null && mapBusinessCodes?.get(newPolicy.BusinessCode__c) == ZDA_SCOPE)
            {
                accountsRelatedToPoliciesZDA.add(newPolicy.PolicyHolder__c); 
            }
        }

        List<Account> accountsToUpdate = new AccountsSelector().selectByIdAndAccountZDA(accountsRelatedToPoliciesZDA, false);
        
        for (Account account : accountsToUpdate)
        {
            account.IsAccountZDA__c = true;
            accountsToMarkClientZDA.add(account);
        }
    }

    /**
    * @description Método que actualiza las cuentas para marcar a true que una cuenta es de ZDA 
    * en caso de que la póliza pertenezca a ZDA.Es decir, que su business code sea de ZDA. 
    *
    * @author aberuete
    * @date 16-05-2024 
    * @param List<Policy__c> newPolicies : Lista de pólizas que van a ser insertadas o actualizas
    * @param Map<Id,Policy__c> oldPolicyMap: Mapa de pólizas que guarda los valores antes de ser actualizada la oportunidad
    **/
    public static void updateAccountsToMarkAccountZDA ()
    {
        List<String> msgErrores = new List<String>();

        if( !accountsToMarkClientZDA.isEmpty() )
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(accountsToMarkClientZDA, false);

                for (Database.SaveResult result: resultList )
                {
                    if( !result.isSuccess() )
                    {
                        for ( Database.Error error :result.getErrors() )
                        {
                            msgErrores.add( error.getStatusCode() + ': ' + error.getMessage() );
                        }
                    }
                }
                if ( !msgErrores.isEmpty() )
                {
                    ErrorLogUtil.commitError( ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando las cuentas relacionadas con las pólizas',PolicyUtil.class.getName(),( String.join(msgErrores,'\n') ) );
                }
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError( e, PolicyUtil.class.getName() );
            }
        }
    }
}