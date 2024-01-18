/**
 * @description       : Batch que permite el borrado de registros de una entidad de Salesforce a partir de un campo.
 *                      El algoritmo recogera valores desde el recurso estático indicado y elimina los registros que
 *                      encuentre a partir de esos valores en el campo indicado.
 * @author            : lrodriguez
 * @group             : Seidor
 * @last modified on  : 05/09/2023
 * @last modified by  : jgallaga
 **/
global with sharing class DeleteRecordsByFieldBatch implements Database.Batchable<SObject>
{
    private String staticResourceName;
    private String sObjectName;
    private String sObjectFieldName;

    @TestVisible
    private static final String NULL_PARAMETER_EXCEPTION_MSG = 'El parametro no puede ser nulo o vacío.';

    global DeleteRecordsByFieldBatch(String staticResource, Schema.SObjectField sObjectField)
    {
        if( String.isBlank(staticResource) )
        {
            throw new IllegalArgumentException(NULL_PARAMETER_EXCEPTION_MSG + ' -> [0:String] staticResourceName');
        }

        if(sObjectField == null)
        {
            throw new IllegalArgumentException(NULL_PARAMETER_EXCEPTION_MSG + ' -> [1:Schema.SobjectField] sObjectField');
        }

        staticResourceName  = staticResource;
        sObjectName         = sObjectField.getDescribe().getSObjectType().getDescribe().getName();
        sObjectFieldName    = sObjectField.getDescribe().getName();
    }

    global Database.QueryLocator start(Database.BatchableContext context)
    {
        String querySR = 'SELECT Id, Name, Body FROM StaticResource WHERE Name =\'' + staticResourceName + '\'';
        List<StaticResource> docs = Database.query(querySR);

        if ( docs.isEmpty() )
        {
            throw new QueryException('There are no Static Resources with the provided name');
        }

        StaticResource theDocument  = (StaticResource) docs.get(0);
        String nameFile             = blobToString(theDocument.Body,'ISO-8859-1');
        List<String> filelines      = nameFile.split('\n');

        //Read these names and from them, retrieve the ids of the offers
        List<String> idsToDelete = new List<String>();
        for (Integer i=0; i < filelines.size(); i++)
        {
            List<String> inputvalues = new List<String>();
            inputvalues = filelines[i].split(',');

            String auxiliar = inputvalues.get(0);
            auxiliar        = auxiliar.trim();

            idsToDelete.add(auxiliar);
        }

        String queryObject = 'SELECT Id FROM ' + sObjectName + ' WHERE ' + sObjectFieldName + ' = :idsToDelete';
        return Database.getQueryLocator(queryObject);
    }

    global void execute(Database.BatchableContext context, List<SObject> recordsToDelete)
    {
        List<Error_Log__c> errors = new List<Error_Log__c>();

        Database.DeleteResult[] resultadoBorrado = Database.delete(recordsToDelete, false);

        for(Database.DeleteResult dr : resultadoBorrado)
        {
            if ( !dr.isSuccess() )
            {
                errors.add(
                    new Error_Log__c(
                        Message__c = dr.getErrors().get(0).getMessage() + dr.getErrors().get(0).getFields(),
                        Source_Class__c = 'Batch_DeleteFields',
                        Source_Method__c = 'Execute',
                        Level__c = 'Error',
                        Record_External_ID__c = dr.getId(),
                        Record_Object__c = sObjectName
                        )
                    );
            }
        }

        if ( !errors.isEmpty() )
        {
            Database.insert(errors, false);
        }
    }

    global void finish(Database.BatchableContext context)
    {
        AsyncApexJob ejecucionBatchBorrado = [Select Id, Status, CreatedBy.Email from AsyncApexJob where Id =: context.getJobId()];

        // Enviamos un mail informando de que se ha completado el batch
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {ejecucionBatchBorrado.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Delete Fields Batch ' + ejecucionBatchBorrado.Status);
        mail.setPlainTextBody('Records processed.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
     * This function convers the input CSV file in BLOB format into a string
     * @param input
     *              Blob data representing correct string in @inCharset encoding
     * @param inCharset
     *              Encoding of the Blob data (for example 'ISO 8859-1')
     */
    global static String blobToString(Blob input, String inCharset)
    {
        String hex = EncodingUtil.convertToHex(input);

        Integer bytesCount = hex.length() >> 1;

        String[] bytes = new String[bytesCount];

        for(Integer i = 0; i < bytesCount; ++i)
        {
            bytes[i] =  hex.mid(i << 1, 2);
        }

        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }
}