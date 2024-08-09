public with sharing class TaskSelector extends RecordsSelector
{

    //#region Contructores

    public TaskSelector()
    {
        super(Task.getSObjectType());
    }

    //#endregion

    /**
     * Método utilizado por Batch_CloseInteractions para obtener las tareas vinculadas a los casos 
     * @author lrodriguez6@seidor.es
     * @param List<Case> listaCasos, casos afectados por el Batch
     * @date 12/02/2024
     * @return Lista de Tareas relacionadas con los casos 
     */
    public List<Task> getTaskRelatedWithCases(List<Case> listaCasos)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Task.Id,
            Task.CallObject
        })
        .addConditionIn(Task.WhatId,listaCasos)
        .addConditionEq(Task.Type,'Email')
        .addConditionEq(Task.Subtype__c,'Note Info');

        return (List<Task>) this.baseQuery.run();        
    }

    /**
     * Método utilizado para obtener las tareas vinculadas a los casos que se han creado por Canal Unico
     * @author arcortazar
     * @param List<Case> listaCasos, casos afectados por el Batch
     * @date 12/02/2024
     * @return Lista de Tareas relacionadas con los casos 
     */
    public List<Task> getTaskFromSingleChannel(List<Case> listaCasos)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Task.Id,
            Task.CallObject
        })
        .addConditionIn(Task.WhatId,listaCasos)
        .addConditionEq(Task.Type,'Email')
        .addConditionEq(Task.Subtype__c,'Single channel');

        return (List<Task>) this.baseQuery.run();        
    }

    /**
     * Método que devuelve las tareas relacionadas con los registros de whatId
     * @author ivan
     * @date 12/04/2024
     * @return Lista de Tareas relacionadas con
     */
    public List<Task> getTaskRelatedWithWhatId(List<String> recordIds)
    {        
        List<Task> result = new List<Task>();

        if (recordIds != null && !recordIds.isEmpty()) {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Task.Id,
                Task.WhatId
            })
            .addConditionIn(Task.WhatId, recordIds);
    
            result = this.baseQuery.run();   
        }

        return result; 
    }

    /**
     * Método que recupera las tareas para callbacks futuros asociadas a un whoId
     * 
     * @author fpalomo
     * @date 12/04/2024
     * 
     *  SELECT WhoId, CallObject
     *  FROM Task
     *  WHERE RecordType.DeveloperName = 'Interaction'
     *      AND CallDisposition = 'Agendar'
     *      AND CallType = 'Outbound'
     *      AND CreatedBy.Profile.Name = 'Ventas User'
     *      AND ActivityDate >= TODAY
     *      AND WhoId = :whoIdSet
     */
    public List<Task> getCallbackTasksByWhoIdSet(Set<String> whoIdSet)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Task.WhoId,
            Task.CallObject,
            Task.Status,
            Task.Description
        })
        .addConditionIn(Task.WhoId, whoIdSet)
        .addConditionEq('RecordType.DeveloperName', 'Interaction')
        .addConditionEq(Task.CallDisposition, 'Agendar')
        .addConditionEq(Task.CallType, 'Outbound')
        .addConditionEq('Task.CreatedBy.Profile.Name', ProfilesSelector.PROFILE_VENTAS_USER)
        .addCondition(
            Query.doOr(
                Query.conditionGt(Task.ActivityDate, System.today()),
                Query.conditionEq(Task.ActivityDate, System.today())
            )
        );

        return (List<Task>) this.baseQuery.run();
    }
}