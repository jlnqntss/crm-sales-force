/**
**
* @author nbizkarra
* @date 01/04/2020
*/
public class AccountUtil
{
    /**
     * Método que crea un nuevo partner si no existe y lo asocia al contacto
     * @author nbizkarra
     * @date 23/04/2020
     */
    public static void associatePartner(
        Contact customer,
        Map<String, Account> mapPartners,
        Map<String, Contact> contactsToUpdateWithPartner,
        Map<String, Account> partnersToUpdateList,
        User recordOwner
        )
    {
        Account partnerSF = mapPartners.get(customer.MasterPolicyNum__c);

        if ( String.isBlank(customer.MasterPolicyDesc__c) )
        {
            customer.MasterPolicyDesc__c = Label.LeadLastName;
        }

        if (partnerSF != null)
        {
            //System.debug('PARTNER existe');
            customer.MasterPolicy__c = partnerSF.Id;
        }
        else
        {
            //System.debug('Parnter no existe');
            Account newPartner = new Account(
                Name = customer.MasterPolicyDesc__c,
                Masterpolicy__c = customer.MasterPolicyNum__c,
                OwnerId = recordOwner.id,
                RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Partner)
                );
            // nts (agonzalezisasi) - 03/11/2020 - Inlcude IBA Multi-Partner logic
            if( !String.isBlank(customer.Partner__c) )
            {
                newPartner.Partner__c = customer.Partner__c;
            }

            Account partnerRef = new Account(
                Masterpolicy__c = customer.MasterPolicyNum__c
                );

            if ( !partnersToUpdateList.containsKey(newPartner.Masterpolicy__c) )
            {
                partnersToUpdateList.put(newPartner.Masterpolicy__c, newPartner);
            }

            customer.MasterPolicy__r = partnerRef;
        }

        contactsToUpdateWithPartner.put(customer.CustomerNum__c, customer);
    }

    /**
     * Método que crea un nuevo partner si no existe y lo asocia a la póliza o quote
     * @author nbizkarra
     * @date 23/04/2020
     */
    public static void associatePartnerToOrder(
        Order order,
        Map<String, Account> mapPartners,
        Map<String, Order> ordersToUpdateWithPartner,
        Map<String, Account> partnersToUpdateList,
        User recordOwner
        )
    {
        Account partnerSF = mapPartners.get(order.MasterPolicyNum__c);

        if ( String.isBlank(order.MasterPolicyDescr__c) )
        {
            order.MasterPolicyDescr__c = Label.LeadLastName;
        }

        if (partnerSF != null)
        {
            // System.debug('PARTNER existe');
            order.MasterPolicy__c = partnerSF.Id;
        }
        else
        {
            //System.debug('Parnter no existe');
            Account newPartner = new Account(
                Name = order.MasterPolicyDescr__c,
                Masterpolicy__c = order.MasterPolicyNum__c,
                OwnerId = recordOwner.id,
                RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Partner)
                );
            Account partnerRef = new Account(
                Masterpolicy__c = order.MasterPolicyNum__c
                );

            if ( !partnersToUpdateList.containsKey(newPartner.Masterpolicy__c) )
            {
                partnersToUpdateList.put(newPartner.Masterpolicy__c, newPartner);
            }

            order.MasterPolicy__r = partnerRef;
        }
        //Si es quote, key=quoteEntry, si es poliza, key=policyNum
        String key;
        if (order.PolicyNum__c != null)
        {
            key = order.PolicyNum__c;
        }
        else
        {
            key = order.QuoteEntry__c;
        }

        ordersToUpdateWithPartner.put(key, order);
    }

    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para Accounts que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     * @edit 30/7/2021 ZE Campaña Telemarketing
     */
    public static void generateScope(List<Account> newList)
    {
        List<Account> accountsToGenerateScope = new List<Account>();
        List<Account> accountsTelemarketingToGenerateScope = new List<Account>();

        for(Account account : newList)
        {
            if( String.isNotBlank(account.INFOCustomerNumber__c) )
            {
                accountsToGenerateScope.add(account);
            }
            else if(String.isNotBlank(account.LeadSource__c) && account.LeadSource__c == 'Telemarketing')
            {//ZE Campaña Telemarketing
                accountsTelemarketingToGenerateScope.add(account);
            }
        }

        if( !accountsToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('Id', null, accountsToGenerateScope);
        }
        //ZE Campaña Telemarketing
        if( !accountsTelemarketingToGenerateScope.isEmpty() )
        {//BusinessCode: 3200012491
            GenerateScopeUtil.generateScopeEvents('Id', 'LeadBusinessCode__c', accountsTelemarketingToGenerateScope);
        }
    }

    /**
     * Método que devuelve un mapa de cuentas por cif a partir de una lista de cuentas
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     * @param Lista de cuentas
     * @return Mapa de cuentas por CIF
     */
    public static Map<String, Account> generateMapByCif(List<Account> accounts)
    {
        Map<String, Account> mapAccountsToRelateByCIF = new Map<String,Account>();
        if(accounts != null && !accounts.isEmpty())
        {
            //Mapa para identificar cada cuenta con su cif
                    
            // Se recorre la lista de cuentas para no tener que recorrerla una vez por cada caso
            for(Account currentAccount : accounts)
            {
                mapAccountsToRelateByCIF.put(currentAccount.NationalId__c, currentAccount);
            }
        }
        return mapAccountsToRelateByCIF;
    }
}