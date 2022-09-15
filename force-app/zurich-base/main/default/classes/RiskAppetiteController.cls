public with sharing class RiskAppetiteController {

    private static final String PREFERENTE_BADGE_CLASS = 'slds-theme_success';
    private static final String NO_PREFERENTE_BADGE_CLASS = 'slds-theme_warning';
    private static final String EXCLUIDO_BADGE_CLASS = 'slds-theme_inverse';
    private static final String FUERA_DE_APETITO_BADGE_CLASS = 'slds-theme_error';
    private static final String VARIOS_BADGE_CLASS = 'slds-theme_lightest';

    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableSICs(){

        try
        {
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findAllMasters();
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'SIC__c');

            List<String> labels = new List<String>();
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                labels.add(generateLabel(currentRecord, 'SIC__c', 'SICDescription__c'));
            }
            return labels;
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product> getProductsForSIC(String SICCode){
        try {
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findProductsBySicCode(SICcode);
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'CodigoProducto__c');

            List<Product> products = new List<Product>();
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                Product product = new Product(generateLabel(currentRecord, 'CodigoProducto__c', 'NombreProducto__c'), currentRecord);
                product.buttonLabel = checkBadgeLabel(records, currentRecord.CodigoProducto__c, 'CodigoProducto__c', 'ApetitoRiesgo__c');
                product.buttonClass = generateButtonClass(product.buttonLabel);
                products.add(product);
            }
            return products;
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
                CommercialActivity activity = new CommercialActivity(currentLabel);
                activity.riskAppetite = checkBadgeLabel(records, currentRecord.CodigoActividad__c, 'CodigoActividad__c', 'ApetitoRiesgo__c');
                activity.riskAppetiteBadge = generateButtonClass(activity.riskAppetite);
                activity.dyo = checkBadgeLabel(records, currentRecord.CodigoActividad__c, 'CodigoActividad__c', 'DyO__c');
                activity.dyoBadge = generateButtonClass(activity.dyo);
                activity.ciber = checkBadgeLabel(records, currentRecord.CodigoActividad__c, 'CodigoActividad__c', 'Ciber__c');
                activity.ciberBadge = generateButtonClass(activity.ciber);
                policies.add(activity);
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
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity(SICcode, productCode, activityCode);
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

    public static String checkBadgeLabel (List<MaestroApetito__c> records, String fieldCode, String fieldName, String fieldToCheck)
    {
        String badgeLabel = '';
        for(MaestroApetito__c currentRecord : records)
        {
            if((String) currentRecord.get(fieldName) == fieldCode)
            {
                if(badgeLabel == '')
                {
                    badgeLabel = (String) currentRecord.get(fieldToCheck);
                }
                else
                {
                    if( (String) currentRecord.get(fieldToCheck) != badgeLabel)
                    {
                        return 'Varios';
                    }
                }
            }
        }
        return badgeLabel;
    }

    public static String generateButtonClass(String preference)
        {
            if(preference == 'Preferente')
            {
                return PREFERENTE_BADGE_CLASS;
            }
            else if(preference == 'No Preferente')
            {
                return NO_PREFERENTE_BADGE_CLASS;
            }
            else if(preference == 'Excluido')
            {
                return EXCLUIDO_BADGE_CLASS;
            }
            else if(preference == 'Fuera de apetito')
            {
                return FUERA_DE_APETITO_BADGE_CLASS;
            }

            return '';
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


    
    @TestVisible
    class Product
    {
        @auraEnabled public String label;
        @auraEnabled public String sharepoint;
        @auraEnabled public String dyoSharepoint;
        @auraEnabled public String ciberSharepoint;
        @AuraEnabled public String buttonClass;
        @AuraEnabled public String buttonLabel;

        public Product (String label, MaestroApetito__c maestro)
        {
            this.label = label;
            this.sharepoint = maestro.SharepointLink__c;
            this.dyoSharepoint = maestro.SharepointLinkDO__c;
            this.ciberSharepoint = maestro.SharepointLinkCyber__c;
        }
    }

    @TestVisible
    class CommercialActivity
    {
        // riskAppetite, dyo y ciber van a ser el label del botón, y a cada uno de ellos se le calcula la clase a partir de eso, solo hace falta crear 3 variables
        @auraEnabled public String label;
        @auraEnabled public String riskAppetite;
        @auraEnabled public String riskAppetiteBadge;
        @auraEnabled public String dyo;
        @auraEnabled public String dyoBadge;
        @auraEnabled public String ciber;
        @auraEnabled public String ciberBadge;

        public CommercialActivity (String label)
        {
            this.label = label;
        }
    }

    @TestVisible
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