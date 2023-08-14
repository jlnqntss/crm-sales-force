public with sharing class RelatedAccountsSelector extends RecordsSelector
{
    public RelatedAccountsSelector() 
    {
        super(RelatedAccount__c.getSObjectType());
    }

    /**
     * Método que devuelve los registros a partir de un identificador de cuenta
     * @author jjuaristi@seidor.es
     * @date 29/12/2022
     * @params identifier identificador de la cuenta (CIF o código de mediador), field Campo con el que comparar el identificador
     * @return relaciones entre avisos y la cuenta a buscar
     */
    public List<RelatedAccount__c> findRelatedAccountsByIdentifier ( String identifier)
    {
        if( identifier != null && identifier != '' )
        {
            this.baseQuery.selectReadableFields();
    
            this.baseQuery.addConditionEq(RelatedAccount__c.Identifier__c, identifier);
            return (List<RelatedAccount__c>) this.baseQuery.run();
        }
        else
        {
            return new List<RelatedAccount__c>();
        }
    }
}
