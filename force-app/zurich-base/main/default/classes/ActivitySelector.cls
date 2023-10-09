/**
 * Clase Apex que encapsula las consultas a BBDD a realizar sobre el objeto Activity y permite la búsqueda y consulta sobre los objetos Task y Event
 * Consideraciones
 * Todas las consultas por defecto recuperarán Id, Status y OwnerId como campos por defecto
 * Salvo referencia explícita, los resultados de la consulta deben ordenarse por SystemModstamp de forma descendente.
 */
public without sharing class ActivitySelector
{
    private static String getFieldListString()
    {
        return ' Id, Status, OwnerId, CallObject, WhatId, WhoId ';
    }
    private static String getSObjectName()
    {
        return ' Task ';
    }
    private static String getOrderBy()
    {
        return ' SystemModstamp DESC ';
    }

    public ActivitySelector()
    {}

    /**
     * Obtiene un listado de tareas a través de un listado de InteractionIds
     * @param interactionIds: Listado de interactionIds.  Si null, devolver Lista vacía.
     * @return Listado de tareas, ordenado de forma descendente por SystemModstamp
     * @author nescudero
     * @date 27/10/2020
     */
    public static List<Task> selectTasksByCallObjectIdentifier(List<String> interactionIds)
    {
        //Devolver lista vacía
        if ( interactionIds == null || interactionIds.isEmpty() )
        {
            return new List<Task>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE CallObject IN :interactionIds ORDER BY {2}',
            new List<String> { getFieldListString(), getSObjectName(), getOrderBy() }
            );

        return (List<Task>) Database.query(query);
    }

    /**
     * Obtiene un listado de tareas a través de un InteractionId
     * @param interactionId: Id. de interacción a buscar. Si null, devolver Lista vacía.
     * @return Listado de tareas, ordenado de forma descendente por SystemModstamp
     * @author nescudero
     * @date 27/10/2020
     */
    public static List<Task> selectTasksByCallObjectIdentifier(String interactionId)
    {
        return selectTasksByCallObjectIdentifier(new List<String> {interactionId});
    }

    /**
     * Obtiene un listado de tareas a través de un Id
     * @param taskIds: Ids. de tarea a recuperar a buscar. Si null, devolver Lista vacía.
     * @return Listado de tareas, ordenado de forma descendente por SystemModstamp
     * @author nescudero
     * @date 27/10/2020
     * @change aberuete - 26/07/2023 - Se añade un campo a devolver por la query
     */
    public static List<Task> selectTasksById(Set<Id> taskIds)
    {
        if(taskIds == null || taskIds.isEmpty() )
        {
            return new List<Task>();
        }

        return [SELECT Id, WhoId, WhatId,IsVisibleInSelfService FROM Task WHERE Id IN : taskIds];
    }


    /**
     * Obtiene un listado de tareas no completas a través de un whatId 
     * @param whatIds: Ids. de objetos relacionados a recuperar a buscar. Si null, devolver Lista vacía.
     * @return Listado de tareas
     * @author dmunoz
     * @date 06/10/2023
     */
    public static List<Task> selectOpenTasksByWhatId(Set<Id> whatIds)
    {
        if(whatIds == null || whatIds.isEmpty() )
        {
            return new List<Task>();
        }

        return [SELECT Id, Status FROM Task WHERE WhatId IN : whatIds];
    }
}