/**
 * Clase programable que calcula el número de casos que tiene asignado cada gestor activo y asigna equitativamente los casos marcados 
 * que no tienen gestor preferente (WithoutBestAgent__c) a los usuarios que son gestores activos (ActiveAgent__c) 
 * teniendo en cuenta la capacidad de los usuarios. 
 * @author aberuete
 * @date 27/06/2024
 */
public with sharing class Job_WorkRouter implements Schedulable 
{
    public void execute(SchedulableContext sc) 
    {
        //Obtiene usuarios con gestor activo junto con el número de casos que tienen asignados
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();

        //Actualización del número de casos por cada usuario con gestor activo
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);

        // Llamadada al batch que gestiona la asignación de casos a los usuarios con gestor activo
        Batch_WorkRouter batch = new Batch_WorkRouter();
        Database.executeBatch(batch, 2000);
    }
}