@isTest
public class CaseUtilTest {

    @TestSetup
    public static void createScenario()
    {
        //Importante usar el RT Customer porque es personal account y se necesita que esté relleno PersonContactId
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1); //Importante que solo se cree 1 porque sino habrá varios con mismo email
        insert accounts;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 1);
        insert contactPointEmails;
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
         Case caso = new Case(SuppliedEmail = emailsToSearch[0], RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId());
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
         Case caso = new Case(SuppliedEmail = emailsToSearch[0], RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId());
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
         Case caso = new Case(SuppliedEmail = 'noexistoentrelosemailscreados@nts-solutions.com', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId());
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
}
