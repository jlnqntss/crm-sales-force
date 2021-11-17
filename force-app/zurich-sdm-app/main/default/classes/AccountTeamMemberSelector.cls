/**
 * Clase selectora para el sobject AccountTeamMember
 * 
 * @author nts (agonzalezisasi)
 * @date 08/11/2021
 */
public with sharing class AccountTeamMemberSelector extends RecordsSelector {
    public AccountTeamMemberSelector()
    {
        super(AccountTeamMember.getSObjectType());
    }

    /**
     * Metodo que recupera los usuarios que cumplen un Rol en los mediadores que contienen un email dado en su
     * correspondiente campo de email. Por ejemplo los usuario RN (rol) que pertenecen a un Director Territorial
     * 
     * @author nts (agonzalezisasi)
     * @date 08/11/2021
     * 
     * @param {String role} rol de equipo de cuenta
     * @param {String fieldEmail} campo de email del medidador
     * @param {String email} valor de email del campo
     */
    public List<AccountTeamMember> findUsersByRoleAndEmailField(String role, String emailField, String email) 
    {
        List<AccountTeamMember> result = null;

        if( String.isNotBlank(role) && String.isNotBlank(email) ) {
            // Recuperamos los campos del usuario
            Set<String> queryFields = new Set<String>{
                'UserId', 'User.Name'
            };
            this.baseQuery.selectFields(queryFields);
            // Rol del usuario en el equipo de cuentas
            this.baseQuery.addConditionEq(AccountTeamMember.TeamMemberRole, role);

            // Account subquery
            Id rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
            Query accountQuery = new Query(Account.getSObjectType());
            accountQuery.selectFields(new List<Schema.SObjectField> {
                Account.Id
            });
            // Tipo de registro mediador
            accountQuery.addConditionEq(Account.RecordTypeId, rtIntermediaryId);
            // Campo
            accountQuery.addConditionString(emailField + ' = \'' + email + '\'');

            // Añadimos la subquery
            this.baseQuery.addConditionIn(AccountTeamMember.AccountId, accountQuery);

            result = (List<AccountTeamMember>)this.baseQuery.run();
        }

        return result;
    }

    /**
     * Se recuperan los ATMs que hay para dichos usuarios. Se incluyen los campos del mediador y de la agrupacion
     * a la que pertenece
     * 
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     * 
     * @param {Set<Id> userIds} lista de ids de usuario
     * @return {List<AccountTeamMember>} lista de ATMs con los mediadores
     */
    public List<AccountTeamMember> findIntermediariesByUsers(Set<Id> userIds)
    {
        List<AccountTeamMember> result = null;

        if( userIds != null && !userIds.isEmpty() ) {
            Id rtId = (new AccountsSelector()).rtIntermediaryId;

            result = [
                SELECT id, AccountId, Account.ParentId, UserId
                FROM AccountTeamMember
                WHERE Account.RecordTypeId = :rtId
                AND UserId IN :userIds
            ];
        }

        return result;
    }
    
    /**
     * Recupera los objetos Account Team Member que pertenecen a alguna de las cuentas de Mediadores dadas
     * 
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     * 
     * @param {List<Account> intermediaries} cuentas de Mediadores
     * @return {List<AccountTeamMember>} lista de ATMs con los mediadores
     */
    public List<AccountTeamMember> findByIntermediary(List<Account> intermediaries)
    {
        List<AccountTeamMember> result = null;

        if( intermediaries != null && !intermediaries.isEmpty() ) {
            result = [
                SELECT Id, AccountId, UserId, User.Email, TeamMemberRole 
                FROM AccountTeamMember 
                WHERE AccountId IN :intermediaries
            ];
        }

        return result;
    }

    /**
     * Recupera los objetos Account Team Member de las cuentas que tengan los NationIDs dados
     * 
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     * 
     * @param {Set<String> nationalIDs} lista de NIFs
     * @return {List<AccountTeamMember>} lista de ATMs
     */
    public List<AccountTeamMember> findByNationalIDs(Set<String> nationalIDs)
    {
        List<AccountTeamMember> result = null;

        if( nationalIDs != null && !nationalIDs.isEmpty() ) {
            result = [
                SELECT Id, AccountId, Account.NationalID__c, Account.ParentId, UserId, TeamMemberRole, 
                    Account.RecordType.DeveloperName
                FROM AccountTeamMember
                WHERE AccountId IN (
                    SELECT Id FROM Account WHERE NationalID__c IN :nationalIDs
                )
            ];
        }
        
        return result;
    }
    
    /**
     * Recupera los Account Team Members que pertecen a los roles indicados por parametro.
     * Incluimos el UserId para poder notificar el cambio en la visibilidad al borrar los ATM
     * 
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     * 
     * @param {List<String> roles} Lista de roles
     * @return {List<AccountTeamMember>} lista de ATMs
     */
    public List<AccountTeamMember> findByRoles(List<String> roles)
    {
        List<AccountTeamMember> result = null;

        if( roles != null && !roles.isEmpty() ) {
            result = [
                SELECT Id, UserId
                FROM AccountTeamMember
                WHERE TeamMemberRole IN :roles
            ];
        }
        
        return result;
    }
}
