/**
 * Clase controlador que es invocada en el LWC -> generateComercialPlan
 * 
 * Proyecto: SDM - Plan comercial anual
 *
 * @author nts (agonzalezisasi)
 * @date 10/09/2021
 *
 */
public with sharing class GenerateComercialPlanController 
{
    private static final String CLASS_NAME = 'GenerateComercialPlanController';

    // Lista de roles de Salesforce que pueden ejercer de Directores en la pantalla
    private static final List<String> Directors = new List<String> {
        SettingsSDM.SF_ROLE_DT_DEVNAME,
        SettingsSDM.SF_ROLE_DV_DEVNAME
    };

    // Lista de roles de Salesforce que pueden ejercer de Consultores o RNs en la pantalla
    private static final List<String> Consultants = new List<String> {
        SettingsSDM.SF_ROLE_RN_DEVNAME,
        SettingsSDM.SF_ROLE_CV_DEVNAME
    };

    // Relacion entre el rol de Salesforce y el campo de email en el objeto mediador (account)
    private static final Map<String, String> mapEmailFieldsByUserRole = new Map<String, String> {
        SettingsSDM.SF_ROLE_DT_DEVNAME => AccountsSelector.SDM_DZ_EMAIL_FIELD,
        SettingsSDM.SF_ROLE_RN_DEVNAME => AccountsSelector.SDM_RN_EMAIL_FIELD,
        SettingsSDM.SF_ROLE_DV_DEVNAME => AccountsSelector.SDM_DV_EMAIL_FIELD,
        SettingsSDM.SF_ROLE_CV_DEVNAME => AccountsSelector.SDM_CV_EMAIL_FIELD
    };

    // Relacion entre el rol de Salesforce de Director y el Rol de Consultor o RN del usuario en el equipo de cuenta de los mediadores
    private static final Map<String, String> mapATMRoleByUserRole = new Map<String, String> {
        SettingsSDM.SF_ROLE_DT_DEVNAME => SettingsSDM.ATM_ROL_BUSINESS,
        SettingsSDM.SF_ROLE_DV_DEVNAME => SettingsSDM.ATM_ROL_LIFECONSULTANT
    };

    public static final String ROW_LABEL_SEGMENT = Label.SDM_PlanAnual_RowSegment;
    public static final String ROW_LABEL_PRODUCT = Label.SDM_PlanAnual_RowProduct;
    public static final String ROW_LABEL_INDICATOR = Label.SDM_PlanAnual_RowIndicator;
    public static final String ROW_LABEL_YEAR = Label.SDM_PlanAnual_RowYear;
    public static final String ROW_LABEL_ZONE = Label.SDM_PlanAnual_RowZone;
    public static final String ROW_LABEL_PLAN = Label.SDM_PlanAnual_RowPlanDT;

    public static final String NEW_DEFAULT_TEXT_PLAN = Label.SDM_PlanAnual_NewPlan;
    public static final String NEW_DEFAULT_SEGMENT = PlanComercialSelector.SEGMENT_ALL; 
    public static final String NEW_DEFAULT_PRODUCT = PlanComercialSelector.PRODUCT_ALL;
    public static final String NEW_DEFAULT_INDICATOR = PlanComercialSelector.INDICATOR_PN;
    public static final String NEW_DEFAULT_ZONE = PlanComercialSelector.ZONE_ALL;

    public static final String COMBOBOX_SEGMENT = 'segmento'; // uso interno
    public static final String COMBOBOX_SEGMENT_PLACEHOLDER = Label.SDM_PlanAnual_SegmentPlaceholder;
    public static final String COMBOBOX_PRODUCT = 'producto'; // uso interno
    public static final String COMBOBOX_PRODUCT_PLACEHOLDER = Label.SDM_PlanAnual_ProductPlaceholder;
    public static final String COMBOBOX_INDICATOR = 'indicador'; // uso interno
    public static final String COMBOBOX_INDICATOR_PLACEHOLDER = Label.SDM_PlanAnual_IndicatorPlaceholder;
    public static final String COMBOBOX_ZONE = 'zone'; // uso interno
    public static final String COMBOBOX_ZONE_PLACEHOLDER = Label.SDM_PlanAnual_ZonePlaceholder;
    private static final String ZONE_ALL_VALUE = PlanComercialSelector.ZONE_ALL; 


    public static final String COL_TOTAL = 'Sumatorio';

    public static final String SEPARATOR = '#';

    public static final String CELL_PROPERTY_IS_MY_PLAN = 'IS_MY_PLAN';
    
    public static final String PLAN_ACCUMULATE_TYPE = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
    public static final String PLAN_SEND_NOTIF = PlanComercialSelector.SEND_NOTIFICATION_ABOVE_THRESHOLD;

    // Numero de fila de la tabla donde empiezan los RN / Mediadores
    public static final Integer ROWS_FROM_RN_INTERMEDIARY = 6;

    @testvisible
    private static String testException;
    
    // ---------------------------------- TABLE DATA --------------------------
    /**
     * Clase con los datos para representar una TABLA en el LWC
     * 
     * @author nts (agonzalezisasi)
     * @date 10/09/2021
     * 
     */
    public class Tabletype 
    {
        // Datos internos
        @testvisible
        Boolean isEdited;
        Boolean canCreate;
        Boolean canSave;

        // Fila de cabecera de la tabla
        @testvisible
        Rowtype headers;
        // Resto de filas de la tabla
        @testvisible
        List<Rowtype> rows;
        // Fila de pie de la tabla
        Rowtype footers;

        // Filas con valores por defecto para un plan nuevo
        @testvisible
        Rowtype headersNew; 
        @testvisible
        List<Rowtype> rowsNew;
        Rowtype footersNew;

        // Datos de valores de combobox
        Transient Map<String, Combotype> mapOptions;
        // Mapa de equivalencias de tipos de indicadores
        Map<String, String> mapIndicatorType;

        // Mapa intermediarios (ids) y sus zonas
        Map<String, String> mapIntermediaryZones;

        // Mapa de dependencias entre desplegables
        Map<String, Map<String, Map<String, String>>> mapDependants;
        // Mapa de relacion entre el desplegable controlador y su dependiente
        Map<String, String> mapDependantCategories;

        // Constructor de la clase
        public Tabletype() {
            canCreate = false;
            canSave = false;
            headers = new Rowtype('');
            rows = new List<Rowtype>();
            headersNew = new Rowtype('');
            rowsNew = new List<Rowtype>();
            footers = new Rowtype(COL_TOTAL);
            footersNew = new Rowtype(COL_TOTAL);

            // Copiamos el mapa de tipos de indicadores para poder usarlos en el lwc
            this.mapIndicatorType = PlanComercialSelector.getMapIndicatorType();
            this.mapIntermediaryZones = null;
        }

        /**
         * Añade filas a la tabla
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @param {String id} id de la fila
         * @param {String name} etiqueta de la fila
         */
        public void addFixedRow(String id, String name)
        {
            this.rows.add(new Rowtype(id, name));
            this.rowsNew.add(new Rowtype(id, name));
        }

        /**
         * Añade filas a la tabla
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @param {String name} etiqueta de la fila
         */
        public void addFixedRow(String name)
        {
            this.rows.add(new Rowtype(name));
            this.rowsNew.add(new Rowtype(name));
        }        

        /**
         * Añade opciones de combobox de tipo mapa a la tabla
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @param {String name} etiqueta de la fila
         * @param {String placeholder} texto de placeholder para el combobox
         * @param {Map<String, String> mapOptionsData} mapa de opcioens
         */
        public void addOptions(String name, String placeholder, Map<String, String> mapOptionsData)
        {
            List<Optiontype> options = mapToOptions(mapOptionsData);
            if( this.mapOptions == null ) this.mapOptions = new Map<String, Combotype>();
            this.mapOptions.put(name, new Combotype(placeholder, options));
        }

        /**
         * Añade opciones de desplegables dependientes entre si
         * 
         * @author nts (agonzalezisasi)
         * @date 30/09/2021
         * 
         * @param {String controller} nombre del desplegable controlador
         * @param {String dependant} nombre del desplegable dependiente
         * @param {Map<String, Map<String, String>> mapDependantOptionsData} mapa de dependencias
         */
        public void addDependant(String controller, String dependant, Map<String, Map<String, String>> mapDependantOptionsData)
        {
            // Si no existen los mapas se crean
            if( this.mapDependants == null ) this.mapDependants = new Map<String, Map<String, Map<String, String>>>();
            if( this.mapDependantCategories == null ) this.mapDependantCategories = new Map<String, String>();
            // Añadimos el mapa de dependencias con el nombre del controlador
            this.mapDependants.put(controller, mapDependantOptionsData);
            // Añadimos la relacion entre el controlador y su dependiente
            this.mapDependantCategories.put(controller, dependant);            
        }

        /**
         * Devuelve el objeto en formato JSON
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @return {String} json de la tabla
         */
        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Clase que permitira mostrar datos de una FILA en la tabla del LWC
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Rowtype 
    {
        public String Key;
        public String Text;
        public List<Celltype> Cells;
        public String Id;
        public Boolean hasId;
        public Boolean isLink;

        // Constructor de la clase. Solo texto y valores por defecto
        public Rowtype(String text)
        {
            this.Text = text;
            this.Key = text;
            this.Cells = new List<Celltype>();
            this.hasId = false;
        }

        // Constructor de la clase. Texto y Id
        public Rowtype(String id, String text)
        {
            this(text);
            this.Id = id;
            this.hasId = true;
        }
    }

    /**
     * Clase que permitira mostrar datos de una CELDA en la tabla del LWC
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Celltype 
    {
        // Valores internos de la celda
        String Key;
        String Name;
        @testvisible
        String Id;
        String HtmlClass;
        String Category;

        // Permiten indicar que tipo de dato es
        Boolean isString;
        Boolean isNumber;
        Boolean isCurrency;
        Boolean isPercent;
        Boolean isDate;
        Boolean isCombobox;

        // Permite indicar los estados de la celda
        Boolean isEditable;
        @testvisible
        Boolean isModified;
        Boolean isLocked;
        Boolean isLink;
        @testvisible
        Boolean isNew;
        Boolean isNewEditable;
        @testvisible
        Boolean isDeleted;

        // Guarda el dato actual
        @testvisible
        Decimal decimalValue;
        @testvisible
        String stringValue;
        Date dateValue;

        // Permitira saber si se ha modificado el dato
        Decimal decimalValueOld;
        String stringValueOld;
        Date dateValueOld;
        String originalValueDescription;

        // Guardara los valores de comparacion
        Boolean isComparingNumber;
        Boolean isComparingCurrency;
        Decimal comparingValue;
        Boolean hasComparing;
        Boolean isComparingPositive;
        boolean comparingHasData;

        String stringValueDefault;
        Decimal decimalValueDefault;
        Date dateValueDefault;

        // Para los datos extra si el campo es de tipo combo
        Combotype combo;

        Map<String, String> mapExtraProperties;

        //---------------------------------- Constructores 
        // Para valores por defecto
        public Celltype()
        {
            this.isString = false;
            this.isNumber = false;
            this.isDate = false;
            this.isEditable = false;
            this.isDeleted = false;
            this.isLocked = false;
            this.isNewEditable = true;
            this.isCombobox = false;
            this.isModified = false;
            this.isCurrency = false;
            this.isPercent = false;
            this.isLink = false;
            this.isNew = false;
            this.hasComparing = false;
            this.isComparingPositive = false;
            this.comparingHasData = false;
            this.stringValueDefault = '';
            this.decimalValueDefault = 0;
            this.dateValueDefault = Date.today();

            this.HtmlClass = '';
        }

        // Para valores comunes
        public Celltype(String category, String name, Boolean isEditable)
        {
            this();
            this.Name = name;
            this.isEditable = isEditable;
            this.Category = category;
        }

        // Para celdas con valor de tipo string
        public Celltype(String category, String name, String value, Boolean isEditable)
        {
            this(category, name, isEditable);
            
            this.stringValue = value;
            this.stringValueOld = value;
            this.isString = true;
        }

        // Para celdas con valor de tipo decimal
        public Celltype(String category, String name, Decimal value, Boolean isEditable, Boolean isCurrency)
        {
            this(category, name, isEditable);

            this.decimalValue = value;
            this.decimalValueOld = value;
            this.isNumber = !isCurrency;
            this.isCurrency = isCurrency;
        }

        // Para celdas con valor de tipo combobox
        public Celltype(String category, String name, String value, Boolean isEditable, Combotype combo)
        {
            this(category, name, isEditable);

            this.isCombobox = true;
            this.stringValue = value;
            this.stringValueOld = value;
            this.combo = combo;
        }   

        //---------------------------------- Metodos publicos
        
        /**
         * Marca una celda como bloqueada
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         */
        public void lock()
        {
            this.isLocked = true;
        }

        /**
         * Añade valores de compracion vacios a la celda
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         */
        public void setSecondaryValueEmpty()
        {
            this.hasComparing = true;
            this.comparingHasData = false;
            this.isComparingPositive = false;
        }

        /**
         * Añade valores de comparacion con el valor principal
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @param {Decimal value} valor
         * @param {Boolean isPositive} si el valor es positivo (true) o no (false)
         */
        public void setSecondaryValue(Decimal value, Boolean isPositive)
        {
            this.comparingValue = value;
            this.hasComparing = true;
            this.comparingHasData = true;
            this.isComparingPositive = isPositive;
        }

        public void addExtraProperty(String name, String value)
        {
            if( this.mapExtraProperties == null ) this.mapExtraProperties = new Map<String, String>();
            this.mapExtraProperties.put(name, value);
        }
    }

    /**
     * Clase que permite mostrar un combobox en la tabla del LWC
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Combotype
    {
        // Placeholder del combobox
        String placeholder;
        // Opciones del combobox
        List<Optiontype> options;
        Boolean isDependant;
        String controlerName;

        // Constructor
        public Combotype(String placeholder, List<Optiontype> options)
        {
            this.isDependant = false;
            this.placeholder = placeholder;
            this.options = options;
        }
    }

    /**
     * Clase que permite añadir opciones (etiqueta-valor) al combobox
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Optiontype 
    {
        // Etiqueta
        public String label;
        // Valor
        public String value;

        // Constructor
        public Optiontype(String label, String value)
        {
            this.label = label;
            this.value = value;
        }
    }


    //------ static

    /**
     * Convierte un mapa de valores de tipo texto a opciones de combobox
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Map<String, String> mapOptions} mapa de valores
     * @return {List<Optiontype>} lista de opciones
     */
    public static List<Optiontype> mapToOptions(Map<String, String> mapOptions)
    {
        List<Optiontype> options = new List<Optiontype>();
        if( mapOptions != null ) {
            for(String key: mapOptions.keySet()) {
                options.add(new Optiontype(mapOptions.get(key), key));
            }
        }
        return options;
    }
    // ------------------------------------------------------------------------

    /**
     * Clase de ayuda para convertir los objetos PlanComercial__c en filas y columnas
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Plandata 
    {
        String Id;
        String ParentId;
        public String Title;
        public String Segment;
        public String Product;
        public String Indicator;
        public String Zone;
        public Integer Year;
        public Decimal Value;
        public Decimal ActualKpi;
        public String AssignedToId;
        public String OwnerId;

        public List<Subplandata> Subplans;
        public Map<Id, Subplandata> mapSubplanByDetail;

        public Boolean isMyPlan {
            get {
                // Considero que es mi plan cuando hay asignado al plan y creador del plan y son
                // la misma persona
                return (AssignedToId != null && OwnerId != null && AssignedToId == OwnerId);
            }
        }

        public Boolean isTitleModified;
        public Boolean isSegmentModified;
        public Boolean isProductModified;
        public Boolean isIndicatorModified;
        public Boolean isZoneModified;
        public Boolean isValueModified;
        public Boolean isDirector;
        public Boolean isNewPlan;

        public PlanComercialSelector.eIndicator IndicatorType;
        public Id rtPlanAnualId;
        

        // Constructor
        public Plandata(String id, String title, String segment, String product, String indicator, String zone, Integer year, Decimal value, Decimal actualKpi, String assignedToId, String ownerId)
        {
            this.Id = id;
            this.Title = title;
            this.Segment = segment;
            this.Product = product;
            this.Indicator = indicator;
            this.Zone = zone;
            this.Year = year;
            this.Value = value;
            this.ActualKpi = actualKpi;
            this.AssignedToId = assignedToId;
            this.OwnerId = ownerId;

            isTitleModified = false;
            isSegmentModified = false;
            isProductModified = false;
            isIndicatorModified = false;
            isZoneModified = false;
            isValueModified = false;
        }


        /**
         * Añade subplanes al plan principal
         * 
         * @author nts (agonzalezisasi)
         * @date 20/09/2021
         * 
         * @param {Subplandata subplan} plan hijo
         * @param {Id detailId} Id de la fila al que hace referencia el plan hijo
         */
        public void addSubplan(Subplandata subplan, Id detailId) 
        {
            // Inicializa la lista y el mapa si no lo estan ya
            if( this.Subplans == null ) this.Subplans = new List<Subplandata>();
            if( this.mapSubplanByDetail == null ) this.mapSubplanByDetail = new Map<Id, Subplandata>();

            // Añade el plan hijo
            this.Subplans.add(subplan);
            // Y la referencia a la fila que le toca
            this.mapSubplanByDetail.put(detailId, subplan);
        }
    }

    /**
     * Clase de ayuda para convertir los planes hijos en filas y columnas de la tabla
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     */
    public class Subplandata 
    {
        public String Name;
        public String Id;

        public Decimal Value;
        public Decimal ComparingValue;

        public Subplandata(String id, String name, Decimal value, Decimal comaringValue)
        {
            this.Id = id;
            this.Name = name;
            this.Value = value;
            this.ComparingValue = comaringValue;
        }
    }

    // ------------------------------------------------------------------------

    /**
     * Obtiene el valor objetivo del plan del campo informado
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {PlanComercial__c plan} el plan
     * @return {Decimal} el valor
     */
    private static Decimal getComercialPlanValue(PlanComercial__c plan)
    {
        Decimal value = plan.TargetKPINumber__c;
        if( value == null ) value = plan.TargetKPICurrency__c;
        if( value == null ) value = plan.TargetKPIPercent__c;
        return value;
    }

    /**
     * Obtiene el valor objetivo del plan del campo informado
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {PlanComercial__c plan} el plan
     * @return {Decimal} el valor
     */
    private static Decimal addCellsPerPlan(List<Rowtype> rows, Plandata plan, PlanComercialSelector.eIndicator indicatorType, Boolean isDirector, Map<String, String> mapZone)
    {
        // Planes => Fila 5 en adelante
        Celltype cell;        
        Decimal sumValue = 0;

        // Por cada fila de tipo subplan se mira si ya existe dicho subplan en el plan
        for(Integer rowPos = ROWS_FROM_RN_INTERMEDIARY; rowPos < rows.size(); rowPos++) {
            // Id de la fila
            Id detailId = rows[rowPos].Id;
            // Nombre de la fila (RN / Mediador)
            String detailName = rows[rowPos].Text;

            // Intentamos recuperar el subplan
            Subplandata sub = plan?.mapSubplanByDetail?.get(detailId);
            // Si no existe se crea uno vacio
            if( sub == null ) sub = new Subplandata(null, detailName, 0, null);

            Decimal subValue = (sub.Value != null ? sub.Value : 0);

             
            // Se rellena la celda con los datos del plan (category, html name, value, isEditable, isCurrency)
            cell = new Celltype( 
                sub.name, 
                plan.Title + SEPARATOR + sub.name + SEPARATOR + sub.id, 
                subValue, 
                true,
                false
            );
            // Se establece el tipo de valor de la celda segun el tipo de indicador del plan
            cell.isPercent = (indicatorType == PlanComercialSelector.eIndicator.type_percent);
            cell.isCurrency = (indicatorType == PlanComercialSelector.eIndicator.type_currency);
            cell.isNumber = (indicatorType == PlanComercialSelector.eIndicator.type_number);
            
            Boolean isLockedIntermediary = isLockedIntermediary(plan, detailId, isDirector, mapZone);
            
            // Id de la celda
            cell.id = sub.Id;
            // Si es nueva o no
            if( sub.Id == null ) cell.isNew = true;
            // Clave del plan
            cell.key = cell.id + SEPARATOR + sub.name;
            // Si es un enlace
            cell.isLink = true;
            // compruebo para el plan actual si no es director si el intermediario i tiene la misma zona que el plan
            cell.isLocked = isLockedIntermediary;
            cell.isNewEditable = !isLockedIntermediary; // lo informo con el valor contrario para que el js no desbloquee la celda ver linea 223 js
            // Si tiene id
            if( sub.Id != null ) {
                cell.setSecondaryValueEmpty();
                if( sub.ComparingValue != null ) {
                    Boolean isPositive = (subValue < sub.ComparingValue);
                    cell.setSecondaryValue(sub.ComparingValue, isPositive);
                }
            }
            // Insertamos la celda en la fila
            rows.get(rowPos).Cells.add(cell);

            // Para que se puedan abrir los mediadores directamente
            if( !isDirector ) rows.get(rowPos).isLink = true;
            
            // Calculamos el sumatorio
            sumValue += subValue;
        }

        return sumValue;
    }

    /**
     * Convierte un plan en filas y columnas de la tabla en el LWC
     * 
     * Se puede añadir un plan vacio para el caso de que se permita añadir
     * nuevos planes con valores por defecto
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Tabletype tabledata} la tabla
     * @param {Plandata plan} el plan
     * @param {String roleType} tipo de rol del usuario
     * @param {Boolean isEmpty} si es un plan vacio (true) o no (false)
     */
    private static void planToTable(Tabletype tabledata, Plandata plan, String roleType, Boolean isEmpty, Map<String, String> mapZone) 
    {
        // Indica si el usuario es director o no en funcion del rol
        Boolean isDirector = Directors.contains(roleType);
        // Indica si el plan es nuevo o no en funcion de si tiene id
        Boolean isNewPlan = (plan.Id == null);

        // Referencias a las filas y columnas de la tabla
        Celltype cell;
        Rowtype headers = tabledata.headers;
        Rowtype footers = tabledata.footers;
        List<Rowtype> rows = tabledata.rows;
        // Para el caso de planes vacios se rellenan otras filas y columnas
        if( isEmpty ) {
            headers = tabledata.headersNew;
            footers = tabledata.footersNew;
            rows = tabledata.rowsNew;
        }

        // Se calcula el tipo de indicador del plan para los campos de importe
        PlanComercialSelector.eIndicator indicatorType = PlanComercialSelector.getIndicatorType(plan.Indicator);

        Decimal sumValue = addCellsPerPlan(rows, plan, indicatorType, isDirector, mapZone);        

        // Titulo => Header (category, html name, value, isEditable, isCurrency)
        cell = new Celltype( 'titulo', 'titulo' + SEPARATOR + plan.Id, plan.Title, true);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'titulo';
        cell.isNew = isNewPlan;
        cell.addExtraProperty(CELL_PROPERTY_IS_MY_PLAN, String.valueOf(plan.isMyPlan));
        if (!isNewPlan) cell.lock();
        if( plan.ActualKpi != null ) cell.isNewEditable = false;
        headers.Cells.add(cell);

        // Sumatorio => footer (category, html name, value, isEditable, isCurrency)
        cell = new Celltype( 'sumatorio', 'sumatorio' + SEPARATOR + plan.Id, sumValue, true, true);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'sumatorio';
        cell.isNew = isNewPlan;
        cell.isPercent = (indicatorType == PlanComercialSelector.eIndicator.type_percent);
        cell.isCurrency = (indicatorType == PlanComercialSelector.eIndicator.type_currency);
        cell.isNumber = (indicatorType == PlanComercialSelector.eIndicator.type_number);        
        footers.Cells.add(cell);

        Integer rowNum = 0;

        // Segmento => Fila 0 (category, html name, value, isEditable, isCurrency)
        Combotype combo = tabledata.mapOptions.get(COMBOBOX_SEGMENT);
        cell = new Celltype( 'segmento', 'segmento' + SEPARATOR + plan.Id, plan.Segment, true, combo);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'segmento';
        cell.isNew = isNewPlan;
        cell.lock();      
        rows.get(rowNum).Cells.add(cell);
        rowNum++;

        // Producto => Fila 1 (category, html name, value, isEditable, isCurrency)
        // Recuperamos el mapa de valores del producto dependientes del segmento
        Map<String, Map<String, String>> mapDependants = tabledata.mapDependants.get(COMBOBOX_SEGMENT);
        // Recuperamos la lista para este valor de segmento
        Map<String, String> mapAvailableProducts = mapDependants.get(plan.Segment);
        // Transformamos los valores en opciones de combobox
        List<Optiontype> options = mapToOptions(mapAvailableProducts);
        // Creamos el combobox para el lwc
        combo = new Combotype(COMBOBOX_PRODUCT_PLACEHOLDER, options);
        cell = new Celltype( 'producto', 'producto' + SEPARATOR + plan.Id, plan.Product, true, combo);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'producto';
        cell.isNew = isNewPlan;
        cell.lock();
        cell.stringValueDefault = NEW_DEFAULT_PRODUCT;
        rows.get(rowNum).Cells.add(cell);
        rowNum++;

        // Indicador => Fila 2 (category, html name, value, isEditable, isCurrency)
        combo = tabledata.mapOptions.get(COMBOBOX_INDICATOR);
        cell = new Celltype( 'indicador', 'indicador' + SEPARATOR + plan.Id, plan.Indicator, true, combo);
        cell.id = plan.Id;
        cell.key = cell.Category + SEPARATOR + cell.id;
        cell.isNew = isNewPlan;
        cell.lock();
        rows.get(rowNum).Cells.add(cell);
        rowNum++;

        // Zona => Fila 3 (category, html name, value, isEditable, isCurrency)
        combo = getDynamicZoneCombo(mapZone);        
        cell = new Celltype( 'zone', 'zone' + SEPARATOR + plan.Id, plan.Zone, true, combo);
        cell.id = plan.Id;
        cell.key = cell.Category + SEPARATOR + cell.id;
        cell.isNew = isNewPlan;
        cell.lock();
        rows.get(rowNum).Cells.add(cell);
        rowNum++;

        // Año => Fila 4 (category, html name, value, isEditable, isCurrency)
        cell = new Celltype( 'anyo', 'anyo' + SEPARATOR + plan.Id, plan.Year, true, false);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'anyo';
        cell.isNew = isNewPlan;
        cell.lock();
        cell.isNewEditable = false;
        rows.get(rowNum).Cells.add(cell);
        rowNum++;

        // Plan Definido Director => Fila 5 (category, html name, value, isEditable, isCurrency)
        Decimal planValue = (plan.Value != null ? plan.Value : 0);
        cell = new Celltype( 'dt_defined', 'dt_defined' + SEPARATOR + plan.Id, planValue, true, true);
        cell.id = plan.Id;
        cell.key = cell.id + SEPARATOR + 'dt_defined';
        cell.isPercent = (indicatorType == PlanComercialSelector.eIndicator.type_percent);
        cell.isCurrency = (indicatorType == PlanComercialSelector.eIndicator.type_currency);
        cell.isNumber = (indicatorType == PlanComercialSelector.eIndicator.type_number);
        cell = lockCellIsNotMyPlan(cell, plan);
        cell = isCellNewEditable(cell, plan);
        if( plan.Id != null ) {
            cell.setSecondaryValueEmpty();
            if( plan.ActualKpi != null ) {
                Boolean isPositive = (planValue < plan.ActualKpi);
                cell.setSecondaryValue(plan.ActualKpi, isPositive);
            }
        }
        rows.get(rowNum).Cells.add(cell);
    }

    /**
     * Uso exclusivo para el título del plan y el input de la fila row en caso de que el plan no sea del usuario que está viendo los planes bloquea las celdas
     * 
     * @author nts (dmunoz)
     * @date 27/10/2022
     * 
     * @param {Celltype cell} celda a comprobar
     * @param {Plandata plan} datos del plan actual
     * @param {CellType>} celda de entrada que se ha calculado si bloquea o no
     */
    private static Celltype lockCellIsNotMyPlan(Celltype cell, Plandata plan) {

        if( !plan.isMyPlan){
            cell.lock();
        } 
        
        return cell;
    }

    /**
     * Uso exclusivo para el título del plan y el input de la fila row en caso de que el plan no sea del usuario que está viendo los planes bloquea las celdas
     * 
     * @author nts (dmunoz)
     * @date 27/10/2022
     * 
     * @param {Celltype cell} celda a comprobar
     * @param {Plandata plan} datos del plan actual
     * @param {CellType>} celda de entrada que se ha calculado si bloquea o no
     */
    private static Celltype isCellNewEditable(Celltype cell, Plandata plan) {

        if( !plan.isMyPlan) {
            cell.isNewEditable = false;
        }
        
        return cell;
    }

    /**
     * Ejecuta las dmls sobre los planes (creacion, modificacion y borrado) que correspondan. 
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {List<PlanComercial__c> plansToDelete} planes a borrar
     * @param {List<PlanComercial__c> existingPlansToUpsert} planes a modificar
     * @param {List<PlanComercial__c> parentPlansToInsert} planes padres a insertar
     * @param {List<PlanComercial__c> childPlansToInsert} planes hijos a insertar
     * @param {Map<Integer, Integer> mapChildToParent} relacion de padres con hijos
     */
    private static void dmlPlans(List<PlanComercial__c> plansToDelete, 
                                List<PlanComercial__c> existingPlansToUpsert, List<PlanComercial__c> parentPlansToInsert, 
                                List<PlanComercial__c> childPlansToInsert, Map<Integer, Integer> mapChildToParent)
    {
        // Planes a borrar
        if( !plansToDelete.isEmpty() ) {
            // Se solicita borrar planes comerciales descendientes
            GenerateComercialPlanHelper.deleteDescendantPlans(plansToDelete);

            delete plansToDelete;
        }

        // Planes existentes a modificar
        if( !existingPlansToUpsert.isEmpty() ) {
            upsert existingPlansToUpsert;

            // Se mira si hay que modificar algun descendiente de los planes modificados
            updateDescendantPlans(existingPlansToUpsert);
        }

        // Planes nuevos a crear
        if( !parentPlansToInsert.isEmpty() ) {
            // Se crea el plan principal
            insert parentPlansToInsert;

            // Para los planes hijos
            if( !childPlansToInsert.isEmpty() ) {
                // A cada plan hijo se le asigna el id de su padre
                for(Integer pos: mapChildToParent.keySet()) {
                    Integer newParentPos = mapChildToParent.get(pos);
                    Id parentId = parentPlansToInsert.get(newParentPos).Id;

                    childPlansToInsert.get(pos).ParentPlan__c = parentId;
                }
                // Se inserta el plan hijo
                insert childPlansToInsert;
            }
        }
    }

    /**
     * Comprueba si un plan se ha modificado y si es asi realiza los cambios y lo incluye en la lista de planes a
     * modificar
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {Plandata myplan} datos del plan
     * @param {List<PlanComercial__c> existingPlansToUpsert} planes a modificar
     */
    private static void addModifiedPlan(Plandata myplan, List<PlanComercial__c> existingPlansToUpsert)
    {
        // Si ha cambiado alguno de los campos del plan
        if( myplan.isTitleModified || myplan.isSegmentModified || myplan.isProductModified
            || myplan.isIndicatorModified || myplan.isZoneModified || myplan.isValueModified ) {
            
            PlanComercial__c parentPlan = new PlanComercial__c( Id= myplan.Id );

            if( myplan.isTitleModified ) {
                parentPlan.Name = myplan.Title;
                parentPlan.Description__c= parentPlan.Name;
            }
            if( myplan.isSegmentModified ) parentPlan.Segment__c = myplan.Segment;
            if( myplan.isProductModified ) parentPlan.Product__c = myplan.Product;
            if( myplan.isZoneModified ) parentPlan.Zone__c = myplan.Zone;
            if( myplan.isIndicatorModified ) parentPlan.Indicator__c = myplan.Indicator;
            if( myplan.isIndicatorModified || myplan.isValueModified ) {
                // En caso de cambio del tipo de indicador se debera "mover" el valor al campo correspondiente y
                // limpiar los otros
                parentPlan.TargetKPICurrency__c = null;
                parentPlan.TargetKPIPercent__c = null;
                parentPlan.TargetKPINumber__c = null;
                // Valor del Plan
                parentPlan.put(PlanComercialSelector.getTargetKPIFieldByType(myplan.IndicatorType), myplan.Value);
            }

            existingPlansToUpsert.add(parentPlan);
        }
    }

    /**
     * Añade todos los planes que corresponan en la lista de planes a borrar
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {List<Rowtype> rowsdata} datos del plan
     * @param {Integer cellPos} posicion de la celda
     * @param {List<PlanComercial__c> plansToDelete} planes a borrar
     * @param {Boolean isMyPlan} si es plan propio (RN)
     * @param {String planId} id de plan padre
     * @param {Integer maxRows} numero maximo de filas
     */
    private static void addPlansToDelete(List<Rowtype> rowsdata, Integer cellPos, List<PlanComercial__c> plansToDelete, 
        Boolean isMyPlan, String planId, Integer maxRows)
    {
        // Lista de ids a borrar
        Set<Id> idsToDelete = new Set<Id>();
        // Id del plan principal solo si es DT o es plan creado por RN
        if( isMyPlan ) idsToDelete.add(planId);
        // Ids de los planes de los RN/Mediadores
        Integer pos = ROWS_FROM_RN_INTERMEDIARY;
        for(Integer j=pos; j<maxRows; j++) {
            Celltype cell = rowsdata?.get(j)?.Cells[cellPos];
            if( cell?.Id != null ) idsToDelete.add(cell.Id);
        }
        
        // Se convierte la lista a planes comerciales
        if( !idsToDelete.isEmpty() ) {
            for(Id idtodelete: idsToDelete) {
                plansToDelete.add(new PlanComercial__c(Id= idtodelete));
            }
        }
    }

    /**
     * Crea un nuevo plan padre y lo mete en los planes padre a crear
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {Plandata myplan} datos del plan
     * @param {List<PlanComercial__c> parentPlansToInsert} planes padre a insertar
     * @param {Set<String> newPlanNames} lista con los nombre de los planes nuevos
     */
    private static void addNewPlan(Plandata myplan, List<PlanComercial__c> parentPlansToInsert, Set<String> newPlanNames)
    {
        PlanComercial__c parentPlan = new PlanComercial__c(
            Name= myplan.Title,
            Description__c= myplan.Title,
            Segment__c= myplan.Segment,
            Product__c= myplan.Product,
            Indicator__c= myplan.Indicator,
            Zone__c = myplan.Zone,
            StartDate__c= Date.newInstance(myplan.Year, 1, 1),
            EndDate__c= Date.newInstance(myplan.Year, 12, 31),
            ParentPlan__c= null,
            AssignedTo__c= myplan.AssignedToId,
            AccumulateType__c= PLAN_ACCUMULATE_TYPE,
            RecordTypeId= myplan.rtPlanAnualId,
            SendNotifications__c= PLAN_SEND_NOTIF
        );
        
        // Valor del Plan
        parentPlan.put(PlanComercialSelector.getTargetKPIFieldByType(myplan.IndicatorType), myplan.Value);

        parentPlansToInsert.add(parentPlan);

        // Si hay plan nuevo del DT se incluye en la lista para notificar
        if( myplan.isDirector ) {
            newPlanNames.add(myplan.Title);
        }
    }

    // Indices del mapa de listas de planes a crear, modificar y borrar
    private static final Integer IDX_PLANS_EXISTING = 0;
    private static final Integer IDX_PLANS_DELETE = 1;
    private static final Integer IDX_PLANS_CHILD = 2;
    private static final Integer IDX_PLANS_PARENT = 3;

    /**
     * Añade un plan hijo a crear, modificar o borrar (si valor 0)
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {Rowtype row} datos del plan
     * @param {Integer cellPos} posicion de la celda
     * @param {Map<Integer, List<PlanComercial__c>> mapPlanLists} mapa de listas de planes
     * @param {Map<Integer, Integer> mapChildToParent} mapa de relacion entre planes padres e hijos
     * @param {Plandata myplan} datos del plan padre
     * @param {Set<String> newPlanNames} lista con los nombre de los planes nuevos
     * @param {Set<Id> rnsToNotify} ids de rns a notificar por nuevo plan
     */
    private static void addChildPlans(Rowtype row, Integer cellPos, Map<Integer, List<PlanComercial__c>> mapPlanLists, 
                                Map<Integer, Integer> mapChildToParent,
                                Plandata myplan, Set<String> newPlanNames, Set<Id> rnsToNotify, List<PlanComercial__c> parentPlansToInsert)
    {
        PlanComercial__c childPlan;
        // Id de la fila
        String rowId = row.Id;

        // Valor decimal de la celda
        Decimal childValue = 0;
        Celltype cell = row.Cells[cellPos];
        childValue = cell.decimalValue;

        List<PlanComercial__c> existingPlansToUpsert = mapPlanLists.get(IDX_PLANS_EXISTING);
        List<PlanComercial__c> plansToDelete = mapPlanLists.get(IDX_PLANS_DELETE);
        List<PlanComercial__c> childPlansToInsert = mapPlanLists.get(IDX_PLANS_CHILD);
        

        if( myplan.isNewPlan || cell.isNew ) { //-------------------- Nuevo Plan o Nuevo subplan (rn/mediador)    
            if( childValue > 0) {
                childPlan = new PlanComercial__c(
                    Name= myplan.Title,
                    Description__c= myplan.Title,
                    Segment__c= myplan.Segment,
                    Product__c= myplan.Product,
                    Zone__c = myPlan.Zone,
                    Indicator__c= myplan.Indicator,
                    StartDate__c= Date.newInstance(myplan.Year, 1, 1),
                    EndDate__c= Date.newInstance(myplan.Year, 12, 31),
                    // ParentPlan__c= null,
                    ParentPlan__c= myplan.ParentId,
                    AccumulateType__c= PLAN_ACCUMULATE_TYPE,
                    RecordTypeId= myplan.rtPlanAnualId,
                    SendNotifications__c= PLAN_SEND_NOTIF
                );
                if( myplan.isDirector ) {
                    childPlan.AssignedTo__c= rowId;

                    // Se incluye el nombre del plan por si es una creacion individual
                    newPlanNames.add(childPlan.Name);
                    // Si hay plan nuevo del DT se incluyen los id de los RNs (filas) en la lista a notificar
                    rnsToNotify.add(rowId);
                } else {
                    childPlan.AssignedTo__c= myplan.AssignedToId;
                    childPlan.Intermediary__c= rowId;
                }
            
                childPlan.put(PlanComercialSelector.getTargetKPIFieldByType(myPlan.IndicatorType), childValue);

                // En caso de no existir plan comercial padre se crea uno nuevo. fix: 
                if( String.isBlank(childPlan.ParentPlan__c) )
                {
                    myplan.Id = null;
                    // addNewPlan(myplan, parentPlansToInsert, newPlanNames);
                    // Añadimos el plan hijo a la lista para crearlo
                    childPlansToInsert.add(childPlan);

                    Integer parentPos = parentPlansToInsert.size()-1;
                    Integer childPos = childPlansToInsert.size()-1;
                    // Y añadimos la referencia al padre
                    mapChildToParent.put(childPos, parentPos);
                } else {
                    childPlan.ParentPlan__c = myplan.ParentId;
                    existingPlansToUpsert.add(childPlan);
                }
            }
        } else if( childValue == 0 ) { //------------------------------------------- Subplan existente a 0
            childPlan = new PlanComercial__c(Id= cell.Id);
            plansToDelete.add(childPlan);
        } else { //----------------------------------------------------------------- Subplan existente
            myplan.Id = cell.Id;
            myplan.isValueModified = cell.isModified;
            myplan.Value = childValue;
            addModifiedPlan(myplan, existingPlansToUpsert);
        }
    }

    /**
     * Convierte la tabla que viene del LWC en modificaciones sobre el objeto PlanComercial__c
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Tabletype tabledata} la tabla
     */
    private static void tableToPlan(Tabletype tabledata, String userId, String roleType)
    {
        System.debug('Table to plan ' + tableData.toJSON());
        Boolean isDirector = Directors.contains(roleType);

        // Fila de cabecera
        Rowtype headerdata = tabledata.headers;
        // Resto de filas
        List<Rowtype> rowsdata = tabledata.rows;        

        // Numero de planes (columnas de la tabla)
        Integer numColumns = headerdata.Cells.size();
        // Numero de filas
        Integer maxRows = rowsdata.size();

        // Lista de planes padre a crear
        List<PlanComercial__c> parentPlansToInsert = new List<PlanComercial__c>();
        // Lista de planes hijos a crear
        List<PlanComercial__c> childPlansToInsert = new List<PlanComercial__c>();
        // Relacion entre los planes padre y los hijos
        Map<Integer, Integer> mapChildToParent = new Map<Integer, Integer>();
        
        // Lista de planes existentes a modificar
        List<PlanComercial__c> existingPlansToUpsert = new List<PlanComercial__c>();
        // Lista de planes existentes a borrar
        List<PlanComercial__c> plansToDelete = new List<PlanComercial__c>();

        Map<Integer, List<PlanComercial__c>> mapPlanLists = new Map<Integer, List<PlanComercial__c>>();
        mapPlanLists.put(IDX_PLANS_EXISTING, existingPlansToUpsert);
        mapPlanLists.put(IDX_PLANS_DELETE, plansToDelete);
        mapPlanLists.put(IDX_PLANS_CHILD, childPlansToInsert);
        mapPlanLists.put(IDX_PLANS_PARENT, parentPlansToInsert);

        // Referencia al plan padre
        // Celltype cellHeaderParent = headerdata.Cells[0];
        // String parentPlan = cellHeaderParent.Id;
        // Referencia al plan hijo
        PlanComercial__c childPlan;

        // Guardara la lista de RNs a notificar si hay nuevos planes del DT
        Set<Id> rnsToNotify = new Set<Id>();
        // Guardara la lista de Planes nuevos a notificar si los ha creado el DT
        Set<String> newPlanNames = new Set<String>();

        Id rtPlanAnualId = (new PlanComercialSelector()).rtPlanAnualId;

        List<String> ejesPlanesExistentes = new List<String>();
        
        // Por cada plan (columna de la tabla)...
        for(Integer i=0; i<numColumns; i++) {
            // Cabecera del plan
            Celltype cellHeader = headerdata.Cells[i];

            String parentPlan = cellHeader.Id;
            childPlan = null;

            // Si es nuevo
            Boolean isNewPlan = cellHeader.isNew;
            // Si es borrado
            Boolean isDeleted = cellHeader.isDeleted;
            // Nombre del plan
            String planName = cellHeader.stringValue;
            // Id del plan
            String planId = cellHeader.Id;
            // Es mi plan
            Boolean isMyPlan = false;
            // Intentamos recuperar el valor, si existe, de las propiedades extra, si existen, de la celda de cabecera
            if( String.isNotBlank(cellHeader?.mapExtraProperties?.get(CELL_PROPERTY_IS_MY_PLAN)) ) {
                isMyPlan = Boolean.valueOf(cellHeader.mapExtraProperties.get(CELL_PROPERTY_IS_MY_PLAN));
            }

            Boolean isHeaderModified = cellHeader.isModified;

            String segment = rowsdata.get(0).Cells.get(i).stringValue;
            String product = rowsdata.get(1).Cells.get(i).stringValue;
            String indicator = rowsdata.get(2).Cells.get(i).stringValue;
            String zone = rowsdata.get(3).Cells.get(i).stringValue;            

            // planes existentes
            if (!isNewPlan && !isDeleted) {
                String planKeys = indicator + '-' + segment + '-' + product + '-' + zone;
                ejesPlanesExistentes.add(planKeys);
            }

            if( !isDeleted ) { //---------------------------------------------- Nuevo o Modificacion
                // Datos FIJOS del plan
                // coge tambien los ejes (indicador, segmento, ...) de arriba
                Integer anyo = Integer.valueOf(rowsdata.get(4).Cells.get(i).decimalValue);
                Decimal definedDT = rowsdata.get(5).Cells.get(i).decimalValue;

                PlanComercialSelector.eIndicator indicatorType = PlanComercialSelector.getIndicatorType(indicator);

                Plandata myplan = new Plandata(
                    planId, planName, segment, product, indicator, zone, anyo, definedDT, null, userId, null
                );
                myplan.indicatorType = indicatorType;
                myplan.isDirector = isDirector;
                myplan.rtPlanAnualId = rtPlanAnualId;
                myplan.isNewPlan = isNewPlan;
                myplan.isTitleModified = isHeaderModified;
                myplan.ParentId = parentPlan;

                // Segmento => Fila 0
                Celltype cell = rowsdata.get(0).Cells.get(i);
                myplan.isSegmentModified = cell.isModified;
                // Producto => Fila 1
                cell = rowsdata.get(1).Cells.get(i);
                myplan.isProductModified = cell.isModified;
                // Indicador => Fila 2
                cell = rowsdata.get(2).Cells.get(i);
                myplan.isIndicatorModified = cell.isModified; 
                // Zona => Fila 3
                cell = rowsdata.get(3).Cells.get(i);
                myplan.isZoneModified = cell.isModified;
                // Año => Fila 4
                cell = rowsdata.get(4).Cells.get(i);
                // myplan.isYearModified = cell.isModified;
                // Plan (Definido DT) => Fila 5
                cell = rowsdata.get(5).Cells.get(i);
                myplan.isValueModified = cell.isModified;

                if( isNewPlan ) { //-------------------------------------- Nuevo Plan principal
                    addNewPlan(myplan, parentPlansToInsert, newPlanNames);
                } else { //----------------------------------------------- Plan existente
                    addModifiedPlan(myplan, existingPlansToUpsert);
                }

                // Datos por RN / Mediador => Fila 6 en adelante
                Integer pos = ROWS_FROM_RN_INTERMEDIARY;
                for(Integer j=pos; j<maxRows; j++) {
                    // Fila de RN/Mediador
                    Rowtype row = rowsdata.get(j);

                    addChildPlans(row, i, mapPlanLists, mapChildToParent, myplan, newPlanNames, rnsToNotify, parentPlansToInsert);
                }
            } else if( planId != null ) { //-------------------------------------------------------- Borrado del plan (Si hay ids de planes)                
                addPlansToDelete(rowsdata, i, plansToDelete, isMyPlan, planId, maxRows);
            }
        }

        // validaciones planes nuevos
        validateNewPlans(ejesPlanesExistentes, parentPlansToInsert);
        // Realizamos todas las modificaciones sobre los planes que corresponda    
        dmlPlans(plansToDelete, existingPlansToUpsert, parentPlansToInsert, childPlansToInsert, mapChildToParent);        

        // Si se han relleando los destinatarios y los nombres del plan correctamente se envia las notificaciones
        sendNotification(rnsToNotify, newPlanNames);
    }


    /**
     * compara los planes a insertar con los planes recibidos de la vista al pulsar guardar, excepto planes a borrar que no se tienen en cuenta para ver duplicados
     * 
     * @author nts (dmunoz)
     * @date 14/11/2022
     * 
     * @param {List<String> ejesPlanesExistentes} año
     * @param {List<PlanComercial__c> parentPlansToInsert} planes principales a insertar
     * @return void
     */
    private static void validateNewPlans(List<String> ejesPlanesExistentes, List<PlanComercial__c> parentPlansToInsert) {

        String planKey = '';
        String result = '';
        for (PlanComercial__c pc: parentPlansToInsert) {
            planKey = pc.indicator__c + '-' + pc.Segment__c + '-' + pc.Product__c + '-' + pc.Zone__c;
            if (ejesPlanesExistentes.contains(planKey)) {
                result += ' ' + pc.Name;
            }
        }
        if (String.isNotEmpty(result)) {
            String exceptionMessage = 'No se puede guardar' + result + ' porque ya existe algún plan con esa información.';
            throw new HandledException(exceptionMessage); // uso esta excepcion generica para poder mostrar el mensaje, en el save se lanza aurahandledexception
        }
    }

    /**
     * Recupera los objetos PlanComercial__c de tipo anual para un año y usuario dado
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Integer actualYear} año
     * @param {Id userId} id de usuario
     * @param {Boolean isDirector} si el usuario es DT (true) o no (false)
     * @return {List<Plandata>} lista de planes en formato Plandata
     */
    private static List<Plandata> getPlans(Integer actualYear, Id userId, Boolean isDirector)
    {
        List<Plandata> plansData = new List<Plandata>();

        // Recuperamos los planes padre del usuario (Director / RN) y sus planes hijos relacionados
        PlanComercialSelector planSel = new PlanComercialSelector();
        List<PlanComercial__c> parentPlans = planSel.findAnualPlansByAssignedUserAndYear(userId, actualYear);

        if( parentPlans != null && !parentPlans.isEmpty() ) {    
            // Para cada plan crearemos un Plandata
            for( PlanComercial__c parentPlan: parentPlans ) {
                // Recogemos el valor del target KPI
                Decimal value = getComercialPlanValue(parentPlan);

                // Creamos el padre
                Plandata plandata = new Plandata(
                    parentPlan.Id,
                    parentPlan.Name, 
                    parentPlan.Segment__c,
                    parentPlan.Product__c,
                    parentPlan.Indicator__c,
                    parentPlan.Zone__c,
                    actualYear,
                    value,
                    parentPlan.Actual_KPI__c,
                    parentPlan.AssignedTo__c,
                    parentPlan.OwnerId
                );

                // Si tiene hijos los añadimos
                for(PlanComercial__c childPlan: parentPlan.ParentPlans__r) {     
                    // Para el director los hijos son los RN           
                    Id detailId = childPlan.AssignedTo__c;
                    String detailName = childPlan.AssignedTo__r.Name;
                    // Para el RN los hijos son los mediadores
                    if( !isDirector ) {
                        detailId = childPlan.Intermediary__c;
                        detailName = childPlan.Intermediary__r.Name;
                    }

                    Decimal childValue = getComercialPlanValue(childPlan);

                    // Le asignamos los datos de los RN / Mediadores
                    Subplandata subplan = new Subplandata(
                        childPlan.Id, 
                        detailName, 
                        childValue,
                        childPlan.Actual_KPI__c
                    );

                    // Añadimos el hijo
                    plandata.addSubplan(subplan, detailId);
                }
                
                // Lo añadimos a la lista de planes
                plansData.add(plandata);
            }
        }

        return plansData;
    }

    
    /**
     * Comprobamos si se han modificado y si es asi asignamos los campos comunes del plan padre al hijo
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {PlanComercial__c} el plan
     */
    private static void planUpdatedFields(PlanComercial__c plan)
    {
        // Ponemos a modificar el campo que haya modificado del padre
        if( plan.Name != plan.ParentPlan__r.Name ) {
            plan.Name = plan.ParentPlan__r.Name;
            plan.Description__c= plan.ParentPlan__r.Name;
        }
        if( plan.Product__c != plan.ParentPlan__r.Product__c ) plan.Product__c = plan.ParentPlan__r.Product__c;
        if( plan.Segment__c != plan.ParentPlan__r.Segment__c ) plan.Segment__c = plan.ParentPlan__r.Segment__c;
        if( plan.Indicator__c != plan.ParentPlan__r.Indicator__c ) {
            plan.Indicator__c = plan.ParentPlan__r.Indicator__c;

            // Comprobamos los campos de valor
            PlanComercialSelector.eIndicator indicatorTypeNew = PlanComercialSelector.getIndicatorType(plan.ParentPlan__r.Indicator__c);

            // Recuperamos el valor actual
            Decimal value = getComercialPlanValue(plan);

            // Limpiamos los campos
            plan.TargetKPINumber__c = null;
            plan.TargetKPICurrency__c = null;
            plan.TargetKPIPercent__c = null;

            // Establecemos el valor nuevo
            plan.put(PlanComercialSelector.getTargetKPIFieldByType(indicatorTypeNew), value);
        }
    }

    /**
     * Modifica los planes descendientes de los planes dados para los campos comunes
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {List<PlanComercial__c} los planes modificados
     */
    private static void updateDescendantPlans(List<PlanComercial__c> plans)
    {
        // Se recupera la lista de planes descendientes de los planes modificados
        List<PlanComercial__c> childPlans = (new PlanComercialSelector()).findAnnualPlanDescendants(plans);
        
        if( childPlans != null && !childPlans.isEmpty() ) {
            // Para cada plan se comprueba si se han modificado los campos comunes
            for(PlanComercial__c plan: childPlans) {
                planUpdatedFields(plan);
            }

            update childPlans;
        }
    }
    
    /**
     * Recupera los valores activos de un campo de objeto dado
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Schema.SObjectField field} campo
     * @return {Map<String, String>} valores de la picklist
     */
    private static Map<String, String> getPicklistValues(Schema.sObjectField field)
    {
        // Get all picklist values
        List<Schema.PicklistEntry> entries = field.getDescribe().getPickListValues();
        // Only return active picklist values
        Map<String, String> mapValues = new Map<String, String>();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                mapValues.put(entry.value, entry.label);
            }
        }

        return mapValues;
    }

    /**
     * Comprueba si una entrada de picklist es valida y tiene valores de control. Si es asi los añade a los valores
     * de dependencia
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {Schema.PicklistEntry entry} entrada de picklist
     * @param {String base64map} mapa de caracteres base 64
     * @param {String validForValue} valores validos
     * @param {List<Schema.PicklistEntry> controlEntries} entradas de control de picklist
     * @param {Map<String, Map<String, String>> dependentPicklistValues} mapa de valores de dependencia
     */
    private static void addValidEntries(Schema.PicklistEntry entry, String base64map, String validForValue,
                                        List<Schema.PicklistEntry> controlEntries,
                                        Map<String, Map<String, String>> dependentPicklistValues)
    {
        // Cogemos las posiciones del campo controlador de la entrada dependiente
        List<String> base64chars = validForValue.split('');
                
        // Vemos a que posicion del campo controlador pertenece ese 
        for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
            Object controlValue =
                    (controlEntries == null ?   
                        (Object) (index == 1) :   
                        (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                    );
            Integer bitIndex = index / 6;
            if (bitIndex > base64chars.size() - 1) break;

            Integer bitShift = 5 - Math.mod(index, 6);
            if( controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0 )
                continue;

            // Add de values
            Map<String, String> mapValues = dependentPicklistValues.get((String) controlValue);
            if( mapValues == null ) {
                mapValues = new Map<String, String>();
                dependentPicklistValues.put((String) controlValue, mapValues);
            }
            mapValues.put(entry.getValue(), entry.getLabel());
        }
    }

    /**
     * Recupera los valores activos de un campo picklist, junto con sus dependencias
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Schema.SObjectField field} campo
     * @return {Map<String, List<String>>} valores de la picklist
     */
    private static Map<String, Map<String, String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Map<String, Map<String, String>> dependentPicklistValues = new Map<String, Map<String, String>>();

        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();

        if (controlToken == null) return dependentPicklistValues;

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
    
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            // validFor es una propiedad de PicklistEntry pero no esta accesible
            String validForValue = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor'));
            
            if (entry.isActive() && String.isNotEmpty(validForValue)) {
                addValidEntries(entry, base64map, validForValue, controlEntries, dependentPicklistValues);
            }
        }
        
        return dependentPicklistValues;
    }

    /**
     * Recupera el developername que le corresponde al id de rol dado 
     * 
     * @author nts (agonzalezisasi)
     * @date 01/10/2021
     * 
     * @param {Id rolId} id del rol
     * @return {String} el developername del rol
     */
    private static String getUserRolDevName(Id rolId)
    {
        String roleName = '';

        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole WHERE Id = :rolId];
        if( !roles.isEmpty() ) roleName = roles[0].Developername;

        return roleName;
    }
    
    /**
     * Metodo que envia la siguiente notificacion a todos los usuarios (RN) que se les ha creado un plan comercial anual
     * 
     * @param {Set<Id> userIds} Lista de usuario receptores de la notificacion
     * @param {Set<String> planSubjects} lista de asuntos de planes a incluir en el mensaje de la notificacion
     */
    public static void sendNotification(Set<Id> userIds, Set<String> planSubjects)
    {
        if( userIds != null && !userIds.isEmpty() && planSubjects != null && !planSubjects.isEmpty() ) {
            String title = Label.SDM_PlanAnual_NotifTitle;
            String bodyContent = Label.SDM_PlanAnual_NotifBody + ' ' + String.join(new List<String>(planSubjects), ',');

            Notification notif = new Notification(Notification.notificationType.SDMAlert);
            // Permite abrir la ventana de gestion de planes anuales
            notif.addPageReference('standard__navItemPage', 'GenerarPlan');
            // Convertimos la lista de ids de usuario a string
            Set<String> stringSet = new Set<String>( (List<String>)new List<Id>( userIds ) );
            notif.send(stringSet, title, bodyContent);
        }
    }

    /**
     * Recupera los usuarios (RN/CV) asociados al usuario DZ/DV
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {String roleName} rol del usuario
     * @param {String userEmail} email del usuario
     * @return {Map<String, String>} detalle de los usuarios
     */
    private static Map<String, Map<String, String>> getDirectorDetail(String roleName, String userEmail)
    {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> mapDetail = new Map<String, String>();
        Map<String, String> mapRNsZone = new Map<String, String>();

        // Recuperamos el campo del director en el mediador para el role de Salesforce del usuario
        String directorEmailField = mapEmailFieldsByUserRole.get(roleName);
        // Recuperamos el rol ATM del Consultor o RN que buscaremos en los equipos de cuentas de los mediadores del
        // director
        String consultantRole = mapATMRoleByUserRole.get(roleName);
        String consultantRoleLabel = (new SettingsSDM()).getATMRoleLabel(consultantRole);

        if( String.isNotBlank(directorEmailField) && String.isNotBlank(consultantRoleLabel) ) {
            // Lista de consultores o RNs del director
            List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findUsersByRoleAndEmailField(
                consultantRoleLabel,
                directorEmailField,
                userEmail
            );

            if( atms != null && !atms.isEmpty() ) {
                // Los metemos en el mapa de detalle
                for(AccountTeamMember atm: atms) {
                    mapDetail.put(atm.UserId, atm.User.Name);
                    if (String.isNotEmpty(atm.Account.Zone__c)) {
                        mapRNsZone.put(atm.Account.Zone__c, atm.Account.Zone__c); // mapa con las zonas como clave y valor para la picklist dinámica 
                    }
                    
                }
                // añado los dos map calculados al map resultado
                result.put('RNNameMap', mapDetail);
                result.put('RNZoneMap', mapRNsZone);
            }
        }

        return result;
    }

    
    /**
     * Recupera los mediadores asociados al usuario RN/Consultor vida
     * 
     * @author nts (agonzalezisasi)
     * @date 16/12/2021
     * 
     * @param {String roleName} rol del usuario
     * @param {String userEmail} email del usuario
     * @return {Map<String, String>} detalle de los mediadores
     */
    private static Map<String, Map<String, String>> getConsultantDetail(String roleName, String userEmail)
    {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> mapDetail = new Map<String, String>();
        Map<String, String> mapIntermediaryZone = new Map<String, String>();

        // Recuperamos el campo del Consultor o RN en el mediador para el role de Salesforce del usuario
        String consultantEmailField = mapEmailFieldsByUserRole.get(roleName);

        if( String.isNotBlank(consultantEmailField) ) {
            // Lista de mediadores del Consultor o RN
            List<Account> intermediaries = (new AccountsSelector()).findIntermediariesByEmailInFields(
                userEmail,
                new Set<String> {consultantEmailField}
            );

            if( intermediaries != null && !intermediaries.isEmpty() ) {
                // Los metemos en el mapa de detalle
                for(Account intermediary: intermediaries) {
                    String colName = String.isBlank(intermediary.IntermediaryDescription__c) ? intermediary.Name : intermediary.IntermediaryDescription__c;
                    mapDetail.put(intermediary.Id, colName);
                    if (String.isNotEmpty(intermediary.Zone__c)) {
                        mapIntermediaryZone.put(intermediary.Id, intermediary.Zone__c);
                    }                    
                }

                // añado los dos map calculados al map resultado
                result.put('IntermediaryNameMap', mapDetail);
                result.put('IntermediaryZoneMap', mapIntermediaryZone);
            }
        }

        return result;
    }


    /**
     * Compara la zona del intermediario con la zona del plan para activar o desactivar la posibilidad de que un RN pueda bajar a sus mediadores los planes si la zona no coincide
     * 
     * @author nts (dmunoz)
     * @date 26/10/2022
     * 
     * @param {Integer plan} plan comercial
     * @param {Integer intermediaryId} id mediador
     * @param {Integer isDirector} año
     * @param {Integer mapZone} mapa que relaciona cada intermediario con su zona
     * @return {Boolean} resultado comparación
     */
    private static Boolean isLockedIntermediary(Plandata plan, Id intermediaryId, Boolean isDirector, Map<String, String> mapZone) { 
        Boolean result = false;

        if (!isDirector && !ZONE_ALL_VALUE.equals(plan.Zone)) {
            result = !plan.Zone.equals(mapZone.get(intermediaryId));  // si no coincide se bloquea la celda
        }

        return result;
    }


    /**
     * Dado un map con las zonas obtenidas de los registros AccountTeamMember de los Directores o RNs obtengo sus zonas para generar de forma dinámica los valores posibles en el picklist zona de la vista
     * 
     * @author nts (dmunoz)
     * @date 26/10/2022
     * 
     * @param {Integer year} año
     * @return {Boolean} resultado comparación
     */
    private static Combotype getDynamicZoneCombo(Map<String, String> mapZones) {

        Combotype combo;
        Set<String> setZone = new Set<String>();

        if (!mapZones.isEmpty()) { // si no esta vacio el map de zonas
            List<String> listZone = mapZones.values();
            listZone.sort(); // ordeno los valores
            
            setZone.addAll(listZone); // convierto a Set para eliminar duplicados
        }
        
        setZone.add(ZONE_ALL_VALUE); // añado el valor Todos a la picklist
        Map<String, String> mapOpcionesZona = new Map<String, String>();
        for (String zone: setZone) {
            mapOpcionesZona.put(zone, zone);
        }
        
        // preparo el objeto combo para cargarlo en el json que se envía a la tabla
        List<Optiontype> optionsZone = mapToOptions(mapOpcionesZona);
        combo = new Combotype(COMBOBOX_ZONE_PLACEHOLDER, optionsZone);

        return combo;
    }

    // ---------------------------------- AURA ENABLED ------------------------

    /**
     * Recupera los datos de los planes del usuario actual para un año dado
     * Devuelve el resultado en formato JSON
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {Integer year} año
     * @return {String} json con los datos
     */
    @AuraEnabled
    public static String getRecords(Integer year)
    {
        try {
            // Para la cobertura del test cuando se produce una excepcion
            if( Test.isRunningTest() && testException != null ) {
                throw new GenerateComercialPlanControllerException(testException);
            }

            // 1. Obtenemos la info del usuario actual
            String userEmail = UserInfo.getUserEmail();
            Id userId = UserInfo.getUserId();
            Id rolId = UserInfo.getUserRoleId();

            // 2. Obtenemos los datos del rol
            String roleName = getUserRolDevName(rolId);

            Boolean isDirector = Directors.contains(roleName);
            Boolean isRN = Consultants.contains(roleName);

            // 3. Obtenemos los RNs del director / los Mediadores del RN            
            Map<String, String> mapDetail;
            Map<String, String> mapZone;
            
            if( isDirector ) { //--------------------------------------------- RNs del director 
                Map<String, Map<String, String>> mapDetailDirector;                
                mapDetailDirector = getDirectorDetail(roleName, userEmail);   
                mapDetail = mapDetailDirector.get('RNNameMap'); 
                mapZone = mapDetailDirector.get('RNZoneMap');            
            } else { //------------------------------------------------------- Mediadores del RN
                Map<String, Map<String, String>> mapDetailConsultant;
                mapDetailConsultant = getConsultantDetail(roleName, userEmail);
                mapDetail = mapDetailConsultant.get('IntermediaryNameMap');
                mapZone = mapDetailConsultant.get('IntermediaryZoneMap');
            }

            // 4. Establecemos el año de ejecucion
            Integer actualYear = year;

            //---------------------------------------------------------- Planes anuales
            // 5. Obtenemos los planes comerciales anuales existentes para el Director / RN
            List<Plandata> plansData = getPlans(actualYear, userId, isDirector);

            //---------------------------------------------------------- Generacion de la tabla
            // 6. A partir de todos los datos anteriores generamos la tabla para el lwc
            Tabletype tabledata = new Tabletype();

            // Editable por defecto
            tabledata.isEdited = true;
            // Si es director puede crear planes, sino no.
            tabledata.canCreate = isDirector || isRN;
            tabledata.canSave = isDirector || isRN;

            // 6.1 Añadimos los etiquetas de las filas
            // Etiquetas fijas de las filas
            tabledata.addFixedRow(ROW_LABEL_SEGMENT);
            tabledata.addFixedRow(ROW_LABEL_PRODUCT);
            tabledata.addFixedRow(ROW_LABEL_INDICATOR);
            tabledata.addFixedRow(ROW_LABEL_ZONE);
            tabledata.addFixedRow(ROW_LABEL_YEAR);
            tabledata.addFixedRow(ROW_LABEL_PLAN);    
            
            // añado la información de zonas de intermediario si no es director
            if (!isDirector) {
                tabledata.mapIntermediaryZones = mapZone;
            }
            

            if( mapDetail != null ) {
                // Etiquetas variables (rn/mediador) de las filas
                for(String key: mapDetail.keySet()) {
                    tabledata.addFixedRow(key, mapDetail.get(key));
                }
            }

            // 6.2 Valores de combobox
            // Segmento
            Map<String, String> segmentValues = getPicklistValues(PlanComercial__c.Segment__c);
            tabledata.addOptions(COMBOBOX_SEGMENT, COMBOBOX_SEGMENT_PLACEHOLDER, segmentValues);
            // Producto, es dependiente del segmento
            // Se recuperan las dependencias y se añaden a la tabla de forma global para que esten accesibles por javascript
            Map<String, Map<String, String>> mapDependantProduct = getDependentPicklistValues(PlanComercial__c.Product__c);
            tabledata.addDependant(COMBOBOX_SEGMENT, COMBOBOX_PRODUCT, mapDependantProduct);
            // Map<String, String> productValues = getPicklistValues(PlanComercial__c.Product__c);
            // tabledata.addOptions(COMBOBOX_PRODUCT, COMBOBOX_PRODUCT_PLACEHOLDER, productValues);
            // Indicador
            Map<String, String> indicatorValues = getPicklistValues(PlanComercial__c.Indicator__c);        
            tabledata.addOptions(COMBOBOX_INDICATOR, COMBOBOX_INDICATOR_PLACEHOLDER, indicatorValues);           
            
            // 6.3 Añadimos un plan vacio para el boton de nuevos planes
            // header = titulo
            // row 0 = segmento, row 1 = producto, row 2 = indicador, row 3= año, row 4= sumatorio
            Plandata newPlandata = new Plandata(
                null, NEW_DEFAULT_TEXT_PLAN, 
                NEW_DEFAULT_SEGMENT, NEW_DEFAULT_PRODUCT, NEW_DEFAULT_INDICATOR, NEW_DEFAULT_ZONE, 
                actualYear, 0, null, userId, userId
            );
            planToTable(tabledata, newPlandata, roleName, true, mapZone);
        
            // 6.4 Añadimos los planes comerciales existentes
            for(Plandata planData: plansData) {
                planToTable(tabledata, planData, roleName, false, mapZone);
            }

            // 7. Devolvemos el resultado en formato string
            System.debug('Result tableData ' + tabledata.toJSON());
            return tabledata.toJSON();
        } catch(Exception ex) {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException(ex.getMessage());
        }
    }

     /**
     * Guarda los cambios realizados por el usuario en los planes
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {String tabledata} datos de los planes en formato tabla
     */
    @AuraEnabled
    public static void saveData(String tabledata)
    {
        try {
            // Para la cobertura del test cuando se produce una excepcion
            if( Test.isRunningTest() && testException != null ) {
                throw new GenerateComercialPlanControllerException(testException);
            }
            
            // Convierte los datos json en objeto Tabletype
            Tabletype toTabledata = (Tabletype)JSON.deserialize(tabledata, Tabletype.class);

            String userId = UserInfo.getUserId();
            String rolId = UserInfo.getUserRoleId();
            String rolName = getUserRolDevName(rolId);

            // Realiza las modificaciones sobre los planes
            tableToPlan(toTabledata, userId, rolName);
        } catch(Exception ex) {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class GenerateComercialPlanControllerException extends Exception {}
}