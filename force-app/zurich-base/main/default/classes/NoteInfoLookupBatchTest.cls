/**
 * Test the methods in the class noteInfoLookupBatch
 * 
 * @author nts (agonzalezisasi)
 * @date 28/04/2021
 */
@isTest
private class NoteInfoLookupBatchTest
{

	/**
	 * Offer
	 *      Opportunity -> InfoQuoteNumber__c
	 *      HegeoPrePolicyId__c, HegeoOfferId__c => OfferId__c
	 * Account
	 * 		Account -> INFOIntermediaryCode__c
	 * 		HegeoIntermediaryId__c => AccountId
	 * Policy
	 * 		Policy__c -> InfoPolicyNumber__c
	 * 		HegeoPolicyId__c => PolicyId__c
	 * Claim
	 * 		Claim__c -> INFOClaimNumber__c
	 * 		HegeoClaimId__c => ClaimId__c
	 */
	@testSetup 
	static void makedata()
	{
		// PreOffer + Account
		Case notePreOffer = new Case(Subject= 'note preoffer', Origin=NoteInfoLookupBatch.NOTE_CASE_ORIGIN);
		notePreOffer.HegeoPrePolicyId__c = String.valueOf(1).leftPad(9, '0');
		notePreOffer.HegeoIntermediaryId__c = String.valueOf(1).leftPad(9, '0');
		insert notePreOffer;

		// Offer + Account + Policy + Claim
		Case noteOffer = new Case(Subject= 'note offer', Origin=NoteInfoLookupBatch.NOTE_CASE_ORIGIN);
		noteOffer.HegeoOfferId__c = String.valueOf(2).leftPad(9, '0');
		noteOffer.HegeoIntermediaryId__c = String.valueOf(2).leftPad(9, '0');
		noteOffer.HegeoPolicyId__c = String.valueOf(2).leftPad(9, '0');
		noteOffer.HegeoClaimId__c = String.valueOf(2).leftPad(9, '0');
		insert noteOffer;
	}

	/**
	 * Creates the parents sobject to be found by the batch for the Note (case)
	 * 
	 * @param {Integer i} numeric secuence to create differnt test cases
	 * @param {Boolean bCreatePolicy} if insert a policy (true) or not (false)
	 * @param {Boolean bCreateClaim} if insert a claim (true) or not (false)
	 * @param {Boolean bCreateOffer} if insert an Offer-Opportunity (true) or not (false)
	 */
	private static void generateNoteRelatedData(Integer i, Boolean bCreatePolicy, Boolean bCreateClaim, Boolean bCreateOffer) {
		Account a = new Account(
			LastName= 'acc test note ' + i,
			INFOIntermediaryCode__c= String.valueOf(i).leftPad(9, '0')
		);
		insert a;
	
		if( bCreatePolicy ) {
			Policy__c p = new Policy__c(
				Name= String.valueOf(i).leftPad(9, '0'),
				InfoPolicyNumber__c = String.valueOf(i).leftPad(9, '0')
			);
			insert p;
		}
	
		if( bCreateClaim ) {
			Claim__c c = new Claim__c(
				Name= String.valueOf(i).leftPad(9, '0'),
				InfoClaimNumber__c = String.valueOf(i).leftPad(9, '0')
			);
			insert c;
		}
	
		if( bCreateOffer ) {
			Date d = Date.today().addDays(10);
			Opportunity o = new Opportunity(
				Name= String.valueOf(i).leftPad(9, '0'),
				CloseDate= d,
				StageName= 'Legit Lead',
				InfoQuoteNumber__c= String.valueOf(i).leftPad(9, '0')
			);
			insert o;
		}
	}

	/**
	 * Test of the batch execution
	 */
	@isTest 
	static void execute() {
		generateNoteRelatedData(1, false, false, true);
		generateNoteRelatedData(2, true, true, true);
		
		
		

		Test.startTest();
		NoteInfoLookupBatch m = new NoteInfoLookupBatch();
		Id batchId = Database.executeBatch(m);
		Test.stopTest();

		Case notePreOffer = [SELECT Id, OfferId__c, AccountId FROM Case WHERE Subject = 'note preoffer'];
		System.assertNotEquals(null, notePreOffer.OfferId__c, 'For PreOffer, the OfferId should not be null');
		System.assertNotEquals(null, notePreOffer.AccountId, 'For PreOffer, the AccountId should not be null');
		Case noteOffer = [SELECT Id, OfferId__c, AccountId, PolicyId__c, ClaimId__c FROM Case WHERE Subject = 'note offer'];
		System.assertNotEquals(null, noteOffer.OfferId__c, 'For Offer, the OfferId should not be null');
		System.assertNotEquals(null, noteOffer.AccountId, 'For Offer, the AccountId should not be null');
		System.assertNotEquals(null, noteOffer.PolicyId__c, 'For Offer, the PolicyId should not be null');
		System.assertNotEquals(null, noteOffer.ClaimId__c, 'For Offer, the ClaimId should not be null');
	}

	@isTest
	static void execute_ko()
	{
		generateNoteRelatedData(1, false, false, true);
		
		Test.startTest();
		NoteInfoLookupBatch m = new NoteInfoLookupBatch('Select'); // for coverage
		m = new NoteInfoLookupBatch();
		m.listHegeoExternal[0].parentSObjectName = 'invalid';
		Id batchId = Database.executeBatch(m);
		Test.stopTest();

		List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
		System.assertEquals(true, errors.size() > 0, 'There should be errors');
	}

	/**
	 * Test of the batch scheduling
	 */
	@isTest 
	static void schedule() {
		NoteInfoLookupBatch m = new NoteInfoLookupBatch();
		String sch = '20 30 8 10 2 ?';

		Test.startTest();
		String jobID = system.schedule('Test Note Info Lookup batch', sch, m);
		Test.stopTest();
		
	}
}