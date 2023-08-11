/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11/08/2023
 * @last modified by  : jgallaga
**/
public with sharing class AccountLeadAssignment
{

    private static final String CONTACT_CENTER           = 'CONTACT_CENTER';
    private static final String DEFAULT_ASSIGNEMENT_TYPE = 'Province';

    @TestVisible
    private static List<LanguageAssignment__mdt> languageAssignmentMetadata
    {
        get
        {
            if(languageAssignmentMetadata != null)
            {
                return languageAssignmentMetadata;
            }

            languageAssignmentMetadata = LanguageAssignment__mdt.getAll().values();
            return languageAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<ForumOriginAssignment__mdt> formOriginAssignmentMetadata
    {
        get
        {
            if(formOriginAssignmentMetadata != null)
            {
                return formOriginAssignmentMetadata;
            }

            formOriginAssignmentMetadata = ForumOriginAssignment__mdt.getAll().values();
            return formOriginAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<MunicipalityAssignment__mdt> municipalityAssignmentMetadata
    {
        get
        {
            if(municipalityAssignmentMetadata != null)
            {
                return municipalityAssignmentMetadata;
            }

            municipalityAssignmentMetadata = MunicipalityAssignment__mdt.getAll().values();
            return municipalityAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<ProvinceAssignment__mdt> provinceAssignmentMetadata
    {
        get
        {
            if(provinceAssignmentMetadata != null)
            {
                return provinceAssignmentMetadata;
            }

            provinceAssignmentMetadata = ProvinceAssignment__mdt.getAll().values();
            return provinceAssignmentMetadata;
        }
        set;
    }

    private static Id defaultUserId
    {
        get
        {
            if(String.isNotBlank(defaultUserId))
            {
                return defaultUserId;
            }

            defaultUserId = getDefaultZRMAccountLeadOwnerId();

            return defaultUserId;
        }
        set;
    }

    public static Id getAssignedUserIdByIntermediaryCode(String intermediaryCode)
    {
        if(intermediaryCode == CONTACT_CENTER)
        {
            return CONTACT_CENTER;
        }

        return getIntermediaryUserId(intermediaryCode);
    }

    public static String getAssignedUserIdByLanguage(String language)
    {
        for(LanguageAssignment__mdt currentLanguageAssignment : languageAssignmentMetadata)
        {
            if(currentLanguageAssignment.Language__c == language && String.isNotBlank(currentLanguageAssignment.AssignTo__c))
            {
                return getIntermediaryUserId(currentLanguageAssignment.AssignTo__c);
            }
        }

        return defaultUserId;
    }

    public static String getAssignedUserIdByAssignmentType(String origin, String postalCode)
    {
        String assignedUser;
        String assignmentType = getAssigmentType(origin);

        switch on assignmentType
        {
            when 'Direct'
            {
                assignedUser = assignedUserDirectly(origin);
            }
            when 'Municipality'
            {
                assignedUser = assignedUserByMunicipality(postalCode);
            }
            when 'Province'
            {
                assignedUser = assignedUserByProvince(postalCode);
            }
            when else
            {
                assignedUser = defaultUserId;
            }
        }

        return assignedUser;
    }

    private static String assignedUserDirectly(String origin)
    {
        if(String.isBlank(origin))
        {
            return defaultUserId;
        }

        for(ForumOriginAssignment__mdt currentFOA : formOriginAssignmentMetadata)
        {
            if(currentFOA.ForumOrigin__c == origin && String.isNotBlank(currentFOA.AssignTo__c))
            {
                return getIntermediaryUserId(currentFOA.AssignTo__c);
            }
        }

        return defaultUserId;
    }

    private static String assignedUserByMunicipality(String postalCode)
    {
        if(String.isBlank(postalCode))
        {
            return defaultUserId;
        }

        for(MunicipalityAssignment__mdt currentMA : municipalityAssignmentMetadata)
        {
            if(currentMA.PostalCode__c == Integer.valueOf(postalCode) && String.isNotBlank(currentMA.AssignTo__c))
            {
                return getIntermediaryUserId(currentMA.AssignTo__c);
            }
        }

        return defaultUserId;
    }

    /**
     * PostalCode deben ser 5 caracteres
     */
    private static String assignedUserByProvince(String postalCode)
    {
        if(String.isBlank(postalCode))
        {
            return defaultUserId;
        }

        Integer postalProvince = Integer.valueOf(postalCode.substring(0, 2));

        for(ProvinceAssignment__mdt currentPA : provinceAssignmentMetadata)
        {
            if(currentPA.PostalCode__c == postalProvince && String.isNotBlank(currentPA.AssignTo__c))
            {
                return getIntermediaryUserId(currentPA.AssignTo__c);
            }
        }

        return defaultUserId;
    }

    private static String getAssigmentType(String origin)
    {
        if(String.isBlank(origin))
        {
            return DEFAULT_ASSIGNEMENT_TYPE;
        }

        for(ForumOriginAssignment__mdt currentFOA : formOriginAssignmentMetadata)
        {
            if(currentFOA.ForumOrigin__c == origin && String.isNotBlank(currentFOA.AssignmentType__c))
            {
                return currentFOA.AssignmentType__c;
            }
        }

        return DEFAULT_ASSIGNEMENT_TYPE;
    }

    private static Id getDefaultZRMAccountLeadOwnerId()
    {
        NTSUser__mdt defaultUserDescription;

        switch on SystemUtil.getSandboxName()
        {
            when null // Producción
            {
                defaultUserDescription = NTSUser__mdt.getinstance('EntornoPro');
            }
            when 'qa'
            {
                defaultUserDescription = NTSUser__mdt.getinstance('EntornoQA');
            }
            when 'staging'
            {
                defaultUserDescription = NTSUser__mdt.getinstance('EntornoStaging');
            }
            when else // Resto de entornos
            {
                defaultUserDescription = NTSUser__mdt.getInstance('EntornoDev');
            }
        }

        if(defaultUserDescription != null && String.isNotBlank(defaultUserDescription.Username__c))
        {
            User defaultUser = [SELECT Id, isActive FROM User WHERE UserName = :defaultUserDescription.Username__c]; //TODO - Llevar a selector

            if(defaultUser != null && defaultUser.isActive)
            {
                return defaultUser.id;
            }
        }

        throw new QueryException('No default User found for Lead Account assignments.');
    }

    private static Id getIntermediaryUserId(String intermediaryCode)
    {
        if(String.isBlank(intermediaryCode))
        {
            return defaultUserId;
        }

        Account intermediaryAccount = [SELECT Id FROM Account WHERE INFOIntermediaryCode__c = :intermediaryCode];

        if(intermediaryAccount == null)
        {
            return defaultUserId;
        }

        User intermediary = [SELECT Id FROM User WHERE Contact.AccountId = : intermediaryAccount.Id];

        if(intermediary != null)
        {
            return intermediary.Id;
        }

        return defaultUserId;
    }
}