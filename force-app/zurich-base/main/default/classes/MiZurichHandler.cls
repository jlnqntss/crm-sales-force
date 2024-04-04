/**
 * @description       : Clase handler de MI_ZURICH
 *                      Procesa las external request cuyo origen sea MI_ZURICH con la ayuda de la clase Transformer
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 08-16-2023
 * @last modified by  : aberuete
**/
public class MiZurichHandler implements ISystem 
{
    public static final String HANDLER_ORIGIN = 'MI_ZURICH';
    
    //Valores Caso
    public static final String FORM_INC = 'FORM_INC';
    public static final String SOBJECT_CASE = 'Case';
    private static final String ORIGIN_WEB = 'Web';
    private static final String SOURCE_AREA_GENERIC_END_CUSTOMER = 'Generic end customer';
    private static final String STATUS_ASIGNADO = 'Asignado';
    private static final String CALL_CENTER_CC_SERVICE = 'CC Service';
    private static final String SUBJECT_HELP_REQUEST = 'Solicitud de ayuda al registro de MiZurich';
    //Cola para asignar como owner del caso para la entidad FORM_INC
    private static List<Group> queueEmailSoporte;

    /**
     * Obtiene la información necesaria para poder procesar las external request pendientes
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Transformer miZurichTransformer : Instancia de la clase que tranforma un origen de datos en objetos Salesforce
     * @param externalRequestList : Lista de external request que deben ser procesadas
     */
    public static void prepare(Transformer miZurichTransformer, List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.prepareExternalRequestToProcess(miZurichTransformer, HANDLER_ORIGIN);

        //Obtener id de la cola para el owner del caso
        queueEmailSoporte = new GroupSelector().findByName('Email_CCS_Soporte');
    }

     /**
     * Realiza las transformaciones necesarias para procesar las external request recibidas y convertirlas en objetos de Salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     * @param externalRequestList : Lista de external request que deben ser procesadas
     */
    public static void process(List<ExternalRequest__c> externalRequestList)
    {
        // 1 - Recorrer todas las external request recibidas
        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            try
            {
                // 1.1 - Comprobar si el contenido de la solicitud está en formato JSON
                if (externalRequest.ContentFormat__c == 'JSON' && String.isNotBlank(externalRequest.Payload__c))
                {
                    // 1.1.1 - Realizar las transformaciones necesarias en base a la entidad 
                    processExternalRequestByEntity(externalRequest);
                }
                else
                {
                    // 1.1.2 - El formato recibido no está soportado
                    ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha recibido información correcta del registro en MiZurich', false);
                }
            }
            catch (Exception e)
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', e.getMessage() + '\n' + e.getStackTraceString(), false);
            }
        }
    }

    /**
     * Realiza las operaciones DML sobre la BBDD y actualiza la información de las external request procesadas
     **
     * @author aberuete
     * @date 15/05/2023
     * @param externalRequestList : Lista de external request que deben ser procesadas
     */
    public static void persists(List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.persistExternalRequest ('MiZurichHandler');
    }

    /**
     * Actualiza las external request procesadas con el resultado obtenido en las operaciones DML
     **
     * @author aberuete
     * @date 15/05/2023
     * @param jobId Id del job que se está ejecutando
     * @param externalRequestList : Lista de external request que deben ser procesadas
     */
    public static void manageResult(Id jobId, List<ExternalRequest__c> externalRequestList)
    {
        ExternalRequestHandlerUtil.manageResultExternalRequest (jobId, externalRequestList, 'MiZurichHandler');  
    }

    /**
     * Convertir JSON a registro de Salesforce en base a la entidad recibida
     **
     * @author aberuete
     * @date 15/05/2023
     * @param externalRequest : External request que debe ser procesada
     */
    private static void processExternalRequestByEntity(ExternalRequest__c externalRequest)
    {
        // 1 - Transformar el contenido del JSON a una estructura Map
        Map<String, Object> recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(externalRequest.Payload__c);

        // 2 - Convertir a mayúsculas todas las claves del mapa de campos de MiZurich
        for ( String field : recordValuesMap.keySet() )
        {
            recordValuesMap.put(field.toUpperCase(), recordValuesMap.get(field));
        }

         // 3 - Realizar las transformaciones necesarias en base a la entidad de MiZurich
         switch on externalRequest.Entity__c.toUpperCase()
         {
            when 'FORM_INC'
            {
                processFormToCase (recordValuesMap, externalRequest);
            }
            when else
            {
                ExternalRequestHandlerUtil.setExternalRequest(externalRequest, true, 'KO', 'No se ha encontrado la entidad indicada', false);
            }
         }
    }

    /**
     * Procesar la entidad FORM_INC al objeto caso de salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param ExternalRequest__c externalRequest : External request que debe ser procesada
     */
    @testvisible
    private static void processFormToCase (Map<String, Object> recordValuesMap, ExternalRequest__c externalRequest)
    {
        Case caseRecord = (Case) ExternalRequestHandlerUtil.tf.transform(FORM_INC, SOBJECT_CASE, recordValuesMap);
        caseRecord.RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY;
        caseRecord.Origin = ORIGIN_WEB;
        caseRecord.SourceArea__c = SOURCE_AREA_GENERIC_END_CUSTOMER;
        caseRecord.Status = STATUS_ASIGNADO;
        caseRecord.CallCenter__c = CALL_CENTER_CC_SERVICE;
        caseRecord.Subject = SUBJECT_HELP_REQUEST; 
        caseRecord.Description = getDescription (recordValuesMap);
        
        if (!queueEmailSoporte.isEmpty())
        {
            caseRecord.OwnerId = queueEmailSoporte[0].Id;
        }

        // Obtener tipificaciones del metadata Robot Hegeo
        caseRecord = ExternalRequestHandlerUtil.fillTypificationIntoCase (recordValuesMap, 'miZurich_inputForm2', 'miZurich_inputForm3', caseRecord);
        
        ExternalRequestHandlerUtil.addRecordToMap(externalRequest, FORM_INC, SOBJECT_CASE, caseRecord);
    }
    
    /**
     * Método que obtiene la descripción del caso
     * @author aberuete
     * @date 22/05/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     */
    @testvisible
    private static String getDescription (Map<String, Object> recordValuesMap)
    {
        String descriptionForCase;
        List<String> fieldsDescription = new List<String> {'miZurich_name', 'miZurich_nif', 'miZurich_email', 'miZurich_telf', 'miZurich_description'};
        
        for (Integer i = 0; i<fieldsDescription.size();i++ ) 
        {
            descriptionForCase = getTextDescriptionToCase (recordValuesMap, i, descriptionForCase, fieldsDescription);

            //Salto de línea
            descriptionForCase = descriptionForCase + '\n';
        }

        return descriptionForCase;
    }

    /**
     * Método que obtiene la descripción del caso
     * @author aberuete
     * @date 9/06/2023
     * @param Map<String, Object> recordValuesMap: Mapa que contiene el contenido del json de las external request
     * @param Integer i : Contador para saber que texto hay que poner
     * @param String descriptionForCase: Campo descripción del caso
     * List<String> fieldsDescription : Listado de los campos del json de las external request para añadir a la descripcion del caso
     */
    private static String getTextDescriptionToCase (Map<String, Object> recordValuesMap, Integer i, String descriptionForCase,List<String> fieldsDescription)
    {
        List<String> textInDescription = new List<String> {'Nombre: ', 'DNI: ', 'Correo electrónico: ', 'Teléfono: ', 'INFORMACIÓN ADICIONAL: '};

        if (i == 0)
        {
            descriptionForCase = textInDescription[i];

            if (recordValuesMap.containsKey(fieldsDescription[i]))
            {
                descriptionForCase = descriptionForCase + recordValuesMap.get(fieldsDescription[i]) + ' '; 
            }

            if (recordValuesMap.containsKey('miZurich_lastName'))
            {
                descriptionForCase = descriptionForCase + recordValuesMap.get('miZurich_lastName') ; 
            }
        }
        else if (i == 4)
        {
            if (recordValuesMap.containsKey(fieldsDescription[i]) && !String.isBlank((String) recordValuesMap.get(fieldsDescription[i])) )
            {
                descriptionForCase = descriptionForCase + textInDescription[i] + recordValuesMap.get(fieldsDescription[i]);
            }
        }
        else 
        {
            descriptionForCase = descriptionForCase + textInDescription[i];

            if (recordValuesMap.containsKey(fieldsDescription[i]))
            {
                descriptionForCase = descriptionForCase + recordValuesMap.get(fieldsDescription[i]);
            }
        }
        return descriptionForCase;
    }
}