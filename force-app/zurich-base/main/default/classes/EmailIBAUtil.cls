/**
**
* @author nbizkarra
* @date 23/04/2020
*/

public with sharing class EmailIBAUtil
{
    /* //Descartado en fase de implementación


       public static void insertEmailIBA(EmailsIBA__c email, Map<String, Contact> mapContacts,List <EmailsIBA__c> emailsToInsert) {

          String customernum= ContactUtil.adaptCustomerNum(email.CustomerNum__c, email.LegalEntity__c);
          Contact contactSF=mapContacts.get(customernum);

          if(contactSF!=null){
                  email.SentTo__c=contactSF.Id;
                  emailsToInsert.add(email);
          }else{
              
              throw new IntegrationException(Label.EmailIBAError +' '+ email.Subject__c+'. '+Label.CustomerError+' '+email.CustomerNum__c);
          }

       }
     */
}