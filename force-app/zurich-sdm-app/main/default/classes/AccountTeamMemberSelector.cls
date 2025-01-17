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

    public static final string ATM_ZRM_INTERMEDIARY_ROLE = 'MediadorZRM';
    public static final string TEMPORARY_ACCOUNT_TEAM_MEMBER = 'RN Temporal';
    
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
                'UserId', 'User.Name', 'Account.Zone__c'
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
            String configValue = GlobalConfigUtil.getGlobalConfigurationValue('AccountTeamMember_TeamMemberRole_RN_Temp');

            result = [
                SELECT id, AccountId, Account.ParentId, UserId, NotificationsOnPlans__c, Account.IntermediaryDescription__c, Account.INFOIntermediaryCode__c
                FROM AccountTeamMember
                WHERE Account.RecordTypeId = :rtId
                AND UserId IN :userIds
                AND Account.StatusIntermediary__c = 'Active'
                AND TeamMemberRole <> :configValue
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
                // Los miembros temporales se crean y eliminan manualmente y no deben ser tenidos en cuenta por otros procesos.
                AND TeamMemberRole <> :TEMPORARY_ACCOUNT_TEAM_MEMBER
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


    /**
     * Recupera los AccountTeamMember que no tienen el check de notificacion activo de un usuario dado     
     * 
     * @author nts (dmunoz)
     * @date 02/12/2022
     * 
     * @param {Id userId} Id de usuario
     * @param {List<String> idsNotificationActiveList} Lista ids activos que debemos filtrar
     * @return {List<AccountTeamMember>} lista de ATMs
     */
    public List<AccountTeamMember> findIntermedariesWithInactiveNotifications(String userId, List<String> idsNotificationActiveList) {
        List<AccountTeamMember> result = null;

        if( userId != null ) {
            Id rtId = (new AccountsSelector()).rtIntermediaryId;

            result = [
                SELECT Id, NotificationsOnPlans__c
                FROM AccountTeamMember
                WHERE Account.RecordTypeId = :rtId
                AND UserId = :userId
                AND id not in :idsNotificationActiveList
                AND NotificationsOnPlans__c = true
                AND Account.StatusIntermediary__c = 'Active'
            ];
        }        
        return result;
    }

    /**
     * Recupera los AccountTeamMember que estén asociados a una lista de cuentas , para unos roles especificos 
     * y cuyos usuarios no hayan sido notificados o si han sido notificados no hayan sido notificados para un tipo de seguimiento en concreto.
     * 
     * @author aberuete
     * @date 13/02/2023
     * 
     * @param {Set<String> roles} Lista de roles de los miembros del equipo de cuentas que debe devolver 
     * @param {Set<Id> accountIds} Lista de ids de cuentas a los que debe estar asciado el miembro del equipo de cuentas
     * @param {String type} Tipo de seguimiento para el que el usuario no debe haber sido notificado
     * @return {List<AccountTeamMember>} lista de ATMs
     */
    public List<AccountTeamMember> findUsersByRoleAndAccountIdFields (Set<String> roles, Set<Id> accountIds,String type) 
    {
        List<Schema.SobjectField> fieldList = new List<Schema.SobjectField>
                                            {
                                                AccountTeamMember.fields.UserId,
                                                AccountTeamMember.fields.Id
                                            };
        Query userQuery = new Query(User.getSObjectType());
        userQuery.selectFields(new List<Schema.SObjectField> {
                                User.Id
                                });
        
        userQuery.addCondition(
            Query.doOr(
                Query.conditionEq(User.Notified__c, false),
                Query.doAnd(
                    Query.ConditionEq(User.Notified__c, true),
                    Query.conditionExcludes(User.NotifyType__c, type)
                )
            )
        );

        if (roles != null && !roles.isEmpty() && !roles.contains('Todos') && accountIds != null && !accountIds.isEmpty() )
        {
           this.baseQuery.selectFields(fieldList)
           .addConditionIn(AccountTeamMember.fields.AccountId,accountIds)
           .addConditionIn(AccountTeamMember.fields.TeamMemberRole,roles)
           .addConditionIn(AccountTeamMember.fields.UserId,userQuery);
        }
        else if (roles != null && !roles.isEmpty() && roles.contains('Todos') && accountIds != null && !accountIds.isEmpty()) 
        {
            this.baseQuery.selectFields(fieldList)
           .addConditionIn(AccountTeamMember.fields.AccountId,accountIds)
           .addConditionIn(AccountTeamMember.fields.UserId,userQuery);
        }
        return (List<AccountTeamMember>)this.baseQuery.run();
    }

    /**
     * Método que recupera los AccountTeamMember según la cuenta y el usuario
     * *
     * @author arcortazar
     * @date 14/11/2023
     * @param Set<String> lista de identificadores de cuentas
     * @param Set<String> lista de identificadores de mediadores
     * @return  List<Opportunity>
     */
    public List<AccountTeamMember> findByAccountAndUser(Set<Id> accountsIds, Set<Id> usersIds)
    {
        List<AccountTeamMember> retorno = new List<AccountTeamMember>();
        if (accountsIDs != null && !accountsIDs.isEmpty() 
            && usersIDs != null && !usersIDs.isEmpty() )
            {
                this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                    AccountTeamMember.Id,
                    AccountTeamMember.AccountId,
                    AccountTeamMember.UserId
                })
                .addConditionIn(AccountTeamMember.AccountId, accountsIDs)
                .addConditionIn(AccountTeamMember.UserId, usersIDs);

                retorno = (List<AccountTeamMember>) this.baseQuery.run();
            }
        return retorno;
    }

    /**
     * Método que recupera los AccountTeamMember según una lista de usuarios
     * 
     * SELECT Id, AccountId, UserId, User.Profile.Name
     * FROM AccountTeamMember
     * WHERE UserId = :userList
     *  AND TeamMemberRole = 'MediadorZRM'
     * 
     * @author dmunoz
     * @date 14/02/2024
     * @param Set<String> lista de identificadores de cuentas
     * @param Set<String> lista de identificadores de mediadores
     */
    public List<AccountTeamMember> findZRMATMsByUser(List<User> userList) {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        if (userList != null && !userList.isEmpty()) {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                AccountTeamMember.AccountId,
                AccountTeamMember.UserId
            };

            result = this.baseQuery
                            .selectFields(fieldsToRetrieve)
                            .selectField('User.Profile.Name')
                            .addConditionIn(AccountTeamMember.UserId, userList)
                            .addConditionEq(AccountTeamMember.TeamMemberRole, ATM_ZRM_INTERMEDIARY_ROLE)
                            .enforceSecurity()
                            .run();
        }

        return result;
    }


    /**
     * Método que recupera los AccountTeamMember de un lead para el batch de merge. Este batch elimina los atm del lead por lo que tenemos que consultarlos antes
     * 
     * SELECT AccountId, UserId, TeamMemberRole, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, ContactAccessLevel 
     * FROM AccountTeamMember 
     * WHERE AccountId = :leadAccount.Id
     *  AND TeamMemberRole = 'MediadorZRM'
     * 
     * @author dmunoz
     * @date 12/03/2024
     */
    public List<AccountTeamMember> getLeadZRMAccountTeamsMember(Account leadAccount)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        if (leadAccount != null)
        {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                AccountTeamMember.AccountId,
                AccountTeamMember.UserId,
                AccountTeamMember.TeamMemberRole,
                AccountTeamMember.AccountAccessLevel,
                AccountTeamMember.OpportunityAccessLevel,
                AccountTeamMember.CaseAccessLevel,
                AccountTeamMember.ContactAccessLevel
            };

            result = this.baseQuery
                            .selectFields(fieldsToRetrieve)
                            .addConditionEq(AccountTeamMember.AccountId, leadAccount.Id)
                            .addConditionEq(AccountTeamMember.TeamMemberRole, ATM_ZRM_INTERMEDIARY_ROLE)
                            .enforceSecurity()
                            .run();
        }
        return result;

    }


    /**
     * Método que recupera los AccountTeamMember de un cliente para un mediador y agrupaciones
     * 
     * SELECT Id FROM AccountTeamMember
     * WHERE AccountId IN :accountIdsSet
     *     AND UserId IN :userList
     *     AND TeamMemberRole = 'MediadorZRM'
     * 
     * @author dmunoz
     * @date 26/02/2024
     */
    public List<AccountTeamMember> getZRMATMByAccountAndUser(Set<String> accountIdsSet, List<User> userList)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        if (accountIdsSet != null && !accountIdsSet.isEmpty() && userList != null && !userList.isEmpty())
        {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                AccountTeamMember.Id
            };

            result = this.baseQuery
                            .selectFields(fieldsToRetrieve)
                            .addConditionIn(AccountTeamMember.AccountId, accountIdsSet)
                            .addConditionIn(AccountTeamMember.UserId, userList)
                            .addConditionEq(AccountTeamMember.TeamMemberRole, ATM_ZRM_INTERMEDIARY_ROLE)
                            .enforceSecurity()
                            .run();
        }        

        return result;
    }

    /**
     * Método que recupera los AccountTeamMember de un cliente para un mediador y agrupaciones
     *
     * SELECT Id FROM AccountTeamMember 
     * WHERE AccountId NOT IN :accountIdsSet 
     *  AND UserId IN :userList
     *  AND TeamMemberRole = 'MediadorZRM'
     * 
     * @author dmunoz
     * @date 26/02/2024
     */
    public List<AccountTeamMember> getZRMATMUserAndOtherAccounts(Set<String> accountIdsSet, List<User> userList)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        if (accountIdsSet != null && !accountIdsSet.isEmpty() && userList != null && !userList.isEmpty())
        {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                AccountTeamMember.Id
            };

            result = this.baseQuery
                            .selectFields(fieldsToRetrieve)
                            .addConditionNotIn(AccountTeamMember.AccountId, accountIdsSet)
                            .addConditionIn(AccountTeamMember.UserId, userList)
                            .addConditionEq(AccountTeamMember.TeamMemberRole, ATM_ZRM_INTERMEDIARY_ROLE)
                            .enforceSecurity()
                            .run();
        }        

        return result;
    }

    /**
     * Método que recupera los ATMs de un cliente a través del ID del usuario
     * @author nikola.cobian@seidor.com
     * @date 08/04/2024
     * @param Set<Id> userId
     * @return List<AccountTeamMember>
     */
    public List<AccountTeamMember> findATMsForIntermediariesByUserId(Set<String> usersId)
    {
        if(usersId != null && !usersId.isEmpty())
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                AccountTeamMember.Id
            })
            .addConditionIn(AccountTeamMember.UserId, usersId)
            .addConditionEq(AccountTeamMember.TeamMemberRole, ATM_ZRM_INTERMEDIARY_ROLE);
            
            return (List<AccountTeamMember>) this.baseQuery.run();
        }
        else
        {
            return new List<AccountTeamMember>();
        }
    }
}