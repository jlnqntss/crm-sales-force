@isTest
private class CaseUtilTest
{

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
        System.assertEquals(false, expectedCases.isEmpty(), 'Se deben de haber creado como mínimo 1 caso!');

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
        System.assertEquals(false, expectedCases.isEmpty(), 'Se deben de haber creado como mínimo 1 caso!');

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
        System.assertEquals(false, expectedCases.isEmpty(), 'Se deben de haber creado como mínimo 1 caso!');

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
        System.assertEquals(false, ents.isEmpty(),'deberían existir entitlements, al menos el Default');

        List<Case> casesEnt = [SELECT Id, EntitlementId FROM Case];
        System.assertEquals(false, casesEnt.isEmpty(),'los casos deberían haberse insertado');
        System.assertEquals(ents[0].Id, casesEnt[0].EntitlementId,'los casos deberían tener entitlement asociado');

        //Comprobar que los milestones no están completados
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesCreated.isEmpty(),'los casos deberían tener casemilestones asociados');
        for(CaseMilestone cm: milestonesCreated)
        {
            System.assertEquals(false, cm.isCompleted, 'el milestone no debería estar completado aún');
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
        System.assertEquals(false, milestonesUpdated.isEmpty(),'los casos deberían tener casemilestones asociados');
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
        System.assertEquals(false, ents.isEmpty(),'deberían existir entitlements, al menos el Default');

        List<Case> casesEnt = [SELECT Id, EntitlementId FROM Case];
        System.assertEquals(false, casesEnt.isEmpty(),'los casos deberían haberse insertado');
        System.assertEquals(ents[0].Id, casesEnt[0].EntitlementId,'los casos deberían tener entitlement asociado');

        //Comprobar que los milestones no están completados
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN :cases];
        System.assertEquals(false, milestonesCreated.isEmpty(),'los casos deberían tener casemilestones asociados');
        for(CaseMilestone cm: milestonesCreated)
        {
            System.assertEquals(false, cm.isCompleted, 'el milestone no debería estar completado aún');
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
        System.assertEquals(false, milestonesUpdated.isEmpty(),'los casos deberían tener casemilestones asociados');
        for(CaseMilestone cmilestone: milestonesUpdated)
        {
            System.assertEquals(false, cmilestone.isCompleted, 'el milestone no debería estar completado porque el caso aún no se cerró');
        }
    }

    /**
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
        CasesSelector caseSel = new CasesSelector(); 
        for(Case currentCase : cases)
        {
            currentCase.RecordTypeId = caseSel.rtUSPId;
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
}
