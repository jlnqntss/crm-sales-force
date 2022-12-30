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
    private static final string WARNING_FIELDSET = 'CompactLayout';
    private static final string AGREEMENT_FIELDSET = 'CompactLayout';
    //#endregion

    //#region public classes
    /**
     * Método que a partir del objeto (CustomerWarning__c o Special_Condition__c) descarga el fieldset necesario y devuelve los campos
     * @author jjuaristi@seidor.es
     * @date 26/12/2022
     * @param Código de ramo
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
            fieldsToShow.add(new Field(field.getLabel(), field.getFieldPath(), field.getType()));
        }

        return fieldsToShow;
    }

    /**
     * Método que a partir del objeto (CustomerWarning__c o Special_Condition__c) descarga el fieldset necesario y devuelve los campos
     * @author jjuaristi@seidor.es
     * @date 26/12/2022
     * @param Código de ramo
     * @return Lista de campos a mostrar
     */
    @AuraEnabled(cacheable=true)
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
        }
    }
    //#endregion
}
