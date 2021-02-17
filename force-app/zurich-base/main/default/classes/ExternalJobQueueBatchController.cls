public class ExternalJobQueueBatchController
{
    static String basedigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    /**
     * Comprobar si hay external request pendientes de procesar y ejecutar el ExternalJobQueueBatch en caso afirmativo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    public static void checkExternalJobQueueBatch()
    {
        try
        {
            List<AsyncApexJob> queuedJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueJob'});
            List<AsyncApexJob> executingJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueBatch'});

            if( queuedJobs.isEmpty() && executingJobs.isEmpty() )
            {
                System.enqueueJob( new ExternalJobQueueJob(Transformer.ORIGIN_NAME_INFO) );
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'checkExternalJobQueueBatch');
        }
    }

    public static void checkExternalJobPriorityQueueBatch()
    {
        try
        {
            List<AsyncApexJob> executingJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobPriorityQueueBatch'});

            if( executingJobs.isEmpty() ) {
                database.executeBatch(new ExternalJobPriorityQueueBatch(Transformer.ORIGIN_NAME_INFO), 200);
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'checkExternalJobQueueBatchPriority');
        }
    }

    /**
     * Comprobar si hay external request pendientes de procesar y ejecutar el ExternalJobQueueBatch en caso afirmativo
     *
     * @author adelgado
     * @date 19/11/2020
     */
    public static List<String> getChunkQueries(String origin)
    {
        List<String> queries = new List<String>();

        try
        {
            Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(origin).getRecordTypeId();

            List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC');

            if( !firstPendingExtReq.isEmpty() )
            {
                List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC');

                String firstId = firstPendingExtReq.get(0).Id;
                String lastId = lastPendingExtReq.get(0).Id;

                if (firstId != null && lastId != null)
                {
                    String startIdStripped = firstId.left(15).right(9);
                    String endIdStripped = lastId.left(15).right(9);

                    Long startNum = base62decode(startIdStripped);
                    Long endNum = base62decode(endIdStripped);

                    Integer chunkSize;

                    if( (endNum - startNum) < 1000 )
                    {
                        chunksize = 100000;
                    }
                    else
                    {
                        Integer availableJobs = Integer.valueOf(SystemUtil.getAdminSetupMetadata().ExternalJobQueueBatchJobs__c);
                        chunksize = (Integer) (endNum - startNum) / availableJobs;
                    }

                    List<Map<String, String> > chunkList = chunkIdRange(firstId, lastId, chunksize);

                    // avoid the priority entities in the queries
                    String priorityEntities = '';
                    if( INFOHandler.PRIORITY_ENTITIES != null && !INFOHandler.PRIORITY_ENTITIES.isEmpty() ) {
                        priorityEntities = ' AND Entity__c NOT IN ' + INFOHandler.PriorityEntitiesToString;
                    }
                    for(Map<String, String> chunk : chunkList)
                    {
                        String q = 'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\'';
                        q += ' AND Id >= \'' + chunk.get('first') + '\' AND Id <= \'' + chunk.get('last') + '\'';
                        q += ' AND Processed__c = false';
                        q += priorityEntities;

                        queries.add(q);
                    }
                }

                return queries;
            }

            return null;
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, 'ExternalJobQueueBatchController', 'getChunkQueries');
        }

        return null;
    }

    /*
     * BEGIN Base62 encode / decode code
     * This is used to convert salesforce Ids to Integers and back for chunking
     *
     * This code ported from python here: https://gist.github.com/adyliu/4494223
     */
    public static Long base62decode(String s)
    {
        Long ret = 0;
        Long mult = 1;

        String[] chars = s.split('');

        String[] charsReversed = new List<String>();

        for(Integer i = chars.size() - 1; i >= 0; i--)
        {
            charsReversed.add( chars.get(i) );
        }

        for (String c: charsReversed)
        {
            Integer index = basedigits.indexOf(c);

            ret += mult * index;
            mult *= 62;
        }

        return ret;
    }


    public static String base62encode(Long num)
    {
        if (num == 0)
        {
            return '0';
        }

        List<String> retList = new List<String>();

        String[] basedigitsArr = basedigits.split('');

        while (num != 0)
        {
            Integer cIndex = (Integer) Math.Mod(num, 62);
            retList.add(basedigitsArr[cIndex]);
            num = (num / 62);
        }

        List<String> retListReversed = new List<String>();
        for(Integer i = retList.size() - 1; i >= 0; i--)
        {
            retListReversed.add( retList.get(i) );
        }

        return String.join(retListReversed, '');
    }

    /*
     * END Base62 encode / decode code
     */

    /*
     * Take a 15 or 18 digit start and ending salesforce Id and break in into chunk ranges of specified size
     * Only works if all the IDs have the same pod identider
     * Be careful of pod splits, sandbox / production data in a sandbox, etc.
     */
    public static List<Map<String, String> > chunkIdRange(String startId, String endId, Integer chunkSize)
    {
        //grab the beginning of the Id.  we will need to append this back on to the chunked Ids at the end
        String idPrefix = startId.left(6);

        String startIdStripped = startId.left(15).right(9);
        String endIdStripped = endId.left(15).right(9);

        //now we have b62 pieces like this: 00006sfef
        //pass them to the method to decode them into Longs

        Long startNum = base62decode(startIdStripped);
        Long endNum = base62decode(endIdStripped);

        //now pass this to the chunkRange method:
        List<Map<String, String> > numberChunkList = chunkRange(startNum, endNum, 9, chunkSize);

        //now loop through the ranges, base62 encode them, and add the id prefix back in
        List<Map<String, String> > idChunkList = new List<Map<String, String> >();
        for (Map<String, String> chunkMap: numberChunkList)
        {
            Long rangeStart = Long.valueOf( drop_leading_zeros( chunkMap.get('first') ) );
            Long rangeEnd   = Long.valueOf( drop_leading_zeros( chunkMap.get('last') ) );

            String rangeStartB62  = prefixStringWithZeros(base62encode(rangeStart), 9);
            String rangeEndB62    = prefixStringWithZeros(base62encode(rangeEnd), 9);

            idChunkList.add(new Map<String, String> {'first'=> idPrefix + rangeStartB62, 'last'=> idPrefix + rangeEndB62});
        }

        return idChunkList;
    }


    /*
     * This method is used to chunk up a large range of Long Integers into a list of smaller ranges.
     * start number, end number, and size of the chunks is passed in
     */
    public static List<Map<String, String> > chunkRange(Long firstNum, Long lastNum, Integer totalLength, Integer chunkSize)
    {
        //get the range between the two numbers passed in.
        Long range = (lastNum - firstNum);

        List<Map<String, Long> > numChunkList = new List<Map<String, Long> >();

        if (range < chunkSize)
        { //range is already smaller than chunk, just add them all
            numChunkList.add(new Map<String, Long> {'first'=> firstNum, 'last'=> lastNum});
        }
        else
        {
            //need to create multiple chunks

            //chunk the range up into chunks the size of chunkSize
            Decimal numChunks = (range / chunkSize); //figure out how many whole and partial chunks we have
            numChunks = numChunks.round(System.RoundingMode.DOWN); //discard the partial chunk remainder
            Integer numWholeChunks = numChunks.intValue();

            //add the first chunk
            Long firstNumChunk =  firstNum;
            Long lastNumChunk =   firstNum + chunkSize - 1;
            numChunkList.add(new Map<String, Long> {'first'=> firstNumChunk, 'last'=> lastNumChunk});

            //add any remaining chunks
            for (Integer i=1; i < numWholeChunks; i++)
            {
                firstNumChunk = (lastNumChunk + 1);
                lastNumChunk = (firstNumChunk + chunkSize - 1);
                numChunkList.add(new Map<String, Long> {'first'=> firstNumChunk, 'last'=> lastNumChunk});
            }

            //add in the any remaining chunk which is < chunkSize
            Long lastlastNumChunk = numChunkList[numChunkList.size() - 1].get('last'); //get last number from last row of the chunkList
            if (lastlastNumChunk < lastNum)
            {
                numChunkList.add(new Map<String, Long> {'first'=> lastlastNumChunk + 1, 'last'=> lastNum});
            }
        }

        //convert our integer map to a padded string map with 0's so it matches the salesforce Id format
        List<Map<String, String> > numChunkListZeroPadded = new List<Map<String, String> >();
        for (Map<String, Long> rangeMap: numChunkList)
        {
            numChunkListZeroPadded.add(new Map<String, String> { 'first'=> prefixLongWithZeros(rangeMap.get('first'), totalLength),
                                                                 'last' => prefixLongWithZeros(rangeMap.get('last'),  totalLength) });
        }

        return numChunkListZeroPadded;
    }


    /*
     * removes leading zeros from a passed string of numbers or returns NULL when not all numeric characters
     *
     * Source: https://www.interactiveties.com/blog/2011/apex-drop-leading-zeros.php#.VMv5Ml7F9sA
     */
    public static String drop_leading_zeros(String passedValue)
    {
        String return_string = null; //return string for passing back
        if (passedValue != null)
        { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if ( check_chars.matches() )
            { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1)
                { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking)
                    { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1)
                        { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        }
                        else
                        { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0')
                { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            }
            else
            { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }


    public static String prefixStringWithZeros(String sInput, Integer totalLength)
    {
        String sOutput = '';

        if (sInput != null)
        {
            sOutput = sInput + '';
        }

        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = ( totalLength - sOutput.length() );
        if (zerosToAdd > 0)
        {
            for (Integer i=0; i < zerosToAdd; i++)
            {
                sOutput = '0' + sOutput;
            }
        }

        return sOutput;
    }


    public static String prefixLongWithZeros(Long lngInput, Integer totalLength)
    {
        String sOutput = '';

        if (lngInput != null)
        {
            sOutput = lngInput + '';
        }

        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = ( totalLength - sOutput.length() );
        if (zerosToAdd > 0)
        {
            for (Integer i=0; i < zerosToAdd; i++)
            {
                sOutput = '0' + sOutput;
            }
        }

        return sOutput;
    }

}