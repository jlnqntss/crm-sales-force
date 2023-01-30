/**
 * Clase que gestiona la configuracion de la aplicación SDM 
 * 
 * @author nts (agonzalezisasi)
 * @date 11/11/2021
 */
public with sharing class SettingsSDM 
{    
    // Roles de Salesforce de los usuarios que pueden usar la pantalla
    public static final String SF_ROLE_DT_DEVNAME = 'SDM_DT'; // Rol Director Territorial / Director Zona
    public static final String SF_ROLE_DV_DEVNAME = 'SDM_DV'; // Rol Director Vida
    public static final String SF_ROLE_RN_DEVNAME = 'SDM_RN'; // Rol Responsable de Negocio
    public static final String SF_ROLE_CV_DEVNAME = 'SDM_CV'; // Rol Consultor vida

    public static final String ATM_ROL_TERRITORY = 'TerritoryManager';
    public static final String ATM_ROL_MANAGER = 'Manager';
    public static final String ATM_ROL_BUSINESS = 'BusinessManager';
    public static final String ATM_ROL_LIFECONSULTANT = 'LifeConsultant';

    public static final String ACR_ROL_MAINEMAIL = 'Main';

    public static final String PERMSET_COMERCIAL_PLAN = 'SDM_Plan_comercial';
    public static final String PROFILE_RN = 'SDM RN';
    public static final String PROFILE_DT = 'SDM Director';

    @testvisible
    private Map<String, String> mapATMRoleToLabel;
    @testvisible
    private Map<String, String> mapACRRoleToLabel;

    @testvisible
    private String testSetupParamValue;

    /**
     * Recupera un valor del metadato de parametros de configuracion general (AdminSetupParameter__mdt)
     * 
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     * 
     * @param {String setupApiName} nombre api del parametro
     * @param {String defaultValue} valor por defecto
     * @return {String} valor configurado, o si no existe, el valor por defecto
     */
    public String getSetupParameter(String setupApiName, String defaultValue)
    {
        // Asignamos el valor por defecto
        String result = defaultValue;
        // Intentamos recuperar el parametro de configuracion
        String setupValue = [
            SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :setupApiName LIMIT 1
        ]?.Value__c;

        if( Test.isRunningTest() && String.isNotBlank(testSetupParamValue) ) {
            setupValue = testSetupParamValue;
        }

        // Y si lo hemos encontrado lo asignamos
        if( String.isNotBlank(setupValue) ) result = setupValue;

        return result;
    }

    /**
     * Recuperamos de los metadatos de configuracion los tipos de calculos que seran necesarios para cada indicador
     * de los planes comerciales
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     */
    public Map<String, SDMCommercialPlan__mdt> getSettingsIndicator(List<SDMCommercialPlan__mdt> testSettingsIndicator)
    {
        // creamos el mapa
        Map<String, SDMCommercialPlan__mdt> mapSettingsIndicator = new Map<String, SDMCommercialPlan__mdt>();
        // Recuperamos los datos de configuracion de los indicadores
        List<SDMCommercialPlan__mdt> settings = [
            SELECT Indicator__c, CalculationType__c, FirstField__c, SecondField__c FROM SDMCommercialPlan__mdt
        ];

        // Solo para los test cambiamos la configuracion
        if( Test.isRunningTest() && testSettingsIndicator != null ) {
            settings = testSettingsIndicator;
        }

        // Por cada indicador...
        for(SDMCommercialPlan__mdt s: settings) {
            mapSettingsIndicator.put( s.Indicator__c, s );
        }

        return mapSettingsIndicator;    
    }

    /**
     * Recupera la relacion entre los roles del objeto Account Team Member y los campos de la cuenta de tipo 
     * Mediador (Intermediary)
     */
    public List<SDMAccountTeamRole__mdt> getAccountRolesWithIntermediaryFields(List<SDMAccountTeamRole__mdt> testSettingsATM)
    {
        List<SDMAccountTeamRole__mdt> result = [
            SELECT Role__c, IntermediaryField__c, Status__c 
            FROM SDMAccountTeamRole__mdt ORDER BY IntermediaryField__c
        ];

        // Solo para los test cambiamos los datos de configuracion
        if( Test.isRunningTest() && testSettingsATM != null && !testSettingsATM.isEmpty() ) {
            result.clear();
            result.addAll(testSettingsATM);
        }
        return result;
    }
    
    /**
     * Recupera la relacion de valores de Rol de AccountTeamMember con la etiqueta de la configuracion
     */
    public String getATMRoleLabel(String role)
    {
        String result = role;
        if( this.mapATMRoleToLabel == null ) {
            this.mapATMRoleToLabel = new Map<String, String>();
            List<Schema.PicklistEntry> pklist = SDMAccountTeamRole__mdt.Role__c.getDescribe().getPicklistValues();
            for(Schema.PicklistEntry e: pklist) {
                this.mapATMRoleToLabel.put(e.getValue(), e.getLabel());
            }
        }

        if( this.mapATMRoleToLabel.containsKey(role) ) {
            result= this.mapATMRoleToLabel.get(role);
        }

        return result;
    }    

    /**
     * Recupera la relacion entre los roles del objeto Account Contact Relation y los campos de la cuenta de tipo 
     * Mediador (Intermediary)
     */
    public List<SDMAccountContactRelation__mdt> getContactRolesWithIntermediaryFields(
        List<SDMAccountContactRelation__mdt> testSettingsACR
        )
    {
        List<SDMAccountContactRelation__mdt> result = [
            SELECT Role__c, IntermediaryField__c, NameText__c 
            FROM SDMAccountContactRelation__mdt
        ];

        // Solo para los test cambiamos los datos de configuracion
        if( Test.isRunningTest() && testSettingsACR != null && !testSettingsACR.isEmpty() ) {
            result.clear();
            result.addAll(testSettingsACR);
        }

        return result;
    }

    /**
     * Recupera la relacion de valores de Rol de AccountContactRelation con la etiqueta de la configuracion
     */
    public String getACRRoleLabel(String role)
    {
        String result = role;
        if( this.mapACRRoleToLabel == null ) {
            this.mapACRRoleToLabel = new Map<String, String>();
            List<Schema.PicklistEntry> pklist = SDMAccountContactRelation__mdt.Role__c.getDescribe().getPicklistValues();
            for(Schema.PicklistEntry e: pklist) {
                this.mapACRRoleToLabel.put(e.getValue(), e.getLabel());
            }
        }

        if( this.mapACRRoleToLabel.containsKey(role) ) {
            result= this.mapACRRoleToLabel.get(role);
        }

        return result;
    }
}
