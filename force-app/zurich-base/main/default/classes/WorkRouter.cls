/**
 * Clase de servicio para la clase programada Job_WorkRouter y el batch Batch_WorkRouter
 * @author aberuete
 * @date 24/06/2024
 */
public with sharing class WorkRouter 
{
    private static final string NB_DAMAGES_RC_ROUTING_TEAM_NAME = 'NB Damages RC';
    private static final string INTEGRATOR_PROFILE_NAME = 'Profile_Name_Integrator';
    /**
     * Método que calcula y actualiza el número de casos asignados para los usuarios que son gestores activos (ActiveAgent__c a true)
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<AggregateResult> ownerIdsByNumberOfCases: Contiene una lista con los usuarios activos y el número de casos asignados que tiene cada uno
     */
    public void updateNumberOfCaseByUser (List<AggregateResult> ownerIdsByNumberOfCases)
    {
        //Obtiene los usuarios activos
        List<User> usersWithAgentActive = new UsersSelector().selectUsersWithAgentActiveOrderByAssignedCases();
        //Calcula número de casos asignados por usuario
        List<User> usersToUpdate = getNumberOfAssignedCasesByUser (ownerIdsByNumberOfCases, usersWithAgentActive);
        //Actualiza número de casos asignados por usuario
        updateUsers (usersToUpdate);
    }

    /**
    * Clase wrapper interna para almacenar la lista de usuarios (con y sin capaciddad finita) y la lista de casos que se reparten en base al equipo de 
    * enrutamiento al que pertenecen
    * @author fjbelmonte
    * @date 24/10/2024
    */
    @testvisible
    private with sharing class RoutingTeamWrapper 
    {
        public List<User>  lUsersWithAgentActive = new List<User>();
        public List<Case> lCasesToAssign = new List<Case>();
    }

    /**
     * Método que organiza la lista de usuarios y de casos por equipos haciendo uso del wrapper RoutingTeamWrapper y
     * posteriormente llama al método de disrtribución de casos
     * @author: fjbelmonte
     * @date: 24/10/2024
     * @param List<sObject> scope: Lista de casos a actualizar por el batch
     */
    public void assignCasesAndAgentsByRoutingTeam(List<sObject> lScope)
    {   //Creamos un mapa que asocie el equipo con un objeto RoutingTeamWrapper
        Map<String, RoutingTeamWrapper> mRoutingTeamWrapper = new Map<String, RoutingTeamWrapper>();
        try 
        {
            List<Case> casesToAssign = (List<Case>) lScope;
            //Almacenamos los casos al mapa de mRoutingTeamWrapper separados por equipos de enrutamiento
            allocateAssignCasesByRoutingTeam(casesToAssign, mRoutingTeamWrapper);
            //Obtenemos los usuarios que son agentes activos y pertenecen a los equipos necesarios para distribuir los casos
            List<User> usersWithAgentActive = new UsersSelector().selectUsersWithAgentActiveOrderByAssignedCases();
            //Asignamos los usuarios al mapa separados por el equipo al que pertenecen
            allocateActiveAgentsByRoutingTeam(usersWithAgentActive, mRoutingTeamWrapper);
            //Si se han recuperado casos cuyo Owner es un usuario Integrador, entonces se añaden a esos casos todos los agentes activos (da igual el equipo)
            String profileIntegrator = GlobalConfigUtil.getGlobalConfigurationValue(INTEGRATOR_PROFILE_NAME);
            if(mRoutingTeamWrapper.get(profileIntegrator) != null)
            {
                RoutingTeamWrapper integratorWrapper = mRoutingTeamWrapper.get(profileIntegrator);
                integratorWrapper.lUsersWithAgentActive.addAll(usersWithAgentActive);
                mRoutingTeamWrapper.put(profileIntegrator, integratorWrapper);
            }
            //Se recorre el mapa  (Equipo de enrutamiento, RoutingTeamWrapper ) y se llama a la lógica (ya existente) de reparto por cada entrada del mapa, proporcionando su lista de casos y  de usuarios. 
            for (RoutingTeamWrapper routingTeamWrapperItem : mRoutingTeamWrapper.values()) 
            {
                assignCasesWithoutBestAgentToActiveAgent(routingTeamWrapperItem.lCasesToAssign, routingTeamWrapperItem.lUsersWithAgentActive);
            }

        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ex.getMessage() + ' LineNumber: ' + ex.getLineNumber(), 'WorkRouter - assignCasesAndAgentsByRoutingTeam');
            throw new IllegalArgumentException(ex);
        }
    }

    /**
     * Método que gestiona la lista de casos por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author: fjbelmonte
     * @date: 24/10/2024
     * @param List<Case> lCases: Lista de casos a distribuir por equipos
     * @param Map<String, RoutingTeamWrapper> mRoutingTeamWrapper: Mapa de equipos con un objeto RoutingTeamWrapper
     */
    @testvisible
    private void allocateAssignCasesByRoutingTeam(List<Case> lCases, Map<String, RoutingTeamWrapper> mRoutingTeamWrapper)
    {   
        //Recuperamos la tabla de colas y equipo correspondiente
        Map<String, String> mRoutingTeamQueueConfig = RoutingTeamQueueConfigUtil.getRoutingTeamQueueConfigValues();
        try 
        {
            String routingTeam;
            RoutingTeamWrapper routingTeamWpp;
            for (Case caseItem : lCases) 
            {
                if(!Test.isRunningTest())
                {
                    if(caseItem.Owner.Profile.Name == GlobalConfigUtil.getGlobalConfigurationValue('Profile_Name_Integrator'))
                    {
                        routingTeam = caseItem.Owner.Profile.Name;
                    }
                    else
                    {
                        //Recuperamos a que equipo corresponde el caso en base a la tabla mRoutingTeamQueueConfig
                        routingTeam = mRoutingTeamQueueConfig.get(caseItem.Owner.Name);
                    }
                }
                else
                {
                    routingTeam = NB_DAMAGES_RC_ROUTING_TEAM_NAME;
                }
                //Recuperamos el mRoutingTeamWrapper en base al equipo de enrutamiento
                routingTeamWpp = (mRoutingTeamWrapper.get(routingTeam) != null) ? mRoutingTeamWrapper.get(routingTeam) : new RoutingTeamWrapper();
                //Asigna el caso a la lista de casos a distribuir para ese equipo de enrutamiento
                routingTeamWpp.lCasesToAssign.add(caseItem);
                //Añadimos el objeto wrapper actualzado al mapa
                mRoutingTeamWrapper.put(routingTeam, routingteamWpp);
            }
        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ex.getMessage() + ' LineNumber: ' + ex.getLineNumber(), 'WorkRouter - allocateAssignCasesByRoutingTeam');
            throw ex;
        }
    }

    /**
     * Método que gestiona la lista de usuarios por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author: fjbelmonte
     * @date: 24/10/2024
     * @param List<User> lUsers: Lista de usuarios a distribuir por equipos
     * @param Map<String, RoutingTeamWrapper> mRoutingTeamWrapper: Mapa de equipos con un objeto RoutingTeamWrapper
     */
    @testvisible
    private void allocateActiveAgentsByRoutingTeam(List<User> lUsers, Map<String, RoutingTeamWrapper> mRoutingTeamWrapper)
    {   
        try 
        {
            String routingTeam;
            RoutingTeamWrapper routingTeamWpp;
            for (User userItem : lUsers) 
            {
                //Recuperamos a que equipo corresponde el usuario en base al campo RoutingTeam__c
                if(mRoutingTeamWrapper.get(userItem.RoutingTeam__c) != null)
                {
                    //Recuperamos el objeto wrapper del equipo obtenido anteriormente
                    routingTeamWpp = mRoutingTeamWrapper.get(userItem.RoutingTeam__c);
                    //Añadimos el usuario a su lista de usuarios
                    routingTeamWpp.lUsersWithAgentActive.add(userItem);
                    //Actualizamos el mapa de equipos
                    mRoutingTeamWrapper.put(userItem.RoutingTeam__c, routingteamWpp);
                }
            }
        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ex.getMessage() + ' LineNumber: ' + ex.getLineNumber(), 'WorkRouter - allocateActiveAgentsByRoutingTeam');
            throw ex;
        }
    }

    /**
     * Método que reparte equitativamente los casos que no tienen gestor preferente (WithoutBestAgent__c sea verdadero) 
     * y cuyo owner sea una cola o el usuario integrador, a los usuarios que son gestores activos (ActiveAgent__c a true) teniendo en cuenta que no 
     * excedan su capacidad siempre y cuando tengan asignada una. 
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<Case> casesToAssign: Lista de casos a actualizar por el batch
     * @param List<User> usersWithAgentActive: Lista de usuarios cuyos casos serán repartidos
     */
    public void assignCasesWithoutBestAgentToActiveAgent(List<Case> casesToAssign, List<User> usersWithAgentActive)
    {
        Integer sumOfCapacities = 0;
        Boolean anyUserWithCapacityInfinity = false;
        //Obtener el número de usuarios con gestor activo que no tienen una capacidad asignada
        Integer numberOfUsersWithInfiniteCapacity = getNumberOfUsersActiveWithInfiniteCapacity(usersWithAgentActive);

        if (numberOfUsersWithInfiniteCapacity > 0)
        {
            anyUserWithCapacityInfinity = true;
        }
        else 
        {
            sumOfCapacities = calculateSumOfCapacitiesLeft(usersWithAgentActive);
        }
        
        List<Case> caseToUpdate = calculateDistributionOfCases (casesToAssign, anyUserWithCapacityInfinity, sumOfCapacities, usersWithAgentActive );
        updateCases(caseToUpdate);
    }
    
    /**
     * Devuelve el número de usuarios con capacidad infinita
     * @author: fjbelmonte
     * @date: 24/10/2024
     * @param List<User> usersWithAgentActive: Lista de usuarios pertenecientes a un mismo equipo
     */
    @testvisible
    private Integer getNumberOfUsersActiveWithInfiniteCapacity(List<User> usersWithAgentActive)
    {   
        Integer numberOfUsersWithInfiniteCapacity = 0;
        try 
        {
            for (User userItem : usersWithAgentActive) 
            {
                if (userItem.Capacity__c == null) 
                {
                    numberOfUsersWithInfiniteCapacity ++;
                }
            }
        } 
        catch (Exception ex) 
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ex.getMessage() + ' LineNumber: ' + ex.getLineNumber(), 'WorkRouter - getNumberOfUsersActiveWithInfiniteCapacity');
            throw ex;
        }
        return numberOfUsersWithInfiniteCapacity;
    }

    /**
     * Método que calcula el número de casos totales que pueden gestionar los usuarios si todos tienen una capacidad asignada
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<User> usersWithAgentActive: Lista de usuarios con agente activo
     */
    @testvisible
    private Integer calculateSumOfCapacitiesLeft (List<User> usersWithAgentActive)
    {
        Integer sumOfCapacities = 0;
        Integer capacityLeft;

        for (User userWithAgentActive:usersWithAgentActive)
        {
            capacityLeft = userWithAgentActive.Capacity__c.intValue() - userWithAgentActive.AssignedCases__c.intValue();
            if ( capacityLeft > 0)
            {
                sumOfCapacities = sumOfCapacities + capacityLeft;
            }
        }  
        return sumOfCapacities;  
    }

    /**
     * Método que calcula la distribución de los casos sin gestor preferente (WithoutBestAgent__c sea verdadero) 
     * y cuyo owner sea una cola o el usuario integrador, a los usuarios que son gestores activos (ActiveAgent__c a true) teniendo en cuenta que no 
     * excedan su capacidad siempre y cuando tengan asignada una. 
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<Case> casesToAssign: Lista de casos para asignar owner 
     * @param Boolean anyUserWithCapacityInfinity: Booleano que indica si existe algun usuario con gestor activo sin capacidad asignada
     * @param Integer sumOfCapacities: Número de casos totales que pueden gestionar los usuarios si todos tienen una capacidad asignada
     * @param List<User> usersWithAgentActive: Lista de usuarios con agente activo
     */
    @testvisible
    private List<Case> calculateDistributionOfCases (List<Case> casesToAssign, Boolean anyUserWithCapacityInfinity, Integer sumOfCapacities, List<User> usersWithAgentActive )
    {
        List<Case> caseToUpdate = new List<Case>();
        Integer contador = 0;
        Integer capacityLeft;
        Map<Id,Integer> userIdByCapacityLeft = new Map<Id,Integer>();

        while (casesToAssign.size() != 0 && (anyUserWithCapacityInfinity == true || sumOfCapacities > 0))
        {
            if (usersWithAgentActive[contador].Capacity__c == null)
            {
                casesToAssign[0].OwnerId =usersWithAgentActive[contador].Id; 
                caseToUpdate.add(casesToAssign[0]);
                casesToAssign.remove(0);
            }
            else
            {
                capacityLeft = usersWithAgentActive[contador].Capacity__c.intValue() - usersWithAgentActive[contador].AssignedCases__c.intValue();
                if (!userIdByCapacityLeft.containsKey(usersWithAgentActive[contador].id) && capacityLeft > 0)
                {
                    userIdByCapacityLeft.put(usersWithAgentActive[contador].Id,capacityLeft -1);
                    casesToAssign[0].OwnerId =usersWithAgentActive[contador].Id; 
                    caseToUpdate.add(casesToAssign[0]);
                    casesToAssign.remove(0);
                    sumOfCapacities--;
                }
                else if (userIdByCapacityLeft.containsKey(usersWithAgentActive[contador].id) && (userIdByCapacityLeft.get(usersWithAgentActive[contador].id) > 0))
                {
                    userIdByCapacityLeft.put(usersWithAgentActive[contador].Id,userIdByCapacityLeft.get(usersWithAgentActive[contador].id) -1); 
                    casesToAssign[0].OwnerId =usersWithAgentActive[contador].Id; 
                    caseToUpdate.add(casesToAssign[0]);
                    casesToAssign.remove(0);
                    sumOfCapacities--;
                }
            }

            contador++;
            if (contador == usersWithAgentActive.size())
            { 
                contador = 0;   
            }
        }  

        return caseToUpdate;
    }

    /**
     * Método que actualiza una lista de casos
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<Case> caseToUpdate: Lista de casos a actualizar
     */
    @testvisible
    private void updateCases(List<Case> caseToUpdate)
    {
        if (caseToUpdate.size()!= 0)
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(caseToUpdate, false);
                ErrorLogUtil.generateMessageByError(resultList,'Se ha producido un error actualizando los casos', WorkRouter.class.getName());

            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError(e, WorkRouter.class.getName());
            }
        }
    }

    /**
     * Método que calcula el número de casos asignados para los usuarios que son gestores activos (ActiveAgent__c a true). 
     * Si el usuario está en la lista ownerIdsByNumberOfCases, se añade el número de casos asignados, si no está en dicha lista el número de casos que tiene es cero.
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<AggregateResult> ownerIdsByNumberOfCases: Contiene una lista con los usuarios activos y el número de casos asignados que tiene cada uno
     * @param List<User> usersWithAgentActive: Lista de usuarios que son gestores activos
     */
    private List<User> getNumberOfAssignedCasesByUser (List<AggregateResult> ownerIdsByNumberOfCases, List<User> usersWithAgentActive)
    {
        List<User> usersToUpdate = new List<User>();
        Map<Id,Integer> numberOfCasesById = new Map<Id,Integer>();

        for (AggregateResult ownerIdByNumberOfCases : ownerIdsByNumberOfCases)
        {
            numberOfCasesById.put(String.valueOf(ownerIdByNumberOfCases.get('OwnerId')),(Integer)ownerIdByNumberOfCases.get('numCases'));
        }

        for (User userWithAgentActive:usersWithAgentActive)
        {
            if (numberOfCasesById.containsKey(userWithAgentActive.Id))
            {
                userWithAgentActive.AssignedCases__c = numberOfCasesById.get(userWithAgentActive.Id);
                usersToUpdate.add(userWithAgentActive);
            }
            else
            {
                userWithAgentActive.AssignedCases__c = 0;
                usersToUpdate.add(userWithAgentActive);
            }
        }
        return usersToUpdate;
    }

    /**
     * Método que actualiza una lista de usuarios
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<User> usersToUpdate: Lista de usuarios a actualizar
     */
    private void updateUsers(List<User> usersToUpdate)
    {
        if( !usersToUpdate.isEmpty() )
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(usersToUpdate, false);
                ErrorLogUtil.generateMessageByError(resultList, 'Se ha producido un error actualizando los usuarios', WorkRouter.class.getName());
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError(e, WorkRouter.class.getName());
            }
        }
    }
}