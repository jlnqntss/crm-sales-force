/**
 * Clase selectora para el sobject Error_Log__c
 * 
 * @author nts (agonzalezisasi)
 * @date 09/11/2021
 */
public with sharing class ErrorLogSelector extends RecordsSelector {
    public ErrorLogSelector() 
    {
        super(Error_Log__c.getSObjectType());
    }

    /**
     * Metodo que recupera todos los Error Logs que hay
     * 
     * @author nts (agonzalezisasi)
     * @date 09/11/2021
     * 
     * @return {List<Error_Log__c}
     */
    public List<Error_Log__c> findAll()
    {
        this.baseQuery.selectFields(new List<Schema.SObjectField> {
            Error_Log__c.Id,
            Error_Log__c.Message__c,
            Error_Log__c.Stack_Trace__c
        });

        return (List<Error_Log__c>) this.baseQuery.run();
    }
}
