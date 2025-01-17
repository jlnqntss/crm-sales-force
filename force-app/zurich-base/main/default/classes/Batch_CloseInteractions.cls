/**
 * Batch que al lanzarse cierra las interacciones de los casos que éste recibe
 * Pueden tener como origen Email o Nota INFO.
 * @author lrodriguez6@seidor.es
 * @date 12/02/2024
 */
global class Batch_CloseInteractions implements Database.Batchable<case>,Database.AllowsCallouts,Database.Stateful, Schedulable
{

    public List<Case> casosQuery= new List<Case>();
    public List<Case> allCasosQuery= new List<Case>();
    global Integer  testOK;

    @TestVisible static Integer testCount;

    /**
     * Constructor por defecto, el conjunto de casos de los que obtener las interacciones se calcula con el método general (start)
     * @author lrodriguez6@seidor.es
     * @date 12/02/2024
     */
    public Batch_CloseInteractions() 
    {

    }

    /**
     * Constructor que recibe List<Case>
     * @author lrodriguez6@seidor.es
     * @date 29/02/2024
     */
    public Batch_CloseInteractions(List<Case> casosQuery) 
    {
        this.casosQuery=casosQuery;
    }

    
    /**
     * En caso de que no se haya introducido una lista en el constructor, se carga la lista por defecto
     * @author lrodriguez6@seidor.es
     * @date 12/02/2024
     */
    global Iterable <case> start(Database.BatchableContext bc)
    {
        
        casosQuery = new CasesSelector().getCasesToCloseInteractions();
        allCasosQuery = new CasesSelector().getCasesToCloseInteractionsAutomatic();
        allCasosQuery.addAll(casosQuery);
        
        return allCasosQuery;
    }
    
    /**
     * Método necesario en todas las clases batchable
     * @author lrodriguez6@seidor.es
     * @date 12/02/2024
     */
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_CloseInteractions(casosQuery), 40);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            //Casos
            List<Case> casesInteractions = scope;
            List<Case> casesToUpdate= new List<Case>();
            //Tareas
            List<Task> listaTareasNotaINFO = new List<Task>();
            List<List<Task>> listaTareas= new List<List<Task>>();
            //String
            List<List<String>> listafinal = new List<List<String>>();
            List<List<String>> salidaStatus = new List<List<String>>();
            List<List<String>> salidaStatusEmail = new List<List<String>>();
            //EmailMessage
            List<EmailMessage> listaEmailMessage= new List<EmailMessage>();
            List<List<EmailMessage>> listaEmail= new List<List<EmailMessage>>();

            System.debug('Número de Casos que recibe el Batch: '+casesInteractions.size());

            try
            {
                //Se recuperan las tareas relacionadas con los casos 
                listaTareasNotaINFO = new TaskSelector().getTaskRelatedWithCases(casesInteractions);

                System.debug('Lista Tareas: '+listaTareasNotaINFO);
                System.debug('Tamaño de Lista Tareas:'+listaTareasNotaINFO.size());

                //Se añade a lista de lista
                listaTareas.add(listaTareasNotaINFO);

                //Se obtienen los id de interacción a partir de las tareas
                salidaStatus = GenesysCloudTaskStatusAction.execute(listaTareas);

                System.debug('Id a partir de tareas: '+salidaStatus);
                System.debug('Tamaño id a partir de tareas: '+salidaStatus.size());

                //Se recuperan los EmailMessage relacionados con los casos
                listaEmailMessage= new EmailMessagesSelector().selectByCaseBatch(casesInteractions);

                System.debug('lista EmailMessage: '+listaEmailMessage);
                System.debug('Tamaño lista EmailMessage');

                //Se añade a lista de lista 
                listaEmail.add(listaEmailMessage);

                //Se recuperan los id de la interacción a partir de los email
                salidaStatusEmail = GenesysCloudEmailStatusAction.execute(listaEmail);

                System.debug('Id a partir de los Email: '+salidaStatusEmail);
                System.debug('Tamaño id a partir de los Email: '+salidaStatusEmail.size());

                //Se añaden estos Id de interacciones a los Id de las interacciones de las Tareas
                salidaStatus.addAll(salidaStatusEmail);
                
                System.debug('Conjunto de interacciones(Email+Task):'+salidaStatus);
                System.debug('Tamaño del conjunto de interacciones: '+salidaStatus.size());

                //Se solicita el cierre de las interacciones
                listafinal= GenesysCloudBatchPatchInteractionAction.execute(salidaStatus);

                System.debug('lista final: '+listafinal);
                System.debug('tamaño lista final: '+listafinal.size());

                testOK=listafinal.size();

                //Se actualiza campo que indica que el caso ha pasado por el batch
                casesToUpdate= CaseUtil.checkCasesCloseInteractions(casesInteractions);

                update casesToUpdate;


            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'Batch_CloseInteractions');
            }
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        testCount=testOK;
    }
}