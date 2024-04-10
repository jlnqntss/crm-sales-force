/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 04-24-2023
 * @last modified by  : aberuete
 **/
public with sharing class OpportunityUtil
{
    private static final String CLASS_NAME = 'OpportunityUtil';
    public static Map<Id, Profile> listaPerfiles; //Mapa de perfiles especiales a los que se les permite bypasear ciertas reglas de validación
    public static Map<Id, String> mapAccountRecordTypes; //Mapa de Accounts con sus respectivos RecordType.DeveloperName
    public static Map<Id, User> listaUsuarios; //Mapa de usuarios especiales a los que se les permite bypasear ciertas reglas de validación
    static final String FIELD_OWNER_ID = 'OwnerId';
    static final String FIELD_STAGE = 'StageName';
    private static List<String> nombresPerfilesVentas; // perfiles de la app ventas y zrm que muestra otro mensaje de error para la validación de cerrada ganada
    private static String userLoggedProfile; // query que obtiene el nombre del perfil del usuario logeado
    private final static String CRM_VENTAS_PROFILE = 'Ventas User';
    public static Map<String, String> mapBusinessCodes; // Mapa que va a contener la relación entre los Business codes y los scopes de las Ofertas


    /**
     * BULK BEFORE
     * Inicializa un mapa de perfiles a los que se les permite bypasear la regla de validación para
     *
     * @date 24/02/2021
     */
    public static void initMapOfProfiles()
    {
        // perfiles
        List<String> nombresPerfiles = new List<String> {'Administrador del sistema', 'System Administrator', 'Genesys Admin', 'Integrator', 'Automation'};
        listaPerfiles = ProfilesSelector.getProfilesByName(nombresPerfiles);

        // usuarios
        List<String> nombresUsuarios = new List<String> {'Automated Process'};
        listaUsuarios = ( new UsersSelector() ).getUsersByName(nombresUsuarios);

        // Perfiles Ventas
        nombresPerfilesVentas = new List<String> {'Agente Ventas', 'Ventas User'};
        userLoggedProfile = ProfilesSelector.getLoggedUserProfile();
    }

    /**
     * Inicializa un mapa de Ids de Account y RecordType.DeveloperName para realizar cálculos antes de la inserción
     *
     * @author nts (jfherrero)
     * @date 15/09/2023
     * @trigger bulkBefore
     */
    public static void initMapOfAccountRecordTypes(List<Opportunity> newList)
    {
        mapAccountRecordTypes = new Map<Id, String>();

        if (newList != null && newList.size() > 0)
        {
            Set<Id> accountIds = new Set<Id>();

            for (Opportunity opp : newList)
            {
                accountIds.add(opp.AccountId);
            }

            List<Account> oppAccounts = new AccountsSelector().selectById(accountIds);

            if (oppAccounts != null && oppAccounts.size() > 0)
            {
                for (Opportunity opp : newList)
                {
                    for (Account acc : oppAccounts)
                    {
                        if (opp.AccountId == acc.Id)
                        {
                            mapAccountRecordTypes.put(acc.Id, acc.RecordType.DeveloperName);
                            break;
                        }
                    }
                }
            }
        }
    }

    /**
     * Método que rellena el mapa que contiene la relación entre Business Code y Scopes
     *
     * @author arcortazar
     * @date 21/12/2023
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
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para Ofertas que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     */
    public static void generateScope(List<Opportunity> newList)
    {
        List<Opportunity> optysToGenerateScope = new List<Opportunity>();

        for(Opportunity opty : newList)
        {

            if( (String.isNotBlank(opty.InfoQuoteNumber__c) && opty.ScopeId__c == null && opty.AccountId != null)
                || ( opty.Scope__c == 'Ventas' && opty.ScopeId__c == null && String.isNotBlank(opty.BusinessCode__c) ) )
            {
                optysToGenerateScope.add(opty);
            }

            if( !optysToGenerateScope.isEmpty() )
            {
                GenerateScopeUtil.generateScopeEvents('AccountId', 'BusinessCode__c', optysToGenerateScope);
            }
        }
    }

    /**
     * Detect a change in the AccountId field of the offer
     * In a batch we will check if the old account is a lead and if so we will merge the lead with the client that is
     * coming from INFO (ocs-920)
     *
     * @author nts (agonzalezisasi)
     * @date 03/02/2021
     * @trigger beforeUpdate
     */
    public static void detectOpportunityAccountChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Integer i=0,j=newList.size(); i < j; i++)
        {
            Opportunity o = newList[i];

            if( o.AccountId != oldMap.get(o.Id).AccountId )
            {
                o.OldAccountId__c = oldMap.get(o.Id).AccountId;
            }
        }
    }

    /**
     * Assign the Sales Process value according to the Account Record Type
     *
     * @author nts (jfherrero)
     * @date 15/09/2023
     * @trigger beforeInsert
     */
    public static void setSalesProcess(List<Opportunity> newList)
    {
        for(Opportunity opp : newList)
        {

            if (mapAccountRecordTypes.get(opp.AccountId) != null)
            {

                if(mapAccountRecordTypes.get(opp.AccountId) == 'Lead' )
                {
                    opp.SalesProcess__c = 'L';
                }
                else if (mapAccountRecordTypes.get(opp.AccountId) == 'BusinessCustomer' ||
                         mapAccountRecordTypes.get(opp.AccountId) == 'Customer' )
                {
                    opp.SalesProcess__c = 'VC';
                }
            }
        }
    }

    /**BEFOREINSERT
     * Desde info no se rellena el campo obligatorio StageName, en ese caso hay que poner Open
     * @date 25/02/2021
     */
    public static void setStageNameOpen(List<Opportunity> newList)
    {
        for(Opportunity opty : newList)
        {
            if( String.isBlank(opty.StageName) )
            {

                // Comprobamos las condiciones del Código de negocio
                if( String.isBlank(opty.BusinessCode__c) || ( !mapBusinessCodes.containsKey(opty.BusinessCode__c) ) || (mapBusinessCodes.get(opty.BusinessCode__c) == 'Ventas') )
                {
                    opty.StageName = 'Quoted';
                }
                else
                {
                    opty.StageName = 'Open';
                }
            }
        }
    }

    /**BEFOREUPDATE
     * Método que previene la pérdida de datos en el registro de oportunidad.
     * Las oportunidades son actualizadas desde INFO un sistema externo mediante una integración.
     * Esta función afectará a los cambios tanto por interfaz como automáticos por integraciones.
     * Si los siguientes campos cambian a nulo entonces se previene esta acción:
     * - Stae
     * - AccountId
     * @author rpolvera
     * @date 25/02/2021
     * @last modified 16/11/2021 : ZE-1149 Ofertas sin tomador.
     */
    public static void preventNullUpdates(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Opportunity opty : newList)
        {
            if( String.isBlank(opty.StageName) )
            {
                Opportunity oldOffer = oldMap.get(opty.Id);
                opty.StageName = oldOffer.StageName;
            }

            if ( String.isBlank(opty.AccountId) && !String.isBlank(oldMap?.get(opty.Id)?.AccountId) )
            {
                opty.AccountId = oldMap?.get(opty.Id)?.AccountId;
            }
        }
    }

    /**
     * Método privado que sustituye la Regla de validación de Opportunity llamada NoCloseWon
     *
     * [VR] de Offer -> NoCloseWon.

            ISPICKVAL(StageName,"Closed Won") &&
            $Profile.Id <> '00e5I000000Hu97' &&
            $Profile.Id <> '00e5I000000UPld' &&
            $Profile.Id <> '00e5I000000QeQS' &&
            $Profile.Id <> '00e5I000000Hu9B' &&
            $User.Username <> 'israel.catala@zurich-es.com' &&
            $User.Username <> 'agustin.zapata@zurich-es.com' &&
            $User.Username <> 'j.tomegarcia@zurich-es.com' &&
            $User.Username <> 'julio.fabeiro@zurich-es.com' &&
            $User.Username <> 'francisco.orta@zurich-es.com'
     *
     *
     * @author arcortazar - nts
     * @created date 09/03/2022
     *
     * @param newList List<Opportunity> lista de oportunidades a updatear con los datos actualizados
     * @param oldMap Map<Id, Opportunity> mapa de las oportunidades a actualizar, con los datos anteriores al update
     * */
    public static void validateOfferStage(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for (Opportunity newOpty : newList)
        {
            Opportunity oldOpty = oldMap.get(newOpty.Id);

            if ( !skipStageNameValidation(newOpty) && !isValidStageName(oldOpty) )
            {
                // ERROR  : Agregar el mensaje a nivel de campo

                newOpty.addError(FIELD_STAGE, nombresPerfilesVentas.contains(userLoggedProfile) ? Label.OfferSalesStageValidationClosedWonMessage : Label.OfferStageValidationMessage);
            }

            // fpalomo - 10/10/2023 - CV-671
            if ( oldOpty.StageName.equalsIgnoreCase('Legit Lead') && newOpty.StageName.equalsIgnoreCase('App Submitted') && userLoggedProfile.equalsIgnoreCase(CRM_VENTAS_PROFILE) )
            {
                newOpty.OwnerId = UserInfo.getUserId();
            }
        }
    }

    /**
     * Método privado que comprueba el StageName de la oportunidad. Si esta se encuentra en closed won, no se podrá actualizar
     *
     * @author arcortazar - nts
     * @created date 09/03/2022
     *
     * @param oldOpty Opportunity que se va a updatear.
     * @return Booleano que indica si el StageName de la opportunity es el adecuado para proceder al update (true) o no (false)
     * */
    @TestVisible
    private static Boolean isValidStageName(Opportunity oldOpty)
    {
        Boolean retorno = true;
        if( oldOpty != null && oldOpty.StageName.equalsIgnoreCase('Closed won') )
        {
            retorno = false;
        }

        return retorno;
    }

    /**
     * Método privado que comprueba si se ha producido un cambio en el OwnerId.
     * @author arcortazar - nts
     * @created date 09/03/2022
     *
     * @param newOpty Opportunity  que se va a comprobar si se puede bypasear las reglas para su actualización
     * @return Boolean que indica si puede bypasearse (true) o no (false).
     * */
    @TestVisible
    private static Boolean skipStageNameValidation(Opportunity newOpty)
    {
        Boolean retorno = false;

        // Bypass por perfil
        if( !listaPerfiles.isEmpty() && ( listaPerfiles.containsKey( UserInfo.getProfileId() ) || listaUsuarios.containsKey( UserInfo.getUserId() ) ) )
        {
            retorno = true;
        }


        // Bypass por usuario (usando los Custom Permisson)
        if( FeatureManagement.checkPermission('Editar_ofertas_cerradas') )
        {
            retorno = true;
        }


        // Bypass por reasignación
        if(newOpty.HasBeenReassigned__c)
        {
            newOpty.HasBeenReassigned__c = false;
            retorno = true;
        }
        return retorno;
    }

    /**
     * Método que devuelve un mapa de Opportunity(Ofertas) por ofertas generadas a partir de una lista de Ofertas
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     * @param Lista de Opportunity
     * @return Mapa de Opportunity por ofertas generadas
     */
    public static Map<String, Opportunity> generateMapByCreatedOffer(List<Opportunity> oportunities)
    {
        Map<String, Opportunity> mapOpportunitiesToRelateByCreatedOffer = new Map<String,Opportunity>();
        if( oportunities != null && !oportunities.isEmpty() )
        {
            //Mapa para identificar cada oportunidad con su oferta generada
            // Se recorre la lista de oportunidades para no tener que recorrerla una vez por cada caso
            for(Opportunity currentOportunity : oportunities)
            {
                mapOpportunitiesToRelateByCreatedOffer.put(currentOportunity.InfoQuoteNumber__c, currentOportunity);
            }
        }
        return mapOpportunitiesToRelateByCreatedOffer;
    }

    /*
     * Si el usuario conectado es un ZE_Advisor no dejar modificar el Owner a excepción de si el OldOwner es Integrator.
     * @author jpereztirado - nts
     * @created date 20/12/2022
     * @param newList List<Opportunity> lista de oportunidades a updatear con los datos actualizados
     * @param oldMap Map<Id, Opportunity> mapa de las oportunidades a actualizar, con los datos anteriores al update
     */
    public static void validateChangeOwner(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        List<PermissionSetAssignment> userList = [SELECT AssigneeId,Assignee.Profile.Name FROM PermissionSetAssignment WHERE (PermissionSet.Name = 'ZE_Advisor' OR Assignee.Profile.Name='Integrator')
                                                  AND Assignee.isActive = True AND Assignee.Profile.Name != 'System Administrator'];
        Id integratorId=null;
        for (Opportunity newOpty : newList)
        {
            Opportunity oldOpty = oldMap.get(newOpty.Id);
            if (newOpty.OwnerId != oldOpty.OwnerId)
            {
                Map<Id, PermissionSetAssignment> mapUsersZEAdvisors = new Map<Id, PermissionSetAssignment>();
                for(PermissionSetAssignment user : userList)
                {
                    if (user.Assignee.Profile.Name == 'Integrator')
                    {
                        integratorId = user.AssigneeId;
                    }
                    else
                    {
                        mapUsersZEAdvisors.put(user.AssigneeId, user);
                    }
                }
                if (mapUsersZEAdvisors.get( UserInfo.getUserId() ) != null && oldOpty.OwnerId != integratorId)
                {
                    //ERROR: Agregar el mensaje a nivel de campo
                    newOpty.addError(FIELD_OWNER_ID, Label.OfferChangeOwnerValidationMessage);
                }
            }
        }
    }

    /**
     * Metodo para dar visibilidad ZRM sobre clientes y leads en caso de insertar una nueva oferta
     *
     * @author dmunoz
     * @created date 05/03/2024
     */
    public static void zrmVisibilityNewOffer(List<Opportunity> newList)
    {

        try
        {
            // 1º obtener los mediadores y clientes de las polizas en vigor <IntermdiaryId__c, List<AccountId>>
            Map<String, Set<String> > accountIdByIntermediaryMap = ZRMOfferVisibilityUtil.getAccountIdByIntermediaryMap(newList);

            if ( accountIdByIntermediaryMap != null && !accountIdByIntermediaryMap.isEmpty() )
            {
                // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
                Map<String, String> intermediaryWithIntermediariesGroupsIdMap = ZRMOfferVisibilityUtil.getIntermediaryGroupIdMap( accountIdByIntermediaryMap.keySet() );

                // 3º Obtener los usuarios de los mediadores <IntermediaryId, List<UserId>
                Map<String, List<String> > intermediariesWithUsers = ZRMOfferVisibilityUtil.getIntermediariesUsers(accountIdByIntermediaryMap.keySet(), intermediaryWithIntermediariesGroupsIdMap);

                // 4º Insertar atm y activar registros de competencia y cuentas relacionadas
                ZRMOfferVisibilityUtil.newOfferInsertATMs(accountIdByIntermediaryMap, intermediariesWithUsers);
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
}