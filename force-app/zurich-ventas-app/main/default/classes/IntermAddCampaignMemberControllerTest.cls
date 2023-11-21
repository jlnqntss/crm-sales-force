/*
 * Test for the IntermAddCampaignMemberController
 *
 * @author mfernandezcarrera
 * @date 20/11/2023
 */
@isTest
private class IntermAddCampaignMemberControllerTest 
{
    /**
    * Test del  Método que se encarga de insertar los miembros de campaña
    * que se pasan por parámetro.
    * @author mfernandezcarrera
    * @date 20/11/2023
    */
    @isTest
    private static void test_insertCampaignMembers()
    {
        //Creamos e insertamos una cuenta tipo customer
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;
        //Creamos e insertamos una campaña
        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        insert campaigns;

        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);

        //Generamos un miembro de campaña para cada campaña que le pasamos
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaigns, 'Subscribed');

        //Iniciamos el test
        Test.startTest();

        //Llamamos a la clase apex, a su metodo de insertar miembros de campañas. Al cual, le pasamos la campaña a insertar
        IntermAddCampaignMemberController.insertCampaignMembers(campaignMembers);

        //Fin test
        Test.stopTest();
        List<CampaignMember> campaingMemberList = [Select Id from CampaignMember];
        System.assertEquals(1, campaingMemberList.size(), 'No cumple las condiciones');
    }
    /**
     * Test del Método que recupera los contactos relacionados con cuentas 
     * de tipo 'Customer' y 'BusinessCustomer' sobre los que un usuario tiene acceso
     * y la cuenta relacionada con el contacto no tiene ningún otro contacto relacionado
     * con un registro de 'CampaignMember'.
     * @author mfernandezcarrera
     * @date 20/11/2023
     */
    @isTest
    private static void test_getContactsFromCampaign()
    {
        //Creamos e insertamos una cuenta tipo customer
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;
        //Creamos e insertamos una campaña
        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        insert campaigns;

        //Guardamos en una variable el Id de la camapaña con la que se va a trabajar
        Id campaignToSearch = campaigns.get(0).Id;

        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);
        //Iniciamos el test
        Test.startTest();
        
        //Llamamos a la clase apex, a su metodo obtner contactos. Al cual, le pasamos la campaña 
        IntermAddCampaignMemberController.getContacts(campaignToSearch);  
        
        Test.stopTest();
        List<Contact> contactList = [Select Id from Contact];  
        System.assertEquals(1, contactList.size(), 'No cumple las condiciones');
    }
    public IntermAddCampaignMemberControllerTest() 
    {}
}