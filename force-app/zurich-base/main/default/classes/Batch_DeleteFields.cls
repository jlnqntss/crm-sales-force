global class Batch_DeleteFields implements Database.Batchable<SObject> {

    String nameSR;
    String fieldToDelete;
    String nameObject;

    public Batch_DeleteFields(String nameSR, String fieldToDelete, String nameObject)
    {
        this.nameSR = nameSR;
        this.fieldToDelete = fieldToDelete;
        this.nameObject = nameObject;
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        //Names of offers to be deleted are retrieved
        String querySR = 'SELECT Id, Name, Body FROM StaticResource WHERE Name =\'' + nameSR + '\'';
        List<StaticResource> docs = Database.query(querySR);
        StaticResource theDocument = (StaticResource)docs.get(0);
        String nameFile = blobToString(theDocument.Body,'ISO-8859-1');
        String[] filelines = nameFile.split('\n');

        //Read these names and from them, retrieve the ids of the offers
        List<String> idToDelete = new List<String>();
        for (Integer i=0;i<filelines.size();i++)
        {
            String[] inputvalues = new String[]{};
            inputvalues = filelines[i].split(',');
            
            String auxiliar = inputvalues[0];
            auxiliar = auxiliar.trim();
            idToDelete.add(auxiliar);
        }

        string queryObject='SELECT Id FROM ' + nameObject+ ' WHERE '+ fieldToDelete+ ' =:idToDelete';
        return Database.getQueryLocator(queryObject);
    }
    
    global void execute(Database.BatchableContext context, List<SObject> recordsToDelete) 
    {       
        List<Error_Log__c> errors = new List<Error_Log__c>();
        Database.DeleteResult[] resultadoBorrado = Database.delete(recordsToDelete, false);

        for(Database.DeleteResult dr : resultadoBorrado) 
        {
            if (!dr.isSuccess()) 
            {
                errors.add(
                new Error_Log__c(
                    Message__c = dr.getErrors().get(0).getMessage()+dr.getErrors().get(0).getFields(),
                    Source_Class__c = 'Batch_DeleteFields',
                    Source_Method__c = 'Execute',
                    Level__c = 'Error',
                    Record_External_ID__c = dr.getId(),
                    Record_Object__c = nameObject
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
        AsyncApexJob a = [Select Id, Status, CreatedBy.Email from AsyncApexJob where Id =:context.getJobId()];

        // Enviamos un mail informando de que se ha completado el batch
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Delete Fields Batch ' + a.Status);
        mail.setPlainTextBody('Records processed.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    /**
         This function convers the input CSV file in BLOB format into a string
        @param input    Blob data representing correct string in @inCharset encoding
        @param inCharset    encoding of the Blob data (for example 'ISO 8859-1')
     */
    global static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }         
 
 }