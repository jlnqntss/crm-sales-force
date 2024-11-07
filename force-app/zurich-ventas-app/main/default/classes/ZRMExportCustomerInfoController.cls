/**
 * @description       : Controlador visualforce page ZRMExportCustomerInfoAndRelated
 * @author            : dmunoz
 * @group             :
 * @last modified on  : 05-11-2024
 **/
global with sharing class ZRMExportCustomerInfoController {
    public Account account { get; set; }
    public List<Opportunity> opportunities { get; set; }
    public List<Policy__c> policies { get; set; }
    public List<Claim__c> claims { get; set; }
    public List<Propensity__c> propensities { get; set; }
    public List<Competitor__c> competitors { get; set; }
    public List<AccountRelationship__c> accountsRelationships { get; set; }
    public List<CampaignMember> campaignMembers { get; set; }
    public String accountPhone { get; set; }
    public String accountEmail { get; set; }
    public String accountCustomerSegment { get; set; }
    public String accountCustomerValue { get; set; }

    public ZRMExportCustomerInfoController(ApexPages.StandardController controller) {
        account = (Account)controller.getRecord();
        Apexpages.currentPage().getHeaders().put('content-disposition',  'inline; filename='+ account.Name + '.pdf');
        loadRelatedData();
    }


    /**
     * Recupera la informacion necesaria a mostrar
     * @author dmunoz
     * @date 05/11/2024
     */
    @TestVisible
    private void loadRelatedData() {

        // Obtenemos los datos que cuelgan del cliente directamente
        List<Account> accountRelatedData = (new AccountsSelector()).selectAccountAndRelatedInfo(new List<String>{account.Id});
        opportunities = accountRelatedData.get(0).Opportunities;
        policies = accountRelatedData.get(0).PoliciesHolder__r;
        claims = accountRelatedData.get(0).Claims__r;
        propensities = accountRelatedData.get(0).Propensiones__r;
        competitors = accountRelatedData.get(0).Competitors__r;
        accountsRelationships = accountRelatedData.get(0).Accounts_Relationships__r;

        // Obtengo la información de las campañas del cliente
        campaignMembers = getAccountCampaignsData(account);

        // Obtengo la información de contacto del cliente
        Map<String, String> contactData = getAccountContactData(accountRelatedData.get(0));
        accountPhone = contactData.get('phone');
        accountEmail = contactData.get('email');

        // Obtengo la informacion de segmento
        accountCustomerSegment = getAccounCustomerSegment(accountRelatedData.get(0));

        // Obtengo la informacion de valor cliente
        accountCustomerValue = getAccounCustomerValue(accountRelatedData.get(0));
    }




    /**
     * Recupera la informacion de contacto
     * @author dmunoz
     * @date 05/11/2024
     */
    private Map<String, String> getAccountContactData(Account account) {
        Map<String, String> result = new Map<String, String>();
        String phone = '';
        String email = '';
        
        // obtengo el registro de email (solo deberia haber uno)
        for(ContactPointEmail emailPrimary: account.ContactPointEmails)  {
            email = emailPrimary.EmailAddress;
            break;
        }

        // obtengo el registro de email (solo deberia haber uno)
        for(ContactPointPhone phonePrimary: account.ContactPointPhones)  {
            phone = phonePrimary.TelephoneNumber;
            break;
        }

        result.put('phone', phone);
        result.put('email', email);

        return result;
    }


    /**
     * Recupera la informacion de miembro de campaña
     * @author dmunoz
     * @date 05/11/2024
     */
    private List<CampaignMember> getAccountCampaignsData(Account account) {
        List<CampaignMember> result = new List<CampaignMember>();
        List<String> accountIdsList = new List<String>();
        CampaignMembersSelector.ProperCampaignMembersSelector selector = new CampaignMembersSelector.ProperCampaignMembersSelector();

        accountIdsList.add(account.Id);

        result = selector.selectCrossSellingCampaingsFromAccount(accountIdsList);

        return result;
    }

    /**
     * Recupera la informacion de segmento cliente, si está vacio devuelve el valor "No Informado"
     * @author dmunoz
     * @date 05/11/2024
     */
    private String getAccounCustomerSegment(Account account) {

        String result = Label.ZRM_CustomerSegment_NoValue;
        if (String.isNotEmpty(account.DescriptionCustomerSegment__c)) {
            result = account.DescriptionCustomerSegment__c;
        }

        return result;
    }

    /**
     * Recupera la informacion de segmento cliente, si está vacio devuelve el valor "No Informado"
     * @author dmunoz
     * @date 05/11/2024
     */
    private string getAccounCustomerValue(Account account) {

        String result = Label.ZRM_CustomerSegment_NoValue;
        if (String.isNotEmpty(account.ScoreCLTV_NoLife__c)) {
            result = account.ScoreCLTV_NoLife__c + '/5';
        }

        return result;
    }
}
