/**
 **
 * @author nbizkarra
 * @date 23/04/2020
 */

public with sharing class DocumentUtil {
  /**
   ** Method that relates document with existing policy
   * @author nbizkarra
   * @date 23/04/2020
   */

  /* Descartado en fase de implementación

    public static void insertDocument(IBADocument__c document,Map<String, Order> mapPolicies, List <IBADocument__c> documentsToInsert) {

        Order policySF=mapPolicies.get(document.PolicyNum__c);

        if(policySF!=null){
            
           // document.Policy__c=policySF.id;
            documentsToInsert.add(document);

        }else{
            System.debug('Error insertando document: poliza no existe');
            throw new IntegrationException(Label.ErrorIBADocument+' '+ document.Name+'. '+Label.PolicyNotExisting+' '+document.PolicyNum__c);

        }
       
    }*/
}
