/**
 * @description       :
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-03-2024
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class CasesSelectorTest
{
    @TestSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 10);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        policies[0].EndDate__c = Date.today().addDays(-60);
        insert policies;

        List<Case> ZRMCases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        ZRMCases[0].RecordTypeId = Caseutil.RT_ID_ZRM;
        ZRMCases[0].PolicyId__c = policies[0].Id;
        ZRMCases[0].Status = 'En Gestión';
        insert ZRMCases;
    }

    @isTest
    private static void test_findOpenByAccount_matchedRecords()
    {
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, INFOIntermediaryCode__c, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];

        List<String> accountIds = new List<String>();
        for(Account acc : accountsToSearch)
        {
            accountIds.add(acc.Id);
        }

        // Test
        Test.startTest();

        List<Case> matchedRecords = new CasesSelector().findOpenByAccount(accountIds);

        Test.stopTest();

        System.assertEquals(20, matchedRecords.size(), 'no devuelve el número de registros correcto');
    }

    @isTest
    private static void test_findOpenByAccount_notFound()
    {
        // Test
        Test.startTest();

        List<Case> matchedRecords = new CasesSelector().findOpenByAccount( new List<String>() );

        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }


    @isTest
    private static void test_findById_matchedRecord()
    {
        List<Case> casos = [SELECT Id FROM Case];
        Set<String> casosIds = new Set<String>();
        casosIds.add(casos.get(0).Id);

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().findById(casosIds);
        Test.stopTest();

        System.assertEquals(casosIds.size(), matchedRecords.size(), 'no devuelve el número de registros correcto');
    }

    @isTest
    private static void test_findById_notFound()
    {
        Set<String> casosIds = new Set<String>();
        casosIds.add('500AAAAAAAAAAAAAAA'); // ponemos un Id inventado

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().findById(casosIds);
        Test.stopTest();

        System.assertEquals(0, matchedRecords.size(), 'No debe devolver ningún Caso');
    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewAccountsBatch
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     */
    @isTest
    private static void test_getQueryStringCasesToRelateToNewAccounts_matchedRecord()
    {
        List<Case> casos = [SELECT Id, RobotDocumentId__c FROM Case];
        casos[0].RobotDocumentId__c = '2341341';
        casos[1].RobotDocumentId__c = '2341341';

        // Solo el primer caso tendrá recordType USP, de esta manera comprobamos que solo aplica a USP
        casos[0].RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
        update casos;

        // Test
        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesToRelateToNewAccounts('5');
        System.debug(query);
        List<Case> matchedRecords = (List<Case>) Database.query(query);
        Test.stopTest();

        System.assertEquals(1, matchedRecords.size(), 'no devuelve el número de registros correcto');
    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewOffersBatch
     * @author lrodriguez6@seidor.es
     * @date 14/11/2022
     */
    @isTest
    private static void test_getQueryStringCasesToRelateToNewOffers_matchedRecord()
    {
        List<Case> casos = [SELECT Id, CreatedOffer__c FROM Case];
        casos[0].CreatedOffer__c = '11111';
        casos[1].CreatedOffer__c = '11112';

        // Solo el primer caso tendrá recordType USP, de esta manera comprobamos que solo aplica a USP
        casos[0].RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;

        update casos;

        // Test
        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesToRelateToNewOffers('5');
        System.debug(query);
        List<Case> matchedRecords = (List<Case>) Database.query(query);
        Test.stopTest();

        System.assertEquals(1, matchedRecords.size(), 'no devuelve el número de registros correcto');
    }

    /**
     * Test del método que devuelve la query de Cases para Batch_RatioConversionIntermediary
     * @author lrodriguez6@seidor.es
     * @date 08/12/2022
     */
    @isTest
    private static void test_getQueryCasesConversionRatio_matchedRecord()
    {
        List<Case> casos = [SELECT Id, CreatedOffer__c FROM Case];
        List<Account> cuentasRatio= [SELECT Id FROM Account];

        for (case cas: casos)
        {
            cas.Subject='test';
            cas.SourceArea__c='Mediator';
            cas.Type='Venta';
            cas.RecordTypeId=CaseUtil.RT_ID_USPINQUIRY;
            cas.Status='Cerrado';
            cas.CloseResult__c='Perdida - Garantías';
            cas.AutomaticNotifications__c=false;
        }

        update casos;

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().getQueryCasesConversionRatio(cuentasRatio,'Combinado','No Realizado','Venta',CaseUtil.RT_ID_USPINQUIRY,'365','Cerrado');
        Test.stopTest();

        System.assertEquals(20, matchedRecords.size(), 'no devuelve el número de registros correcto');

    }


    /**
     * Test del método que devuelve la query de Cases para Batch_RatioConversionIntermediary
     * @author lrodriguez6@seidor.es
     * @date 08/12/2022
     */
    @isTest
    static void test_getQueryChildCasesConversionRatio_matchedRecord()
    {
        List<Case> casos = [SELECT Id, CreatedOffer__c FROM Case];
        List<Case> casosPadre= new List<Case>();
        Case casoPadre1= casos[0];
        casoPadre1.Subject='test';
        casoPadre1.SourceArea__c='Mediator';
        casoPadre1.Type='Venta';
        casoPadre1.RecordTypeId=CaseUtil.RT_ID_USPINQUIRY;
        casoPadre1.Status='Cerrado';
        casoPadre1.CloseResult__c='Perdida - Garantías';
        casoPadre1.AutomaticNotifications__c=false;

        update casoPadre1;
        casosPadre.add(casoPadre1);

        List<Account> cuentasRatio= [SELECT Id FROM Account];


        for (Integer i=5; i < casos.size(); i++)
        {
            casos[i].Subject='test';
            casos[i].SourceArea__c='Mediator';
            casos[i].Type='Venta';
            casos[i].RecordTypeId=CaseUtil.RT_ID_USPINQUIRY;
            casos[i].Status='Cerrado';
            casos[i].CloseResult__c='Ganada';
            casos[i].AutomaticNotifications__c=false;
            casos[i].ParentId=casoPadre1.Id;
            casos[i].QuotationStage__c='Won';
        }

        update casos;



        // Test
        Test.startTest();
        Map <Id, Decimal> matchedRecords = new CasesSelector().getMapChildCasesConversionRatio(casosPadre,'Won','No Realizado','Combinado','Venta',CaseUtil.RT_ID_USPINQUIRY,'365','Cerrado');
        Test.stopTest();


        System.assertEquals(1, matchedRecords.size(), 'no devuelve el número de registros correcto');

    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewOffersBatch. En este test la query ha de volver completada
     * @author arcortazar
     * @date 23/03/2022
     */
    @isTest
    private static void test_getQueryStringCasesWithoutPolicyOffer_queryOK()
    {
        List<String> origenes = new List<String>();
        origenes.add('Email');

        List<String> recordTypes = new List<String>();
        recordTypes.add('OCSInquiry');

        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesWithoutPolicyOffer('7', origenes, recordTypes);
        Test.stopTest();

        System.assertNotEquals('', query, 'La query no ha de volver vacía');
    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewOffersBatch. En este test la query ha de volver vacía
     * @author arcortazar
     * @date 23/03/2022
     */
    @isTest
    private static void test_getQueryStringCasesWithoutPolicyOffer_queryKO()
    {
        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesWithoutPolicyOffer( '', new List<String>(), new List<String>() );
        Test.stopTest();

        System.assertEquals('', query, 'La query ha de volver vacía');
    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewOffersBatch. Lanzamos la query para comprobar que está bien construida
     * @author arcortazar
     * @date 23/03/2022
     */
    @isTest
    private static void test_getQueryStringCasesWithoutPolicyOffer_obtainedResults()
    {
        List<String> origenes = new List<String>();
        List<String> recordTypes = new List<String>();

        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesWithoutPolicyOffer('7', origenes, recordTypes);
        List<Case> matchedRecords = (List<Case>) Database.query(query);
        Test.stopTest();

        System.assertNotEquals(0, matchedRecords.size(), 'Ha de devolver casos');
    }

    /**
     * Test del método que devuelve una lista de casos filtada por el tipo de cuenta que tiene asociado el caso
     * @author aberuete
     * @date 06/03/2024
     */
    @isTest
    private static void test_getCasesFilterByRecordTypeNamesAccount()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        List<Case> allCases = [Select id from Case];
        System.assertEquals (22, allCases.size(), 'El número de casos totales no es correcto');

        Test.startTest();
        List<Case> casesReturned = new CasesSelector().getCasesFilterByRecordTypeNamesAccount (allCases, new List<String> {'Customer'});
        Test.stopTest();

        System.assertEquals (2, casesReturned.size(),'El número de casos devuelto no es correcto');

    }

    /**
     * Se comprueba que el metodo getCasesByTicketId funciona correctamente. Para ello:
     * - Comprueba que pasandole un set nulo no retorna nada
     * - Comprueba que pasandole un set vacio no retorna nada
     * - Comprueba que pasandole dos TicketId existentes (uno de ZDA y otro de USP) y uno no existente, debe retornar solo un caso (el de ZDA)
     */
    @isTest
    private static void test_getCasesByTicketId()
    {
        Case existingZDACase = [SELECT Id FROM Case LIMIT 1];

        existingZDACase.RecordTypeId = CaseUtil.RT_ID_ZDA;
        existingZDACase.CuTicketId__c = '12345678';

        Case newUSPCase = new Case(
            RecordTypeId = CaseUtil.RT_ID_USPINQUIRY,
            CuTicketId__c = '87654321'
            );

        List<Case> casesToUpsert = new List<Case>();
        casesToUpsert.add(existingZDACase);
        casesToUpsert.add(newUSPCase);
        upsert casesToUpsert;

        List<Case> createdUSPCase = [SELECT Id FROM Case WHERE RecordTypeId = : CaseUtil.RT_ID_USPINQUIRY AND CuTicketId__c = : newUSPCase.CuTicketId__c];
        Assert.isFalse(createdUSPCase.isEmpty(), 'Se deberia haber creado un caso de tipo USP');

        Test.startTest();
        List<Case> emptyCases = new CasesSelector().getCasesByTicketId(null);
        List<Case> emptyCases2 = new CasesSelector().getCasesByTicketId( new Set<String>() );
        List<Case> foundCases = new CasesSelector().getCasesByTicketId(new Set<String> {existingZDACase.CuTicketId__c, newUSPCase.CuTicketId__c, '748'});
        Test.stopTest();

        Assert.areEqual( 0, emptyCases.size() );
        Assert.areEqual( 0, emptyCases2.size() );
        Assert.areEqual( 1, foundCases.size() );
        Assert.areEqual(foundCases[0].Id, existingZDACase.Id);
        Assert.areEqual(foundCases[0].CuTicketId__c, existingZDACase.CuTicketId__c);
    }

    /**
     * Testea el metodo getZdaChildCases
     * 
     * @author mario.navarro@seidor.com
     * @date 05/06/2024
     */
    @isTest
    private static void test_getZdaChildCases()
    {
        //creamos 2 casos de zda, uno padre del otro
        List<Case> zdaCases = TestDataFactory.generateZDACases(2);
        zdaCases[1].RelatedCuTicketId__c = zdaCases[0].CuTicketId__c;
        insert zdaCases;

        //creamos un tercer caso no zda, hijo de un zda (para que no lo retorne)
        Case newUSPCase = new Case(
            RecordTypeId = CaseUtil.RT_ID_USPINQUIRY,
            RelatedCuTicketId__c = zdaCases[0].CuTicketId__c
        );
        insert newUSPCase;

        Test.startTest();
        List<Case> emptyCases = new CasesSelector().getZdaChildCases(null);
        List<Case> emptyCases2 = new CasesSelector().getZdaChildCases(new Set<String>());
        List<Case> foundCases = new CasesSelector().getZdaChildCases(new Set<String>{zdaCases[0].CuTicketId__c});
        Test.stopTest();

        Assert.isTrue(emptyCases.isEmpty());
        Assert.isTrue(emptyCases2.isEmpty());
        Assert.isFalse(foundCases.isEmpty());
        Assert.areEqual(1, foundCases.size());
        Assert.areEqual(zdaCases[1].Id, foundCases[0].Id);
    }

    /**
     * Se comprueba que el metodo getByIdWithZDAInfo funciona correctamente. Para ello:
     * - Comprueba que pasandole un id nulo no retorna nada
     * - Comprueba que pasandole un id de un caso NO ZDA no retorna nada
     * - Comprueba que pasandole un id de un caso ZDA lo retorna
     */
    @isTest
    private static void test_getByIdWithZDAInfo()
    {
        Case existingZDACase = [SELECT Id FROM Case LIMIT 1];

        existingZDACase.RecordTypeId = CaseUtil.RT_ID_ZDA;
        existingZDACase.CuTicketId__c = '12345678';

        Case newUSPCase = new Case(
            RecordTypeId = CaseUtil.RT_ID_USPINQUIRY,
            CuTicketId__c = '87654321'
            );

        List<Case> casesToUpsert = new List<Case>();
        casesToUpsert.add(existingZDACase);
        casesToUpsert.add(newUSPCase);
        upsert casesToUpsert;

        Test.startTest();
        Case nullCase = new CasesSelector().getByIdWithZDAInfo(null);
        Case uspCase = new CasesSelector().getByIdWithZDAInfo(newUSPCase.Id);
        Case zdaCase = new CasesSelector().getByIdWithZDAInfo(existingZDACase.Id);
        Test.stopTest();

        Assert.isNull(nullCase);
        Assert.isNull(uspCase);
        Assert.isNotNull(zdaCase);
    }

    /*
     * Test del método que devuelve casos para el Batch_CloseInteractions
     * @author lrodriguez6@seidor.es
     * @date 01/03/2024
     */
    @isTest
    private static void test_casesBatchCloseInteractions_matchedRecord()
    {
        List<Case> casos = [SELECT Id, CreatedOffer__c FROM Case LIMIT 1];

        casos[0].RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
        casos[0].CloseInteractionBatch__c= true;
        casos[0].ExpectedClosingDate__c= System.TODAY();
        casos[0].CloseByBatch__c= false;

        update casos;


        Test.startTest();
        casos = new CasesSelector().getCasesToCloseInteractions();
        Test.stopTest();

        System.assertEquals(1, casos.size(), 'no devuelve el número de registros correcto');
    }

    /*
     * Test del método que devuelve casos para findByIdControlCC (método de EmailMessageUtil)
     * @author lrodriguez6@seidor.es
     * @date 01/03/2024
     */
    @isTest
    private static void test_findByIdControlCC_matchedRecord()
    {
        Case casoCC = [SELECT Id FROM Case LIMIT 1];
        casoCC.ControlEmailCC__c=true;
        update casoCC;

        Set<String> casosIds = new Set<String>();
        casosIds.add(casoCC.Id);

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().findByIdControlCC(casosIds);
        Test.stopTest();

        System.assertEquals(matchedRecords.size(), 1, 'no devuelve el número de registros correcto');
        System.assertEquals(matchedRecords[0].ControlEmailCC__c,true);
    }

    @isTest
    private static void test_getNotClosedZrmCasesByRelatedPolicy()
    {
        Id rtZrmInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZRMInquiry').getRecordTypeId();
        List<Account> accountRecord = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accountRecord, 1);
        Set<String> policiesIds = new Set<String>();

        policies[0].EndDate__c = System.today();

        insert policies;
        Case caso = [SELECT Id From Case LIMIT 1];

        caso.PolicyId__c = policies[0].Id;
        caso.recordTypeId = rtZrmInquiryId;
        caso.EndDate__c = System.today();

        update caso;

        policiesIds.add(policies[0].Id);

        Test.startTest();
        List<Case> cases = new CasesSelector().getNotClosedZrmCasesByRelatedPolicy(policiesIds);
        Test.stopTest();

        Assert.areEqual( 1, cases.size() );
    }

    /**
     * Método test para Batch_CloseZRMExpiredCases. El selector devuelve una query que ha de volver informada
     * ya que los dos parámetros String del método están informados con el valor correcto
     * @author nikola.cobian@seidor.com
     * @date 23/04/2024
     */
    @isTest
    private static void test_getQueryStringZRMExpiredAndNotClosedCasesWithPolicy_OK()
    {
        String recordTypeName = CaseUtil.RT_NAME_ZRM;
        String months = '2';

        Test.startTest();
        String query = new CasesSelector().getQueryStringZRMExpiredAndNotClosedCasesWithPolicy(recordTypeName, months);
        Test.stopTest();

        Assert.areNotEqual('', query, 'El resultado de la query debe estar informado');
    }

    /**
     * Método test para Batch_CloseZRMExpiredCases. El selector devuelve una query que ha de volver vacía
     * ya que uno de los dos parámetros String del método están vacíos
     * @author nikola.cobian@seidor.com
     * @date 23/04/2024
     */
    @isTest
    private static void test_getQueryStringZRMExpiredAndNotClosedCasesWithPolicy_KO()
    {
        String recordTypeName = '';
        String months = '2';

        Test.startTest();
        String query = new CasesSelector().getQueryStringZRMExpiredAndNotClosedCasesWithPolicy(recordTypeName, months);
        Test.stopTest();

        Assert.areEqual('', query, 'El resultado de la query debe estar vacío');
    }

    /**
     * Método test para Batch_CloseZRMExpiredCases. El selector devuelve una query que manipulamos mediante
     * la instrucción Database.query para comprobar los valores esperados en el caso generado
     * @author nikola.cobian@seidor.com
     * @date 23/04/2024
     */
    @isTest
    private static void test_getQueryStringZRMExpiredAndNotClosedCasesWithPolicy_obtainedResults()
    {
        String recordTypeName = CaseUtil.RT_NAME_ZRM;
        String months = '2';

        Test.startTest();
        String query = new CasesSelector().getQueryStringZRMExpiredAndNotClosedCasesWithPolicy(recordTypeName, months);
        List<Case> matchedRecords = (List<Case>) Database.query(query);
        Test.stopTest();

        Assert.areNotEqual('', query, 'El resultado de la query debe estar informado');
        Assert.areNotEqual(0, matchedRecords.size(), 'Deben haberse generado casos');
        Assert.areEqual(CaseUtil.RT_ID_ZRM, matchedRecords[0].RecordTypeId, 'El tipo de registro debe coincdir');
    }
    
    /**
     * Test del método que devuelve el número de casos que tiene cada usuario que es un gestor activo.
     * @author aberuete
     * @date 24/06/2024
     */
    @isTest
    private static void test_getNumberOfAssignedCasesGroupById()
    {
        Integer numCasos = null; 
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);
        insert accounts;

        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name = 'USP User'];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 1);
        userUsp[0].ActiveAgent__c = true;
        insert userUsp;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        cases[0].OwnerId = userUsp[0].Id; 
        insert cases;

        Test.startTest();
        List<AggregateResult> casesReturned = new CasesSelector().getNumberOfAssignedCasesGroupById();
        Test.stopTest();

        for (AggregateResult caseResult : casesReturned )
        {
            if ( String.valueOf(caseResult.get('OwnerId')) == userUsp[0].Id)
            {
                numCasos = (Integer)caseResult.get('numCases');
            }
        }
        
        Assert.areEqual(1, numCasos);
    }

     /**
     * Test del método que devuelve la query de Cases para Batch_CloseInteractions
     * @author lrodriguez6@seidor.es
     * @date 04/06/2024
     */
    @isTest
    private static void test_getCasesToCloseInteractionsAutomatic_matchedRecord()
    {
        String uSPRecordTypeId = GlobalConfigUtil.getGlobalConfigurationValueId('Case_RecordType_USP_Id');
        String filterCallCenter = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Call_Center_USP');
        String filterTypeTareas = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Type_Tareas');
        String filterSourceMediator = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Source_Area_Mediator');

        Case casoQuery = [SELECT Id, CreatedOffer__c FROM Case   LIMIT 1];

        casoQuery.SourceArea__c=filterSourceMediator;
        casoQuery.RecordTypeId=uSPRecordTypeId;
        casoQuery.CallCenter__c=filterCallCenter;
        casoQuery.Type=filterTypeTareas;
        casoQuery.SourceArea__c=filterSourceMediator;


        // Test
        Test.startTest();
        update casoQuery;

        List<Case> matchedRecords = new CasesSelector().getCasesToCloseInteractionsAutomatic();
        Test.stopTest();

        System.assertEquals(1, matchedRecords.size(), 'no devuelve el número de registros correcto');

    }
}