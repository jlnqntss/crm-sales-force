/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 15-11-2021
 * @last modified by  : jjuaristi
**/
public without sharing class TechnicalIncidenceController {

    @AuraEnabled(cacheable=true)
    public static Boolean getScope(String record){
        try {
            // Recogemos los scopes de ZE y los de ZEO y los concatenamos haciendo uso de addAll
            List<Scope__c> scopes = new ScopesSelector(new Set<String> {'Id','TechnicalIncidence__c'}).selectByAccountIdAndScope(new Set<Id>{record}, RecordsSelector.Scope.ZE);
            scopes.addAll(new ScopesSelector(new Set<String> {'Id','TechnicalIncidence__c'}).selectByAccountIdAndScope(new Set<Id>{record}, RecordsSelector.Scope.ZEO));

            // Si en alguno de los scopes el check de incidencia técnica está marcado, devolvemos true
            for(Scope__c scope : scopes)
            {
                if(scope.TechnicalIncidence__c)
                    return true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return false;
    }
}
