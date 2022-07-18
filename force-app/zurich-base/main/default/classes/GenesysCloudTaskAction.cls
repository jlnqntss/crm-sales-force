public with sharing class GenesysCloudTaskAction {

    /** 
     * Esta acción ejecuta la busca del estado de las tareas para poder
     * recuperar el GenesysID y poder realizar la desconexión de estas tareas
     * @param Se recibe una lista de listas de tareas
     * @return Se devuelve una lista de listas de string, en el que se incluye
     * la GenesysId, el tipo de participant y su state, así como una variable única
     * para poder distinguirlos.
    */
    
    @InvocableMethod(
        label='Check the status of Tasks using Genesys Cloud API'
               description='Check the status of a task to get their Genesys ID'
                            category='Other'
        )

    public static List<List<String>> execute (List<List<Task>> estadoTasks)
    { 
        //creamos una lista de listas de string que usaremos para introducir los datos y usarla como return
        List<List<String>> listaTareasDevueltas = new List<List<String>>();
        //recorremos la lista de listas de tareas que hemos recibido como parámetro
        for (List<Task> listaParaEstadoTareas : estadoTasks)
        {
            //creamos una lista de strings para poder guardar los estados de las tareas
            List<String> listaEstadosTasks = new List<String>();
            //recorremos cada tarea que tenemos en la lista
            for(Task tasks : listaParaEstadoTareas)
            {
                //inicializamos una variable tipo string vacía para poder guardar los valores que obtengamos
                String valores = '';

                try 
                {
                    //generamos una nueva interacción de Genesys Cloud
                    GenesysCloud.InteractionStatus statusInteract = new GenesysCloud.InteractionStatus();
                    //igualamos el GenesysId de la nueva interacción al GenesysId de la tarea
                    statusInteract.conversationId = tasks.CallObject;
                    //creamos una nueva respuestaHttp pasándole como parámetro al StatusService (para comprobar el estado del GenesysId) el que hemos introducido arriba
                    HttpResponse idEstado = GenesysCloud.StatusService.status(statusInteract);
                    //traemos el body que obtenemos de idEstado
                    String body = idEstado.getBody();
                    //deserializamos el body para obtener un mapa de objetos 
                    Map<String,Object> mapaObjetos = (Map<String,Object>) JSON.deserializeUntyped(body);
                    //obtenemos los participants que haya en el mapaObjetos
                    Object taskListObj = mapaObjetos.get('participants');
                    //indicamos la lista que hemos obtenido de los participantes como una lista de objetos para poder recuperarla
                    List<Object> participantsTasks = (List<Object>) taskListObj;
                    //recorremos la lista que hemos obtenido arriba
                    for(Object participantsTasksObj : participantsTasks)
                    {
                        //por cada participante que haya en esta lista, creamos un mapa para obtener el id y el valor de cada campo
                        Map<String, Object> participant = (Map<String,Object>) participantsTasksObj;
                        //mientras valores esté vacío...
                        if (valores == '')
                        {
                            //comprobamos que el purpose del participant sea agent y esté connected o alerting
                            if (participant.get('purpose') == 'agent' && (participant.get('state') == 'connected' || participant.get('state') == 'alerting'))
                            {
                                //añadiremos a valores el GenesysID de la tarea, el id del participant y le asignamos una variable única "working"
                                valores = tasks.CallObject + '#' + participant.get('id') + '#' + 'working';
                            }
                            //en cambio, si el purpose del participant es acd y está connected
                            else if (participant.get('purpose') == 'acd' && participant.get('state') == 'connected')
                            {
                                //añadiremos a valores el GenesysID de la tarea, el id del participant y le asignamos una variable única "pending"
                                valores = tasks.CallObject + '#' + participant.get('id') + '#' + 'pending';
                            }
                        }
                    }
                    //una vez añadido las ids a valores, comprobamos si esta variable no está vacía
                    if (valores != '')
                    {
                        //añadimos valores a la lista segunda que hemos creado.
                        listaEstadosTasks.add(valores);
                    }
                }
                catch (Exception e)
                {
                    System.debug(e.getMessage() );
                }
            }
            //una vez recorridas las tareas, añadiremos la lista superior a la lista primera que devolveremos para proceder a la desconexión de las tareas 
            listaTareasDevueltas.add(listaEstadosTasks);
        }
        return listaTareasDevueltas;
    }
}