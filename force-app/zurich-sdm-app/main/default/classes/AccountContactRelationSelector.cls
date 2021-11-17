/**
 * Clase selectora para el sobject AccountTeamMember
 * 
 * @author nts (agonzalezisasi)
 * @date 17/11/2021
 */
public with sharing class AccountContactRelationSelector extends RecordsSelector 
{
    public AccountContactRelationSelector()
    {
        super(AccountContactRelation.getSObjectType());
    }
    
    /**
     * Recupera los objetos Account Contact Relation que pertenecen a las cuentas de Mediadores
     * 
     * @author nts (agonzalezisasi)
     * @date 17/11/2021
     * 
     * @param {List<Account> intermediaries} lista de mediadores
     * @return {List<AccountContactRelation>} lista de ACRs con los mediadores
     */
    public List<AccountContactRelation> findByIntermediaries(List<Account> intermediaries)
    {
        List<AccountContactRelation> result = null;

        if( intermediaries != null && !intermediaries.isEmpty() ) {
            result = [
                SELECT Id, AccountId, ContactId, Contact.Email, Roles, StartDate, EndDate, IsActive, isDirect
                FROM AccountContactRelation
                WHERE AccountId IN :intermediaries
            ];
        }

        return result;
    }
}