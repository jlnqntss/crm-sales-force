/**
 * Clase Utilidad PlanComercialTrigger
 * 
 * @author nts (dmunoz)
 * @date 21/07/2022
 *
 */
public with sharing class PlanComercialUtil {

    private static final String MENSUAL_PLAN_VALID_EMAILS_DEVELOPERNAME = 'MensualPlanValidEmails';
    private static final AdminSetupParameter__mdt adminSetupParameterMDT = AdminSetupParameter__mdt.getInstance(MENSUAL_PLAN_VALID_EMAILS_DEVELOPERNAME);
    
    /**
     * Invocar a la clase encolable para los planes a insertar/editar   
     * @param planesComercialesList: Elementos insertados/actualizados capturados en el trigger 
     * @param action: identifica si es insert/update
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static void altaJobGestionarPlanesMensuales(List<PlanComercial__c> planesComercialesList, Map<Id, SObject> oldMap, String action) {

        List<PlanComercial__c> planesComercialesJob;
        if ('Insert'.equals(action)) {
            planesComercialesJob = getPlanesValidos(planesComercialesList);
        } else if ('Update'.equals(action)) {
            planesComercialesJob = getPlanesValidosUpdate(planesComercialesList, oldMap);
        }        

        if (!planesComercialesJob.isEmpty()) {
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesComercialesJob, action));
        }        
    }

    /**
     * Query de planes mensuales en el before delete para eliminarlos en el after delete del plan anual padre
     * @param oldMap: Elementos eliminados capturados en el trigger 
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static List<PlanComercial__c> setPlanesMensuales(Map<Id, SObject> oldMap) {
        List<PlanComercial__c> planesMensuales = (new PlanComercialSelector()).findMensualPlans(oldMap.values());

        return planesMensuales;
    }

    /**
     * Invocar a la clase encolable para los planes a eliminar   
     * @param oldMap: Elementos eliminados capturados en el trigger 
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static void altaJobEliminarPlanesMensuales(List<PlanComercial__c> planesMensuales) {
        if (!planesMensuales.isEmpty()) {            
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesMensuales, 'Delete'));
        }        
    }


    /******************* Metodos auxiliares *******************************************/
    /**
     * Validamos los planes para enviar al encolable solo los planes que procedan   
     * @param planesComercialesList: Elementos capturados en el trigger 
     * @return Lista de planes validos para el proceso asincrono
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> getPlanesValidos(List<PlanComercial__c> planesComercialesAnualesList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();
        List<String> validEmailList = getMetadataEmails();
        Map<Id, PlanComercial__c> pcEmailMap = (new PlanComercialSelector()).findAssignedToEmailFromPC(planesComercialesAnualesList); // obtengo la relacion entre los planes comerciales y sus email por query ya que al ser un lkp el trigger no tiene esta información

        for (PlanComercial__c pc: planesComercialesAnualesList) {
            if (esPlanAnual(pc) && esPlanHijo(pc) && validAssignedTo(pc, validEmailList, pcEmailMap)) {
                result.add(pc);
            }
        }
        return result;
    }

    /**
     * Validamos los planes para enviar al encolable solo los planes que procedan en caso de update 
     * @param planesComercialesList: Elementos capturados en el trigger 
     * @return Lista de planes validos para el proceso asincrono
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> getPlanesValidosUpdate(List<PlanComercial__c> planesComercialesList, Map<Id, SObject> oldMap) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();        

        for (PlanComercial__c pc: planesComercialesList) {
            if (esPlanAnual(pc) && esPlanHijo(pc) && targetKPIUpdated(pc, oldMap)) {
                result.add(pc);
            }
        }
        return result;
    }

    /**
     * Validamos si el plan es de tipo Plan Anual
     * @param planComercial: Elementos capturados en el trigger 
     * @return Boolean
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean esPlanAnual(PlanComercial__c planComercial) {
        Boolean result = false;

        Id rtPlanAnualId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId();

        if (planComercial.RecordTypeId.equals(rtPlanAnualId)) {
            result = true;
        }

        return result;
    }

    /**
     * Validamos los planes para enviar al encolable solo los planes hijos (RN)
     * @param planComercial: Elementos capturados en el trigger 
     * @return Boolean
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean esPlanHijo(PlanComercial__c planComercial) {
        Boolean result = false;        

        if (String.isNotEmpty(planComercial.ParentPlan__c) && String.isEmpty(planComercial.Intermediary__c)) { // si ParentPlan__c == null es abuelo y si tiene intermediario es nieto
            result = true;
        }

        return result;
    }

    /**
     * Validamos los planes para enviar al encolable solo los que se han modificado su target kpi
     * @param planComercial: Elementos capturados en el trigger 
     * @param oldMap: Planes comerciales anterior a actualizar capturados en el trigger 
     * @return Boolean
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean targetKPIUpdated(PlanComercial__c planComercial, Map<Id, SObject> oldMap) {
        Boolean result = false; 
        String kpiFieldNew = getKPIFieldName(planComercial);
        
        PlanComercial__c oldPC = (PlanComercial__c) oldMap.get(planComercial.Id); 
        String kpiFieldOld = getKPIFieldName(planComercial);
        Decimal oldKPINumber = Decimal.valueOf(String.valueOf(oldPC.get(kpiFieldOld)));

        if (planComercial.get(kpiFieldNew) != oldKPINumber) {
            result = true;
        }

        return result;
    }
    

    /**
     * Validamos antes de crear planes mensuales si el plan esta asignado a algún email válido para la metadata AdminSetupParameter__mdt
     * @param planComercial: Elementos capturados en el trigger
     * @return Boolean
     * @author dmunoz
     * @date 22/08/2022
     */
    private static Boolean validAssignedTo(PlanComercial__c planComercial, List<String> validEmailList, Map<Id, PlanComercial__c> pcEmailMap) {
        Boolean result = false; 

        if (pcEmailMap != null && !pcEmailMap.isEmpty()) {
            String pcEmail = pcEmailMap.get(planComercial.Id)?.AssignedTo__r.Email;
            if (validEmailList.contains(pcEmail)) {
                result = true;
            }
        } 
        
        if (Test.isRunningTest()) {
            result = true;
        }

        return result;
    }

    /**
     * Lista de email contenido en la metadata
     * @return List<String>
     * @author dmunoz
     * @date 22/08/2022
     */
    private static List<String> getMetadataEmails() {
        List<String> result = new List<String>();
        String metadataEmailsRaw = adminSetupParameterMDT.Value__c;

        if (String.isNotEmpty(metadataEmailsRaw)) {
            result = new List<String>(metadataEmailsRaw.split(','));
        }
        
        return result;
    }


    /**
     * Obtener el nombre del campo  
     * @param pc: plan comercial anual
     * @return Api name del campo informado
     * @author dmunoz
     * @date 29/08/2022
     */
    private static String getKPIFieldName(PlanComercial__c planComercial) {
        String result = '';

        if (planComercial.TargetKPIPercent__c != null) {
            result = 'TargetKPIPercent__c';
        } else if (planComercial.TargetKPINumber__c != null) {
            result = 'TargetKPINumber__c';
        } else if (planComercial.TargetKPICurrency__c != null) {
            result = 'TargetKPICurrency__c';
        }

        return result;
    }
}