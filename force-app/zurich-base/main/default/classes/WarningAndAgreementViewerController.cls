/**
 * Clase controladora del componente LWC WarningAndAgreementViewer
 * @author jjuaristi@seidor.es
 * @date 26/12/2022
 */
public with sharing class WarningAndAgreementViewerController 
{
    //#region atributos
    private static final string WARNING_OBJECT = 'CustomerWarning__c';
    private static final string AGREEMENT_OBJECT = 'Special_Condition__c';
    private static final string WARNING_FIELDSET = 'RelatedListFields';
    private static final string AGREEMENT_FIELDSET = 'RelatedListFields';

    private static final string MANAGEMENT_CUSTOM_PERMISSION = 'USPManageAgreementsWarnings';
    
    //#endregion

    //#region public classes
    /**
     * Método que a partir del objeto (CustomerWarning__c o Special_Condition__c) descarga el fieldset necesario y devuelve los campos
     * @author jjuaristi@seidor.es
     * @date 26/12/2022
     * @param Objeto Salesforce
     * @return Lista de campos a mostrar
     */
    @AuraEnabled(cacheable=true)
    public static List<Field> getFields(String salesforceObject)
    {
        //#region variables
        List<Schema.FieldSetMember> fieldList = new List<Schema.FieldSetMember>();
        List<Field> fieldsToShow = new List<Field>();
        //#endregion

        if (salesforceObject == WARNING_OBJECT)
        {
            // Descargamos los campos
            fieldList = getFieldSetMembers(salesforceObject, WARNING_FIELDSET);
        }
        else if (salesforceObject == AGREEMENT_OBJECT )
        {
            // Descargamos los campos
            fieldList = getFieldSetMembers(salesforceObject, AGREEMENT_FIELDSET);
        }
        else 
        {
            return new List<Field>();    
        }

        // To return the field api name
        for(FieldSetMember field : fieldList)
        {
            if(
                String.valueOf(field.getType()).toLowerCase() == 'textarea' 
                &&
                salesforceObject == AGREEMENT_OBJECT
            )
            {
                fieldsToShow.add(new Field(field.getLabel(), field.getFieldPath(), 'richText'));
            }
            else
            {
                fieldsToShow.add(new Field(field.getLabel(), field.getFieldPath(), field.getType()));
            }
        }

        System.debug(fieldsToShow);

        return fieldsToShow;
    }

    /**
     * Método que devuelve los avisos
     * @author jjuaristi@seidor.es
     * @date 09/01/2023
     * @param registro, objeto y tipo de registro
     * @return Lista de campos a mostrar
     */
    @AuraEnabled
    public static List<CustomerWarning__c> getWarnings(Account record, String salesforceObject, String recordType)
    {
        String identifier;
        Set<Id> warningIds = new Set<Id>();
        if(record == null || salesforceObject == null || salesforceObject != WARNING_OBJECT || recordType == null)
        {
            // Alguno de los parámetros no es correcto, no hay que devolver avisos
            return new List<CustomerWarning__c>();
        }
        if( recordType == AccountsSelector.RT_NAME_INTERMEDIARY )
        {
            // Mediador
            identifier = record.INFOIntermediaryCode__c;
        }
        else
        {
            // Cliente
            identifier = record.NationalId__c;
        }

        List<RelatedAccount__c> relatedAccounts = new RelatedAccountsSelector().findRelatedAccountsByIdentifier(identifier);

        for(RelatedAccount__c relatedAccount : relatedAccounts)
        {
            warningIds.add(relatedAccount.Warning__c);
        }

        List<CustomerWarning__c> warnings = new CustomerWarningsSelector().findWarningsByIds(warningIds);

        return warnings;
    }

     /**
     * Método que devuelve los acuerdos
     * @author jjuaristi@seidor.es
     * @date 09/01/2023
     * @param registro, objeto y direccion Territorial
     * @return Lista de campos a mostrar
     */
    @AuraEnabled
    public static List<Special_Condition__c> getAgreements(Account record, String salesforceObject)
    {
        List<Special_Condition__c> agreements = new List<Special_Condition__c>();
        if(record == null || salesforceObject == null || salesforceObject != AGREEMENT_OBJECT)
        {
            // Alguno de los parámetros no es correcto, no hay que devolver avisos
            return new List<Special_Condition__c>();
        }
        else
        {
            agreements = new SpecialConditionsSelector().findAgreements(record.Id, record.TerritorialDirection__c);
        }

        return agreements;
    }

    /**
     * Método que recupera una cuenta de la base de datos
     * @author jjuaristi@seidor.es
     * @date 30/12/2022
     * @param Id de la cuenta
     * @return Cuenta
     */
    @AuraEnabled
    public static Account getAccountById(Id accountId)
    {
        List<Account> account = new AccountsSelector().selectById(new Set<Id>{accountId});
        return account[0];
    }

    /**
     * Método que cancela un acuerdo
     * @author jjuaristi@seidor.es
     * @date 10/01/2023
     */
    @AuraEnabled
    public static void cancelAgreements(List<Special_Condition__c> agreements)
    {
        if(agreements != null && !agreements.isEmpty())
        {
            for(Special_Condition__c agreement : agreements)
            {
                agreement.EndDate__c = System.today();
                agreement.IsActive__c = false;
            }
            update agreements;
        }
    }

    /**
     * Método que cancela un aviso
     * @author jjuaristi@seidor.es
     * @date 10/01/2023
     */
    @AuraEnabled
    public static void cancelWarnings(List<CustomerWarning__c> warnings)
    {
        if(warnings != null && !warnings.isEmpty())
        {
            for(CustomerWarning__c warning : warnings)
            {
                warning.EndDate__c = System.today();
            }
            update warnings;
        }
    }

    /**
     * Método que comprueba si el running user tiene el permiso para crear y cancelar registros
     * @author jjuaristi@seidor.es
     * @date 12/01/2023
     */
    @AuraEnabled
    public static Boolean checkPermission()
    {
        return FeatureManagement.checkPermission(MANAGEMENT_CUSTOM_PERMISSION);
    }

    /**
     * Método que crea la cuenta relacionada a partir del aviso manual
     * @author jjuaristi@seidor.es
     * @date 12/01/2023
     */
    @AuraEnabled
    public static void createRelatedAccount(Account record, String warningNumber, String recordType)
    {
        RelatedAccount__c newRecord = new RelatedAccount__c();
        CustomerWarning__c warning = new CustomerWarningsSelector().findWarningByNumber(warningNumber);
        newRecord.Warning__c = warning.Id;
        if( recordType == AccountsSelector.RT_NAME_INTERMEDIARY )
        {
            // Mediador
            newRecord.Identifier__c = record.INFOIntermediaryCode__c;
        }
        else
        {
            // Cliente
            newRecord.Identifier__c = record.NationalId__c;
        }
        insert newRecord;
    }

    //#endregion

    //#region private classes
    /**
     * Método que devuelve los campos de un fieldSet en base a su nombre
     * @author jjuaristi@seidor.es
     * @date 26/12/2022
     * @param nombre del fieldset
     * @return campos en el fieldset
     */
    private static List<Schema.FieldSetMember> getFieldSetMembers(String salesforceObject, String fieldSet)
    {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(salesforceObject);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSet);
        return fieldSetObj.getFields(); 
    }
    //#endregion

    //#region inner classes
    /**
     * Inner class que contiene la información de los campos
     * @author jjuaristi@seidor.es
     * @date 26/12/2022
     */
    @TestVisible
    class Field {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public Boolean wrapText {get;set;}

        /**
         * Contructor de la clase Field
         * @author jjuaristi@seidor.es
         * @date 26/12/2022
         */
        public Field(String label, String fieldName, Schema.DisplayType type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type = String.valueOf(type).toLowerCase();
            this.wrapText = true;
        }

        /**
         * Contructor de la clase Field con string
         * @author jjuaristi@seidor.es
         * @date 26/12/2022
         */
        public Field(String label, String fieldName, String type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type = type;
            this.wrapText = true;
        }
    }
    //#endregion
}
