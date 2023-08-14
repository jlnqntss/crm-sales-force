/**
 * Batch que se ejecuta de forma diaria y crea registros de campaign member desde la campaña general para los usuarios de CC
 * 
 * @author nts (dmunoz)
 * @date 10/08/2023
 *
 */
global with sharing class Batch_InitCrossSellingCampaign implements Database.Batchable<sObject>, Schedulable {

    private Map<String, Id> campaignIdByExtId;
    private static final String CLASS_NAME = 'Batch_InitCrossSellingCampaign';

    // constructor
    public Batch_InitCrossSellingCampaign() {
        campaignIdByExtId = new Map<String, Id>();
    }

    /*********** Invocar Schedule Batch **************************************************************************/
    /**
     * Método para programar de forma sencilla al batch 
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @return String: job id
     * @author dmunoz
     * @date 11/08/2023
     */
    public static String createStandardSchedule(String jobName, String timeExpression) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new Batch_InitCrossSellingCampaign());
    }


    /*********** Métodos Schedulable **************************************************************************/
    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 11/08/2023
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_InitCrossSellingCampaign(), 200);               
    }




    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos que se eliminarán en el paso execute
     * @param bc: batch context
     * @return List los campaign member a clonar
     * @author dmunoz
     * @date 11/08/2023
     */
    global List<CampaignMember> start(Database.BatchableContext bc) { 
        return (new CampaignMembersSelector()).findZRMPendingRevMediatorCampaignMembers();        
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de CampaignMember procedentes del método start
     * @return void
     * @author dmunoz
     * @date 11/08/2023
     */
    global void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        try {
            // inicializar el map campaignIdByExtId
            campaignIdByExtId = getCampaignIdByExternalId(scope, campaignIdByExtId);
            // update cm
            updateCampaignMemberToGestionCC(scope);
            // insert cm
            insertCampaignMemberToCC(campaignIdByExtId, scope);
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
    
    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 11/08/2023
     */
    global void finish(Database.BatchableContext bc) {
        // nothing
    }




    /******************************************************************************************* Métodos auxiliares ************************************************************************************************/

    /**
     * Inicializa el map campaignIdByExtId, 
     * @param scope lista de CampaignMember procedentes del método start
     * @return Map<String, Id>
     * @author dmunoz
     * @date 11/08/2023
     */
    private Map<String, Id> getCampaignIdByExternalId(List<CampaignMember> scope, Map<String, Id> campaignIdByExtId) {
        Set<String> externalIdSet = new Set<String>();        
        // obtengo el conjunto de external id y los transformo para el que tendrá su equivalente de CC
        for (CampaignMember cm: scope) {
            externalIdSet.add(cm.Campaign.ExternalId__c + '#CC');
        }

        // consulto las campañas de CC para obtener su id
        List<Campaign> ccCampaignsList = (new CampaignsSelector()).findCampaignByExternalId(externalIdSet);

        // informo el map campaignIdByExtId
        if (!ccCampaignsList.isEmpty()) {
            for (Campaign c: ccCampaignsList) {
                campaignIdByExtId.put(c.ExternalId__c, c.Id);
            }
        }

        return campaignIdByExtId;
    }

    /**
     * Actualizar los miembros de campaña que ha encontrado el batch
     * @param scope lista de CampaignMember procedentes del método start
     * @return void
     * @author dmunoz
     * @date 11/08/2023
     */
    private void updateCampaignMemberToGestionCC(List<CampaignMember> scope) {
        
        for (CampaignMember cm: scope) {
            cm.Status = 'Gestión CC';
        }
        update scope;
    }

    /**
     * Insertar los miembros de campaña en la campaña de CC
     * @param scope lista de CampaignMember procedentes del método start
     * @return void
     * @author dmunoz
     * @date 11/08/2023
     */
    private void insertCampaignMemberToCC(Map<String, Id> campaignIdByExtId, List<CampaignMember> scope) {

        List<CampaignMember> campaignMembersListToInsert = new List<CampaignMember>();
        CampaignMember campaignMemberToInsert;

        for (CampaignMember cm: scope) {
            campaignMemberToInsert = new CampaignMember();
            campaignMemberToInsert.CampaignId = campaignIdByExtId.get(cm.Campaign.ExternalId__c + '#CC');
            campaignMemberToInsert.ContactId = cm.ContactId;
            campaignMemberToInsert.LeadPhone__c = cm.LeadPhone__c;

            campaignMembersListToInsert.add(campaignMemberToInsert);
        }

        insert campaignMembersListToInsert;
    }

    /******************************************************************************************* Métodos auxiliares Schedule************************************************************************************************/
    /**
     * Dar un nombre por defecto al Job programado en caso de no informar este valor
     * @param jobName: Nombre del batch programado
     * @return String
     * @author dmunoz
     * @date 09/09/2022
     */
    private static String setJobName(String jobName) {
        if (String.isEmpty(jobName)){
            jobName = 'Ventas_Batch_InitCrossSellingCampaign';
        } 
        return jobName; 
    }

    /**
     * Dar una expresión CRON por defecto al Job programado en caso de no informar este valor
     * @param timeExpression: Expresión CRON a utilizar
     * @return String
     * @author dmunoz
     * @date 09/09/2022
     */
    private static String setTimeExpression(String timeExpression) {
        if (String.isEmpty(timeExpression)){
            timeExpression = '0 0 3 * * ?' ; 
        } 
        return timeExpression; 
    }
}