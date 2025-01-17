/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 15-11-2023
 * @last modified by  : amiranda
**/
public with sharing class ContactsSelector extends RecordsSelector
{
    public RecordsSelector.Scope relatedRecordsScope;
    public Map<String, Schema.RecordTypeInfo> ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

    public String ACCOUNT_RT_CUSTOMER = ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME.get('Customer').getRecordTypeId();
    public String ACCOUNT_RT_BUSINESS_CUSTOMER = ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME.get('BusinessCustomer').getRecordTypeId();
    public String ACCOUNT_RT_LEAD = ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME.get('Lead').getRecordTypeId();
    public String ACCOUNT_RT_PARTNER_OCS = ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME.get('PartnerOCS').getRecordTypeId();
    public String ACCOUNT_RTID_FIELD = 'Account.RecordTypeId';
    public String ACCOUNT_RT_NAME_FIELD = 'Account.RecordType.DeveloperName';
    public String ACCOUNT_TYPE_FIELD = 'Account.Type';

    //#region Contructores

    public ContactsSelector()
    {
        super(Contact.getSObjectType());
    }

    //#endregion

    public static final String RT_NAME_CONTACT = 'Contact';

    // Recupera el Id del RecordType de cuentas de tipo CONTACT
    public ID rtContactId {
        get {
            return Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(RT_NAME_CONTACT)?.getRecordTypeId();
        }
    }

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 02/02/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de ContactsSelector con el filtro de scope aplicado
     */
    public ContactsSelector setScope(RecordsSelector.Scope scope)
    {

        switch on scope 
        {
            when ALL
            {
                this.baseQuery.addConditionIn(ACCOUNT_RTID_FIELD, new Set<String>{ACCOUNT_RT_CUSTOMER, ACCOUNT_RT_BUSINESS_CUSTOMER, ACCOUNT_RT_LEAD});
            }
            when Z 
            {
                this.baseQuery.addConditionIn(ACCOUNT_RTID_FIELD, new Set<String>{ACCOUNT_RT_CUSTOMER, ACCOUNT_RT_BUSINESS_CUSTOMER});

                this.relatedRecordsScope = RecordsSelector.Scope.Z;
            }
            when ZE  
            {
                this.baseQuery.addConditionIn(ACCOUNT_RTID_FIELD, new Set<String>{ACCOUNT_RT_CUSTOMER, ACCOUNT_RT_LEAD, ACCOUNT_RT_BUSINESS_CUSTOMER, ACCOUNT_RT_PARTNER_OCS});

                this.relatedRecordsScope = RecordsSelector.Scope.ZE;
            }
            when ZEO
            {
                this.baseQuery.addConditionIn(ACCOUNT_RTID_FIELD, new Set<String>{ACCOUNT_RT_CUSTOMER, ACCOUNT_RT_LEAD, ACCOUNT_RT_BUSINESS_CUSTOMER, ACCOUNT_RT_PARTNER_OCS});
                
                this.relatedRecordsScope = RecordsSelector.Scope.ZEO;
            }
            when else 
            {
                // else code
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de entidad legal a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  legalEntity  Entidad legal a aplicar en el filtro
     * @return              Instancia de ContactsSelector con el filtro de entidad legal aplicado
     */
    public ContactsSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI, LIFE
            {
                Query.Condition condition = Query.doOr
                (
                    Query.conditionEq(Contact.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity)),
                    Query.conditionEq('Account.LegalEntity__c', RecordsSelector.getLegalEntity(legalEntity))
                );

                this.baseQuery.addCondition(condition);
            }
            when else 
            {
                // else code
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de record type name a las cuentas asociadas a los contactos
     * @author aberuete
     * @date 02/06/2023
     * @param List<String> recordTypeNames : Listado de record type names de cuentas asociados a contactos a filtrar
     */
    public ContactsSelector setRecordType (List<String> recordTypeNames)
    {
        if ( recordTypeNames != null && !recordTypeNames.isEmpty())
        {
            this.baseQuery.addConditionIn(ACCOUNT_RT_NAME_FIELD, recordTypeNames);
        }
        return this;
    }

    /**
     * Aplicar el filtro de tipo de cuentas a las cuentas asociadas a los contactos
     * @author aberuete
     * @date 06/06/2023
     * @param List<String> recordTypeNames : Listado de tipo de cuentas asociados a contactos a filtrar
     */
    public ContactsSelector setTypeOfAccount (List<String> typeNames)
    {
        if ( typeNames != null && !typeNames.isEmpty())
        {
            this.baseQuery.addConditionIn(ACCOUNT_TYPE_FIELD, typeNames);
        }
        return this;
    }

    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = findInContactPointsByPhoneNumber(phones, relatedRecordsScope);

        Query.Condition condition = Query.doOr
        (
            Query.conditionIn(Contact.Id, matchedRecordIds),
            Query.conditionIn(Contact.AccountId, matchedRecordIds)
        );

        this.baseQuery.selectFields
        (
            new Set<Schema.SObjectField>
            {
                Contact.Id, 
                Contact.AccountId
            }
        )
        .addCondition(condition);
       

        return (List<Contact>) this.baseQuery.run();

    }

    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByEmail(List<String> emails)
    {
        Set<Id> matchedRecordIds = findInContactPointsByEmail(emails, relatedRecordsScope);

        Query.Condition condition = Query.doOr
        (
            Query.conditionIn(Contact.Id, matchedRecordIds),
            Query.conditionIn(Contact.AccountId, matchedRecordIds)
        );

        this.baseQuery.selectFields
        (
            new Set<Schema.SObjectField>
            {
                Contact.Id, 
                Contact.AccountId
            }
        ).addCondition(condition);

        return (List<Contact>) this.baseQuery.run();
    }

    public static Set<Id> findInContactPointsByPhoneNumber(List<String> phones, RecordsSelector.Scope scope)
    {
        Set<Id> recordIds = new Set<Id>();
        String phonesToFind = processPhoneList(phones);

        for(List<SObject> records : [FIND :phonesToFind IN PHONE FIELDS RETURNING ContactPointPhone(Id, ParentId, ContactId__c, Scope__c)])
        {
            for(sObject record : records)
            {
                ContactPointPhone contactPoint = (ContactPointPhone) record;

                if(scope == null || contactPoint.Scope__c == scope.name())
                {
                    if( String.isNotBlank(contactPoint.ParentId) )
                    {
                        recordIds.add(contactPoint.ParentId);
                    }

                    if( String.isNotBlank(contactPoint.ContactId__c) )
                    {
                        recordIds.add(contactPoint.ContactId__c);
                    }
                }
            }
        }

        return recordIds;
    }


    public static Set<Id> findInContactPointsByEmail(List<String> emails, RecordsSelector.Scope scope)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(emails, ' OR ') IN EMAIL FIELDS RETURNING ContactPointEmail(Id, ParentId, ContactId__c, Scope__c)])
        {
            for(sObject record : records)
            {
                ContactPointEmail contactPoint = (ContactPointEmail) record;

                if(scope == null || contactPoint.Scope__c == scope.name())
                {
                    if( String.isNotBlank(contactPoint.ParentId) )
                    {
                        recordIds.add(contactPoint.ParentId);
                    }

                    if( String.isNotBlank(contactPoint.ContactId__c) )
                    {
                        recordIds.add(contactPoint.ContactId__c);
                    }
                }
            }
        }

        return recordIds;
    }

    /**
     * Busca contactos que tengan los emails dados por parametro en el campo Email
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByEmailField(List<String> emails)
    {
        List<Contact> result = null;

        if( emails != null && !emails.isEmpty() ) {
            this.baseQuery.selectFields (
                new Set<Schema.SObjectField> {
                    Contact.Id, 
                    Contact.Email,
                    Contact.AccountId
                }
            );
            this.baseQuery.addConditionIn(Contact.Email, emails);

            result = (List<Contact>) this.baseQuery.run();
        }
        return result;
    }

    /**
     * Método que busca contactos por ANI
     * @author jjuaristi@seidor.es
     * @date 16/11/2022
     * @param String con el ANI
     * @return Lista de contactos con ese ANI (debería ser solo 1)
     */
    public List<Contact> findByANI(String phone)
    {
        List<Contact> result = null;

        if( phone != null && phone != '' ) {
            this.baseQuery.selectFields (
                new Set<Schema.SObjectField> {
                    Contact.Id, 
                    Contact.Phone,
                    Contact.AccountId
                }
            );
            this.baseQuery.addConditionEq(Contact.Phone, phone)
            .addConditionIn(ACCOUNT_RTID_FIELD, new Set<String>{ACCOUNT_RT_PARTNER_OCS});
            result = (List<Contact>) this.baseQuery.run();
        }
        return result;
    }

    /**
     * Consulta de contacto a partir de email y código de cliente del record type Intermediary (Mediador)
     * @author dmunoz
     * @date 16/11/2022
     * @param String email
     * @param String accountCode
     * @return Lista de contactos
     */
    public List<Contact> findIntermediaryContactByEmailAndAccountCode(String email, String accountCode) {
        List<Contact> result = new List<Contact>();
        String idAgentMediator = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('AgentMediator')?.getRecordTypeId();


        if (email != null && String.isNotEmpty(email) && accountCode != null && String.isNotEmpty(accountCode)) {
            result = new List<Contact>([
                SELECT Id FROM Contact WHERE Account.RecordTypeId = :ACCOUNT_SCHEMA_SOBJECT_RT_DEVNAME.get('Intermediary').getRecordTypeId() 
                AND Account.INFOIntermediaryCode__c = :accountCode AND Email = :email 
                AND RecordtypeId = :idAgentMediator       
            ]);
        }
        return result;
    }

    /**
     * Consulta de contacto a partir de codigo de afiliación de su cuenta
     * @author dmunoz
     * @date 16/11/2022
     * @param String email
     * @param String affiliationCodeList
     * @return Lista de contactos
     */
    public List<Contact> findContactByEmailAndAccountAffiliationCode(String email, List<String> affiliationCodeList) {
        List<Contact> result = new List<Contact>();
        if (email != null && String.isNotEmpty(email) && affiliationCodeList != null && !affiliationCodeList.isEmpty()) {
            result = new List<Contact>([
                SELECT Id FROM Contact WHERE 
                Account.INFOBusinessCode__c = :affiliationCodeList
                AND RecordtypeId = :rtContactId 
                AND Email = :email  
            ]);
        }
        return result;
    }
    
    /**
    * @description Método que recupera contactos cuyas cuentas relacionadas son 
    * de uno de los tipos de registro que se pasan por parámetro y no están relacionados
    * con ninguno de los Ids de las cuentas pasados por parámetro.
    *
    * @author amiranda
    * @date 15-11-2023 
    * @param recordTypeNames Lista con el nombre de los tipos de registros de cuentas a recupera
    * @param accountIds Conjunto de Ids de cuentas sobre las que no considerar a la hora de recuperar los contactos
    * @return List<Contact> Lista de contactos recuperados
    **/
    public List<Contact> selectByRelatedAccountRecordTypeAndNotInAccountIds(List<String> recordTypeNames, Set<Id> accountIds)
    {
        Set<String> fieldsToRetrieve = new Set<String>
        {
            'Id',
            'AccountId',
            'Account.Name',
            'Account.INFOCustomerNumber__c',
            'Account.NationalId__c',
            'Account.RecordType__c'
        };

        return this.setRecordType(recordTypeNames).baseQuery
               .selectfields(fieldsToRetrieve)
               .addConditionNotIn(Contact.AccountId, accountIds)
               .orderBy('Account.Name', 'ASC')
               .enforceSecurity()
               .run();
    }

    public List<Contact> findById(Set<String> ids)
    {
        List<Contact> result = null;

        if( ids != null && !ids.isEmpty() ) {
            this.baseQuery.selectFields (
                new Set<Schema.SObjectField> {
                    Contact.Id, 
                    Contact.AccountId
                }
            );
            this.baseQuery.addConditionIn(Contact.Id, ids);
            result = (List<Contact>) this.baseQuery.run();
        }
        return result;
    }

    /**
     * Busca contactos que tengan los emails dados por parametro en el campo Email
     *
     * @author nts (jfherrero)
     * @date 22/11/2023
     * @param  phones Listado de teléfonos
     * @return        String para la query de ContactPointPhone
     */
    private static String processPhoneList(List<String> phones)
    {
        List<String> alternativePhones = new List<String>();

        for (String phone : phones)
        {
            if (phone.contains('+'))
            {
                alternativePhones.add(phone.remove('+'));
            }
            else
            {
                alternativePhones.add('+' + phone);
            }
        }

        String phonesToFind = String.join(phones, ' OR ').replace('+', '\\+') + ' OR ' + String.join(alternativePhones, ' OR ');

        return phonesToFind;
    }

}