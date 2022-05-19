public with sharing class GenesysCloudTaskAction {

    @InvocableMethod(
        label='Check the status of Tasks using Genesys Cloud API'
               description='Check the status of a task to get their Genesys ID'
                            category='Other'
        )

    public static List<List<String>> execute (List<List<Task>> estadoTasks)
    { 
        List<List<String>> listaTareasDevueltas = new List<List<String>>();

        for (List<Task> listaParaEstadoTareas : estadoTasks)
        {
            List<String> listaEstadosTasks = new List<String>();

            for(Task tasks : listaParaEstadoTareas)
            {
                String valores = '';

                try 
                {
                    GenesysCloud.InteractionStatus statusInteract = new GenesysCloud.InteractionStatus();

                    statusInteract.conversationId = tasks.CallObject;

                    HttpResponse idEstado = GenesysCloud.StatusService.status(statusInteract);

                    String body = idEstado.getBody();

                    Map<String,Object> mapaObjetos = (Map<String,Object>) JSON.deserializeUntyped(body);

                    Object taskListObj = mapaObjetos.get('participants');

                    List<Object> participantsTasks = (List<Object>) taskListObj;

                    for(Object participantsTasksObj : participantsTasks)
                    {
                        Map<String, Object> participant = (Map<String,Object>) participantsTasksObj;
                        if (valores == '')
                        {
                            if (participant.get('purpose') == 'agent' && (participant.get('state') == 'connected' || participant.get('state') == 'alerting'))
                            {
                                valores = tasks.CallObject + '#' + participant.get('id') + '#' + 'working';
                            }
                            else if (participant.get('purpose') == 'acd' && participant.get('state') == 'connected')
                            {
                                valores = tasks.CallObject + '#' + participant.get('id') + '#' + 'pending';
                            }
                        }
                    }
                    if (valores != '')
                    {
                        listaEstadosTasks.add(valores);
                    }
                }
                catch (Exception e)
                {
                    System.debug(e.getMessage() );
                }
            }
            listaTareasDevueltas.add(listaEstadosTasks);
        }
        return listaTareasDevueltas;
    }
}