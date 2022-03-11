public class OpportunityUtil
{
    public static Map<Id, Profile> listaPerfiles; //Mapa de perfiles especiales a los que se les permite bypasear ciertas reglas de validación

    /**
     * BULK BEFORE
     * Inicializa un mapa de perfiles a los que se les permite bypasear la regla de validación para
     *
     * @date 24/02/2021
     */
    public static void initMapOfProfiles()
    {
        listaPerfiles = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Genesys Admin', 'Integrator', 'Automation')]);
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
            if( String.isNotBlank(opty.InfoQuoteNumber__c) && opty.ScopeId__c == null
                && opty.AccountId != null)
            {
                optysToGenerateScope.add(opty);
            }
        }

        if( !optysToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('AccountId', 'BusinessCode__c', optysToGenerateScope);
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
        for(Integer i=0,j=newList.size();i<j;i++) {
            Opportunity o = newList[i];

            if( o.AccountId != oldMap.get(o.Id).AccountId ) {
                o.OldAccountId__c = oldMap.get(o.Id).AccountId;
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
            if(String.isBlank(opty.StageName))
            {
                opty.StageName = 'Open';
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
            if(String.isBlank(opty.StageName))
            {
                Opportunity oldOffer = oldMap.get(opty.Id);
                opty.StageName = oldOffer.StageName;
            }

            if (String.isBlank(opty.AccountId) && !String.isBlank(oldMap?.get(opty.Id)?.AccountId))
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

            if (!skipStageNameValidation(newOpty) && !isValidStageName(oldOpty))
            { 
                // ERROR  : Agregar el mensaje a nivel de campo 
                newOpty.addError('StageName', Label.OfferStageValidationMessage);
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

        if (oldOpty != null )
        {
            if( oldOpty.StageName.equalsIgnoreCase('Closed won'))
            {
                retorno = false;
            }
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
        if (!listaPerfiles.isEmpty())
        {
            if(listaPerfiles.containsKey(UserInfo.getProfileId()))
            {
                retorno = true;
            }
        }

        // Bypass por usuario (usando los Custom Permisson)
        if(FeatureManagement.checkPermission('Editar_ofertas_cerradas'))
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
}