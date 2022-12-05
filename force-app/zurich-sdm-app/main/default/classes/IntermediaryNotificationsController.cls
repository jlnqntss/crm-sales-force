/**
 * Clase Apex controladora del componente LWC ControlIntermediaryMensualPlanNotifications
 */
public with sharing class IntermediaryNotificationsController {

    /**
     * Obtiene un mapa con los registros de account team member discriminando por el campo NotificationsOnPlans__c para informar el multipicklist del componente
     * @return Mapa con la información de AccountTeam para informar el multipicklist
     * @author dmunoz
     * @date 30/11/2022
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<Id, String>> getRecords(){
        try {
            Map<String, Map<Id, String>> result = new Map<String, Map<Id, String>>(); // guardamos los mapas con los registros a añadir en el multipicklist ya sean los que están activos como los que no
            Map<Id, String> intermediariesWithActiveNotifications = new Map<Id, String>(); // guardo los id y la descripción de aquellos que tienen el check NotificationsOnPlans__c a true
            Map<Id, String> intermediariesWithNoActiveNotifications = new Map<Id, String>(); // guardo los id y la descripción de aquellos que no tienen el check NotificationsOnPlans__c a true
            Id logedUserId = UserInfo.getUserId();

            Set<Id> userIdSet = new Set<Id>();
            userIdSet.add(logedUserId);

            List<AccountTeamMember> intermediariesFromUser = (new AccountTeamMemberSelector()).findIntermediariesByUsers(userIdSet);

            for (AccountTeamMember atm: intermediariesFromUser) {
                if (atm.NotificationsOnPlans__c) {
                    intermediariesWithActiveNotifications.put(atm.Id, atm.Account.INFOIntermediaryCode__c + '-' + atm.Account.IntermediaryDescription__c);
                } else {
                    intermediariesWithNoActiveNotifications.put(atm.Id, atm.Account.INFOIntermediaryCode__c + '-' + atm.Account.IntermediaryDescription__c);
                }
            }

            result.put('ActiveIntermediary', intermediariesWithActiveNotifications);
            result.put('NonActiveIntermediary', intermediariesWithNoActiveNotifications);


            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    

    /**
     * Metodo que actualiza el flag de notificaciones para cada mediador del usuario logueado
     * @param List<String> notificationsToActiveList: ids activados desde el componente 
     * @return Mapa con la información de AccountTeam para informar el multipicklist
     * @author dmunoz
     * @date 30/11/2022
     */
    @AuraEnabled
    public static void updateIntermediaryNotificationFlag(List<String> notificationsToActiveList) {
        try {
            if (notificationsToActiveList != null ) { // solo compruebo nulos porque si llega lista vacia intento desactivar todas las notificaciones para los mediadores del usuario logueado

                List<AccountTeamMember> atmsToUpdate = new List<AccountTeamMember>();
                
                // actualizo a true el flag de los mediadores que se han recibido del componente
                AccountTeamMember atmToActive;
                for (String idToActive :notificationsToActiveList) {
                    atmToActive = new AccountTeamMember(Id = idToActive, NotificationsOnPlans__c = true);
                    atmsToUpdate.add(atmToActive);
                }

                // consulto los demás registros de atm para este usuario que no se vayan a activar y las actualizo a false el campo NotificationsOnPlans__c
                List<AccountTeamMember> otherLoggedUserATMs = (new AccountTeamMemberSelector()).findIntermedariesWithInactiveNotifications(UserInfo.getUserId(), notificationsToActiveList);

                if (otherLoggedUserATMs != null && !otherLoggedUserATMs.isEmpty()) {
                    AccountTeamMember atmToInactive;
                    for (AccountTeamMember atmToInactivateNotification :otherLoggedUserATMs) {
                        atmToInactive = new AccountTeamMember(Id = atmToInactivateNotification.Id, NotificationsOnPlans__c = false);
                        atmsToUpdate.add(atmToInactive);                                                
                    }
                }

                if (!atmsToUpdate.isEmpty()) {
                    runFlow(atmsToUpdate);                    
                }              
            }

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, 'IntermediaryNotificationsController', 'updateIntermediaryNotificationFlag');
            throw new AuraHandledException(System.Label.SDM_ControlIntermediaryNotifiaction_ErrorFlowUpdate);
        }
    }


    private static void runFlow(List<AccountTeamMember> atmsToUpdate) {

        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('AccountTeamsMemberstoUpdate', atmsToUpdate);
         
        Flow.Interview.SDM_Update_Notification_Flag_ATM myFlow = new Flow.Interview.SDM_Update_Notification_Flag_ATM(inputs);
        myFlow.start();
        String flowFaultMessage = (String) myFlow.getVariableValue('FaultMessage');

        // si hay error levanto excepcion con el mensaje recibido del flujo
        if (String.isNotEmpty(flowFaultMessage)) {            
            throw new HandledException(flowFaultMessage);
        }
        
    }
}