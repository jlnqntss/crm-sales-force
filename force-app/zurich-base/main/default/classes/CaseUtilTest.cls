/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 08-03-2024
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class CaseUtilTest
{
    static final String MESSAGE_UN_CASO_CREADO = 'Se debe de haber creado como mínimo 1 caso!';
    static final String MESSAGE_ENTITLEMENTS = 'Deberían existir entitlements, al menos el Default';
    static final String MESSAGE_CASEMILESTONES = 'Los casos deberían tener casemilestones asociados';
    static final String MESSAGE_MILESTONE_NOT_COMPLETED_YET = 'El milestone no debería estar completado aún';
    static final String MESSAGE_CUSTOMERFOUNDBY_NOT_CORRECT = 'El valor de CustomerFoundBy__c en el caso no se actualizó correctamente';
    static final String MESSAGE_CONTACTID_NOT_CORRECT = 'El valor de ContactId en el caso no se actualizó correctamente';
    static final String LABEL_GENERAL_INSURANCE = 'General Insurance';
    static final String LABEL_ANULACION = 'Anulación';
    static final String MESSAGE_CUENTA_NO_ASIGNADA = 'La cuenta no se ha asignado correctamente';
    static final String LABEL_SUBJECT_ZURICH = 'Solicitud de ayuda al registro de MiZurich';
    static final String EMAIL_CASE = 'exampletocontactpointemail@gmail.com.invalid';

    static final String ROBOT_TYPE_N1 = 'Dorsales';

    static final String SHORT_DESCRIPTION = 'test';
    static final String LONG_DESCRIPTION = 'Se diferencia clientes empresas de clientes personas. Se detecta que las empresas no usan el campo Firstname o le colocan un punto. También es posible filtrar los Contactos que no están activos.  De esta manera que extraen los datos por medio de la fecha de creación. Consiguiendo finalizar la operación en 3 ficheros';

    @TestSetup
    private static void createScenario()
    {

        /*****************************  CUSTOM SETTINGS  ****************************/
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

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
        Entitlement entitlementUsp = new Entitlement( AccountId = cuentaHolder.Id, Name = 'DefaultUsp', SlaProcessId = slasUsp[0].Id, StartDate = System.today() );
        insert entitlementUsp;

         /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 1);
        intermediaryAccounts.get(0).INFOIntermediaryCode__c = '0000012345';
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 1);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            // Usuario Nominal
            String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 1);
            userList[0].ContactId = contacts[0].Id;
            insert userList;
        }
    }

    /**
     * Prueba a que estén rellenos Case.AccountId y Case.ContactId si se encontró
     * un cliente a través del ContactPointEmail
     */
    @isTest
    private static void test_assignAccountAndContactFromSuppliedEmail_ok()
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
        Case caso = new Case( SuppliedEmail = emailsToSearch[0], RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY);
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN : cases];
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
    private static void test_assignAccountAndContactFromSuppliedEmail_ko_MoreThanOne()
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
        Case caso = new Case( SuppliedEmail = emailsToSearch[0], RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY);
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN : cases];
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
    private static void test_assignAccountAndContactFromSuppliedEmail_ko_NoExists()
    {
        Test.startTest();
        //Crear caso
        List<Case> cases = new List<Case>();
        Case caso = new Case( SuppliedEmail = 'noexistoentrelosemailscreados@nts-solutions.com', RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY);
        cases.add(caso);
        //insertarlo
        insert cases;
        Test.stopTest();

        //Recuperar de nuevo los test insertados
        List<Case> expectedCases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id IN : cases];
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
    private static void test_markMilestonesCompletedWhenClose_ok()
    {
        Id rtOCSInquiryId = CaseUtil.RT_ID_OCSINQUIRY;

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
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
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

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
        System.assertEquals(false, milestonesUpdated.isEmpty(),MESSAGE_CASEMILESTONES);
        for(CaseMilestone cmilestone: milestonesUpdated)
        {
            System.assertEquals(true, cmilestone.isCompleted, 'el milestone debería estar completado ya');
        }
    }

    /**
     * Se comprueba que los procesos que asignan los atributos para la clasificación del caso operan correctamente.
     * En este escenario se inserta un caso con una clasificación o TAG previa, esta clasificación se realiza fuera de Salesforce.
     * Con la clasificación previa, Salesforce inluye el resto de atributos del caso.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     */
    @isTest
    private static void test_setSprinklrCaseTipification()
    {
        Case newSprinklrCase = new Case ();
        newSprinklrCase.RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR;
        newSprinklrCase.RobotTypeN1__c = 'Dorsales';
        newSprinklrCase.Subject = 'test_setSprinklrCaseTipification';
        newSprinklrCase.SuppliedEmail = 'sprinklrCase@zurich.com';

        Test.startTest();
        insert newSprinklrCase;
        Test.stopTest();

        Case caseToCompare = [SELECT Id, RobotTypeN1__c, Type, SubType__c, TypeN3__c, CallCenter__c, OwnerId FROM Case WHERE id =: newSprinklrCase.id];
        Robot_Hegeo_Field_Mapping__mdt expectedValues = [SELECT Type__c, SubType__c, TypeN3__c FROM Robot_Hegeo_Field_Mapping__mdt WHERE SourceType__c =: newSprinklrCase.RobotTypeN1__c LIMIT 1];
        Assert.areEqual(expectedValues.Type__c, caseToCompare.Type);
        Assert.areEqual(expectedValues.SubType__c, caseToCompare.Subtype__c);
        Assert.areEqual(expectedValues.TypeN3__c, caseToCompare.TypeN3__c);
    }

    /**
     * Test que comprueba la correcta inserción de caso tipo Sprinklr con una descripcion menor a 255 caracteres
     * El caso debe ser insertado con el mismo valor para Description que para PrimerMensaje__c
     */
    @isTest
    private static void test_descriptionCaseShort()
    {
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();
        List<Case> newList = new List<Case>();

        Case caseShortDescription = new Case();
        caseShortDescription.RecordTypeId = rtOCSSprinklrId;
        caseShortDescription.RobotTypeN1__c = ROBOT_TYPE_N1;
        caseShortDescription.Description = SHORT_DESCRIPTION;

        newList.add(caseShortDescription);

        insert newList;

        Case caseToCompareShort = [SELECT id,Description, PrimerMensaje__c FROM Case where id =: caseShortDescription.id];

        System.assertEquals(caseToCompareShort.Description.length() == caseToCompareShort.PrimerMensaje__c.length(), true, 'Se ha asignado bien el campo PrimerMensaje__c');
    }

    /**
     * Test que comprueba la correcta inserción de caso tipo Sprinklr con una descripcion superior a 255 caracteres
     * El caso debe ser insertado con el campo PrimerMensaje__c acotado a 255 caracteres.
     */
    @isTest
    private static void test_descriptionCaseLong()
    {
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();
        List<Case> newList = new List<Case>();

        Case caseLongDescription = new Case();
        caseLongDescription.RecordTypeId = rtOCSSprinklrId;
        caseLongDescription.RobotTypeN1__c = ROBOT_TYPE_N1;
        caseLongDescription.Description = LONG_DESCRIPTION;

        newList.add(caseLongDescription);

        insert newList;

        Case caseToCompareLong = [SELECT id,Description, PrimerMensaje__c FROM Case where id =: caseLongDescription.id];
        System.assertEquals(caseToCompareLong.PrimerMensaje__c.length()  < 256, true,'El campo PrimerMensaje__c no supera el límite de caracteres');
    }

    /**
     * Test que comprueba la correcta inserción de caso tipo Sprinklr con una descripcion nula
     * El caso debe ser insertado correctamente.
     */
    @isTest
    private static void test_descriptionCaseNull()
    {
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();
        List<Case> newList = new List<Case>();
        Case caseNullDescription = new Case();

        caseNullDescription.RecordTypeId = rtOCSSprinklrId;
        caseNullDescription.RobotTypeN1__c = ROBOT_TYPE_N1;

        newList.add(caseNullDescription);

        insert newList;

        Case caseToCompareNull = [SELECT id,Description, PrimerMensaje__c FROM Case where id =: caseNullDescription.id];
        System.assertEquals(caseToCompareNull.PrimerMensaje__c == null, true,'Description era nulo y ha sido correctamente insertado el caso');
    }

    /**
     * Se valida que el metodo relateCasesByTicketId relaciona correctamente los casos por el TicketId__c y RelatedRequestId__c, para ello:
     * - Se crea un caso sin RelatedRequestId__c. No debe vincular nada
     * - Se crea un caso con RelatedRequestId__c, pero no existe el 'parent'. No debe vincular nada
     * - Se crea un caso con RelatedRequestId__c, el 'parent' existe. Debe vincular con el parent
     * - Se crea un caso con RelatedRequestId__c, el 'parent' existe pero no es de ZDA (no deberia suceder). No debe vincular nada
     *
     * @author mario.navarro@seidor.com
     * @date 09/04/2024
     */
    @isTest
    private static void test_relateCasesByTicketId()
    {
        Case parentCaseZDA = new Case(
            TicketId__c = 1,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Caso padre ZDA'
            );
        Case parentCaseNoZDA = new Case(
            TicketId__c = 2,
            RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR,
            Subject = 'Caso padre no ZDA'
            );
        insert new List<Case> {parentCaseZDA, parentCaseNoZDA};

        List<Case> parentsCreated = [SELECT Id FROM Case WHERE TicketId__c IN (1,2)];
        Assert.areEqual( 2, parentsCreated.size() );

        Case noRelatedCase = new Case(
            TicketId__c = 10,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso no relacionado'
            );
        Case relatedWithoutParentCase = new Case(
            TicketId__c = 20,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso relacionado sin parent',
            RelatedRequestId__c = 666
            );
        Case relatedWithParentCase = new Case(
            TicketId__c = 30,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso relacionado con parent',
            RelatedRequestId__c = parentCaseZDA.TicketId__c
            );
        Case relatedWithParentCaseNoZDA = new Case(
            TicketId__c = 40,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso relacionado con parent no ZDA',
            RelatedRequestId__c = parentCaseNoZDA.TicketId__c
            );

        Test.startTest();
        insert new List<Case> {noRelatedCase, relatedWithoutParentCase, relatedWithParentCase, relatedWithParentCaseNoZDA};
        Test.stopTest();

        Case noRelatedCaseCreated = [SELECT Id, ParentId FROM Case WHERE Id = : noRelatedCase.Id];
        Case relatedWithoutParentCaseCreated = [SELECT Id, ParentId FROM Case WHERE Id = : relatedWithoutParentCase.Id];
        Case relatedWithParentCaseCreated = [SELECT Id, ParentId FROM Case WHERE Id = : relatedWithParentCase.Id];
        Case relatedWithParentCaseNoZDACreated = [SELECT Id, ParentId FROM Case WHERE Id = : relatedWithParentCaseNoZDA.Id];

        Assert.isNotNull(noRelatedCaseCreated);
        Assert.isNull(noRelatedCaseCreated.ParentId);
        Assert.isNotNull(relatedWithoutParentCaseCreated);
        Assert.isNull(relatedWithoutParentCaseCreated.ParentId);
        Assert.isNotNull(relatedWithParentCaseCreated);
        Assert.areEqual(parentCaseZDA.Id, relatedWithParentCaseCreated.ParentId);
        Assert.isNotNull(relatedWithParentCaseNoZDACreated);
        Assert.isNull(relatedWithParentCaseNoZDACreated.ParentId);
    }

    /**
     * Se valida que el metodo relateCasesWithMediatedAccount relaciona correctamente los casos por el
     * SuppliedEmail y el MainEmail__c de la cuenta Intermediary
     * - Se crea un caso sin SuppliedEmail. No debe vincular nada
     * - Se crea un caso con SuppliedEmail, pero no existe la cuenta. No debe vincular nada
     * - Se crea un caso con SuppliedEmail, existe la cuenta. Debe vincular con la cuenta
     * - Se crea un caso con SuppliedEmail, existela cuenta pero no es Intermediary. No debe vincular nada
     *
     * @author mario.navarro@seidor.com
     * @date 10/04/2024
     */
    @isTest
    private static void test_relateCasesWithMediatedAccount()
    {
        //generamos la cuenta de tipo Intermediary
        Account intermediaryAccount = TestDataFactory.generateAccounts('001', 'Intermediary', 1)[0];
        intermediaryAccount.MainEmail__c = 'test@mail.com';

        Account otherTypeAccount = TestDataFactory.generateAccounts('001', 'BusinessCustomer', 1)[0];
        otherTypeAccount.MainEmail__c = 'test2@mail.com';

        insert new List<Account> {intermediaryAccount, otherTypeAccount};

        Case noRelatedCase = new Case(
            TicketId__c = 10,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Origin = 'CanalUnico',
            Subject = 'Asunto de caso sin mediador'
            );
        Case relatedWithoutAccount = new Case(
            TicketId__c = 20,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Origin = 'CanalUnico',
            Subject = 'Asunto de caso con mediador inexistente',
            SuppliedEmail = 'notExisting@email.com'
            );
        Case relatedWithAccount = new Case(
            TicketId__c = 30,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Origin = 'CanalUnico',
            Subject = 'Asunto de caso con mediador existente',
            SuppliedEmail = intermediaryAccount.MainEmail__c
            );
        Case relatedWithNoIntermediaryAcc = new Case(
            TicketId__c = 40,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Origin = 'CanalUnico',
            Subject = 'Asunto de caso con mail de cuenta no mediadora',
            SuppliedEmail = otherTypeAccount.MainEmail__c
            );

        Test.startTest();
        insert new List<Case> {noRelatedCase, relatedWithoutAccount, relatedWithAccount, relatedWithNoIntermediaryAcc};
        Test.stopTest();

        Case noRelatedCaseCreated = [SELECT AccountId FROM Case WHERE Id = : noRelatedCase.Id];
        Case relatedWithoutAccountCreated = [SELECT AccountId FROM Case WHERE Id = : relatedWithoutAccount.Id];
        Case relatedWithAccountCreated = [SELECT AccountId FROM Case WHERE Id = : relatedWithAccount.Id];
        Case relatedWithNoIntermediaryAccCreated = [SELECT AccountId FROM Case WHERE Id = : relatedWithNoIntermediaryAcc.Id];

        Assert.isNotNull(noRelatedCaseCreated);
        Assert.isNull(noRelatedCaseCreated.AccountId);
        Assert.isNotNull(relatedWithoutAccountCreated);
        Assert.isNull(relatedWithoutAccountCreated.AccountId);
        Assert.isNotNull(relatedWithAccountCreated);
        Assert.areEqual(intermediaryAccount.Id, relatedWithAccountCreated.AccountId);
        Assert.isNotNull(relatedWithNoIntermediaryAccCreated);
        Assert.isNull(relatedWithNoIntermediaryAccCreated.AccountId);
    }

    /**
     * Se comprueba que los procesos que asignan los atributos para la clasificación del caso operan correctamente.
     * En este escenario se inserta un caso SIN una clasificación o TAG previa, esta clasificación se realiza fuera de Salesforce.
     * El caso se clasifica utilizando la configuración por defecto.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     */
    @isTest
    private static void test_setSprinklrCaseTipificationWithInvalidConfiguration()
    {
        Case newSprinklrCase = new Case ();
        newSprinklrCase.RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR;
        newSprinklrCase.Subject = 'test_setSprinklrCaseTipificationWithInvalidConfiguration';
        newSprinklrCase.SuppliedEmail = 'sprinklrCase@zurich.com';

        Test.startTest();
        insert newSprinklrCase;
        Test.stopTest();

        Case caseToCompare = [SELECT Id, RobotTypeN1__c, Type, SubType__c, TypeN3__c, CallCenter__c, OwnerId FROM Case WHERE id =: newSprinklrCase.id];
        Robot_Hegeo_Field_Mapping__mdt expectedValues = [SELECT Type__c, SubType__c, TypeN3__c FROM Robot_Hegeo_Field_Mapping__mdt WHERE SourceType__c =: CaseUtil.DEFAULT_SPRINKLR_CASE_TIPIFICATION];
        Assert.areEqual(expectedValues.Type__c, caseToCompare.Type);
        Assert.areEqual(expectedValues.SubType__c, caseToCompare.Subtype__c);
        Assert.areEqual(expectedValues.TypeN3__c, caseToCompare.TypeN3__c);
    }

    /**
     * Se comprueba que los procesos que asignan los atributos para la clasificación del caso no restringen el alta del caso.
     * En este escenario se inserta un caso con una clasificación o TAG incorrecta, es decir, las clasificación del caso no coincide con la configuración de Salesforce.
     * Esta clasificación se realiza fuera de Salesforce.
     * El caso no se clasifica pero este se guarda.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     */
    @isTest
    private static void test_setSprinklrCaseTipificationBadTag()
    {
        Case newSprinklrCase = new Case ();
        newSprinklrCase.RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR;
        newSprinklrCase.RobotTypeN1__c = 'NO EXISTE';
        newSprinklrCase.Subject = 'test_setSprinklrCaseTipificationWithInvalidConfiguration';
        newSprinklrCase.SuppliedEmail = 'sprinklrCase@zurich.com';

        Test.startTest();
        insert newSprinklrCase;
        Test.stopTest();

        Case caseToCompare = [SELECT Id, RobotTypeN1__c, Type, SubType__c, TypeN3__c, CallCenter__c, OwnerId FROM Case WHERE id =: newSprinklrCase.id];
        Assert.isNull(caseToCompare.Type);
        Assert.isNull(caseToCompare.SubType__c);
        Assert.isNull(caseToCompare.TypeN3__c);
    }



    /**
     * Se comprueba la correcta asignación de CallCenter__c y Queue para casos tipo Sprinklr que vengan con una TAGSprinklr
     * reconocida por Salesforce. Esta TAG viene establecida desde fuera del sistema.
     * @author jchavez
     * @date 04/03/2024
     */
    @isTest
    private static void test_setSprinklrCaseCallCenterAndGroup()
    {
        Case newSprinklrCase = new Case ();
        newSprinklrCase.RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR;
        newSprinklrCase.RobotTypeN1__c = 'Asistencia';
        newSprinklrCase.Subject = 'test_setSprinklrCaseCallCenterAndGroup';
        newSprinklrCase.SuppliedEmail = 'sprinklrCase@zurich.com';
        List<Group> queueSiniestrosRRSS = new GroupSelector().findByName(CaseUtil.SPRINKLR_QUEUE_SINIESTROS);

        Test.startTest();
        insert newSprinklrCase;
        Test.stopTest();

        Case caseToCompare = [SELECT Id, CallCenter__c, OwnerId FROM Case WHERE id =: newSprinklrCase.id];
        Assert.areEqual(CaseUtil.SPRINKLR_CALLCENTER_SINIESTROS, caseToCompare.CallCenter__c);
        Assert.areEqual(queueSiniestrosRRSS[0].id, caseToCompare.OwnerId);

    }

    /**
     * Se comprueba que el metodo applyFormatToZDABody funciona correctamente. Para ello:
     * - Crea un caso de tipo ZDA (origen CanalUnico) con descripcion formateable. DEBE APLICAR FORMATO
     * - Crea un caso de tipo ZDA (origen CanalUnico) con sin ;;. NO DEBE HABER CAMBIOS
     * - Crea un caso de tipo ZDA (origen Web) con descripcion formateable. NO DEBE HABER CAMBIOS
     * - Crea un caso de tipo Sprinklr (origen CanalUnico) con descripcion formateable. NO DEBE HABER CAMBIOS
     *
     * @author mario.navarro@seidor.com
     * @date 08/04/2024
     */
    @isTest
    private static void test_applyFormatToZDABody()
    {
        Case newZDACaseToFormat = new Case (
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Description = 'Usuario: NOMBRE APELLIDO1 APELLIDO2;;Correo electrónico: USUARIO@bancsabadell.com;;Unidad de trabajo: 0086',
            Origin = 'CanalUnico',
            Subject = 'Caso a formatear'
            );
        String formattedText = newZDACaseToFormat.Description.replace(';;', '\n');
        Case newZDACaseNoFormat = new Case (
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Description = 'Descripcion no formateable',
            Origin = 'CanalUnico',
            Subject = 'Caso NO formatear 1'
            );
        Case newZDACaseNoFormat2 = new Case (
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Description = newZDACaseToFormat.Description,
            Origin = 'Web',
            Subject = 'Caso NO formatear 2'
            );
        Case newSprinklrCase = new Case (
            RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR,
            Description = newZDACaseToFormat.Description,
            Origin = 'CanalUnico',
            Subject = 'Caso NO formatear 3'
            );
        List<Case> casesToInsert = new List<Case>();
        casesToInsert.add(newZDACaseToFormat);
        casesToInsert.add(newZDACaseNoFormat);
        casesToInsert.add(newZDACaseNoFormat2);
        casesToInsert.add(newSprinklrCase);

        Test.startTest();
        insert casesToInsert;
        Test.stopTest();

        List<Case> casesToCompare = [SELECT Subject, Description FROM Case];
        for (Case caseToCompare : casesToCompare)
        {
            if ( caseToCompare.Subject.equals(newZDACaseToFormat.Subject) )
            {
                //Caso que debe haber sido formateado
                Assert.areEqual(formattedText, caseToCompare.Description);
            }
            else
            {
                //El resto no se deben haber formateado
                Assert.areNotEqual(formattedText, caseToCompare.Description);
            }
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
    private static void test_markMilestonesCompletedWhenClose_ko()
    {
        Id rtOCSInquiryId = CaseUtil.RT_ID_OCSINQUIRY;

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
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
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

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
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
    private static void test_completeUSPMilestonesWhenClosedOrPending_ok()
    {
        Id rtUSPId = CaseUtil.RT_ID_USPINQUIRY;

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
        List<CaseMilestone> milestonesCreated = [SELECT IsCompleted, MilestoneType.Name FROM CaseMilestone WHERE CaseId IN : cases];
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

        List<CaseMilestone> milestonesUpdated = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
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
    private static void test_relateCasesToNewAccounts_OK()
    {
        // Se establece el recordtype para que el proceso relacione los casos con esta cuenta
        Account customer = [SELECT Id, NationalId__c FROM Account LIMIT 1];
        AccountsSelector accSel = new AccountsSelector();
        customer.RecordTypeId = accSel.rtCustomerId;
        update customer;

        // Se establece recordType y CIF para que se relacionen
        List<Case> cases = [SELECT Id, MediatedCustomer__c, RobotDocumentId__c FROM case];
        for(Case currentCase: cases)
        {
            currentCase.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
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
    private static void test_relateCasesToNewOffers_OK()
    {
        Account cuenta = [SELECT Id, NationalId__c FROM Account LIMIT 1];
        //oferta
        Opportunity oferta= new Opportunity();
        oferta.InfoQuoteNumber__c='11111';
        oferta.Name='Test';
        oferta.AccountId=cuenta.Id;
        oferta.StageName='Quoted';
        oferta.CloseDate=System.today() + 1;

        insert oferta;
        // Se establece recordType y oferta creada para que se relacionen
        List<Case> cases = [SELECT Id,OfferId__c,CreatedOffer__c,RobotDocumentId__c FROM case];

        for(Case currentCase: cases)
        {
            currentCase.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
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
    private static void test_checkTypification_OK()
    {

        Map<String, List<String> > mapaT1 = SystemUtil.getDependantPicklistValues('Case', 'Type', 'Subtype__c');
        Map<String, List<String> > mapaT2 = SystemUtil.getDependantPicklistValues('Case', 'Subtype__c', 'TypeN3__c');

        List<String> listaT1 = new List<String>( mapaT1.keySet() );
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
    private static void test_checkTypification_KO()
    {
        Map<String, List<String> > mapaT1 = SystemUtil.getDependantPicklistValues('Case', 'Type', 'Subtype__c');

        List<String> listaT1 = new List<String>( mapaT1.keySet() );
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
    private static void test_checkTypificationByRecordType_OK()
    {
        String recordTypeOCS = CaseUtil.RT_ID_OCSINQUIRY;

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
    private static void test_checkTypificationByRecordType_KO()
    {
        String recordTypeOCS = CaseUtil.RT_ID_OCSINQUIRY;

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
    private static void test_generateAccountRatio_OK()
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
            caseRelatedToIntermediary.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
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
    private static void test_relateCasesToPolicyOffers_OK()
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
    private static void test_getCasesToUpdateContactFromEmailToCase()
    {
        // Crear datos de prueba: Caso y Contacto relacionado
        Case caso = new Case( Origin = 'Email', SuppliedEmail = 'test@test.com', LegalEntity__c = LABEL_GENERAL_INSURANCE,
                              SourceCountry__c = 'US', Partner__c = 'TestPartner',
                              RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry').getRecordTypeId() );
        insert caso;

        Contact contactoSF = new Contact( Email = 'test@test.com', LegalEntity__c = LABEL_GENERAL_INSURANCE, SourceCountry__c = 'US',
                                          Partner__c = 'TestPartner', LastName = 'Prueba contactoSF',
                                          RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId() );
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
    private static void test_getCasesToMarkMilestonesCompletedWhenClose()
    {
        // Crea datos de prueba
        Id rtOCSInquiryId = CaseUtil.RT_ID_OCSINQUIRY;
        Case oldCase = new Case(Status = 'Abierto', RecordTypeId = rtOCSInquiryId);
        Case newCase = new Case(Status = 'Cerrado', RecordTypeId = rtOCSInquiryId);
        insert new List<Case> {oldCase, newCase};

        List<Case> caseList = [Select id,Status,RecordTypeId,SlaExitDate from Case where id =: newCase.Id];

        Test.startTest();
        // Ejecuta la función a probar
        List<Case> updatedCases = CaseUtil.getCasesToMarkMilestonesCompletedWhenClose(caseList, new Map<Id, Case> {newCase.Id => oldCase});
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
    private static void test_updatePolicyToCaseifCaseDoesNotHavePolicy()
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
        policy.EffectiveDate = Date.valueOf('1994-01-01');
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
    private static void test_updateContactToCaseByEmail()
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
    private static void test_updateContactToCaseByPhone()
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
    private static void test_ifCaseFromWebFranceUpdateTranslationToCase()
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
    private static void test_updateTranscomCase()
    {
        List<Group> queueRetencion = new GroupSelector().findByName('Email_TWW_Retencion');
        List<Group> queueAnulacion = new GroupSelector().findByName('Email_TWW_Anulacion');
        List<Case> caseList = new List<Case>();

        Id ocsInquiry = CaseUtil.RT_ID_OCSINQUIRY;

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
        System.assertEquals(null, caseAfterInsertRetencion.Type, 'El tipo del caso no debería estar completado automáticamente');
        System.assertEquals(null, caseAfterInsertRetencion.Subtype__c, 'El subtipo del caso no debería estar completado automáticamente');
        System.assertEquals(null, caseAfterInsertRetencion.TypeN3__c, 'El tipo N3 del caso no debería estar completado automáticamente');
        System.assertEquals('TWW Retención', caseAfterInsertAnulacion.CallCenter__c, 'El call center del caso anulación no es correcto');
        System.assertEquals('Generic end customer', caseAfterInsertAnulacion.SourceArea__c, 'El area del caso anulación no es correcto');
        System.assertEquals(null, caseAfterInsertAnulacion.Type, 'El tipo del caso no debería estar completado automáticamente');
        System.assertEquals(null, caseAfterInsertAnulacion.Subtype__c, 'El subtipo del caso no debería estar completado automáticamente');
        System.assertEquals(null, caseAfterInsertAnulacion.TypeN3__c, 'El tipo N3 del caso no debería estar completado automáticamente');
    }

    /**
     * Test que comprueba que se asocia correctamente la cuenta al caso por CIF
     **
     * @author aberuete
     * @date 16/08/2023
     */
    @isTest
    private static void test_linkAccountAndContactToCaseByCIF()
    {
        Case caseRecord = new Case ();
        caseRecord.Subject = LABEL_SUBJECT_ZURICH;
        caseRecord.RobotNif__c = '73562398D';

        List<Account> accountFromCase = TestDataFactory.generateAccounts(null, 'Customer', 1);
        accountFromCase[0].NationalId__c = '73562398D';
        accountFromCase[0].Type = 'F';
        insert accountFromCase;

        Test.startTest();
        insert caseRecord;
        Test.stopTest();

        Case caseAfterInsert = [Select id,AccountId from Case where id =: caseRecord.id];

        System.assertEquals(accountFromCase[0].id, caseAfterInsert.AccountId, MESSAGE_CUENTA_NO_ASIGNADA);
    }

    /**
     * Test que comprueba que se asocia correctamente la cuenta al caso por email
     **
     * @author aberuete
     * @date 22/08/2023
     */
    @isTest
    private static void test_linkAccountAndContactToCaseByEmail()
    {
        Case caseRecord = new Case ();
        caseRecord.Subject = LABEL_SUBJECT_ZURICH;
        caseRecord.RobotNif__c = '73562398D';
        caseRecord.SuppliedEmail = EMAIL_CASE;

        List<Account> accountFromCase = TestDataFactory.generateAccounts(null, 'Customer', 1);
        accountFromCase[0].Type = 'F';
        insert accountFromCase;

        List<ContactPointEmail> contactPointEmailsToInsert = TestDataFactory.generateContactPointEmailsFromAccounts(accountFromCase, 1);
        contactPointEmailsToInsert[0].EmailAddress = EMAIL_CASE;
        insert contactPointEmailsToInsert;

        Set<Id> recordIds = new Set<Id>();

        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
        }

        Test.setFixedSearchResults( new List<Id>(recordIds) );

        Test.startTest();
        insert caseRecord;
        Test.stopTest();

        Case caseAfterInsert = [Select id,AccountId from Case where id =: caseRecord.id];

        System.assertEquals(accountFromCase[0].id, caseAfterInsert.AccountId, MESSAGE_CUENTA_NO_ASIGNADA);
    }

    /**
     * Test que comprueba que se asocia correctamente la cuenta al caso por teléfono
     **
     * @author aberuete
     * @date 22/08/2023
     */
    @isTest
    private static void test_linkAccountAndContactToCaseByPhone()
    {
        Case caseRecord = new Case ();
        caseRecord.Subject =  LABEL_SUBJECT_ZURICH;
        caseRecord.RobotNif__c = '73562398D';
        caseRecord.SuppliedEmail = EMAIL_CASE;
        caseRecord.SuppliedPhone = '607342167';

        List<Account> accountFromCase = TestDataFactory.generateAccounts(null, 'Customer', 1);
        accountFromCase[0].Type = 'F';
        insert accountFromCase;

        List<ContactPointPhone> contactPointPhonesToInsert = TestDataFactory.generateContactPointPhonesFromAccounts (accountFromCase, 1);
        contactPointPhonesToInsert[0].TelephoneNumber = '607342167';
        insert contactPointPhonesToInsert;

        Set<Id> recordIds = new Set<Id>();
        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointPhone])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        Test.startTest();
        insert caseRecord;
        Test.stopTest();

        Case caseAfterInsert = [Select id,AccountId from Case where id =: caseRecord.id];

        System.assertEquals(accountFromCase[0].id, caseAfterInsert.AccountId, MESSAGE_CUENTA_NO_ASIGNADA);
    }

    /**
     * Test que comprueba que se activa el campo closeByBatch en el proceso de cierre de interacciones
     **
     * @author lrodriguez
     * @date 01/03/2024
     */
    @isTest
    private static void test_checkCasesCloseInteractions()
    {
        Case caseRecord = new Case ();
        List<Case> listaEntrada= new List<Case>();
        List<Case> listaSalida= new List<Case>();
        caseRecord.subject='test campo closeByBatch';

        insert caseRecord;

        listaEntrada.add(caseRecord);
        Test.startTest();
        listaSalida= CaseUtil.checkCasesCloseInteractions(listaEntrada);
        Test.stopTest();

        System.assertEquals(true, listaSalida[0].CloseByBatch__c, 'no devuelve el valor esperado');
    }

    /**
     * Test que comprueba que al actualizar un caso de tipo Sprinklr enlazando una cuenta de tipo customer,
     * se actualiza el contacto asociado al perfil social del caso.
     **
     * @author aberuete
     * @date 08/03/2024
     */
    @isTest
    private static void test_getSprinklrSocialPersonaToLinkContact()
    {
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();
        List<Account> accountTiLinkCase = [Select id,PersonContactId from Account where RecordType.DeveloperName = 'Customer' limit 1 ];

        spr_sf__SocialPersona__c sprSocialPersona = new spr_sf__SocialPersona__c ( Name = 'sprSocialPersonaTest');
        insert sprSocialPersona;

        Case caseToLinkAccount = new Case();
        caseToLinkAccount.RecordTypeId = rtOCSSprinklrId;
        caseToLinkAccount.SprinklrSocialPersona__c = sprSocialPersona.Id;
        insert caseToLinkAccount;

        Test.startTest();
        caseToLinkAccount.AccountId = accountTiLinkCase[0].Id;
        update caseToLinkAccount;
        Test.stopTest();

        spr_sf__SocialPersona__c sprSocialPersonaReturned = [Select id,spr_sf__Contact__c from spr_sf__SocialPersona__c where id=: sprSocialPersona.id];
        System.assertEquals (accountTiLinkCase[0].PersonContactId, sprSocialPersonaReturned.spr_sf__Contact__c, 'No se ha actualizado correctamente el perfil social');
    }

    /**
     * Se valida que el metodo relateCaseToCustomerByNifCif relaciona correctamente el caso con
     * el cliente mediado (cuenta.NationalId__c = caso.CustomerNifCif__c) y establece el campo
     * MediatedCustomer__c en caso de encontrar relacion. Para ello:
     * - Se crea un caso con CustomerNifCif__c, cuyo DNI solo existe en una cuenta. Debe vincular
     * - Se crea un caso con CustomerNifCif__c, cuyo DNI existe en dos cuentas. NO debe vincular
     * - Se crea un caso sin CustomerNifCif__c. NO debe vincular
     *
     * @author mario.navarro@seidor.com
     * @date 10/04/2024
     */
    @isTest
    private static void test_relateCaseToCustomerByNifCif()
    {
        List<String> dnis = new List<String> {'11222333R', '77888999I'};
        List<Account> accToInsert = new List<Account>();
        Account accountUniqueDNI = new Account(
            LastName = 'Cuenta DNI unico',
            NationalId__c = dnis[0],
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId()
            );
        accToInsert.add(accountUniqueDNI);
        Account accountDupDNI1 = new Account(
            LastName = 'Cuenta DNI dup1',
            NationalId__c = dnis[1],
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId()
            );
        accToInsert.add(accountDupDNI1);
        Account accountDupDNI2 = new Account(
            LastName = 'Cuenta DNI dup2',
            NationalId__c = dnis[1],
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId()
            );
        accToInsert.add(accountDupDNI2);
        insert accToInsert;
        List<Account> createdAccs = [SELECT Id FROM Account WHERE NationalId__c IN : dnis];
        Assert.areEqual( accToInsert.size(), createdAccs.size() );

        Case caseToLink = new Case(
            TicketId__c = 10,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso a vincular',
            CustomerNifCif__c = accountUniqueDNI.NationalId__c
            );
        Case caseNoLink = new Case(
            TicketId__c = 20,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso a NO vincular',
            CustomerNifCif__c = accountDupDNI1.NationalId__c
            );
        Case caseNoLink2 = new Case(
            TicketId__c = 20,
            RecordTypeId = CaseUtil.RT_ID_ZDA,
            Subject = 'Asunto de caso a NO vincular 2'
            );

        Test.startTest();
        insert new List<Case> {caseToLink, caseNoLink, caseNoLink2};
        Test.stopTest();

        Case linkedCase = [SELECT MediatedCustomer__c FROM Case WHERE Id = : caseToLink.Id];
        Case notLinkedCase = [SELECT MediatedCustomer__c FROM Case WHERE Id = : caseNoLink.Id];
        Case notLinkedCase2 = [SELECT MediatedCustomer__c FROM Case WHERE Id = : caseNoLink2.Id];

        Assert.isNotNull(linkedCase);
        Assert.areEqual(accountUniqueDNI.Id, linkedCase.MediatedCustomer__c);
        Assert.isNotNull(notLinkedCase);
        Assert.isNull(notLinkedCase.MediatedCustomer__c);
        Assert.isNotNull(notLinkedCase2);
        Assert.isNull(notLinkedCase2.MediatedCustomer__c);
    }

    /**
     * Test que comprueba que al actualizar un caso de tipo Sprinklr enlazando una cuenta de un tipo distinto a customer,
     * no se actualiza el contacto asociado al perfil social del caso.
     **
     * @author aberuete
     * @date 08/03/2024
     */
    @isTest
    private static void test_getSprinklrSocialPersonaToNotLinkContact()
    {
        List<Account> accountTiLinkCase = TestDataFactory.generateAccounts('001', 'BusinessCustomer', 1);
        insert accountTiLinkCase;
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();

        spr_sf__SocialPersona__c sprSocialPersona = new spr_sf__SocialPersona__c ( Name = 'sprSocialPersonaTest');
        insert sprSocialPersona;

        Case caseToLinkAccount = new Case();
        caseToLinkAccount.RecordTypeId = rtOCSSprinklrId;
        caseToLinkAccount.SprinklrSocialPersona__c = sprSocialPersona.Id;
        insert caseToLinkAccount;

        Test.startTest();
        caseToLinkAccount.AccountId = accountTiLinkCase[0].Id;
        update caseToLinkAccount;
        Test.stopTest();

        spr_sf__SocialPersona__c sprSocialPersonaReturned = [Select id,spr_sf__Contact__c from spr_sf__SocialPersona__c where id=: sprSocialPersona.id];
        System.assertEquals (null, sprSocialPersonaReturned.spr_sf__Contact__c, 'El perfil social no debería tener un contacto asociado');
    }

    /**
     * Test que comprueba que al actualizar un caso de tipo Sprinklr eliminado su cuenta asociada,
     * se elimina el contacto del perfil social del caso.
     **
     * @author aberuete
     * @date 08/03/2024
     */
    @isTest
    private static void test_getSprinklrSocialPersonaToDeleteContactRelated()
    {
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();
        List<Account> accountTiLinkCase = [Select id, PersonContactId from Account where RecordType.DeveloperName = 'Customer' limit 1 ];

        spr_sf__SocialPersona__c sprSocialPersona = new spr_sf__SocialPersona__c ( Name = 'sprSocialPersonaTest', spr_sf__Contact__c = accountTiLinkCase[0].PersonContactId);
        insert sprSocialPersona;

        Case caseToLinkAccount = new Case();
        caseToLinkAccount.RecordTypeId = rtOCSSprinklrId;
        caseToLinkAccount.SprinklrSocialPersona__c = sprSocialPersona.Id;
        caseToLinkAccount.AccountId = accountTiLinkCase[0].Id;
        insert caseToLinkAccount;

        Test.startTest();
        caseToLinkAccount.AccountId = null;
        update caseToLinkAccount;
        Test.stopTest();

        spr_sf__SocialPersona__c sprSocialPersonaAfterDeleted= [Select id,spr_sf__Contact__c from spr_sf__SocialPersona__c where id=: sprSocialPersona.id];
        System.assertEquals (null, sprSocialPersonaAfterDeleted.spr_sf__Contact__c, 'El contacto se debería haber borrado');
    }

    @isTest
    private static void test_checkIfPolicyHaveOpenZrmCase()
    {
        Id rtZrmInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZRMInquiry').getRecordTypeId();
        List<Account> accountRecord = [Select id, PersonContactId from Account where RecordType.DeveloperName = 'Customer' limit 1 ];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accountRecord, 1);
        for(Policy__c poliza : policies)
        {
            poliza.EndDate__c = System.today();
        }

        insert policies;

        Case caseToLinkAccount = new Case();
        caseToLinkAccount.RecordTypeId = rtZrmInquiryId;
        caseToLinkAccount.AccountId = accountRecord[0].Id;
        caseToLinkAccount.policyId__c = policies[0].Id;
        insert caseToLinkAccount;

        Boolean exceptionThrown = false;
        Test.startTest();
            //Creamos otro caso para que salte el AddError.
            Case caseToLaunchError = new Case();
                caseToLaunchError.RecordTypeId = rtZrmInquiryId;
                caseToLaunchError.AccountId = accountRecord[0].Id;
                caseToLaunchError.policyId__c = policies[0].Id;
            Database.SaveResult sr = Database.insert(caseToLaunchError, false);
        
        
        Test.stopTest();

        Database.Error error = sr.getErrors()[0];
        Assert.areEqual(true, error.getMessage().contains(Label.CaseZRMOpenedCase));
    } 

    @isTest
    private static void test_getRelatedPolicyIds()
    {
        Id rtZrmInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZRMInquiry').getRecordTypeId();
        Id rtOCSSprinklrId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSSprinklr').getRecordTypeId();

        List<Account> accountRecord = [Select id, PersonContactId from Account where RecordType.DeveloperName = 'Customer' limit 1 ];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accountRecord, 10);
        for(Policy__c poliza : policies)
        {
            poliza.EndDate__c = System.today();
        }

        insert policies;

        List<Case> cases = new List<Case>();
        Case c;
        for (Integer i = 0; i < 10; i++) {
            c = new Case();
                c.RecordTypeId = rtOCSSprinklrId;
                c.AccountId = accountRecord[0].Id;
                c.policyId__c = policies[i].Id;
            cases.add(c);
        }

        Integer expected = 0;
        for (Integer i = 0; i < 5; i++) {
            cases[i].recordTypeId = rtZrmInquiryId;
            expected ++;
        }
        
        Set<String> result;
        Test.startTest();
            result = CaseUtil.getRelatedPolicyifZRMIds(cases);
        Test.stopTest();

        Assert.areEqual(expected, result.size());
    }

    @isTest
    private static void test_buildNotClosedZrmCasesByPolicyId()
    {
        Id rtZrmInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZRMInquiry').getRecordTypeId();
        List<Account> accountRecord = [Select id, PersonContactId from Account where RecordType.DeveloperName = 'Customer' limit 1 ];
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accountRecord, 5);
        insert policies;

        Map<String, Case> expectedMap = new Map<String, Case>();
        Map<String, Case> resultMap = new Map<String, Case>();

        List<Case> cases = new List<Case>();
        Case c; 

        for(Policy__c policy : policies)
        {
            c = new Case();
            c.RecordTypeId = rtZrmInquiryId;
            c.AccountId = accountRecord[0].Id;
            c.policyId__c = policy.Id;
            cases.add(c);
            expectedMap.put(policy.Id, c);
        }

        Test.startTest();
            resultMap = CaseUtil.buildNotClosedZrmCasesByPolicyId(cases);
        Test.stopTest();

        Assert.areEqual(expectedMap, resultMap);
    }

     /**
     * Test que comprueba que para un caso de rt ZRMInquiry al insertarlo con un usuario de comunidad ZRM se cambia el owner al usuario por defecto 
     **
     * @author dmunoz
     * @date 24/04/2024
     */
    @isTest
    private static void test_updateInquiryCaseOwnerOnZRMCreation_OK() {

        // Obtener cliente
        List<Account> clienteList = new List<Account>([SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'Customer' LIMIT 1]);

        // Obtener mediador
        Account intermediary = [SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'Intermediary' AND Name = 'MediadorTest' LIMIT 1];

        // Inserto una poliza para que se cree el atm y el registro con el que vamos a relacionar el caso de retencion zrm
        List<Policy__c> policyToInsert = TestDataFactory.generatePoliciesForEachAccount(clienteList, 1);
        for (Policy__c policy: policyToInsert) {
            policy.IntermediaryId__c = intermediary.Id;
            policy.EndDate__c = System.today().addDays(10);
        }

        insert policyToInsert;

        // Obtengo el usuario para ejecutar el test
        User u = [SELECT Id FROM User WHERE Contact.AccountId = :intermediary.Id];

        System.runAs(u) {
            Test.startTest();

            // Creo el caso y lo inserto
            Id rtZRMid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ZRMInquiry').getRecordTypeId();

            Case zrmCase = new Case();
            zrmCase.PolicyId__c = policyToInsert.get(0).Id; 
            zrmCase.RecordTypeId = rtZRMid;
            zrmCase.Status = 'No iniciado';
            zrmCase.IntermediaryId__c = intermediary.Id;
            insert zrmCase;

            Test.stopTest();
        }

        List<Case> zrmCaseList = new List<Case>([SELECT Id, OwnerId FROM Case WHERE Recordtype.DeveloperName = 'ZRMInquiry']);

        Assert.isTrue(!zrmCaseList.isEmpty(), 'Se debe haber insertado un caso de retencion zrm');
        Assert.isTrue(zrmCaseList.get(0).OwnerId != u.Id, 'El Owner del caso debe ser diferente al usuario que lo ha insertado');

    }
}