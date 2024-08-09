/**
 * @description       : Clase de servicio que gestiona la lógica del recurso
 * 'leadGeneration' del web service 'WS_SalesCRM'.
 *
 * @author            : amiranda
 * @date              : 07-03-2024
 * @last modified on  : 07-03-2024
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   21-09-2023   amiranda   Initial Version
 **/
public with sharing class SalesCRMLeadGenerationService
{
    // #region Attributes

    private static final Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
    private static final String PRODUCT_BRANCH_VIDA_CODE = configValues.get('Product_Branch_Vida_Code');
    private static final Id OFFER_RECORD_TYPE_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_Life')).getRecordTypeId();
    private static final Id OFFER_RECORD_TYPE_NO_VIDA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_NoLife')).getRecordTypeId();
    private static final String LEGAL_ENTITY_LIFE_INSURANCE = configValues.get('Legal_Entity_Life_Insurance');

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
    private static final String INVALID_FIELD = 'INVALID_FIELD';
    @TestVisible
    private static final String NATIONAL_ID_TYPE_NIF = 'N';

    // #endregion

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

    public static void manageCallMeBack(Lead requestData)
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = leadOffersCS.VoiceQueue__c;
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack callMeBack = new CallMeBackUtil.CallMeBack();
        callMeBack.name = requestData.name;
        callMeBack.phone = requestData.phone;
        callMeBack.bestTimeFrom = requestData.bestTimeFrom;
        callMeBack.bestTimeUntil = requestData.bestTimeUntil;
        callMeBack.webIdentifier = requestData.webIdentifier;
        callMeBack.businessCode = businessCode;

        CallMeBackUtil.CallMeBackFull fullObj = new CallMeBackUtil.CallMeBackFull();
        fullObj.request = callMeBack;
        fullObj.queueName = leadOffersCS.VoiceQueue__c;
        fullObj.businessHoursName = leadOffersCS.BusinessHour__c;

        List<CallMeBackUtil.CallMeBackFull> lstCallMeBack = new List<CallMeBackUtil.CallMeBackFull>();
        lstCallMeBack.add(fullObj);

        CallMeBackUtil.insertCallMeBack(lstCallMeBack);
    }

    /**
     * @description Método que se encarga de comprobar si existe una oferta asociada
     * a un Lead. Si no existe se crea la oferta.
     *
     * @author amiranda
     * @date 02-09-2023
     * @param Account leadAccount cuenta de tipo Lead
     * @param Id leadId Id de la cuenta de tipo 'Lead' insertada en SF
     * @param Lead requestData con la inforamción del Lead
     * @return Opportunity recuperada/generada
     * 
     * @change amiranda 06/03/2024 Se elimina la asignación de 'Owner'
     * @change igarcia 11/06/2024 Se añade la lógica del recordtype de vida
     **/
    public static Opportunity manageOffer(Map<String, Account> accountByRelatedUser, Id leadId, Lead requestData)
    {
        Id offerOwnerId = new List<String>( accountByRelatedUser.keySet() ).get(0);
        Account account = accountByRelatedUser.get(offerOwnerId);
        Boolean isOfferLife = (requestData.isProductLife == 1);
        String offerRecordType = isOfferLife ? OFFER_RECORD_TYPE_VIDA : OFFER_RECORD_TYPE_NO_VIDA;

        List<Opportunity> offers = new OpportunitiesSelector()
                                   .findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed(
            leadId,
            account != null ? account.INFOIntermediaryCode__c : null,
            requestData.productBranch,
            offerRecordType,
            Query.last_n_days(7) );

        if ( offers.isEmpty() )
        {

            Opportunity offerToInsert = new Opportunity();
            offerToInsert.Name = ( 'OF' + Datetime.now().getTime() / 1000 + leadId.to15() ).left(120);
            offerToInsert.StageName = 'Legit Lead';
            offerToInsert.CloseDate = Date.today().addDays(10);
            offerToInsert.AccountId = leadId;
            offerToInsert.IntermediaryId__c = account != null ? account.Id : null;
            offerToInsert.IntermediaryCode__c = account != null ? account.INFOIntermediaryCode__c : null;
            offerToInsert.PersonLeadSource__c = requestData.origin;
            offerToInsert.ProductBranch__c = requestData.productBranch;
            offerToInsert.Description = requestData.comments;

            if(isOfferLife)
            {
                offerToInsert.recordTypeId = OFFER_RECORD_TYPE_VIDA;
                offerToInsert.LegalEntity__c = LEGAL_ENTITY_LIFE_INSURANCE;
                offerToInsert.isProductLife__c = true;
            }
            else
            {
                offerToInsert.recordTypeId = OFFER_RECORD_TYPE_NO_VIDA;
            }

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
     * @throws LeadGenerationException
     **/
    @TestVisible
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
     * @throws LeadGenerationException
     **/
    @TestVisible
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
     *
     * @change amiranda 02/10/2023 Se añade una condición para informar el campo
     * LastName únicamente si la cuenta que se pasa por parámetro se encuentra en
     * Salesforce.
     **/
    @TestVisible
    private static void fillAccountFields(Account accountToFill, Lead requestData)
    {
        // Si el Id no está informado se considera que no se ha encontrado una cuenta duplicada en el sistema
        if ( !accountToFill.isSet(Account.Id) )
        {
            accountToFill.LastName = requestData.name;
        }

        accountToFill.Phone = requestData.phone;
        accountToFill.WebId__c = requestData.webIdentifier;

        setNationalIdType( accountToFill, (String) requestData.get('documentId') );

        for ( String notNullableField : notNullableFields.keySet() )
        {
            if (requestData.get(notNullableField) != null)
            {
                accountToFill.put( notNullableFields.get(notNullableField), requestData.get(notNullableField) );
            }
        }
    }

    /**
     * @description Método que se encarga de informar el campo 'NationalIdType__c'
     * con valor 'N' (NIF). Se informará siempre y cuando el parámetro 'documentId'
     * no sea nulo y la cuenta sobre la que se informará el campo `NationalIdType__c'
     * (accountToFill) no tenga este último campo informado o no tenga el campo
     * 'NationalId__c' informado.
     *
     * @author amiranda
     * @date 13-09-2023
     * @param accountToFill Cuenta sobre la que se va a informar el campo NationalIdType__c
     * @param documentId Documento de identidad del Lead recibido en la request
     **/
    @TestVisible
    private static void setNationalIdType(Account accountToFill, String documentId)
    {
        if ( String.isNotBlank(documentId) &&
             (accountToFill.NationalIdType__c == null || accountToFill.NationalId__c == null) )
        {
            accountToFill.NationalIdType__c = NATIONAL_ID_TYPE_NIF;
        }
    }

    // #endregion

    // #region Auxiliar classes

    /**
     * Clase interna que representa una solicitud de 'LeadGeneration'
     */
    public class Lead
    {
        @TestVisible
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
                return (String) valuesByProperty.get('language');
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
        public Decimal isProductLife
        {
            get
            {
                return (Decimal) valuesByProperty.get('isProductLife');
            }
            set
            {
                valuesByProperty.put('isProductLife', value);
            }
        }

        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }

        @TestVisible
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