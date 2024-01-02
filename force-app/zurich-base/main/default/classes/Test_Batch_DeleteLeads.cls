/**
 * Clases de test para Batch_DeleteLeads
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private with sharing class Test_Batch_DeleteLeads
{
    /**
     * Create test data
     **
     * @author nbizkarra
     * @date 27/04/2020
     */
    @TestSetup
    private static void test_CreateData()
    {
        Contact lead = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            IsSubscriber__c = true // it will be anonymized
            );
        insert lead;

        Contact lead2 = new Contact(
            Email = 'edu2@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu2',
            LastName = 'Sanchez2',
            CustomerNum__c = 'GI-1111',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            IsSubscriber__c = true,
            HasOptedOutOfEmail = true //it will be deleted
            );
        insert lead2;
    }

    /**
     * El campo 'lastmodified' de los registros de lead
       no son más antiguos que 7 días, no se elimina ningún regitro.
     **
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    private static void test_NoEliminarLead()
    {
        Integer numContact = [SELECT COUNT() FROM Contact];
        System.assertEquals(2, numContact);

        String query = 'SELECT Id FROM Error_Log__c WHERE LastModifiedDate < LAST_N_DAYS:7';
        Test.startTest();
        database.executeBatch(new Batch_DeleteLeads(query),200);
        Test.stopTest();

        numContact = [SELECT COUNT() FROM Contact];

        System.assertEquals(2, numContact);
    }

    /**
     * Este método de test llama al Batch a través de una query personalizada.
       y elimina todos los registros existentes de lead.
     * *
     * @author nbizkarra
     * @date 27/04/2020
     */

    @isTest
    private static void test_EliminarLead()
    {
        Integer numContact = [SELECT COUNT() FROM Contact];
        System.assertEquals(2, numContact);

        String query = 'SELECT Id , AccountId, IsSubscriber__c, HasOptedOutOfEmail, Balance__c, Birthdate, CNO__c,' +
        'CreditCard__c, CustomerID__c, CustomerNum__c, DNI__c, EmailHash__c, Gender__c, Job__c,' +
        'JobPosition__c, MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet,' +
        'MasterPolicy__c, MasterPolicyDesc__c, MasterPolicyNum__c, MobilePhone, MonthExpiryDate__c, ' +
        'Nationality__c, YearExpiryDate__c from Contact ';

        Test.startTest();
        Batch_DeleteLeads b = new Batch_DeleteLeads(query); 
        database.executeBatch(b, 200 );
        Test.stopTest();

        numContact = [SELECT COUNT() FROM Contact];
        // Lead1 will be anonymized and lead2 will be deleted
        System.assertEquals(1, numContact);
    }

    /**
     * Comprobar que el batch elimina correctamente los contactos creados hace más de 10 días, que se han suscrito y son clientes
     * *
     * @author aberuete
     * @date 03/04/2023
     */
    @isTest
    private static void test_DeleteLeadCreated11daysAgo()
    {
        List<Contact> leadsToDeleteBefore = [Select id,CreatedDate from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true AND CustomerNum__c !=null and HasOptedOutOfEmail = true ];
        Datetime elevenDaysAgo = Datetime.now().addDays(-11);
        Test.setCreatedDate(leadsToDeleteBefore[0].Id, elevenDaysAgo);

        Test.startTest(); 
        Batch_DeleteLeads b = new Batch_DeleteLeads();
        database.executeBatch(b, 200 );
        Test.stopTest(); 

        List<Contact> leadsToDeleteAfter = [Select id,CreatedDate from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true AND CustomerNum__c !=null and HasOptedOutOfEmail = true ];

        System.assertEquals (1,leadsToDeleteBefore.size(),'El número de contactos debe ser 1');
        System.assertEquals (0,leadsToDeleteAfter.size(),'El contacto se debe haber borrado');
    }

    
    /**
     * Comprobar la programación del batch
     * *
     * @author aberuete
     * @date 03/04/2023
     */
    @isTest
    private static void test_schedule () 
    {
        Test.startTest();
        String jobID = system.schedule( 'Delete Leads Test', '20 30 8 10 2 ?', new Batch_DeleteLeads() );
        Test.stopTest();
    
        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch'); 
    }

}