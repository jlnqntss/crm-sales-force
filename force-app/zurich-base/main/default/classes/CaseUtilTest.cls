/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 07-28-2023
 * @last modified by  : aberuete
**/
@isTest
private class CaseUtilTest
{
    static final String MESSAGE_UN_CASO_CREADO = 'Se debe de haber creado como mínimo 1 caso!';
    static final String MESSAGE_ENTITLEMENTS = 'Deberían existir entitlements, al menos el Default';
    static final String MESSAGE_CASEMILESTONES = 'Los casos deberían tener casemilestones asociados';
    static final String MESSAGE_MILESTONE_NOT_COMPLETED_YET = 'El milestone no debería estar completado aún';
    static final String MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT = 'El valor de CustomerFoundBy__c en el caso no se actualizó correctamente';
    static final String MESSAGE_CONTACTID_NOT_CORRECT = 'El valor de ContactId en el caso no se actualizó correctamente';
    static final String LABEL_GENERAL_INSURANCE = 'General Insurance';
    static final String LABEL_ANULACION = 'Anulación';

    @TestSetup
    public static void createScenario()
    {
        //Importante usar el RT Customer porque es personal account y se necesita que esté relleno PersonContactId
        List<Account> createdAccounts = TestDataFactory.generateAccounts('001', 'Customer', 1); //Importante que solo se cree 1 porque sino habrá varios con mismo email
        insert createdAccounts;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(createdAccounts, 1);
        insert contactPointEmails;

        //Crear cuenta Entitlement Holder
        Account cuentaHolder = new Account(Name = 'Entitlement Holder');
        insert cuentaHolder;

        //Recuperar los EntitlementProcess existentes. tienen que existir!!
        List<SlaProcess> slas = [SELECT Name, ID FROM SlaProcess];
        //Crear al menos el Entitlement Default usado en el flow CaseTriggerBeforeEntitlement encargado de su asignación
        Entitlement e = new Entitlement(AccountId = cuentaHolder.Id, Name = 'Default', SlaProcessId = slas[0].Id);
        insert e;

        List<SlaProcess> slasUsp = [SELECT Name, ID FROM SlaProcess WHERE Name = 'generico cierre interaccion 30h'];
        Entitlement entitlementUsp = new Entitlement(AccountId = cuentaHolder.Id, Name = 'DefaultUsp', SlaProcessId = slasUsp[0].Id, StartDate = System.today());
        insert entitlementUsp;
    }

    /**
     * Prueba a que estén rellenos Case.AccountId y Case.ContactId si se encontró
     * un cliente a través del ContactPointEmail
     */
    @isTest
    static void test_assignAccountAndContactFromSuppliedEmail_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> emailsToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            emailsToSearch.add(contactPoint.EmailAddress);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) ); //Importante

        Test.startTest();
        //Crear caso
        List<Case> cases = new List<Case>();
        Case caso = new Case( SuppliedEmail = emailsToSearch[0], RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId() );
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN :cases];
        System.assertEquals(false, expectedCases.isEmpty(), MESSAGE_UN_CASO_CREADO);

        //Si en el Before Insert se ha actualizado su accountId y PersonContactId
        for(Case record : expectedCases)
        {
            System.assertEquals(false, String.isBlank(record.AccountId), 'La cuenta del caso debe estar rellena');
            System.assertEquals(false, String.isBlank(record.ContactId), 'El contacto del caso debe estar relleno');
        }
    }

    /**
     * Se quiere probar que se queden a null la cuenta y el contacto del caso
     * si se encuentra más de 1 cliente con el mismo email
     * ya que no se puede decidir por uno o por otro
     */
    @isTest
    static void test_assignAccountAndContactFromSuppliedEmail_ko_MoreThanOne()
    {
        //Clonar cuenta para que no se pueda decidir cual de las dos es
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1); //El email se llamará igual para ambas: null@nts-solutions.com
        insert accounts;
        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 1);
        insert contactPointEmails;

        // SOSL - Resultados de búsqueda
        List<String> emailsToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            emailsToSearch.add(contactPoint.EmailAddress);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) ); //Importante

        Test.startTest();
        //Crear caso
        List<Case> cases = new List<Case>();
        Case caso = new Case( SuppliedEmail = emailsToSearch[0], RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId() );
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN :cases];
        System.assertEquals(false, expectedCases.isEmpty(), MESSAGE_UN_CASO_CREADO);

        //Si en el Before Insert se ha actualizado su accountId y PersonContactId
        for(Case record : expectedCases)
        {
            System.assertEquals(true, String.isBlank(record.AccountId), 'La cuenta del caso debe estar vacía');
            System.assertEquals(true, String.isBlank(record.ContactId), 'El contacto del caso debe estar vacío');
        }
    }

    /**
     * Se quiere probar que al no existir el email dentro de los contactPointEmail
     * se quede sin rellenar los datos en el caso
     */
    @isTest
    static void test_assignAccountAndContactFromSuppliedEmail_ko_NoExists()
    {
        Test.startTest();
        //Crear caso
        List<Case> cases = new List<Case>();
        Case caso = new Case( SuppliedEmail = 'noexistoentrelosemailscreados@nts-solutions.com', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId() );
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN :cases];
        System.assertEquals(false, expectedCases.isEmpty(), MESSAGE_UN_CASO_CREADO);

        //Si en el Before Insert se ha actualizado su accountId y PersonContactId
        for(Case record : expectedCases)
        {
            System.assertEquals(true, String.isBlank(record.AccountId), 'La cuenta del caso debe estar vacía');
            System.assertEquals(true, String.isBlank(record.ContactId), 'El contacto del caso debe estar vacío');
        }
    }

    /**
     * IMPORTANTE: este test depende de que esté activo el flow CaseTriggerBeforeEntitlement
     * porque es el encargado de asignar al caso un entitlement, y debido a eso se generan
     * los CaseMilestones
     * IMPORTANTE2: este test depende de que existan EntitlementProcess en el sistema
     * @date 03/03/2021
     */
    @isTest
    static void test_markMilestonesCompletedWhenClose_ok()
    {
        Id rtOCSInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();

        //Crear caso
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 3; i++)
        {   //Importante, el RT OcsInquiry y que el caso no tenga cuenta para qe el flow le asigne el Entitlement Default
            Case caso = new Case(RecordTypeId = rtOCSInquiryId);
            cases.add(caso);
        }
        insert cases;

        List<Entitlement> ents = [SELECT Id FROM Entitlement];
        System.assertEquals(false, ents.isEmpty(),MESSAGE_ENTITLEMENTS);

        List<Case> casesEnt = [SELECT Id, EntitlementId FROM Case];
        System.assertEquals(false, casesEnt.isEmpty(),'los casos deberían haberse insertado');
        System.assertEquals(ents[0].Id, casesEnt[0].EntitlementId,'los casos deberían tener entitlement asociado');

        //Comprobar que los milestones no están completados
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesCreated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cm: milestonesCreated)
        {
            System.assertEquals(false, cm.isCompleted, MESSAGE_MILESTONE_NOT_COMPLETED_YET);
        }

        Test.startTest();
        //Actualizar caso
        for(Case c: cases)
        {
            c.Status = 'Asignado';
        }
        update cases;
        for(Case c: cases)
        {
            c.Status = 'Cerrado';
        }                                          //No se puede pasar a close directamente
        update cases;
        Test.stopTest();

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesUpdated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cmilestone: milestonesUpdated)
        {
            System.assertEquals(true, cmilestone.isCompleted, 'el milestone debería estar completado ya');
        }
    }

    /**
     * IMPORTANTE: este test depende de que esté activo el flow CaseTriggerBeforeEntitlement
     * porque es el encargado de asignar al caso un entitlement, y debido a eso se generan
     * los CaseMilestones
     * IMPORTANTE2: este test depende de que existan EntitlementProcess en el sistema
     * @date 03/03/2021
     */
    @isTest
    static void test_markMilestonesCompletedWhenClose_ko()
    {
        Id rtOCSInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();

        //Crear caso
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 3; i++)
        {   //Importante, el RT OcsInquiry y que el caso no tenga cuenta para qe el flow le asigne el Entitlement Default
            Case caso = new Case(RecordTypeId = rtOCSInquiryId, SuppliedEmail='no@existe.com');
            cases.add(caso);
        }
        insert cases;

        List<Entitlement> ents = [SELECT Id FROM Entitlement];
        System.assertEquals(false, ents.isEmpty(),MESSAGE_ENTITLEMENTS);

        List<Case> casesEnt = [SELECT Id, EntitlementId FROM Case];
        System.assertEquals(false, casesEnt.isEmpty(),'los casos deberían haberse insertado');
        System.assertEquals(ents[0].Id, casesEnt[0].EntitlementId,'los casos deberían tener entitlement asociado');

        //Comprobar que los milestones no están completados
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesCreated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cm: milestonesCreated)
        {
            System.assertEquals(false, cm.isCompleted, MESSAGE_MILESTONE_NOT_COMPLETED_YET);
        }

        Test.startTest();
        //Actualizar caso
        for(Case c: cases)
        {
            c.Status = 'Asignado';
        }
        update cases;
        Test.stopTest();

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesUpdated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cmilestone: milestonesUpdated)
        {
            System.assertEquals(false, cmilestone.isCompleted, 'el milestone no debería estar completado porque el caso aún no se cerró');
        }
    }

    /**
    * IMPORTANTE2: este test depende de que existan EntitlementProcess en el sistema
    * @author jjuaristi@seidor.es
    * @date 24/10/2022
    */
    @isTest
    static void test_completeUSPMilestonesWhenClosedOrPending_ok()
    {
        Id rtUSPId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();

        List<Entitlement> ents = [SELECT Id FROM Entitlement WHERE Name = 'DefaultUsp'];
        System.assertEquals(false, ents.isEmpty(),MESSAGE_ENTITLEMENTS);

        //Crear caso
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 3; i++)
        {   
            Case caso = new Case(RecordTypeId = rtUSPId);
            caso.EntitlementId = ents[0].Id;
            cases.add(caso);
        }
        insert cases;

        //Comprobar que los milestones no están completados
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted, MilestoneType.Name FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesCreated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cm: milestonesCreated)
        {
            System.assertEquals(false, cm.isCompleted, MESSAGE_MILESTONE_NOT_COMPLETED_YET);
        }

        Test.startTest();
        //Actualizar caso
        for(Case c: cases)
        {
            //No se puede pasar a closed directamente
            c.Status = 'Asignado';
        }
        update cases;
        for(Case c: cases)
        {
            //No se puede pasar a closed directamente
            c.Status = 'Respondido';
        }
        update cases;
        for(Case c: cases)
        {
            c.Status = 'Cerrado';
        }
        update cases;
        Test.stopTest();

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesUpdated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cmilestone: milestonesUpdated)
        {
            System.assertEquals(true, cmilestone.isCompleted, 'el milestone debería estar completado ya');
        }
    }

    /*
    * Test del método que relaciona los casos que no tienen cliente con su cliente cuando este se ha creado posteriormente
    * @author jjuaristi@seidor.es
    * @date 20/10/2022
    */
    @isTest
    static void test_relateCasesToNewAccounts_OK()
    {
        // Se establece el recordtype para que el proceso relacione los casos con esta cuenta
        Account customer = [SELECT Id, NationalId__c FROM Account LIMIT 1];
        AccountsSelector accSel = new AccountsSelector(); 
        customer.RecordTypeId = accSel.rtCustomerId;
        update customer;

        // Se establece recordType y CIF para que se relacionen
        List<Case> cases = [SELECT Id, MediatedCustomer__c, RobotDocumentId__c FROM case];
        for(Case currentCase : cases)
        {
            currentCase.RecordTypeId = CaseUtil.rtUSPId;
            currentCase.RobotDocumentId__c = customer.NationalId__c;
        }

        // Se comprueba que la relación no existía previamente
        for(Case currentCase : cases)
        {
            System.assertEquals(null, currentCase.MediatedCustomer__c, 'No deberia haber customer');
        }

        List<Case> casesToUpdate = CaseUtil.relateCasesToNewAccounts(cases, '5');

        // Se comprueba que se ha hecho bien la relación
        for(Case currentCase : casesToUpdate)
        {
            System.assertNotEquals(null, currentCase.MediatedCustomer__c, 'Deberia haber customer');
        }
    }

    /*
    * Test del método que relaciona los casos que no tienen oferta con su oferta cuando esta se ha creado posteriormente
    * @author lrodriguez6@seidor.es
    * @date 14/11/2022
    */
    @isTest
    static void test_relateCasesToNewOffers_OK()
    {
        Account cuenta = [SELECT Id, NationalId__c FROM Account LIMIT 1];
        //oferta
        Opportunity oferta= new Opportunity();
        oferta.InfoQuoteNumber__c='11111';
        oferta.Name='Test';
        oferta.AccountId=cuenta.Id;
        oferta.StageName='Quoted';
        oferta.CloseDate=System.today()+1;

        insert oferta;
        // Se establece recordType y oferta creada para que se relacionen
        List<Case> cases = [SELECT Id,OfferId__c,CreatedOffer__c,RobotDocumentId__c FROM case];

        for(Case currentCase : cases)
        {
            currentCase.RecordTypeId = CaseUtil.rtUSPId;
            currentCase.CreatedOffer__c = oferta.InfoQuoteNumber__c;
        }

        // Se comprueba que la relación no existía previamente
        for(Case currentCase : cases)
        {
            System.assertEquals(null, currentCase.OfferId__c, 'No deberia haber oferta');
        }

        List<Case> casesToUpdate = CaseUtil.relateCasesToNewAccounts(cases, '5');

        // Se comprueba que se ha hecho bien la relación
        for(Case currentCase : casesToUpdate)
        {
            System.assertNotEquals(null, currentCase.OfferId__c, 'Deberia haber oferta');
        }
    }


    /*
    * Test del método que comprueba la tipificación de un caso sin tener en cuenta el recordType. Resultado OK (Encuentra la tipificacion)
    * @author arcortazar
    * @date 18/11/2022
    */
    @IsTest
    public static void test_checkTypification_OK()
    {

        Map<String, List<String>> mapaT1 = SystemUtil.getDependantPicklistValues('Case', 'Type', 'Subtype__c');
        Map<String, List<String>> mapaT2 = SystemUtil.getDependantPicklistValues('Case', 'Subtype__c', 'TypeN3__c');

        List<String> listaT1 = new List<String>(mapaT1.keySet());
        String tipo = listaT1.get(0);
        String subtipo = mapaT1.get(tipo).get(0);
        String tipoN3 = mapaT2.get(subtipo).get(0);

        List<Account> listaAccounts = [SELECT id FROM Account];
        List<Case> listaCasos = TestDataFactory.generateCasesForEachAccount(listaAccounts, 1);

        listaCasos[0].Type = tipo;
        listaCasos[0].Subtype__c = subtipo;
        listaCasos[0].TypeN3__c = tipoN3;

        Boolean resultado;
        test.startTest();
        resultado = CaseUtil.checkTypification(listaCasos[0]);
        test.stopTest();

        System.assertEquals(true, resultado);
    }

    /*
    * Test del método que comprueba la tipificación de un caso sin tener en cuenta el recordType. Resultado KO (No encuentra la tipificacion)
    * @author arcortazar
    * @date 18/11/2022
    */
    @IsTest
    public static void test_checkTypification_KO()
    {
        Map<String, List<String>> mapaT1 = SystemUtil.getDependantPicklistValues('Case', 'Type', 'Subtype__c');

        List<String> listaT1 = new List<String>(mapaT1.keySet());
        String tipo = listaT1.get(0);
        String subtipo = mapaT1.get(tipo).get(0);

        List<Account> listaAccounts = [SELECT id FROM Account];
        List<Case> listaCasos = TestDataFactory.generateCasesForEachAccount(listaAccounts, 1);
        
        listaCasos[0].Type = tipo;
        listaCasos[0].Subtype__c = subtipo;
        listaCasos[0].TypeN3__c = 'Inventamos';

        Boolean resultado;
        test.startTest();
        resultado = CaseUtil.checkTypification(listaCasos[0]);
        test.stopTest();

        System.assertEquals(false, resultado);
    }

    /*
    * Test del método que comprueba la tipificación de un caso teniendo en cuenta el recordType. Resultado OK (No encuentra la tipificacion)
    * @author arcortazar
    * @date 15/02/2023
    */
    @IsTest
    public static void test_checkTypificationByRecordType_OK()
    {
        String recordTypeOCS = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        
        Boolean resultado;
        test.startTest();
        resultado = CaseUtil.checkTypificationByRecordType('A', 'A1', 'A11', recordTypeOCS);
        test.stopTest();

        System.assertEquals(true, resultado);
    }

    /*
    * Test del método que comprueba la tipificación de un caso teniendo en cuenta el recordType. Resultado KO (No encuentra la tipificacion)
    * @author arcortazar
    * @date 15/02/2023
    */
    @IsTest
    public static void test_checkTypificationByRecordType_KO()
    {
        String recordTypeOCS = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        
        Boolean resultado;
        test.startTest();
        resultado = CaseUtil.checkTypificationByRecordType('A', 'A1', 'A12', recordTypeOCS);
        test.stopTest();

        System.assertEquals(false, resultado);
    }

    /*
    * Test del método que calcula el ratio de conversión en las cuentas con recordType Intermediary
    * @author lrodriguez6@seidor.es
    * @date 09/02/2023
    *
    * @change amiranda 18/05/2023 Refactorizar método para tener en cuenta que el método
    * 'Case.generateAccountRatio' no devuelve una lista ordenada.
    */
    @IsTest
    public static void test_generateAccountRatio_OK()
    {  
        // Crear cuentas intermediarios
        List<Account> createdAccountsIntermediary = TestDataFactory.generateAccounts('001', 'Intermediary', 2);
        insert createdAccountsIntermediary;
       
        // Crear casos relacionados con los intermediarios
        List<Case> casesRelatedToIntermediaries = TestDataFactory.generateCasesForEachAccount(createdAccountsIntermediary, 4);
        insert casesRelatedToIntermediaries;

        for (Case caseRelatedToIntermediary : casesRelatedToIntermediaries)
        {
            caseRelatedToIntermediary.Type = 'Venta';
            caseRelatedToIntermediary.RecordTypeId = CaseUtil.rtUSPId;
            caseRelatedToIntermediary.Status = 'Cerrado';
            caseRelatedToIntermediary.QuotationStage__c = 'Work In Progress';
        }
        update casesRelatedToIntermediaries;

        // Marcar un caso como ganado
        Case wonCase = casesRelatedToIntermediaries.get(0);
        wonCase.QuotationStage__c = 'Won';
        update wonCase;

        // Crear un mapa para almacenar los valores esperados de USPConversionRatio__c
        Map<Id, Integer> expectedRatioByAccountId = new Map<Id, Integer>();
        for (Account createdAccountIntermediary : createdAccountsIntermediary)
        {
            expectedRatioByAccountId.put(createdAccountIntermediary.Id, (createdAccountIntermediary.Id == wonCase.AccountId) ? 25 : 0);
        }

        test.startTest();
        List<Account> accountsUpdateRatio = CaseUtil.generateAccountRatio(createdAccountsIntermediary);
        test.stopTest();

        // Verificar los valores esperados
        for (Account accountUpdateRatio : accountsUpdateRatio)
        {
            Decimal expectedRatio = expectedRatioByAccountId.get(accountUpdateRatio.Id);
            Decimal actualRatio = accountUpdateRatio.USPConversionRatio__c;

            Assert.areEqual(expectedRatio,
                            actualRatio,
                            'El ratio de conversión esperado no coincide con el valor obtenido.');
        }
    }

     /*
    * Test del método que actualiza los casos con la póliza/oferta indicada en el campo de Hegeo
    * @author arcortazar
    * @date 23/03/2023
    */
    @IsTest
    public static void test_relateCasesToPolicyOffers_OK()
    {   //Crear cuentas intermediarios
        List<Account> createdAccounts = [SELECT Id FROM Account LIMIT 1];
        //Crear casos relacionados con los intermediarios
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(createdAccounts, 2);
        insert cases;
        
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(createdAccounts, 1);
        insert policies;

        List<Opportunity> offers = TestDataFactory.generateOpportunitiesForEachAccount(createdAccounts, 'General', 'New', System.today().addDays(10), 1);
        insert offers;

        List<Case> allCases= [SELECT Id, PolicyId__c, OfferId__c, HegeoOfferId__c, HegeoPolicyId__c, HegeoPrePolicyId__c FROM Case];
        List<Policy__c> allPolicies= [SELECT Id,InfoPolicyNumber__c FROM Policy__c];
        List<Opportunity> allOffers= [SELECT Id,Name FROM Opportunity];

        allCases[0].HegeoOfferId__c = allOffers[0].Name;
        allCases[1].HegeoPolicyId__c = allPolicies[0].InfoPolicyNumber__c;
        update allCases;

        test.startTest();
        List<Case> updatedCases=CaseUtil.relateCasesToPolicyOffers(allCases);
        test.stopTest();

        System.assertEquals(allOffers[0].Id,updatedCases[0].OfferId__c);
        System.assertEquals(allPolicies[0].Id,updatedCases[1].PolicyId__c);
    }

    /*
    * Test que comprueba que se actualizan correctamente los contactos asociados a los casos
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_getCasesToUpdateContactFromEmailToCase()
    {
        // Crear datos de prueba: Caso y Contacto relacionado
        Case caso = new Case(Origin = 'Email', SuppliedEmail = 'test@test.com', LegalEntity__c = LABEL_GENERAL_INSURANCE, 
                            SourceCountry__c = 'US', Partner__c = 'TestPartner', 
                            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry').getRecordTypeId());
        insert caso;
        
        Contact contactoSF = new Contact(Email = 'test@test.com', LegalEntity__c = LABEL_GENERAL_INSURANCE, SourceCountry__c = 'US', 
                                        Partner__c = 'TestPartner', LastName = 'Prueba contactoSF',
                                        RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId());
        insert contactoSF;
        
        List<Case> updateCases = new List<Case>();

        // Ejecutar el código a probar
        Test.startTest();
        updateCases = CaseUtil.getCasesToUpdateContactFromEmailToCase (updateCases,caso);
        Test.stopTest();
        
        // Validar los resultados
        System.assertEquals(1, updateCases.size(), 'Se esperaba que se actualizara 1 caso');
        System.assertEquals(contactoSF.Id, updateCases[0].ContactId, 'El Id de contacto asignado al caso no es el esperado');
        System.assertEquals('Email', updateCases[0].CustomerFoundBy__c, MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT);
    }

    /*
    * Test que comprueba que se obtienen correctamente los casos para que sea marcado el campo CaseMilestone a completado
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_getCasesToMarkMilestonesCompletedWhenClose()
    {
        // Crea datos de prueba
        Id rtOCSInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        Case oldCase = new Case(Status = 'Abierto', RecordTypeId = rtOCSInquiryId);
        Case newCase = new Case(Status = 'Cerrado', RecordTypeId = rtOCSInquiryId);
        insert new List<Case>{oldCase, newCase};

        List<Case> caseList = [Select id,Status,RecordTypeId,SlaExitDate from Case where id =:newCase.Id];
        
        Test.startTest();
        // Ejecuta la función a probar
        List<Case> updatedCases = CaseUtil.getCasesToMarkMilestonesCompletedWhenClose(caseList, new Map<Id, Case>{newCase.Id => oldCase});
        Test.stopTest();

        // Verifica el resultado esperado
        System.assertEquals(1, updatedCases.size(), 'El número de casos actualizados no coincide con el esperado');
        System.assertEquals(newCase.Id, updatedCases[0].Id, 'El caso actualizado no coincide con el esperado');
    }

    /*
    * Test que comprueba que se asocia correctamente la póliza y el contacto al caso
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_updatePolicyToCaseifCaseDoesNotHavePolicy()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        Id rtId = SystemUtil.getOrderRecordTypeIdByName('PolicyGI');

        Contact contactOrder = [Select id from Contact limit 1];
        Account accountOrder = [SELECT Id FROM Account LIMIT 1];

        // Crear objeto Case
        Case caso = new Case();
        caso.PolicyNum__c = '12345';
        caso.Partner__c = 'Partner1';
        caso.sourceCountry__c = 'France';
        insert caso;

        // Crear registro de prueba de Order
        Order policy = new Order();
        policy.PolicyNum__c = 'PartnerName1-12345';
        policy.ContactId__c = contactOrder.Id;
        policy.LegalEntity__c = LABEL_GENERAL_INSURANCE;
        policy.RecordTypeId = rtId;
        policy.AccountId = accountOrder.Id;
        policy.EffectiveDate = Date.valueOf('1994-01-01') ;
        policy.Status = 'Sync';
        insert policy;

        // Crear mapa de prueba mapMultiPartner
        Map<String, String> mapMultiPartner = new Map<String, String>();
        mapMultiPartner.put('Partner1', 'PartnerName1');

        // Llamar al método de prueba
        Test.startTest();
        caso = CaseUtil.updatePolicyToCaseifCaseDoesNotHavePolicy(adminSetup, caso, mapMultiPartner);
        Test.stopTest();

        // Verificar los resultados esperados
        System.assertEquals('PartnerName1-12345', caso.PolicyNum__c, 'El valor de PolicyNum__c en el caso no se actualizó correctamente');
        System.assertEquals(contactOrder.Id, caso.ContactId, MESSAGE_CONTACTID_NOT_CORRECT);
        System.assertEquals(policy.Id, caso.Policy__c, 'El valor de Policy__c en el caso no se actualizó correctamente');
        System.assertEquals(LABEL_GENERAL_INSURANCE, caso.LegalEntity__c,'El valor de LegalEntity__c en el caso no se actualizó correctamente');
        System.assertEquals('Policy Number', caso.CustomerFoundBy__c,MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT);
    }

    /*
    * Test que comprueba que se asocia correctamente el contacto al caso
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_updateContactToCaseByEmail()
    {
        // Crear registros de prueba necesarios
        // Crear objeto Case
        Case caso = new Case();
        caso.SuppliedEmail = 'test@example.com';
        caso.LegalEntity__c = LABEL_GENERAL_INSURANCE;
        caso.SourceCountry__c = 'France';
        caso.Partner__c = 'Partner1';
        insert caso;

        // Crear registro de prueba de Contact
        Contact contactoSF = new Contact();
        contactoSF.LastName = 'ContactSF prueba';
        contactoSF.Email = caso.SuppliedEmail;
        contactoSF.LegalEntity__c = caso.LegalEntity__c;
        contactoSF.SourceCountry__c = caso.SourceCountry__c;
        contactoSF.Partner__c = caso.Partner__c;
        contactoSF.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
        insert contactoSF;

        // Llamar al método de prueba
        Test.startTest();
        caso = CaseUtil.updateContactToCaseByEmail(caso);
        Test.stopTest();

        // Verificar los resultados esperados
        System.assertEquals(contactoSF.Id, caso.ContactId, MESSAGE_CONTACTID_NOT_CORRECT );
        System.assertEquals('Email', caso.CustomerFoundBy__c, MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT);
    }

    /*
    * Test que comprueba que se asocia correctamente el contacto al caso
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_updateContactToCaseByPhone()
    {
        // Crear registros de prueba necesarios
        // Crear objeto Case
        Case caso = new Case();
        caso.SuppliedPhone = '604324568';
        caso.LegalEntity__c = LABEL_GENERAL_INSURANCE;
        caso.SourceCountry__c = 'France';
        caso.Partner__c = 'Partner1';
        insert caso;

        // Crear registro de prueba de Contact
        Contact contactoSF = new Contact();
        contactoSF.LastName = 'ContactSF prueba';
        contactoSF.MobilePhone = caso.SuppliedPhone;
        contactoSF.LegalEntity__c = caso.LegalEntity__c;
        contactoSF.SourceCountry__c = caso.SourceCountry__c;
        contactoSF.Partner__c = caso.Partner__c;
        contactoSF.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
        insert contactoSF;

        // Llamar al método de prueba
        Test.startTest();
        caso = CaseUtil.updateContactToCaseByPhone(caso);
        Test.stopTest();

        // Verificar los resultados esperados
        System.assertEquals(contactoSF.Id, caso.ContactId, MESSAGE_CONTACTID_NOT_CORRECT );
        System.assertEquals('Phone', caso.CustomerFoundBy__c, MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT);
    }

    /*
    * Test que comprueba que se añade correctamente la traducción al campo tipo del caso si el caso proviene de la web de francia
    * @author aberuete
    * @date 18/04/2023
    */
    @IsTest
    public static void test_ifCaseFromWebFranceUpdateTranslationToCase()
    {
        // Crear registros de prueba necesarios
        // Crear objeto Case
        Case caso = new Case();
        caso.SourceCountry__c = 'France';
        caso.Origin = 'Web';
        caso.Type = 'Contratar mi seguro';
        caso.Subtype__c = 'Close result';
        insert caso;

        // Llamar al método de prueba
        Test.startTest();
        caso = CaseUtil.ifCaseFromWebFranceUpdateTranslationToCase(caso);
        Test.stopTest();

        // Verificar los resultados esperados
        System.assertEquals('Souscrire mon assurance', caso.Type_translation__c,'El valor de Type_translation__c en el caso no se actualizó correctamente' );
    }

    /*
    * Test que comprueba que se actualizan correctamente los valores del caso proveniente del email to case de transcom antes de insertarlo
    * @author aberuete
    * @date 22/06/2023
    */
    @IsTest
    public static void test_updateTranscomCase()
    {
        List<Group> queueRetencion = new GroupSelector().findByName('Email_TWW_Retencion');
        List<Group> queueAnulacion = new GroupSelector().findByName('Email_TWW_Anulacion');
        List<Case> caseList = new List<Case>();
        
        Id ocsInquiry = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry')?.getRecordTypeId();

        Case caso = new Case();
        caso.RecordTypeId = ocsInquiry;
        caso.OwnerId = queueRetencion[0].id;
        caso.Origin = 'Email';
        caseList.add(caso);

        Case caso2 = new Case();
        caso2.RecordTypeId = ocsInquiry;
        caso2.OwnerId = queueAnulacion[0].id;
        caso2.Origin = 'Email';
        caseList.add(caso2);
        
        Test.startTest();
        insert caseList;
        Test.stopTest();

        Case caseAfterInsertRetencion = [Select id,CallCenter__c,SourceArea__c,Type,Subtype__c,TypeN3__c from case where ownerid =: queueRetencion[0].id limit 1];
        Case caseAfterInsertAnulacion = [Select id,CallCenter__c,SourceArea__c,Type,Subtype__c,TypeN3__c from case where ownerid =: queueAnulacion[0].id limit 1];

        System.assertEquals('TWW Retención', caseAfterInsertRetencion.CallCenter__c, 'El call center del caso retención no es correcto');
        System.assertEquals('End customer partner', caseAfterInsertRetencion.SourceArea__c, 'El area del caso retención no es correcto');
        System.assertEquals('Gestión Servicios', caseAfterInsertRetencion.Type, 'El tipo del caso retención no es correcto');
        System.assertEquals(LABEL_ANULACION, caseAfterInsertRetencion.Subtype__c, 'El subtipo del caso retención no es correcto');
        System.assertEquals(LABEL_ANULACION, caseAfterInsertRetencion.TypeN3__c, 'El tipo N3 del caso retención no es correcto');
        System.assertEquals('TWW Retención', caseAfterInsertAnulacion.CallCenter__c, 'El call center del caso anulación no es correcto');
        System.assertEquals('Generic end customer', caseAfterInsertAnulacion.SourceArea__c, 'El area del caso anulación no es correcto');
        System.assertEquals('Gestión Servicios', caseAfterInsertAnulacion.Type, 'El tipo del caso anulación no es correcto');
        System.assertEquals(LABEL_ANULACION, caseAfterInsertAnulacion.Subtype__c, 'El subtipo del caso anulación no es correcto');
        System.assertEquals(LABEL_ANULACION, caseAfterInsertAnulacion.TypeN3__c, 'El tipo N3 del caso anulación no es correcto');
    }
}