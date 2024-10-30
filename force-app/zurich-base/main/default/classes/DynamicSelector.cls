/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 16-07-2024
 * @last modified by  : lgonzalez
**/
public with sharing class DynamicSelector extends RecordsSelector {

    public DynamicSelector(SObjectType objectName)
    {
        super(objectName);
    }

    /**
     * Método utilizado por el GetRecordsExportButton para obtener el registro del metadato Export_CSV_Field__mdt
     * correspondiente al objeto cuyos registros se quieren exportar 
     * @author lrodriguez6@seidor.es
     * @date 28/10/2024
     * @param String objectName para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public List<Export_CSV_Field__mdt> getQueryStringMetadataInfoToExport(String objectName)
    {
        if(objectName != null && !String.isBlank(objectName) ){
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Export_CSV_Field__mdt.Id,
                Export_CSV_Field__mdt.FieldToExport__c,
                Export_CSV_Field__mdt.Labels__c
            })
            .addConditionEq(Export_CSV_Field__mdt.Object__c,objectName);
          
            return (List<Export_CSV_Field__mdt>) this.baseQuery.run();
        }
        else{
            return new List<Export_CSV_Field__mdt>();
        }
    }

    /**
     * Método utilizado por el GetRecordsExportButton para obtener los datos
     * correspondiente al objeto a los registros se quieren exportar 
     * @author lrodriguez6@seidor.es
     * @date 30/10/2024
     * @param String fieldsQuery(campos a exportar),objetExportName(objeto del que se obtienen),flowInputs(ids de los registros a exportar)
     * @return String query que se va a lanzar en el batch
     */
    public List<SObject> getListSobjectToExport(String fieldsQuery, String objetExportName,List<String> flowInputs) 
    {
        List<SObject> result = new List<SObject>();
        if (fieldsQuery != null && String.isNotEmpty(fieldsQuery) && objetExportName != null && String.isNotEmpty(objetExportName) && flowInputs!=null ){
            String query= 'SELECT '+ fieldsQuery +' '+'FROM '+ objetExportName +' WHERE Id IN: flowInputs';
            result = Database.query(query);
        }
        return result;
    }

}