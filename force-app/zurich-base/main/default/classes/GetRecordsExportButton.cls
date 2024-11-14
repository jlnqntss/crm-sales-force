public with sharing class GetRecordsExportButton
{
     @InvocableMethod
     (  
        label = 'Botón exportar registros desde vista de lista' 
        description = 'A partir de este botón se pueden exportar desde una vista de lista los registros que hayan sido seleccionados por el usuario'
     )

     public static void getRecordsExportButton(List<List<String>> flowInputs)
    {
        getRecordExport(flowInputs[0]);
    }

     public static ContentVersion getRecordExport(List<String> flowInputs)
    {
        String infoRecordsDisplay, fieldsQuery;
        Export_CSV_Field__mdt metadataFieldObject = new Export_CSV_Field__mdt();

        Id idObjetToExport = (Id) flowInputs[0]; 
        // Se recupera el tipo de dato del objeto de la lista de vista desde la que se inicia la acción.
        String objetExportName = getObjectTypeRecordsToExport(idObjetToExport);
        //Se recupera el registro de metadato correcto en función del objeto a exportar         
        List<Export_CSV_Field__mdt> listaMetadataFieldObject= new DynamicSelector(metadataFieldObject.getsobjectType()).getQueryStringMetadataInfoToExport('Case');
        metadataFieldObject=listaMetadataFieldObject[0];
        //Campos solicitados en Query
        fieldsQuery = metadataFieldObject.FieldToExport__c.replace(';',',');
        //Cabeceras fichero Excel 
        infoRecordsDisplay=metadataFieldObject.Labels__c+ '\n';
        List<SObject> listRecords= new DynamicSelector(idObjetToExport.getsobjectType()).getListSobjectToExport(fieldsQuery,objetExportName,flowInputs);
        //Split campos para obtener su valor desde el Sobject 
        List<String> fieldsQueryList = fieldsQuery.split(',');
        // Agrega los datos de cada registro al CSV
        infoRecordsDisplay=buildCSV(listRecords,fieldsQueryList,infoRecordsDisplay);
       
        // Crea un adjunto
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Export.csv';
        contentVersion.PathOnClient = 'Export.csv';
        contentVersion.VersionData = Blob.valueOf(infoRecordsDisplay);
        insert contentVersion;

        return ContentVersion;

    }

    Public static String getObjectTypeRecordsToExport(Id idObjetToExport)
    {
        Schema.SObjectType sObjectToExpost = idObjetToExport.getsobjectType().newSobject(idObjetToExport).getSObjectType();
        String objetExportName = sObjectToExpost.getDescribe().getName();
        
        return objetExportName;
    }


    Public static String buildCSV(List<SObject> listRecords,List<String> fieldsQueryList, String infoRecordsDisplay )
    {
       for (SObject record : listRecords)
        {
            List<String> values = new List<String>();

            for (String fieldName : fieldsQueryList)
            {
                Object fieldValue;
                //Se hace Split del String que almacena el nombre del campo para saber que campos son del objeto directo
                // y cuales se obtienen de un objeto relacionado
                List<String> otherObject = fieldName.split('\\.');

                if(otherObject.size()==2)
                {   
                    String objectName = otherObject[0];
                    String relatedFieldName = otherObject[1];

                    SObject parentObject = record.getSObject(objectName);
                    if(parentObject!=null){
                    fieldValue= parentObject.get(relatedFieldName);}
                }
                else
                {
                    fieldValue = record.get(fieldName);
                }

                values= obtainFormattedValues(fieldValue,values);
                    
            }
            infoRecordsDisplay += String.join(values,';') + '\n';
        }
            return infoRecordsDisplay;
    }


    public static List<String> obtainFormattedValues(Object fieldValue,List<String> values)
    {
        // Maneja formatos de los campos
        String formattedValue = fieldValue == null ? '' : (fieldValue instanceof Date ? ((DateTime)fieldValue).format('yyyy-MM-dd') : String.valueOf(fieldValue));
        formattedValue = formattedValue.replace('\n', ''); 
        Boolean isValidDecimal = true;

        if(formattedValue != null)
        {

            try
            {
                Decimal.valueOf(formattedValue);
                formattedValue=formattedValue.replace('.',',');
            }
            catch(TypeException e)
            {
                isValidDecimal = false; 
            }
        }
        values.add(formattedValue);

        return values;
    }

}