 /**
 * Clase de servicio para la clase programada Job_WorkRouter y el batch Batch_WorkRouter
 * @author aberuete
 * @date 24/06/2024
 */
public with sharing class WorkRouter 
{
    /**
     * Método que calcula y actualiza el número de casos asignados para los usuarios que son gestores activos (ActiveAgent__c a true)
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<AggregateResult> ownerIdsByNumberOfCases: Contiene una lista con los usuarios activos y el número de casos asignados que tiene cada uno
     */
    public void updateNumberOfCaseByUser (List<AggregateResult> ownerIdsByNumberOfCases)
    {
        //Obtiene los usuarios activos
        List<User> usersWithAgentActive = new UsersSelector().getUsersWithAgentActiveOrderByAssignedCases();
        //Calcula número de casos asignados por usuario
        List<User> usersToUpdate = getNumberOfAssignedCasesByUser (ownerIdsByNumberOfCases, usersWithAgentActive);
        //Actualiza número de casos asignados por usuario
        updateUsers (usersToUpdate);
    }

    /**
     * Método que reparte equitativamente los casos que no tienen gestor preferente (WithoutBestAgent__c sea verdadero) 
     * y cuyo owner sea una cola o el usuario integrador, a los usuarios que son gestores activos (ActiveAgent__c a true) teniendo en cuenta que no 
     * excedan su capacidad siempre y cuando tengan asignada una. 
     * @author: aberuete
     * @date: 27/06/2024
     * @param List<sObject> scope: Lista de casos a actualizar por el batch
     */
    public void assignCasesWithoutBestAgentToActiveAgent(List<sObject> scope)
    {
        Integer sumOfCapacities = 0;
        Boolean anyUserWithCapacityInfinity = false;
        List<Case> casesToAssign = (List<Case>) scope;
        //Obtener los usuarios con gestor activo, obteniendo su capacidad y el número de casos asignados
        List<User> usersWithAgentActive = new UsersSelector().getUsersWithAgentActiveOrderByAssignedCases();
        //Obtener el número de usuarios con gestor activo que no tienen una capacidad asignada
        Integer numberOfUsersWithInfiniteCapacity = new UsersSelector().getNumberOfUsersActiveWithInfiniteCapacity();

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
            List<String> msgErrores = new List<String>();
            try
            {
                Database.SaveResult [] resultList = Database.update(caseToUpdate, false);
                
                for (Database.SaveResult result: resultList )
                {
                    if(!result.isSuccess())
                    {
                        for (Database.Error error :result.getErrors())
                        {
                            msgErrores.add(error.getStatusCode() + ': ' + error.getMessage());
                        }
                    }
                }   
                if (!msgErrores.isEmpty())
                {
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando los casos',WorkRouter.class.getName(),(String.join(msgErrores,'\n')));
                } 
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
        List<String> msgErrores = new List<String>();

        if( !usersToUpdate.isEmpty() )
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(usersToUpdate, false);
                
                for (Database.SaveResult result: resultList )
                {
                    if(!result.isSuccess())
                    {
                        for (Database.Error error :result.getErrors())
                        {
                            msgErrores.add(error.getStatusCode() + ': ' + error.getMessage());
                        }
                    }
                }   
                if (!msgErrores.isEmpty())
                {
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando los usuarios', WorkRouter.class.getName(),(String.join(msgErrores,'\n')));
                } 
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError(e, WorkRouter.class.getName());
            }
        }
    }
}