/**
 * @description       : Clase selectora para el objeto case history
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-26-2023
 * @last modified by  : aberuete
**/
public with sharing class CaseHistorySelector extends RecordsSelector
{
    public CaseHistorySelector()
    {
        super(CaseHistory.getSObjectType());
    }

     /**
     * Aplica el filtro de id del caso, campo que se ha actualizado y tipo de dato para obtener el histórico del caso
     * @author aberuete
     * @date 26/06/2023
     * @param  String caseId : id del caso
     * @param String fieldHistory : campo que se ha actualizado 
     * @param String datatype : tipo de campo que se ha actualizado 
     */
    public List<CaseHistory> findByCaseIdAndFieldAndDatType (String caseId, String fieldHistory, String datatype)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            CaseHistory.Id,
            CaseHistory.OldValue, 
            CaseHistory.NewValue,
            CaseHistory.CaseId
         })
         .selectFields('Case.OwnerId')
         .selectFields('Case.Owner.Name');
         
        if (caseId != null & !String.isBlank(caseId) )
        {
             this.baseQuery.addConditionEq(CaseHistory.CaseId, caseId);
        }

        if (fieldHistory != null & !String.isBlank(fieldHistory))
        {
            this.baseQuery.addConditionEq(CaseHistory.Field, fieldHistory);
        }

        if (datatype != null & !String.isBlank(datatype))
        {
            this.baseQuery.addConditionEq(CaseHistory.DataType, datatype);
        }

        this.baseQuery.orderBy('CreatedDate', 'DESC');

        return (List<CaseHistory>) this.baseQuery.run(); 
    }
}