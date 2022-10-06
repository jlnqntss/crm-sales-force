/**
 * Clase controladora para los componentes que forman el flow Screen de Apetitos de riesgo
 * @author jjuaristi@seidor.es
 * @date 05/10/2022
 */
public with sharing class RiskAppetiteController {

    private static final String PREFERENTE_BADGE_CLASS = 'slds-theme_success';
    private static final String NO_PREFERENTE_BADGE_CLASS = 'slds-theme_warning';
    private static final String EXCLUIDO_BADGE_CLASS = 'slds-theme_inverse';
    private static final String FUERA_DE_APETITO_BADGE_CLASS = 'slds-theme_error';
    private static final String VARIOS_BADGE_CLASS = 'slds-theme_lightest';

    /**
     * Método que es llamado desde el componente de selección de SIC para recoger todos los posibles
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @return Etiquetas a mostrar en el componente
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableSICs(){
        try
        {
            // Buscamos todos los registros
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findAllMasters();
            // Eliminamos los duplicados para mostrar solo una vez cada SIC
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'SIC__c');

            List<String> labels = new List<String>();
            // Hacemos un bucle que recorre todos los SICs posibles y genera el label a mostrar al usuario
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                labels.add(generateLabel(currentRecord, 'SIC__c', 'SICDescription__c'));
            }
            // Devolvemos las etiquetas
            return labels;
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Método que es llamado desde el componente de selección de ramo para recoger todos los posibles
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param SIC escogido
     * @return Ramos posibles, se mostrarán en el componente
     */
    @AuraEnabled(cacheable=true)
    public static List<Product> getProductsForSIC(String sicCode){
        try {
            // Buscamos todos los registros filtrados por SIC
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findProductsBySicCode(sicCode);
            // Eliminamos los duplicados para mostrar solo una vez cada ramo
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'CodigoProducto__c');

            List<Product> products = new List<Product>();
            // Hacemos un bucle que recorre todos los registros posibles y genera la lista de ramos a mostrar
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                // Generamos etiqueta a mostrar
                Product product = new Product(generateLabel(currentRecord, 'CodigoProducto__c', 'NombreProducto__c'), currentRecord);
                // Generamos el estilo del badge del apetito de riesgo (color y etiqueta)
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

    /**
     * Método que es llamado desde el componente de selección de actividad comercial para recoger todos los posibles
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param SIC y ramo escogidos
     * @return 
     */
    @AuraEnabled(cacheable=true)
    public static List<CommercialActivity> getCommercialActivitiesForProducts(String sicCode, String productCode){
        try {
            // Buscamos todos los registros filtrados por SIC y ramo
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findCommercialActivitiesByProductCode(sicCode, productCode);
            // Eliminamos los duplicados para mostrar solo una vez cada actividad comercial
            List<MaestroApetito__c> noDuplicatesList = removeDuplicates(records, 'CodigoActividad__c');
            List<CommercialActivity> policies = new List<CommercialActivity>();

            String currentLabel;
            for(MaestroApetito__c currentRecord : noDuplicatesList)
            {
                // Hacemos un bucle que recorre todos los registros posibles y genera la lista de actividades a mostrar
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

    /**
     * Método que es llamado desde el componente de selección de políticas técnicas para recoger todos los posibles
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param 
     * @return 
     */
    @AuraEnabled(cacheable=true)
    public static List<MaestroApetito__c> getTechPoliciesForActivities(String sicCode, String productCode, String activityCode){
        try {
            // Buscamos todos los registros filtrados por SIC, ramo y actividad comercial
            List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity(sicCode, productCode, activityCode);
            // Devolvemos las opciones posibles
            return records;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Método que elimina registros duplicados en base a un campo determinado
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Lista de registros de la que se van a eliminar los duplicados, String con el nombre api del campo en base al que se va a comprobar
     * @return Lista sin duplicados
     */
    private static List<MaestroApetito__c> removeDuplicates(List<MaestroApetito__c> records, String fieldToCheck)
    {
        // Lista nueva en la que vamos a añadir los registros no duplicados
        List<MaestroApetito__c> noDuplicatesList = new List<MaestroApetito__c>();
        Set<String> values = new Set<String>();

        for(MaestroApetito__c maestro : records)
        {
            // Recorremos la lista original
            if(values != null && !values.contains((String)maestro.get(fieldToCheck)))
            {
                // Si no se ha añadido ya un registro con el mismo valor en el campo determinado, se añade
                values.add((String)maestro.get(fieldToCheck));
                noDuplicatesList.add(maestro);
            }
        }
        return noDuplicatesList;
    }

    /**
     * Método que genera la etiqueta en base a un registro, y los campos en los que se encuentran el código y la descripción 
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param registro, [fieldCode] código (SIC, ramo o actividad comercial), [fieldName] descripción
     * @return Etiqueta 
     */
    private static String generateLabel(MaestroApetito__c record, String fieldCode, String fieldName)
    {
        // Concatenamos el código del campo que hemos recibido con un '-'
        String label = record.get(fieldCode) + ' - ';
        // Si la descripción no es nula, concatenamos descripción (para evitar excepciones en caso de que no esté relleno)
        if(record.get(fieldName) != null)
        {
            label += record.get(fieldName);
        }
        return label;
    }

    /**
     * Método que calcula la etiqueta que va a tener un badge
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param lista de registros, valor a comprobar, y campos a comprobar
     * @return Label
     */
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

    /**
     * Método que en base a la etiqueta del badge, genera la clase necesaria para añadirle color en html
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param label del badge
     * @return Clase del badge
     */
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

    /**
     * Método que a partir del ramo descarga el fieldset necesario y devuelve los campos
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Código de ramo
     * @return Lista de campos a mostrar
     */
    @AuraEnabled(cacheable=true)
    public static List<Field> getFields(String productCode)
    {
        // Generamos el nombre del fieldSet
        String fieldSet = 'ramo' + productCode;
        // Descargamos los campos
        List<Schema.FieldSetMember> fieldList = getFieldSetMembers(fieldSet);

        List<Field> fieldsToShow = new List<Field>();

        // To return the field api name
        for(FieldSetMember field : fieldList)
        {
            fieldsToShow.add(new Field(field.getLabel(), field.getFieldPath(), field.getType()));
        }

        return fieldsToShow;
    }

    /**
     * Método que devuelve los campos de un fieldSet en base a su nombre
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param nombre del fieldset
     * @return campos en el fieldset
     */
    private static List<Schema.FieldSetMember> getFieldSetMembers(String fieldSet)
    {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get('MaestroApetito__c');
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSet);
        return fieldSetObj.getFields(); 
    }

    /**
     * Método que devuelve los metadatos con los 'Otros ramos'
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @return Lista de metadatos
     */
    @AuraEnabled(cacheable=true)
    public static List<OtherProduct__mdt> getOtherProducts()
    {
        try 
        {
            List<OtherProduct__mdt> products = new List<OtherProduct__mdt>();
            products = [SELECT Id, MasterLabel, ProductCode__c,	SharepointLink__c FROM OtherProduct__mdt ORDER BY ProductCode__c];
            return products;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Método que recupera un caso de la base de datos
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Id del caso
     * @return Caso
     */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(String caseId)
    {
        return new CasesSelector().findById(new Set<String>{caseId})[0];
    }

    /**
     * Método que devuelve la política técnica fijada
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Json con los elementos necesarios para encontrar la política técnica fijada
     * @return Política técnica
     */
    @AuraEnabled(cacheable=true)
    public static MaestroApetito__c getSetTechPolicies(String caseQuery)
    {
        MaestroApetito__c record = (MaestroApetito__c) JSON.deserialize(caseQuery, MaestroApetito__c.Class);

        // Cargamos los fieldsets que contienen los campos relevantes a la hora de lanzar la query
        String fieldSet = 'Checkboxes';
        List<Schema.FieldSetMember> fieldList = getFieldSetMembers(fieldSet);

        fieldSet = 'IdentifyingCodes';
        fieldList.addAll(getFieldSetMembers(fieldSet));

        List<String> fields = new List<String>();
        for(Schema.FieldSetMember field : fieldList)
        {
            fields.add(field.getFieldPath());
        }

        // Lanzamos la query para obtener el maestro fijado determinado
        MaestroApetito__c maestroFijado = new RiskAppetiteMasterSelector().getQueryFindTechnicalPolicy(record, fields);
        return maestroFijado;
    }

    /**
     * Método que fija la política técnica 
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Id del caso en el que se fija, registro de la política a fijar
     */
    @AuraEnabled
    public static void holdTechPolicy(String caseIdToUpdate, MaestroApetito__c technicalPolicy)
    {
        try
        {
            Case caseToUpdate = new Case(Id = caseIdToUpdate);

            String fieldSet = 'Checkboxes';
            List<Schema.FieldSetMember> fieldList = getFieldSetMembers(fieldSet);
            
            fieldSet = 'IdentifyingCodes';
            fieldList.addAll(getFieldSetMembers(fieldSet));
            
            List<String> fields = new List<String>();
            for(Schema.FieldSetMember field : fieldList)
            {
                fields.add(field.getFieldPath());
            }
            
            // Generar json con los valores que van a ir al where
            caseToUpdate.Query__c = generateQueryJson(technicalPolicy, fields);
            caseToUpdate.RiskAppetite__c = technicalPolicy.ApetitoRiesgo__c;
            update caseToUpdate;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Método que en base a la política técnica a fijar genera el json necesario para luego poder recuperarlo
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Registro, campos a añadir al json
     * @return Json
     */
    private static String generateQueryJson(MaestroApetito__c record, List<String> fields)
    {
        // Registro auxiliar que solo tendrá los campos requeridos en el json
        MaestroApetito__c recordForJson = new MaestroApetito__c();

        // Añadimos los campos requeridos
        for(String field : fields)
        {
            recordForJson.put(field, record.get(field));
        }

        // Serializamos el objeto a formato json
        return JSON.serialize(recordForJson);
    }

    /**
     * Método que desfija una política técnica
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     * @param Id del caso
     */
    @AuraEnabled
    public static void unsetTechPolicy(String caseIdToUpdate)
    {
        try
        {
            // Registro auxiliar
            Case caseToUpdate = new Case(Id = caseIdToUpdate);
            // Vacíamos el campo que contiene el json
            caseToUpdate.Query__c = '';
            caseToUpdate.RiskAppetite__c = '';
            // Actualizamos el caso
            update caseToUpdate;
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Inner class que contiene la información de los ramos
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
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

    /**
     * Inner class que contiene la información de las actividades comerciales
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
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

    /**
     * Inner class que contiene la información de los campos
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
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
        public Integer initialWidth {get;set;}

        /**
         * Contructor de la clase Field
         * @author jjuaristi@seidor.es
         * @date 05/10/2022
         */
        public Field(String label, String fieldName, Schema.DisplayType type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            calculateType(type);
        }

        /**
         * Método que calcula el tipo del campo pero de forma que html lo entienda
         * @author jjuaristi@seidor.es
         * @date 05/10/2022
         * @param Tipo del campo
         */
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