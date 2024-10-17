/**
 * @description       : Clase selectora del sobject LeadAssignmentConfiguration
 * @author            : jlnavarroq
 * @group             :
 * @last modified on  : 11/10/2024
 * @last modified by  : jlnavarroq
 **/

 public with sharing class LeadAssignmentConfigurationsSelector extends RecordsSelector {

    public RecordsSelector.Scope relatedRecordsScope;
    
    public LeadAssignmentConfigurationsSelector()
    {
        super( LeadAssignmentConfiguration__c.getSObjectType() );
    }

    //#region RECORD TYPES
    public static final String RT_Forum_Origin_Assignment   = GlobalConfigUtil.getGlobalConfigurationValue('AccountLeadAssignmentForumRT');
    public static final String RT_Language_Assignment       = GlobalConfigUtil.getGlobalConfigurationValue('AccountLeadAssignmentLanguageRT');
    public static final String RT_Municipality_Assignment   = GlobalConfigUtil.getGlobalConfigurationValue('AccountLeadAssignmentMunicipalRT');
    public static final String RT_Province_Assignment       = GlobalConfigUtil.getGlobalConfigurationValue('AccountLeadAssignmenProvinceRT');
     
    public ID rtForumOriginId {
        get {
            return Schema.SObjectType.LeadAssignmentConfiguration__c.getRecordTypeInfosByDeveloperName().get(RT_Forum_Origin_Assignment)?.getRecordTypeId();
        }
    }
     
     public ID rtLanguageAssignmentId {
        get {
            return Schema.SObjectType.LeadAssignmentConfiguration__c.getRecordTypeInfosByDeveloperName().get(RT_Language_Assignment)?.getRecordTypeId();
        }
    }
     
     public ID rtMunicipalityAssignmentId {
        get {
            return Schema.SObjectType.LeadAssignmentConfiguration__c.getRecordTypeInfosByDeveloperName().get(RT_Municipality_Assignment)?.getRecordTypeId();
        }
    }
     
     public ID rtProvinceAssignmentId {
        get {
            return Schema.SObjectType.LeadAssignmentConfiguration__c.getRecordTypeInfosByDeveloperName().get(RT_Province_Assignment)?.getRecordTypeId();
        }
    }
    
    // Recupera campos del RecordType ForumOriginAssignment de LeadAssignmentConfiguratio
    public List<LeadAssignmentConfiguration__c> getForumOriginAssignments() {
        return getLeadAssignmentConfiguratioByRT( RT_Forum_Origin_Assignment );
    }

    // Recupera campos del RecordType LanguageAssignment de LeadAssignmentConfiguratio
    public List<LeadAssignmentConfiguration__c> getLanguageAssignments() {
        return getLeadAssignmentConfiguratioByRT( RT_Language_Assignment );
    }

    // Recupera campos del RecordType MunicipalityAssignment de LeadAssignmentConfiguratio
    public List<LeadAssignmentConfiguration__c> getMunicipalityAssignments() {
        return getLeadAssignmentConfiguratioByRT( RT_Municipality_Assignment );
    }

    // Recupera campos del RecordType ProvinceAssignment de LeadAssignmentConfiguratio
    public List<LeadAssignmentConfiguration__c> getProvinceAssignments() {
        return getLeadAssignmentConfiguratioByRT( RT_Province_Assignment );
    }

    private List<LeadAssignmentConfiguration__c> getLeadAssignmentConfiguratioByRT(String rt) {
            
        if( rt == RT_Forum_Origin_Assignment ){
            // Agregar los campos a seleccionar
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    LeadAssignmentConfiguration__c.AssignTo__c,
                    LeadAssignmentConfiguration__c.AssignmentType__c,
                    LeadAssignmentConfiguration__c.ForumOrigin__c
                }
            );
            // Agregar la condición para filtrar por RecordTypeId
        	this.baseQuery.addConditionEq('RecordTypeId', rtForumOriginId);
        }
        if( rt == RT_Language_Assignment ){
            // Agregar los campos a seleccionar
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    LeadAssignmentConfiguration__c.AssignTo__c,
                    LeadAssignmentConfiguration__c.Language__c
                }
            );
            // Agregar la condición para filtrar por RecordTypeId
        	this.baseQuery.addConditionEq('RecordTypeId', rtLanguageAssignmentId);
        }
        if( rt == RT_Municipality_Assignment ){
            // Agregar los campos a seleccionar
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    LeadAssignmentConfiguration__c.ProvinceCode__c,
                    LeadAssignmentConfiguration__c.ZIPRanges__c
                }
            );
            // Agregar la condición para filtrar por RecordTypeId
        	this.baseQuery.addConditionEq('RecordTypeId', rtMunicipalityAssignmentId);
        }
        if( rt == RT_Province_Assignment ){
            // Agregar los campos a seleccionar
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    LeadAssignmentConfiguration__c.AssignTo__c,
                    LeadAssignmentConfiguration__c.PostalCode__c,
                    LeadAssignmentConfiguration__c.Province__c
                }
            );
            // Agregar la condición para filtrar por RecordTypeId
        	this.baseQuery.addConditionEq('RecordTypeId', rtProvinceAssignmentId);
        }  

        // Ejecutar la query
        return this.baseQuery.run();
    }
     
    
    
}