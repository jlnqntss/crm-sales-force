public with sharing class AccountsSelector
{
    public Set<Id> recordTypeIds;

    /**
     * Busca cuentas a partir de un listado de DNIs
     *
     * @author rlopez
     * @date 04/11/2020
     * @param  nationalIds          Listado de DNIs. Válido cualquier formato
     * @param  nationalIdType       Tipo de documento a buscar
     * @param  legalEntity          Entidad legal en la que buscar
     * @return                      Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByNationalId(List<String> nationalIds, String nationalIdType, String legalEntity)
    {
        if( nationalIds != null && !nationalIds.isEmpty() && String.isNotBlank(nationalIdType) && String.isNotBlank(legalEntity) )
        {
            return [SELECT Id, NationalId__c FROM Account WHERE NationalId__c IN : nationalIds AND NationalIdType__c =: nationalIdType AND LegalEntity__c =: legalEntity AND RecordTypeId IN: this.recordTypeIds];
        }
        else
        {
            return new List<Account>();
        }
    }

    /**
     * Instancia AccountsSelector inicializando la variable recordTypeIds con los IDs
     * de los tipos de registro que se utilizan en el Scope indicado com parámetro
     *
     * @author rlopez
     * @date 06/11/2020
     * @param  scope    Contexto en el que se utilizarán las búsqueda de contacto (ZE, OCS, ...)
     * @return          Instancia de AccountsSelector con la variable recordTypeIds inicializada
     */
    public AccountsSelector applyScope(String scope)
    {
        Map<ID, Schema.RecordTypeInfo> recordTypeInfosById = Schema.SObjectType.Account.getRecordTypeInfosById();
        Map<String, Schema.RecordTypeInfo> recordTypeInfosByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        //Por defecto añadimos todos los recordTypeIds, y en los distintos scopes controlamos cuales se utilizan
        this.recordTypeIds = recordTypeInfosById.keySet();

        // Rellenamos el recordTypeIds con los Ids de cada scope
        switch on scope.toLowerCase() {
            when 'ze' {
                this.recordTypeIds = new Set<Id>();
                for (String recordTypeName: recordTypeInfosByDeveloperName.keySet()) {
                    if(recordTypeName == 'BusinessCustomer')
                    {
                        this.recordTypeIds.add(recordTypeInfosByDeveloperName.get(recordTypeName).getRecordTypeId());
                    }
                }
            }
            when 'klink' {
                
            }
        }

        return this;
    }
}
