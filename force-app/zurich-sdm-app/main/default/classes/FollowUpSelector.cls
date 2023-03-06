/**
 * @description       : Clase selectora para el sobject AccountTeamMember
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/
public with sharing class FollowUpSelector extends RecordsSelector
{
    private static final Integer LIMIT_BATCH= 50000;
    
    public FollowUpSelector() 
    {
        super(FollowUp__c.getSObjectType());
    }

     /**
     * Método que recupera los seguimientos cuyo tipo coincida con uno dado y que no hayan sido creados el día de hoy
     * 
     * @author aberuete
     * @date 23/02/2023
     * 
     * @param {String type} tipo de seguimientos para filtrar
     */
    public String findByTypeAndCreatedDateLessThanToday(String type)
    {
        String query = null;
        Datetime today = date.today();
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
                                            {
                                                FollowUp__c.fields.Id,
                                                FollowUp__c.fields.Type__c,
                                                FollowUp__c.fields.CreatedDate
                                            };
        if (type != null)
        {
            this.baseQuery.selectFields(fieldList)
            .addConditionEq(FollowUp__c.fields.Type__c, type)
            .addConditionLt(FollowUp__c.fields.CreatedDate, today)
            .setLimit(LIMIT_BATCH);
            query = this.baseQuery.toQueryString();
        }

        return query;                                    
    }

    /**
     * Método que recupera los seguimientos cuyo tipo coincida con uno dado, que hayan sido creados el día de hoy y cuyo procesamiento coincida con uno dado
     * 
     * @author aberuete
     * @date 06/03/2023
     * 
     * @param {String type} tipo de seguimientos para filtrar
     * @param {Boolean processed} si el seguimiento ha sido procesado o no
     */
    public String findByTypeCreatedDateTodayAndProccessed(String type, Boolean processed)
    {
        String query = null;
        Datetime today = date.today();
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
                                            {
                                                FollowUp__c.fields.Id,
                                                FollowUp__c.fields.Type__c,
                                                FollowUp__c.fields.CreatedDate,
                                                FollowUp__c.fields.Processed__c,
                                                FollowUp__c.fields.Notify__c,
                                                FollowUp__c.fields.Account__c
                                            };
        if (type != null)
        {
            this.baseQuery.selectFields(fieldList)
            .addConditionEq(FollowUp__c.fields.Type__c, type)
            .addConditionEq(FollowUp__c.fields.Processed__c, processed)
            .addConditionGe(FollowUp__c.fields.CreatedDate, today)
            .setLimit(LIMIT_BATCH);
            query = this.baseQuery.toQueryString();
        }

        return query;                                    
    }

    /**
     * Método que recupera el número de seguimientos cuyo tipo coincida con uno dado y que no hayan sido creados en el día de hoy
     * 
     * @author aberuete
     * @date 03/03/2023
     * 
     * @param {String type} tipo de seguimientos para filtrar
     */
    public Integer countByTypeAndCreatedDateLessThanToday (String type)
    {
        Integer numberOfFollowUps = 0;
        Datetime today = date.today();

        if (type != null)
        {
            this.baseQuery
            .addConditionEq(FollowUp__c.fields.Type__c, type)
            .addConditionLt(FollowUp__c.fields.CreatedDate, today);
            numberOfFollowUps = this.baseQuery.countQuery();
        }

        return numberOfFollowUps;
    }

    /**
     * Método que recupera el número de seguimientos cuyo tipo coincida con uno dado, que hayan sido creados en el día de hoy y cuyo procesamiento coincida con uno dado
     * 
     * @author aberuete
     * @date 03/03/2023
     * 
     * @param {String type} tipo de seguimientos para filtrar
     * @param {Boolean processed} si el seguimiento ha sido procesado o no
     */
    public Integer countByTypeCreatedDateTodayAndProcessed (String type, Boolean processed)
    {
        Integer numberOfFollowUps = 0;
        Datetime today = date.today();

        if (type != null)
        {
            this.baseQuery
            .addConditionEq(FollowUp__c.fields.Type__c, type)
            .addConditionEq(FollowUp__c.fields.Processed__c, processed)
            .addConditionGe(FollowUp__c.fields.CreatedDate, today);
            numberOfFollowUps = this.baseQuery.countQuery();
        }

        return numberOfFollowUps;
    }
}