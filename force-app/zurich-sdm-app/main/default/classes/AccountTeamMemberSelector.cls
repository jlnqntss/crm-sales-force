/**
 * Clase selectora para el sobject AccountTeamMember
 * 
 * @author nts (agonzalezisasi)
 * @date 08/11/2021
 */
public with sharing class AccountTeamMemberSelector extends RecordsSelector {
    // Roles de los usuarios en los equipos de cuenta de los mediadores. Directamente relacionados con el metadato AccountTeamRole
    public static final String ATM_ROLE_RN_NAME = 'Responsable de Negocio';
    public static final String ATM_ROLE_CV_NAME = 'Consultor Vida';
    
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
}
