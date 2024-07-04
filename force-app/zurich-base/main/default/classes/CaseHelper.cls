/**
 * Clase que contiene métodos que completan la funcionalidad
 * 
 * @author arcortazar
 * @date 25/06/2024
 */
public with sharing class CaseHelper {

    @testVisible
    private static List<List<String>> testingResult = new List<List<String>>();

    @future (callout=true)
    public static void closeInteractions(List<String> lstIDCasos)
    {
        List<List<String>> interactionValues = new List<List<String>>();
        // 0.- Al ser metodo future no acepta lista de casos -> los buscamos 
        List<Case> lstCasos = new CasesSelector().findAllDataById(new Set<String>(lstIDCasos));

        // 1.- Obtenemos las interacciones generadas por comunicaciones via API (Nota Info, Formulario, Canal Unico)
        List<List<Task>> lstListaApiTasks = new List<List<Task>>();  // Lista de listas necesaria para Action

        List<Task> lstApiTasks = new TaskSelector().getTaskFromSingleChannel(lstCasos);
        lstApiTasks.addAll(new TaskSelector().getTaskRelatedWithCases(lstCasos));
        
        if(!lstApiTasks.isEmpty())
        {
            lstListaApiTasks.add(lstApiTasks);
            //Se obtienen los id de interacción a partir de las tareas
            interactionValues = GenesysCloudTaskStatusAction.execute(lstListaApiTasks);
        }

        // 2.- Obtenemos las interacciones generadas por comunicaciones via email
        //Se recuperan los EmailMessage relacionados con los casos y se inserta en la Lista de listas
        List<List<EmailMessage>> lstListaEmailMessages = new List<List<EmailMessage>>(); 

        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'ParentId','Incoming','GenesysInteractionId__c'};
        List<EmailMessage> lstRetrievedEmails = emailMessagesSelectorObj.selectByCaseBatch(lstCasos);

        Map<Id, List<EmailMessage> > retrievedEmailByCase = (Map<Id, List<EmailMessage>>) CollectionUtil.groupListBy( lstRetrievedEmails, EmailMessage.fields.ParentId.getDescribe().getName() );
        for(List<EmailMessage> lstEmails : retrievedEmailByCase.values())
        {
            // Eliminamos el último elemento de la lista
            lstEmails.remove(lstEmails.size() - 1 );
            if(!lstEmails.isEmpty())
            {
                lstListaEmailMessages.add(lstEmails);
            }
        }

        //Si tenemos interacciones de email que cerrar, se recuperan los id de la interacción a partir de los email
        if(!lstListaEmailMessages.isEmpty())
        {
            interactionValues.addAll(GenesysCloudEmailStatusAction.execute(lstListaEmailMessages));
        }

        //3.- Se solicita el cierre de las interacciones
        testingResult = GenesysCloudBatchPatchInteractionAction.execute(interactionValues);
    }
}