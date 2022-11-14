/**
 * Clase que permite enviar Notificaciones
 *
 * @author nts (agonzalezisasi)
 * @date 19/08/2021
 */
public with sharing class Notification {
    private static final String CLASS_NAME = 'Notification';
    private static final String DUMMY_ID = '000000000000000AAA';
    private static final Integer TITLE_MAX_LENGTH = 250;
    private static final Integer BODY_MAX_LENGTH = 750;
    
    // Tipo de notificacion
    public enum NotificationType {
        SDMAlert
    }
    // Mapa de conversion del tipo de notificacion a su DeveloperName
    private static final Map<NotificationType, String> mapTypesToName = new Map<NotificationType, String>{
        NotificationType.SDMAlert => 'SDMTaskDueDateAlert'
    };

    // Parametros de la notificacion
    String targetId;
    PageReference pageReference;
    Set<String> userIds;
    private ID notificationTypeId;

    @testvisible
    private Boolean testUknownError;

    public Notification(NotificationType notifType)
    {
        // Obtenemos el developer name de la notificacion
        String typeDeveloperName = mapTypesToName.get(notifType);
        // Y el Id del tipo de notificacion para ese developer name
        CustomNotificationType notificationType = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :typeDeveloperName
        ];
        this.notificationTypeId = notificationType.Id;
    }

    public void send(String subject, String content)
    {
        // Si no hay target se pone un id dummy
        if( this.targetId == null ) this.targetId = DUMMY_ID;
        
        // Creamos una nueva notificacion
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Establecemos el contenido de la notificacion
        notification.setTitle(subject.left(TITLE_MAX_LENGTH));
        notification.setBody(content.left(BODY_MAX_LENGTH));

        // Establecemos el tipo de notificacion y el Target
        notification.setNotificationTypeId(this.notificationTypeId);
        notification.setTargetId(this.targetId);

        if( this.pageReference != null ) {
            notification.setTargetPageRef(this.pageReference.toJSON());
        }
        
        // Finalmente se envia la notificacion
        try {
            if( Test.isRunningTest() && this.testUknownError != null && this.testUknownError )
                throw new NotificationException('Unknown Error');

            notification.send(this.userIds);
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    public void send(String objectId, Set<String> userIds, String subject, String content)
    {
        this.targetId = objectId;
        this.userIds = userIds;

        this.send(subject, content);
    }

    public void send(Set<String> userIds, String subject, String content)
    {
        this.send(null, userIds, subject, content);
    }

    public void addPageReference(String refType, String objectApiName, String actionName, String stateFilterName)
    {

        PageReference pageRef = new PageReference(refType, objectApiName, actionName, stateFilterName);
        addPageReference(pageRef);
    }

    public void addPageReference(String refType, String navItemApiName)
    {
        Pagereference pageRef = new PageReference(refType, navItemApiName);
        addPageReference(pageRef);
    }

    public void addPageReference(PageReference pageRef)
    {
        this.pageReference = pageRef;
    }

    /**
     * Clase de apoyo para crear referencias a paginas de salesforce
     * 
     * Referencias:
     * https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_page_reference_type
     * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Messaging_CustomNotification.htm#apex_Messaging_CustomNotification_setTargetPageRef
     * https://salesforce.stackexchange.com/questions/323553/custom-notification-recipients-to-new-places-with-page-reference-navigation
     */
    public class PageReference {
        public String type;
        public Map<String, String> attributes;
        public Map<String, String> state;

        /**
         * Crea una referencia a una pagina de salesforce para mas detalles ir a:
         * https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_page_reference_type
         * 
         * @param {String refType} tipo de referecia. Ej: standard__objectPage
         * @param {String objectApiName} nombre de objeto. Ej: Account
         * @param {String actionName} nombre de la accion. Ej: list
         * @param {String stateFilterName} nombre del filtro de la accion. Ej: Recent
         */
        public PageReference(String refType, String objectApiName, String actionName, String stateFilterName)
        {
            type = refType; // ej: 'standard__objectPage';
            attributes = new Map<String, String>{
                'objectApiName' => objectApiName,
                'actionName' => actionName
            };
            state = new Map<String, String>{
                'filterName' => stateFilterName
            };
        }

        /**
         * Crea una referencia a una pagina de salesforce para mas detalles ir a:
         * https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_page_reference_type
         * 
         * @param {String refType} tipo de referecia. Ej: standard__navItemPage
         * @param {String navItemApiName} nombre de objeto. Ej: MyCustomTabName
         */
        public Pagereference(String refType, String navItemApiName)
        {
            type = refType; // ej: standard__navItemPage
            attributes = new Map<String, String>{
                'apiName' => navItemApiName
            };
        }

        /**
         * Convierte este objeto en texto con formato JSON
         */
        public string toJSON() {
            return JSON.serialize(this);
        }
    }

    private class NotificationException extends Exception {}
}