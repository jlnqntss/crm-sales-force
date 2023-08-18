global class Batch_DeleteFields implements Database.Batchable<SObject>, Schedulable {

    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    String[] filelines = new String[]{};

    List<String> idToDelete;
    String auxiliar;

    String nameSR;
    String fieldToDelete;
    String nameObject;

    
    global Batch_DeleteFields(List<String> parame)
    {
        if (parame!=null)
        {
            //nombre del recurso estático
            nameSR=parame[0];
            //nombre del campo a borrar
            fieldToDelete= parame[1];
            //nombre del objeto donde esta ese campo
            nameObject= parame[2];

        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        //Names of offers to be deleted are retrieved
        List<StaticResource> docs;
        String querySR = 'SELECT Id, Name, Body FROM StaticResource WHERE Name =\'' + nameSR + '\'';
        docs = Database.query(querySR);
        StaticResource theDocument = (StaticResource)docs.get(0);
        nameFile =blobToString( theDocument.Body,'ISO-8859-1');
        filelines = nameFile.split('\n');

        //Read these names and from them, retrieve the ids of the offers
        idToDelete= new List<String>();
        for (Integer i=0;i<filelines.size();i++)
        {
            String[] inputvalues = new String[]{};
            inputvalues = filelines[i].split(',');
            
            auxiliar = inputvalues[0];
            auxiliar=auxiliar.trim();
            idToDelete.add(auxiliar);
        }


        string queryObject='SELECT Id FROM ' + nameObject+ ' WHERE '+ fieldToDelete+ ' =:idToDelete';

        return Database.getQueryLocator(queryObject);
    }
    
    global void execute(Database.BatchableContext context, List<SObject> records) {
       
        try{
            
        delete records;}
        catch(Exception e){
            System.debug('Error al borrar : '+e.getMessage());
            System.debug('Lugar del error : '+e.getStackTraceString());
        }

    } 
    
    global void finish(Database.BatchableContext context) {
        System.debug('Borrado OK');
    }
    
    global void execute(SchedulableContext context) {
        Database.executeBatch(this, 200);
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