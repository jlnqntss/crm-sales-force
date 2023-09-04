public with sharing class SalesCRMLeadGenerationService
{
    // #region Attributes

    private static Set<String> requiredFields = new Set<String> {'origin', 'webIdentifier', 'name', 'phone'};
    private static Map<String, Schema.SObjectField> picklistTypeFieldsByJsonFieldName = new Map<String, Schema.SObjectField>
    {
        'language' => Account.Language__c,
        'productBranch' => Opportunity.ProductBranch__c
    };
    private static Map<String, Schema.SObjectField> notNullableFields = new Map<String, Schema.SObjectField>
    {
        'documentId' => Account.NationalId__c,
        'language' => Account.Language__c,
        'email' => Account.PersonEmail,
        'bestTimeFrom' => Account.PreferedContactStart__c,
        'bestTimeUntil' => Account.PreferedContactEnd__c,
        'comments' => Account.Description
    };
    // #endregion

    private static final String INVALID_FIELD = 'INVALID_FIELD';

    // #region Public methods

    /**
    * @description Método que se encarga de validar la información recibida en el
    * Ws 'WS_SalesCRM' para el recurso 'leadGeneration'
    *
    * @author amiranda
    * @date 02-09-2023 
    * @param Lead requestData con la información del Lead
    **/
    public static void validateRequestData(Lead requestData)
    {
        checkRequiredFields(requestData);
        checkPicklistValues(requestData);
    }

    /**
    * @description Método que se encarga de comprobar si el Lead recibido existe
    * en el sistema. Si existe se actualiza, sino se crea un nuevo Lead con los
    * datos recibidos.
    *
    * @author amiranda
    * @date 02-09-2023 
    * @param Lead requestData con la información del Lead
    * @return Account de tipo Lead recuperada o generada
    **/
    public static Account manageLead(Lead requestData)
    {
        Account duplicateAccount = AccountLeadUtil.leadDuplicatesControl(requestData.documentID, requestData.phone);
        AccountsSelector accountSelector = new AccountsSelector();

        if ( ( duplicateAccount != null
               && duplicateAccount.RecordTypeId.equals(accountSelector.rtLeadId) )
             || duplicateAccount == null )
        {
            if (duplicateAccount == null)
            {
                duplicateAccount = new Account();
                duplicateAccount.RecordTypeId = accountSelector.rtLeadId;
                duplicateAccount.PersonLeadSource__c = requestData.origin;
            }

            fillAccountFields(duplicateAccount, requestData);

            upsert duplicateAccount;
        }

        return duplicateAccount;
    }

    /**
    * @description Método que se encarga de comprobar si existe una oferta asociada
    * a un Lead. Si no existe se crea la oferta.
    *
    * @author amiranda 
    * @date 02-09-2023 
    * @param Account leadAccount cuenta de tipo Lead
    * @param Lead requestData con la inforamción del Lead
    * @return Opportunity recuperada/generada
    **/
    public static Opportunity manageOffer(Account leadAccount, Lead requestData)
    {
        //#region Fragmento de código temporal
        User userToAssign = [SELECT Contact.Account.Id FROM User WHERE Alias = 'agente.m' AND Contact.AccountId != null LIMIT 1];
        Account userToAssignRelatedAccount = [SELECT INFOIntermediaryCode__c FROM Account WHERE Id =: userToAssign.Contact.Account.Id];

        Id offerIntermediaryId = userToAssignRelatedAccount.Id;
        String offerIntermediaryCode = userToAssignRelatedAccount.INFOIntermediaryCode__c;
        //#endregion

        List<Opportunity> offers = new OpportunitiesSelector()
                            .findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed(
            leadAccount.Id,
            offerIntermediaryCode,
            requestData.productBranch,
            Query.last_n_days(7));

        if ( offers.isEmpty())
        {
            Opportunity offerToInsert = new Opportunity();
            offerToInsert.Name = ('OF' + Datetime.now().getTime() + leadAccount.Id).left(120);
            offerToInsert.StageName = 'Legit Lead';
            offerToInsert.CloseDate = Date.today().addDays(10);
            offerToInsert.AccountId = leadAccount.Id;
            offerToInsert.OwnerId = userToAssign.Id;
            offerToInsert.IntermediaryId__c = offerIntermediaryId;
            offerToInsert.IntermediaryCode__c = offerIntermediaryCode;
            offerToInsert.PersonLeadSource__c = requestData.origin;
            offerToInsert.ProductBranch__c = requestData.productBranch;
            offerToInsert.Description = requestData.comments;
            offerToInsert.PreferedContactStart__c = requestData.bestTimeFrom;
            offerToInsert.PReferedContactEnd__c = requestData.bestTimeUntil;

            offers.add(offerToInsert);

            insert offers;
        }

        return offers.get(0);
    }

    // #endregion

    // #region Private methods

    /**
    * @description Método que comprueba que se han recibido los campos requeridos
    * en el objeto de la clase pasada por parámetro
    * 
    * @author amiranda
    * @date 02-09-2023 
    * @param Lead requestData con la información del Lead
    **/
    private static void checkRequiredFields(Lead requestData)
    {
        Set<String> receivedFields = requestData.getReceivedFields();
        Set<String> missedRequiredFields = new Set<String>();

        for (String requiredField : requiredFields)
        {
            if ( !receivedFields.contains(requiredField) )
            {
                missedRequiredFields.add(requiredField);
            }
        }

        if ( !missedRequiredFields.isEmpty() )
        {
            throw new LeadGenerationException(
                      INVALID_FIELD,
                      'The following required fields are missing: ' + String.join(missedRequiredFields, ', ') );
        }
    }

    /**
    * @description Método que comprueba que los valores recibidos en los campos
    * de tipo picklist de la clase pasasa por parámetro son valores válidos en SF 
    *
    * @author amiranda
    * @date 02-09-2023 
    * @param Lead requestData con la información del Lead
    **/
    private static void checkPicklistValues(Lead requestData)
    {
        Set<String> invalidFields = new Set<String>();

        for ( String jsonField : picklistTypeFieldsByJsonFieldName.keySet() )
        {
            String requestDataFieldValue = (String) requestData.get(jsonField);

            if(requestDataFieldValue != null)
            {
                // Se obtienen todos lo valores de la picklist
                List<Schema.PicklistEntry> picklistEntries = picklistTypeFieldsByJsonFieldName
                                                             .get(jsonField)
                                                             .getDescribe()
                                                             .getPicklistValues();

                List<String> picklistValues = new List<String>();
                for (Schema.PicklistEntry picklistEntry : picklistEntries)
                {
                    if ( picklistEntry.isActive() )
                    {
                        picklistValues.add( picklistEntry.getValue() );
                    }
                }

                if ( !picklistValues.contains(requestDataFieldValue) )
                {
                    invalidFields.add(jsonField);
                }
            }
        }

        if ( !invalidFields.isEmpty() )
        {
            throw new LeadGenerationException(
                      INVALID_FIELD,
                      'The following fields send invalid values for the picklist entries: ' + String.join(invalidFields, ', ') );
        }
    }

    /**
    * @description Método que se encarga de rellenar los campos del registro de 
    * Account que se almacenará en SF con los datos recibidos.
    *
    * @author amiranda
    * @date 02-09-2023 
    * @param Account accountToFill que se va a rellenar con los datos del Lead
    * @param Lead requestData con la información del Lead
    **/
    private static void fillAccountFields(Account accountToFill, Lead requestData)
    {
        accountToFill.LastName = requestData.name;
        accountToFill.Phone = requestData.phone;
        accountToFill.WebId__c = requestData.webIdentifier;

        for ( String notNullableField : notNullableFields.keySet() )
        {
            if (requestData.get(notNullableField) != null)
            {
                accountToFill.put( notNullableFields.get(notNullableField), requestData.get(notNullableField) );
            }
        }
    }

    // #endregion

    // #region Auxiliar classes

    /**
     * Clase interna que representa una solicitud de 'LeadGeneration'
     */
    public class Lead
    {
        private Map<String, Object> valuesByProperty
        {
            get
            {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }

                return valuesByProperty;
            }
            set;
        }

        public String origin
        {
            get
            {
                return (String) valuesByProperty.get('origin');
            }
            set
            {
                valuesByProperty.put('origin', value);
            }
        }
        public String webIdentifier
        {
            get
            {
                return (String) valuesByProperty.get('webIdentifier');
            }
            set
            {
                valuesByProperty.put('webIdentifier', value);
            }
        }
        public String intermediaryCode
        {
            get
            {
                return (String) valuesByProperty.get('intermediaryCode');
            }
            set
            {
                valuesByProperty.put('intermediaryCode', value);
            }
        }
        public String name
        {
            get
            {
                return (String) valuesByProperty.get('name');
            }
            set
            {
                valuesByProperty.put('name', value);
            }
        }
        public String documentID
        {
            get
            {
                return (String) valuesByProperty.get('documentId');
            }
            set
            {
                valuesByProperty.put('documentId', value);
            }
        }
        public String phone
        {
            get
            {
                return (String) valuesByProperty.get('phone');
            }
            set
            {
                valuesByProperty.put('phone', value);
            }
        }
        public String language
        {
            get
            {
                return (String) valuesByProperty.get('phone');
            }
            set
            {
                valuesByProperty.put('language', value);
            }
        }
        public String postalCode
        {
            get
            {
                return (String) valuesByProperty.get('postalCode');
            }
            set
            {
                valuesByProperty.put('postalCode', value);
            }
        }
        public String email
        {
            get
            {
                return (String) valuesByProperty.get('email');
            }
            set
            {
                valuesByProperty.put('email', value);
            }
        }
        public String productBranch
        {
            get
            {
                return (String) valuesByProperty.get('productBranch');
            }
            set
            {
                valuesByProperty.put('productBranch', value);
            }
        }
        public Datetime bestTimeFrom
        {
            get
            {
                return (Datetime) valuesByProperty.get('bestTimeFrom');
            }
            set
            {
                valuesByProperty.put('bestTimeFrom', value);
            }
        }
        public Datetime bestTimeUntil
        {
            get
            {
                return (Datetime) valuesByProperty.get('bestTimeUntil');
            }
            set
            {
                valuesByProperty.put('bestTimeUntil', value);
            }
        }
        public String comments
        {
            get
            {
                return (String) valuesByProperty.get('comments');
            }
            set
            {
                valuesByProperty.put('comments', value);
            }
        }

        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }

        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /**
     * Clase interna que representa un error que se produce dentro de la clase
     * SalesCRMLeadGenerationService
     */
    public class LeadGenerationException extends Exception
    {
        public String statusCode {get; set;}
        public String message {get; set;}

        public LeadGenerationException(String statusCode, String message)
        {
            this.statusCode = statusCode;
            this.setMessage(message);
        }
    }

    // #endregion
}