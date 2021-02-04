/**
 * Clases de test para ContentDocumentLinkUtil
 **
 * @author rlopez
 * @date 26/01/2021
 */
@isTest(SeeAllData=false)
private with sharing class ContentDocumentLinkUtilTest
{
    public static final String FAKE_FROM_ADDRESS = 'from@fakeemail.com.invalid';
    public static final String FAKE_TO_ADDRESS = 'to@fakeemail.com.invalid';
    //Type;Subtype__c;TypeN3__c;HegeoProductGroupCode__c;HegeoOfferId__c;HegeoPrePolicyId__c;HegeoPolicyId__c;HegeoReceiptNumber__c;HegeoClaimId__c;AccountId
    
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 1);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 1);
        insert policies;

        List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy('Address', policies, 1);
        insert insuredObjects;

        List<Claim__c> claims = TestDataFactory.generateClaimsForEachPolicyInsuredObject(policies, insuredObjects, 1);
        insert claims;
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointEmail marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito
     *
     * @author rlopez
     * @date 26/01/2021
     */
    @isTest
    static void test_email2case_hegeo_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c
            FROM Robot_Hegeo_Setting__mdt
        ];
        System.assertEquals(false, robotHegeoSettings.isEmpty(), 'List should not be empty');

        //Cargamos los valores del mapeo de tipificación
        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = [
            SELECT Id, Type__c, Subtype__c, TypeN3__c, SourceType__c, SourceSubtype__c
            FROM Robot_Hegeo_Field_Mapping__mdt
        ];
        System.assertEquals(false, robotHegeoFieldsMapping.isEmpty(), 'List should not be empty');

        Map<String, Map<String, String>> caseTypesMap = new Map<String, Map<String, String>>();
        for(Robot_Hegeo_Field_Mapping__mdt fieldMapping: robotHegeoFieldsMapping)
        {
            Map<String, String> typeValuesMap = new Map<String, String>();
            if(String.isNotBlank(fieldMapping.Type__c))
            {
                typeValuesMap.put('Type', fieldMapping.Type__c);
            }
            if(String.isNotBlank(fieldMapping.Subtype__c))
            {
                typeValuesMap.put('Subtype__c', fieldMapping.Subtype__c);
            }
            if(String.isNotBlank(fieldMapping.TypeN3__c))
            {
                typeValuesMap.put('TypeN3__c', fieldMapping.TypeN3__c);
            }

            caseTypesMap.put(fieldMapping.SourceType__c + fieldMapping.SourceSubtype__c, typeValuesMap);
        }

        //Creamos una oferta para comprobar que el caso queda relacionado en el Case Trigger Hegeo - Before update
        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = 'email2case@fakeemail.com.invalid';
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';'+relatedClaim.InfoClaimNumber__c+';;\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        System.debug('newVerion: ' + newVersion);

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(FAKE_TO_ADDRESS, updatedEmailMessage.ToAddress, 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Type').toLowerCase(), updatedCase.Type.toLowerCase(), 'Type successfully saved');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Subtype__c').toLowerCase(), updatedCase.Subtype__c.toLowerCase(), 'Subtype successfully saved');

        System.assertEquals(relatedOffer.Id, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(relatedClaim.Id, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(receiptNumber, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }

    /**
     * 
     *
     * @author rlopez
     * @date 28/01/2021
     */
    @isTest
    static void test_createDocument_not_linked_with_emailMessage_ok()
    {
        Case relatedCase = new Case();
        insert relatedCase;

        String csvContent = '3;20;;;1;;2;3;4;;\n';
        csvContent += 'Fake Name <from@fakeemail.com.invalid>\n';
        csvContent += 'Fake Name <to@fakeemail.com.invalid>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'HEGEO-CLASIFICACION';
        newVersion.PathOnClient = 'HEGEO-CLASIFICACION.csv';
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = relatedCase.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        List<EmailMessage> updatedEmails = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE FromAddress = 'from@fakeemail.com.invalid' OR ToAddress = 'to@fakeemail.com.invalid'];
        System.assertEquals(true, updatedEmails.isEmpty(), 'There should not be any emails with addresses from CSV');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(true, String.isBlank(updatedCase.Type), 'Type is blank');
        System.assertEquals(true, String.isBlank(updatedCase.Subtype__c), 'Subtype is blank');
    }

    /**
     * 
     *
     * @author rlopez
     * @date 28/01/2021
     */
    @isTest
    static void test_email2case_empty_CSV_ok()
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = 'email2case@fakeemail.com.invalid';
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String csvContent = '\n';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'HEGEO-CLASIFICACION';
        newVersion.PathOnClient = 'HEGEO-CLASIFICACION.csv';
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(true, updatedEmailMessage.FromAddress != 'from@fakeemail.com.invalid', 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress != 'to@fakeemail.com.invalid', 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c FROM Case WHERE Id =: relatedCase.Id];
        System.debug('updatedCase: ' + updatedCase);
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(true, updatedCase.Type == 'No definido', 'Type is undefined');
        System.assertEquals(true, updatedCase.Subtype__c == 'No definido', 'Subtype is undefined');
    }

    /**
     * Comprueba que el CSV se procesa correctamente aunque
     * no haya valores en la primera línea para tipificar el caso
     * pero si con valores en los emails
     *
     * @author rlopez
     * @date 02/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_firstLine_empty_ok()
    {
        //TODO
    }

    /**
     * Comprueba que el CSV se procesa correctamente aunque
     * existan valores de tipificación incorrectos, y comprueba
     * que se genera un ErrorLog especificando esos valores
     *
     * @author rlopez
     * @date 02/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_invalidValues_ok()
    {
        //TODO:

    }

    /**
     * Test que comprueba que si el documento adjunto no tiene el nombre 
     * correcto, la información del CSV no se procesa
     *
     * @author rlopez
     * @date 02/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_invalid_documentTitle_ok()
    {
        //Creamos una oferta para comprobar que el caso queda relacionado en el Case Trigger Hegeo - Before update
        Opportunity relatedOffer = new Opportunity();
        relatedOffer.InfoQuoteNumber__c = '1';
        relatedOffer.Name = 'Test Opportunity Name';
        relatedOffer.StageName = 'Closed Won';
        relatedOffer.CloseDate = System.today();
        insert relatedOffer;

        Policy__c relatedPolicy = new Policy__c();
        relatedPolicy.InfoPolicyNumber__c = '2';
        insert relatedPolicy;

        Claim__c relatedClaim = new Claim__c();
        relatedClaim.InfoClaimNumber__c = '4';
        insert relatedClaim;

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = 'email2case@fakeemail.com.invalid';
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String csvContent = '3;20;;;1;;2;3;4;;\n';
        csvContent += 'Fake Name <from@fakeemail.com.invalid>\n';
        csvContent += 'Fake Name <to@fakeemail.com.invalid>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'Invalid Document Title';
        newVersion.PathOnClient = 'Invalid Document Title.csv';
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(true, updatedEmailMessage.FromAddress != 'from@fakeemail.com.invalid', 'FromAddress is not the one from CSV file');
        System.assertEquals(true, updatedEmailMessage.ToAddress != 'to@fakeemail.com.invalid', 'ToAddress is not the one from CSV file');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(true, updatedCase.Type != 'Administración', 'Type is not the one from CSV file');
        System.assertEquals(true, updatedCase.Subtype__c != 'Anulación póliza', 'Subtype is is not the one from CSV file');

        System.assertEquals(null, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(null, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(null, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(null, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c was not saved');
    }
}