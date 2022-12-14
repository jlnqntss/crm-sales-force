/**
 * Batch that calculates the lookup fields of Notes (Case of origin equal to NoteInfo) for when the parents comes
 * after the Note has been inserted in Salesforce
 * 
 * @author nts (agonzalezisasi)
 * @date 27/04/2021
 *
 */
global class NoteInfoLookupBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts
{
    @testvisible
    private static final String NOTE_CASE_ORIGIN = 'NoteINFO';
    private static final String SETTINGS_LAST_N_DAYS = 'BatchNoteInfoLookupLastNdays';
    private static final Integer DEFAULT_LAST_N_DAYS = 7;

    private String query;
    private Integer last_n_days;
    @testvisible
    private List<HegeoExternal> listHegeoExternal;

    /**
     * Constructor
     */
    global NoteInfoLookupBatch()
    {
        // Get the Last N days from the metadata configuration
        List<AdminSetupParameter__mdt> settings = [SELECT Id, Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :SETTINGS_LAST_N_DAYS];
        last_n_days = (!settings.isEmpty() ? Integer.valueOf(settings[0].Value__c) : DEFAULT_LAST_N_DAYS);

        // Configure the Hegeo fields in the Note with the equivalences with the Parents
        // Offer
        //      Opportunity -> InfoQuoteNumber__c 
        //      HegeoPrePolicyId__c, HegeoOfferId__c => OfferId__c
        // Policy
        //      Policy__c -> InfoPolicyNumber__c
        //      HegeoPolicyId__c => PolicyId__c
        // Claim
        //      Claim__c -> INFOClaimNumber__c
        //      HegeoClaimId__c => ClaimId__c
        // Account
        //      Account -> INFOIntermediaryCode__c
        //      HegeoIntermediaryId__c => AccountId
        listHegeoExternal = new List<HegeoExternal>();
        
        listHegeoExternal.add(new HegeoExternal('HegeoPrePolicyId__c', 'OfferId__c', 'Opportunity', 'InfoQuoteNumber__c'));
        listHegeoExternal.add(new HegeoExternal('HegeoOfferId__c', 'OfferId__c', 'Opportunity', 'InfoQuoteNumber__c'));
        listHegeoExternal.add(new HegeoExternal('HegeoPolicyId__c', 'PolicyId__c', 'Policy__c', 'InfoPolicyNumber__c'));
        listHegeoExternal.add(new HegeoExternal('HegeoClaimId__c', 'ClaimId__c', 'Claim__c', 'INFOClaimNumber__c'));
        listHegeoExternal.add(new HegeoExternal('HegeoIntermediaryId__c', 'AccountId', 'Account', 'INFOIntermediaryCode__c'));
    }

    /**
     * Constructor. Use a custom query
     */
    global NoteInfoLookupBatch(String p_query)
    {
        this();

        if ( !String.isBlank(p_query) ) {
            query = p_query;
        }
    }

    /**
     * Start. Execute the query locator for the batch
     */
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if( String.isBlank(query) ) {
            // Get the configured fields for the query
            List<String> conditions = new List<String>();
            Set<String> fields = new Set<String>();
            for(HegeoExternal hegeo: listHegeoExternal) {
                // Select fields
                fields.add(hegeo.noteHegeoFieldName);
                fields.add(hegeo.noteParentIdFieldName);
                // where conditions
                conditions.add(hegeo.condition);
            }
            
            // Format the soql query for the Notes
            query = 'SELECT Id, ' + String.join(new List<String>(fields), ',') +
                 ' FROM Case WHERE Origin = \''+ NOTE_CASE_ORIGIN + '\'' + 
                 ' AND CreatedDate >= LAST_N_DAYS:' + last_n_days +
                 ' AND (' + String.join(conditions, ' OR ') + ')';
        }

        return Database.getQueryLocator(query);
    }

    /**
     * Execute. The method for the scheduled batch
     */
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new NoteInfoLookupBatch(query), 200);
    }

    /**
     * Execute. The method for each batch
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() ) {
            try {
                List<Case> notesScope = (List<Case>)scope;
                List<Case> notesToUpdate = new List<Case>();

                // 0. Clear the list of external Ids and map of external ids and SF ids for each hegeo field
                for(HegeoExternal hegeo: listHegeoExternal) {
                    hegeo.clear();
                }

                // 1. Get the list of external ids for each hegeo field
                for (Case note : notesScope) {
                    for(HegeoExternal hegeo: listHegeoExternal) {
                        // Check that has Hegeo external id but not the look up field
                        hegeo.checkNote(note);
                    }
                }

                // 2. Get the SF ids of the parents (soql parent sobjects)
                for(HegeoExternal hegeo: listHegeoExternal) {
                    hegeo.searchParents();
                }

                // 3. Assign the parent ids, if found, to the Note (case)
                for (Case note: notesScope ) {
                    Boolean isParentFound = false;
                    Case noteToUpdate = new Case(Id= note.Id);

                    // for each hegeo field
                    for(HegeoExternal hegeo: listHegeoExternal) {
                        if( hegeo.checkParent(note, noteToUpdate) ) {
                            isParentFound = true;
                        }
                    }

                    // if any parent found
                    if( isParentFound ) {
                        notesToUpdate.add(noteToUpdate);
                    }
                }

                // Updates the notes
                if( !notesToUpdate.isEmpty() ) update notesToUpdate;
            } catch (Exception e) {
                ErrorLogUtil.commitError(e, 'NoteInfoLookupBatch');
            }
        }
    }

    /**
     * Finish. The postprocesing method
     */
    global void finish(Database.BatchableContext bc)
    {}

    //-------------------------------------------------------------------------

    /**
     * Helper Class. Represents each hegeo field in the Note SObject (case) and its relation with the parent SObject
     * (Offer, Policy, Claim, Account)
     */
    private class HegeoExternal {
        String noteHegeoFieldName;
        String noteParentIdFieldName;

        @testvisible
        String parentSObjectName;
        String parentExtidFieldName;

        List<String> externalIds;
        Map<String, ID> mapParentIds;

        String condition {
            get {
                return '(' + noteHegeoFieldName + ' != null AND ' + noteParentIdFieldName + ' = null)';
            }
        }

        /**
         * Constructor
         */
        public HegeoExternal(String noteHegeoFieldName, String noteIdFieldName, String sObjectName, String idFieldName) {
            this.noteHegeoFieldName = noteHegeoFieldName;
            this.noteParentIdFieldName = noteIdFieldName;
            this.parentSObjectName = sObjectName;
            this.parentExtidFieldName = idFieldName;

            this.externalIds = new List<String>();
            this.mapParentids = new Map<String, ID>();
        }

        /**
         * Get the list of hegeo external ids if the note have the external id but not the lookup parent id
         * 
         * @author nts (agonzalezisasi)
         * @date 28/04/2021
         * 
         * @param {Case note}  the note
         */
        public void checkNote(Case note) 
        {
            String noteHegeoValue = (String)note?.get(this.noteHegeoFieldName);
            ID noteIdValue = (ID)note?.get(this.noteParentIdFieldName);

            if( String.isNotBlank(noteHegeoValue) && noteIdValue == null ) {
                externalIds.add(noteHegeoValue);
            }
        }

        /**
         * Check if the note has external id, not look up and the parent id is found. If so, fill the ID into a cloned
         * Note to update it
         * 
         * @author nts (agonzalezisasi)
         * @date 28/04/2021
         * 
         * @param {Case note} the original note
         * @param {Case noteToUpdate} the sobject to update if the parent is found (same id as the original note)
         * @return {Boolean} if the parent is found (true) or not (false)
         */
        public Boolean checkParent(Case note, Case noteToUpdate)
        {
            Boolean isParentFound = false;
            String noteHegeoValue = (String)note?.get(this.noteHegeoFieldName);
            ID noteIdValue = (ID)note?.get(this.noteParentIdFieldName);

            if( String.isNotBlank(noteHegeoValue) && noteIdValue == null && mapParentIds.containsKey(noteHegeoValue) ) {
                this.mapParentIds.get(noteHegeoValue);
                if( noteToUpdate != null )
                    noteToUpdate.put(this.noteParentIdFieldName, this.mapParentIds.get(noteHegeoValue));
                isParentFound = true;
            }

            return isParentFound;
        }

        /**
         * Get a map of hegeo external id with look up parent id
         * 
         * @author nts (agonzalezisasi)
         * @date 28/04/2021
         */
        public void searchParents()
        {
            mapParentIds = parentSelection(externalIds, parentSObjectName, parentExtidFieldName);
        }

        /**
         * Clear the list of hegeo external ids
         * 
         * @author nts (agonzalezisasi)
         * @date 28/04/2021
         */
        public void clear()
        {
            this.externalIds.clear();
            this.mapParentIds.clear();
        }

        /**
         * Get the IDs of the parent object from the list of given hegeo external ids
         * 
         * @author nts (agonzalezisasi)
         * @date 28/04/2021
         * 
         * @param {List<String infoNumbers}  the list of external ids
         * @param {String sobjectName} the name of the SObject in SF to search for the lookup id
         * @param {String infoExtfieldName}  the name of the external id field in the parent SObject
         * @return {Map<String, ID>} a map with the relation between the external id and the SF id
         */
        private Map<String, ID> parentSelection(List<String> infoNumbers, String sobjectName, String infoExtFieldName)
        {
            Map<String, ID> result = new Map<String, ID>();

            if( infoNumbers != null && !infoNumbers.isEmpty() ) {
                String soql = String.format('SELECT Id, {0} FROM {1} WHERE {0} IN :infoNumbers', new List<String>{infoExtFieldName, sobjectName});
                List<SObject> results = Database.query(soql);
                for(SObject o: results) {
                    result.put((String)o.get(infoExtFieldName), (ID)o.get('Id'));
                }
            }

            return result;
        }
    }
}