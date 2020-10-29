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

        if (String.isBlank(customer.MasterPolicyDesc__c) )
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
            Account partnerRef = new Account(
                Masterpolicy__c = customer.MasterPolicyNum__c
                );

            if (!partnersToUpdateList.containsKey(newPartner.Masterpolicy__c) )
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

        if (String.isBlank(order.MasterPolicyDescr__c) )
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

            if (!partnersToUpdateList.containsKey(newPartner.Masterpolicy__c) )
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
}