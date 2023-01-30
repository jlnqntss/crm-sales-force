public with sharing class ActaSelector {
    
    /**Recuperar informacion de un acta
     * @author nts (dmunoz)
     * @date 26/01/2023
     * 
     * @param {Id} actaId
     * @return {List<Acta__c>} evento que cumple el filtro 
     */
    public static List<Acta__c> getAccionesTratadasActa(Id actaId) {
        List<Acta__c> result = new List<Acta__c>();

        if (actaId != null && String.isNotEmpty(actaId)) {
            result = new List<Acta__c>([SELECT Id, Name, (SELECT Id, Actions__c, PersonInCharge__c, DueDate__c, Observations__c from AccionesTratadasActa__r) FROM Acta__c where ID = :actaId]);
        } 

        return result;
    }
}