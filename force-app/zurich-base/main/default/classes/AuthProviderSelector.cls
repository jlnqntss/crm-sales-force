/**
 * @description       : Clase selectora AuthProvider
 * @author            : dmunoz
 * @group             :
 * @last modified on  : 04/06/2024
 * @last modified by  : dmunoz
 **/
public with sharing class AuthProviderSelector extends RecordsSelector {
    public AuthProviderSelector() {
        super( AuthProvider.getSObjectType() );
    }

    /** Obtiene los datos del auth provider vía developer name
     * Query: SELECT Id FROM AuthProvider WHERE DeveloperName = :developerName LIMIT 1
     * @author dmunoz
     * @date 04/06/2024
     * @param List<String> typeNames : Listado de tipos de cuentas a filtrar
     */
    public List<AuthProvider> getAuthProvider(String developerName) 
    {
        List<AuthProvider> result = new List<AuthProvider>();
        if ( developerName != null && String.isNotEmpty(developerName) )
        {
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    AuthProvider.Id
                }
            );

            this.baseQuery.addConditionEq(AuthProvider.DeveloperName, developerName);
            this.baseQuery.setlimit(1);

            result = this.baseQuery.run();
        }

        return result;
    }

}