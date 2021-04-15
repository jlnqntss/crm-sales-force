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
    public static final String FAKE_CC_ADDRESS = 'cc@fakeemail.com.invalid';
    public static final String FAKE_BCC_ADDRESS = 'bcc@fakeemail.com.invalid';
    //Type;Subtype__c;TypeN3__c;HegeoProductGroupCode__c;HegeoOfferId__c;HegeoPrePolicyId__c;HegeoPolicyId__c;HegeoReceiptNumber__c;HegeoClaimId__c;AccountId
    
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'Z', 1);
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
     * Test que comprueba que el procesamiento del CSV recibido del
     * robot Hegeo se realiza correctamente cuando los datos son correctos
     *
     * @author rlopez
     * @date 26/01/2021
     */
    @isTest
    static void test_processCSV_hegeo_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';'+relatedClaim.InfoClaimNumber__c+';'+relatedIntermediary.INFOIntermediaryCode__c+'\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_CC_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_BCC_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress, BccAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress contains the email from CSV');
        System.assertEquals(true, updatedEmailMessage.CcAddress.contains(FAKE_CC_ADDRESS), 'CCAddress contains the email from CSV');
        System.assertEquals(true, updatedEmailMessage.BccAddress.contains(FAKE_BCC_ADDRESS), 'BCCAddress contains the email from CSV');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Type').toLowerCase(), updatedCase.Type.toLowerCase(), 'Type successfully saved');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Subtype__c').toLowerCase(), updatedCase.Subtype__c.toLowerCase(), 'Subtype successfully saved');

        System.assertEquals(relatedOffer.Id, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(relatedClaim.Id, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(relatedIntermediary.Id, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(receiptNumber, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }

    /**
     * Test que comprueba que se inserta correctamente un documento que
     * no está relacionado con un EmailMessage y no se procesa ningún tipo de información
     *
     * @author rlopez
     * @date 28/01/2021
     */
    @isTest
    static void test_createDocument_not_linked_with_emailMessage_ok()
    {
        Case relatedCase = new Case();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
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
     * Test que comprueba que no se procesa la información de un adjunto de un EmailMessage
     * que no esta relacionado con un Caso, independientemente se que cumpla las configuraciones 
     * establecidas en el metadato del robot Hegeo
     *
     * @author rlopez
     * @date 28/01/2021
     */
    @isTest
    static void test_processCSV_emailMessage_not_relatedWithCase_ok()
    {
        Opportunity relatedOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.RelatedToId = relatedOpportunity.Id; 
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

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;;;;'+receiptNumber+';;\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

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

        EmailMessage updatedEmail = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmail != null, 'EmailMessage exists');
        System.assertEquals(true, updatedEmail.FromAddress != FAKE_FROM_ADDRESS, 'FromAddress from CSV has not been processed');
        System.assertEquals(false, updatedEmail.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress from CSV has not been processed');
    }

    /**
     * Test que comprueba un documento se inserta correctamente en caso de cumplir
     * todas las condiciones de procesamiento incluso si el CSV está vacío.
     * 
     * Al estar vacío, ni el EmailMessage ni el Caso se actualizan
     *
     * @author rlopez
     * @date 28/01/2021
     */
    @isTest
    static void test_process_empty_CSV_robotHegeo_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
            FROM Robot_Hegeo_Setting__mdt
        ];
        System.assertEquals(false, robotHegeoSettings.isEmpty(), 'List should not be empty');

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
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
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(true, updatedCase.Type == null, 'Type is undefined');
        System.assertEquals(true, updatedCase.Subtype__c == null, 'Subtype is undefined');

        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'There are error logs created');
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
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
            FROM Robot_Hegeo_Setting__mdt
        ];
        System.assertEquals(false, robotHegeoSettings.isEmpty(), 'List should not be empty');

        //Cargamos los valores del mapeo de tipificación
        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = [
            SELECT Id, Type__c, Subtype__c, TypeN3__c, SourceType__c, SourceSubtype__c
            FROM Robot_Hegeo_Field_Mapping__mdt
        ];
        System.assertEquals(false, robotHegeoFieldsMapping.isEmpty(), 'List should not be empty');

        //Preparamos un mapa para realizar comprobaciones de actualización
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

        //Creamos registros a relacionar con el caso a traves del flow before update para casos de hegeo
        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        //Dejamos los tipos del caso vacíos para comprobar que la ejecución procesa el CSV igualmente
        String caseTypeValue = '';
        String caseSubtypeValue = '';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;;;;;;;\n';
        csvContent += FAKE_FROM_ADDRESS+'\n';
        csvContent += FAKE_TO_ADDRESS+'\n';
        csvContent += FAKE_CC_ADDRESS+'\n';
        csvContent += FAKE_BCC_ADDRESS;

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        //Preparamos el registro que lanza la ejecución del trigger
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;

        Test.startTest();
        insert newLink;
        Test.stopTest();

        //Comprobamos que el Email se ha actualizado con los campos del CSV
        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress is the same');

        //Comprobamos que el caso no tiene actualizado ninguno de los campos a actualizar
        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(null, updatedCase.Type, 'Type is undefined');
        System.assertEquals(null, updatedCase.Subtype__c, 'Subtype is undefined');
        
        System.assertEquals(null, updatedCase.OfferId__c, 'There is not related offer');
        System.assertEquals(null, updatedCase.PolicyId__c, 'There is not related policy');
        System.assertEquals(null, updatedCase.ClaimId__c, 'There is not related claim');
        System.assertEquals(null, updatedCase.AccountId, 'There is not related account');
        System.assertEquals(null, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c is null');

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'There are error logs created');
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
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
            FROM Robot_Hegeo_Setting__mdt
        ];
        System.assertEquals(false, robotHegeoSettings.isEmpty(), 'List should not be empty');

        //Cargamos los valores del mapeo de tipificación
        List<Robot_Hegeo_Field_Mapping__mdt> robotHegeoFieldsMapping = [
            SELECT Id, Type__c, Subtype__c, TypeN3__c, SourceType__c, SourceSubtype__c
            FROM Robot_Hegeo_Field_Mapping__mdt
        ];
        System.assertEquals(false, robotHegeoFieldsMapping.isEmpty(), 'List should not be empty');

        //Preparamos un mapa para realizar comprobaciones de actualización
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

        //Creamos registros a relacionar con el caso a traves del flow before update para casos de hegeo
        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        //Ponemos el tipo y subtipo con una combinación que no existe en la configuración actual
        String caseTypeValue = '2';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        //Añadimos al CSV un número de oferta y un número de siniestro no validos
        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;invalidquotenumber;;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';invalidclaimnumber;'+relatedIntermediary.INFOIntermediaryCode__c+'\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        //Preparamos el registro que lanza la ejecución del trigger
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;

        Test.startTest();
        insert newLink;
        Test.stopTest();

        //Comprobamos que el Email se ha actualizado con los campos del CSV
        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress is the same');

        //Comprobamos que el caso no tiene actualizados los campos de tipificación (Type, Subtype, TypeN3)
        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(null, updatedCase.Type, 'Type is undefined');
        System.assertEquals(null, updatedCase.Subtype__c, 'Subtype is undefined');
        
        //Comprobamos que la oferta y el siniestro no están relacionados, ya que no existen en el sistema
        System.assertEquals(null, updatedCase.OfferId__c, 'There is not related offer');
        System.assertEquals(null, updatedCase.ClaimId__c, 'There is not related claim');

        //Comprobamos que el resto de relaciones si se han actualizado
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(relatedIntermediary.Id, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(receiptNumber, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'There are error logs created');
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
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

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';'+relatedClaim.InfoClaimNumber__c+';'+relatedIntermediary.INFOIntermediaryCode__c+'\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

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

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(null, updatedCase.Type, 'Type is undefined');
        System.assertEquals(null, updatedCase.Subtype__c, 'Subtype is undefined');
        
        System.assertEquals(null, updatedCase.OfferId__c, 'There is not related offer');
        System.assertEquals(null, updatedCase.ClaimId__c, 'There is not related claim');
        System.assertEquals(null, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(null, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(null, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }

    /**
     * Test para pasar la cobertura de código del handler
     *
     * @author rlopez
     * @date 05/02/2021
     */
    @isTest
    static void test_update_delete_contentDocumentLink_ok()
    {
        Case relatedCase = new Case();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
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
        insert newLink;

        newLink.ShareType = 'V';
        Test.startTest();
        update newLink;
        delete newLink;
        Test.stopTest();
    }

    /**
     * Test que comprueba que el CSV se procesa correctamente aunque 
     * la lista de valores de tipificación del caso en la primera línea 
     * sea mayor que los configurados en los metadatos
     * 
     * Se realiza el mapeo de campos por orden y los sobrantes se descartan
     *
     * @author rlopez
     * @date 05/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_more_values_than_expected_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';'+relatedClaim.InfoClaimNumber__c+';'+relatedIntermediary.INFOIntermediaryCode__c+';1;1;1;1;1;1\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
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
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Type').toLowerCase(), updatedCase.Type.toLowerCase(), 'Type successfully saved');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Subtype__c').toLowerCase(), updatedCase.Subtype__c.toLowerCase(), 'Subtype successfully saved');

        System.assertEquals(relatedOffer.Id, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(relatedClaim.Id, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(relatedIntermediary.Id, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(receiptNumber, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }

    /**
     * Test que comprueba que el CSV se procesa correctamente aunque
     * la lista de valores de tipificación del caso en la primera línea
     * sea menor que los configurados en los metadatos
     * 
     * Se realiza el mapeo de los valores recibidos y el resto de campos se quedan vacíos
     *
     * @author rlopez
     * @date 05/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_less_values_than_expected_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+'\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
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
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Type').toLowerCase(), updatedCase.Type.toLowerCase(), 'Type successfully saved');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Subtype__c').toLowerCase(), updatedCase.Subtype__c.toLowerCase(), 'Subtype successfully saved');

        System.assertEquals(relatedOffer.Id, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(null, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(null, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(null, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }

    /**
     * Test que comprueba que no se procesan correctamente los datos
     * si los valores recibidos son menos que el mínimo necesario
     * para tipificar correctamente un caso (Type, Subtype y TypeN3)
     * 
     * En ese caso no se actualiza el caso, si se actualiza el Email y
     * se deja registro de un error log.
     *
     * @author rlopez
     * @date 05/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_insufficient_values_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
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
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS), 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(null, updatedCase.Type, 'Type is undefined');
        System.assertEquals(null, updatedCase.Subtype__c, 'Subtype is undefined');

        System.assertEquals(null, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(null, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(null, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(null, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(null, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'There are error logs created');
    }

    /**
     * Test que comprueba el correcto procesamiento de los emails
     * cuando se recibe una lista de correos en el toAddress
     *
     * @author rlopez
     * @date 05/02/2021
     */
    @isTest
    static void test_process_hegeoCSV_two_toAdresses_ok()
    {
        //Cargamos los metadatos de configuración
        List<Robot_Hegeo_Setting__mdt> robotHegeoSettings = [
            SELECT Id, CaseFields__c, CaseFieldsIndex__c, FromAddressIndex__c, Separator__c, ToAddressIndex__c, IsActive__c, DocumentTitle__c, FileExtension__c, CaseRecordTypeNames__c, RoutingAddresses__c
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

        Account relatedIntermediary = [SELECT Id, INFOIntermediaryCode__c FROM Account WHERE INFOIntermediaryCode__c != null LIMIT 1];

        Opportunity relatedOffer = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE InfoQuoteNumber__c != null AND AccountId =: relatedIntermediary.Id LIMIT 1];

        Policy__c relatedPolicy = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE OpportunityName__c =: relatedOffer.Id LIMIT 1];

        Claim__c relatedClaim = [SELECT Id, InfoClaimNumber__c FROM Claim__c WHERE Policy__c =: relatedPolicy.Id LIMIT 1];

        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = robotHegeoSettings.get(0).RoutingAddresses__c.split(',').get(0);
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String caseTypeValue = '1';
        String caseSubtypeValue = '6';
        String caseTypeCombination = caseTypeValue + caseSubtypeValue;
        String receiptNumber = '123456789';

        String csvContent = ''+caseTypeValue+';'+caseSubtypeValue+';;1;'+relatedOffer.InfoQuoteNumber__c+';;'+relatedPolicy.InfoPolicyNumber__c+';'+receiptNumber+';'+relatedClaim.InfoClaimNumber__c+';'+relatedIntermediary.INFOIntermediaryCode__c+'\n';
        csvContent += 'Fake Name <'+FAKE_FROM_ADDRESS+'>\n';
        String secondEmailAddress = 'secondfakeemailaddress@fakeemail.com.invalid';
        csvContent += 'Fake Name <'+FAKE_TO_ADDRESS+'>, '+secondEmailAddress+'';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = robotHegeoSettings.get(0).DocumentTitle__c;
        newVersion.PathOnClient = robotHegeoSettings.get(0).DocumentTitle__c + '.' + robotHegeoSettings.get(0).FileExtension__c;
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
        System.assertEquals(FAKE_FROM_ADDRESS, updatedEmailMessage.FromAddress, 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress.contains(FAKE_TO_ADDRESS) && updatedEmailMessage.ToAddress.contains(secondEmailAddress), 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c, OfferId__c, PolicyId__c, ClaimId__c, HegeoReceiptNumber__c, AccountId FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Type').toLowerCase(), updatedCase.Type.toLowerCase(), 'Type successfully saved');
        System.assertEquals(caseTypesMap.get(caseTypeCombination).get('Subtype__c').toLowerCase(), updatedCase.Subtype__c.toLowerCase(), 'Subtype successfully saved');

        System.assertEquals(relatedOffer.Id, updatedCase.OfferId__c, 'Offer successfully related');
        System.assertEquals(relatedPolicy.Id, updatedCase.PolicyId__c, 'Policy successfully related');
        System.assertEquals(relatedClaim.Id, updatedCase.ClaimId__c, 'Claim successfully related');
        System.assertEquals(relatedIntermediary.Id, updatedCase.AccountId, 'Intermediary Account successfully related');
        System.assertEquals(receiptNumber, updatedCase.HegeoReceiptNumber__c, 'HegeoReceiptNumber__c successfully saved');
    }
}