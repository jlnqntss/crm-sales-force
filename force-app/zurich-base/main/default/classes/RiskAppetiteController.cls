public with sharing class RiskAppetiteController {

    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableSICs(){

        try
        {
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findAllMasters();
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'SIC__c');

            List<String> labels = new List<String>();
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                // TODO Aquí se pone el nombre de los campos a concatenar, no es SicDesc ni Subfamilia
                labels.add(generateLabel(currentRecord, 'SIC__c', 'Subfamilia__c'));
            }
            return labels;
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductsForSIC(String SICCode){
        try {
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findProductsBySicCode(SICcode);
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'CodigoProducto__c');

            List<String> labels = new List<String>();
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                // TODO Aquí se pone el nombre de los campos a concatenar, no es SicDesc ni Subfamilia
                labels.add(generateLabel(currentRecord, 'CodigoProducto__c', 'NombreProducto__c'));
            }
            return labels;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CommercialActivity> getCommercialActivitiesForProducts(String SICCode, String productCode){
        try {
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findCommercialActivitiesByProductCode(SICcode, productCode);
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'CodigoActividad__c');
            List<CommercialActivity> policies = new List<CommercialActivity>();

            String currentLabel;
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                currentLabel = generateLabel(currentRecord, 'CodigoActividad__c', 'ObservacionesActividad__c');
                policies.add(new CommercialActivity(currentLabel, currentRecord.ApetitoRiesgo__c, currentRecord.DyO__c, currentRecord.Ciber__c));
            }
            return policies;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MaestroApetito__c> getTechPoliciesForActivities(String SICCode, String productCode, String activityCode){
        try {
            System.debug(SICCode);
            System.debug(productCode);
            System.debug(activityCode);
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity(SICcode, productCode, activityCode);
            System.debug(records);
            return records;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static List<MaestroApetito__c> removeDuplicates(List<MaestroApetito__c> records, String fieldToCheck)
    {
        List<MaestroApetito__c> noDuplicatesList = new List<MaestroApetito__c>();
        Set<String> values = new Set<String>();

        for(MaestroApetito__c maestro : records)
        {
            if(values != null)
            {
                if(!values.contains((String)maestro.get(fieldToCheck)))
                {
                    values.add((String)maestro.get(fieldToCheck));
                    noDuplicatesList.add(maestro);
                }
            }
        }
        return noDuplicatesList;
    }

    private static String generateLabel(MaestroApetito__c record, String fieldCode, String fieldName)
    {
        String label = record.get(fieldCode) + ' - ';
        if(record.get(fieldName) != null)
        {
            label += record.get(fieldName);
        }
        return label;
    }

    @AuraEnabled(cacheable=true)
    public static List<Field> getFields(String productCode)
    {
        String fieldSet = 'ramo' + productCode;
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('MaestroApetito__c');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSet);
        List<Schema.FieldSetMember> fieldList = fieldSetObj.getFields(); 

        List<Field> fieldsToShow = new List<Field>();

        // To return the field api name
        for(FieldSetMember field : fieldList)
        {
            fieldsToShow.add(new Field(field.getLabel(), field.getFieldPath(), field.getType()));
        }

        return fieldsToShow;
    }

    class Product
    {
        @auraEnabled public String label;
        @auraEnabled public String enlace1;
        @auraEnabled public String enlace2;
        @auraEnabled public String enlace3;

        public Product (String label, String enlace1, String enlace2, String enlace3)
        {
            this.label = label;
            this.enlace1 = enlace1;
            this.enlace2 = enlace2;
            this.enlace3 = enlace3;
        }
    }

    class CommercialActivity
    {
        @auraEnabled public String label;
        @auraEnabled public String riskAppetite;
        @auraEnabled public String dyo;
        @auraEnabled public String ciber;

        public CommercialActivity (String label, String riskAppetite, String dyo, String ciber)
        {
            this.label = label;
            this.riskAppetite = riskAppetite;
            this.dyo = dyo;
            this.ciber = ciber;
        }
    }

    class Field {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public Integer initialWidth {get;set;}

        public Field(String label, String fieldName, Schema.DisplayType type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            calculateType(type);
        }

        private void calculateType(Schema.DisplayType type)
        {
            this.type = String.valueOf(type).toLowerCase();
            if(this.type == 'boolean')
            {
                this.initialWidth = 15;
            }
            else if(this.type == 'currency')
            {
                this.initialWidth = 120;
            }
            else 
            {
                this.initialWidth = 90;
            }
        }
    }
}