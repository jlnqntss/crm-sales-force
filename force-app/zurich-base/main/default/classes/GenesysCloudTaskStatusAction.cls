public with sharing class GenesysCloudTaskStatusAction {

    /** 
     * Esta acción ejecuta la busca del estado de las tareas para poder
     * recuperar el GenesysID y poder realizar la desconexión de estas tareas
     * @param Se recibe una lista de listas de tareas
     * @return Se devuelve una lista de listas de string, en el que se incluye
     * la GenesysId y el tipo de participant, así como una variable única
     * para poder distinguirlos.
    */
    
    @InvocableMethod(
        label='Check the status of Tasks using Genesys Cloud API'
               description='Check the status of a task to get their Genesys ID'
                            category='Other'
        )

    public static List<List<String>> execute (List<List<Task>> estadoTasks)
    { 
        List<List<String>> listaTareasDevueltas = new List<List<String>>();
        System.debug('*Lista Entrada GenesysCloudTaskStatusAction*: '+estadoTasks);

        listaTareasDevueltas= forTask(estadoTasks,listaTareasDevueltas);
        
        return listaTareasDevueltas;
    }

    public static List<List<String>> forTask(List<List<Task>> estadoTasks,List<List<String>> listaTareasDevueltas)
    {
        for (List<Task> listaParaEstadoTareas : estadoTasks)
        {
            List<String> listaEstadosTasks = new List<String>();

            for(Task tasks : listaParaEstadoTareas)
            {
                String valores = '';
                listaEstadosTasks= tryInteractionTask(tasks,listaEstadosTasks,valores);  
            }

            listaTareasDevueltas.add(listaEstadosTasks);
        }
        return listaTareasDevueltas;
    }

    public static List<String> tryInteractionTask(Task tasks,List<String> listaEstadosTasks,String valores)
    {
        try 
                {
                    //generamos una nueva interacción de Genesys Cloud
                    GenesysCloud.InteractionStatusId statusInteract = new GenesysCloud.InteractionStatusId();
                    System.debug('GenesysCloudTaskStatusAction StatusInteract: '+statusInteract);

                    //igualamos el GenesysId de la nueva interacción al GenesysId de la tarea
                    statusInteract.conversationId = tasks.CallObject;
                    System.debug('GenesysCloudTaskStatusAction conresationId:'+statusInteract.conversationId);

                    //creamos una nueva respuestaHttp pasándole como parámetro al StatusService (para comprobar el estado del GenesysId) el que hemos introducido arriba
                    HttpResponse idEstado = new GenesysCloud.StatusServiceId().status(statusInteract);
                    System.debug('GenesysCloudTaskStatusAction idEstado: '+idEstado);

                    String body = idEstado.getBody();
                    System.debug('*GenesysCloudTaskStatusAction body*:'+body);
                    Map<String,Object> mapaObjetos = (Map<String,Object>) JSON.deserializeUntyped(body);
                    System.debug('*GenesysCloudTaskStatusAction mapaObjetos*:'+mapaObjetos);
                    Object taskListObj = mapaObjetos.get('participants');
                    System.debug('*GenesysCloudTaskStatusAction taskListObj*:'+taskListObj);

                    List<Object> participantsTasks = (List<Object>) taskListObj;

                    for(Object participantsTasksObj : participantsTasks)
                    {
                        Map<String, Object> participant = (Map<String,Object>) participantsTasksObj;

                        if (valores == '')
                        {
                            valores = tasks.CallObject + '#' + participant.get('id');
                        }
                    }
                    if (valores != '')
                    {
                        listaEstadosTasks.add(valores);
                        System.debug('Tamaño salida listEstadosTask: '+listaEstadosTasks.size());
                    }
                }
                catch (Exception e)
                {
                    ErrorLogUtil.commitError(e, 'GenesysCloudTaskStatusAction->'+e.getMessage());
                }

                return listaEstadosTasks;
    }
}