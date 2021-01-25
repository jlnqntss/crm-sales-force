/**
 *
 * @author nbizkarra
 * @date 23/04/2020
 */
public class CaseUtil
{
    /**
     * Método que inserta o actualiza un siniestro
     * @author nbizkarra
     * @date 23/04/2020
     **/
    public static void upsertClaim(Case claim)
    {
        System.debug('- - - - - ExternalRequestUtil.upsertClaim - - - - -');
        Case claimSF = ExternalRequestUtil.mapClaims.get(claim.ClaimNumber__c);

        if ( claimSF != null ) //claim exists
        {
            claim.Id = claimSF.Id;
            ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
        }
        else //claim doesn't exist
        {
            System.Debug('***** PolicyNum: ' + claim.PolicyNum__c);
            Order policySF = ExternalRequestUtil.mapPolicies.get(claim.PolicyNum__c);
            if ( policySF != null ) //policy exists
            {
                claim.RecordTypeId = SystemUtil.getClaimRecordType();
                claim.LegalEntity__c = policySF.LegalEntity__c;
                claim.OwnerId = ExternalRequestUtil.recordOwner.id;
                claim.Policy__c = policySF.id;
                // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                // we get this from the policy too
                claim.CustomerNum__c = policySF.CustomerNum__c;
                // nts (agonzalezisasi) - 18/dic/2020 - fix: when claim is IBA Spain add LegalEntity to the search if needed
                if( !ExternalRequestUtil.isIBAMultiPartner && !ExternalRequestUtil.isEMEA )
                {
                    if( !claim.CustomerNum__c.contains('GI') && !claim.CustomerNum__c.contains('LIFE') )
                    {
                        claim.CustomerNum__c = ContactUtil.adaptCustomerNum(claim.CustomerNum__c, policySF.LegalEntity__c);
                    }
                }
                // if (claim.sourceCountry__c != 'Spain') {
                //   claim.CustomerNum__c = 'EMEA-' + claim.CustomerNum__c;
                // }

                if (claim.InsuredObjectId__c != null)
                {
                    OrderItem orderItemSF = ExternalRequestUtil.mapOrderItem.get( claim.InsuredObjectId__c );
                    if (orderItemSF != null)
                    {
                        claim.Product__c = orderItemSF.id;
                    }
                }

                System.Debug('***** CustomerNum: ' + claim.CustomerNum__c);
                Contact contactSF = ExternalRequestUtil.mapContacts.get( claim.CustomerNum__c );
                if ( contactSF != null ) //contact exists
                {
                    claim.ContactId = contactSF.Id;
                    ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
                }
                else
                {
                    System.debug('Error: Cliente no existe');
                    throw new IntegrationException(
                              Label.ClaimError + ' ' + claim.ClaimNumber__c + '. ' + Label.CustomerError + ' ' + claim.CustomerNum__c
                              );
                }
            }
            else // policy doesnt exist
            {
                System.debug('Error: Póliza no existe');
                throw new IntegrationException(
                          Label.ClaimError + ' ' + claim.ClaimNumber__c + '. ' + Label.PolicyNotExisting + ' ' + claim.PolicyNum__c
                          );
            }
        }
    }

    /**
     * Método que setea en el contacto el número total de siniestros
     * @author nbizkarra
     * @date 23/04/2020
     **/
    public static void SummaryTotalClaims(List<Case> newList)
    {
        Set<Id> idSet = new Set<Id>();

        if (newList != null)
        {
            for (Case claim : newList)
            {
                if (!String.isBlank(claim.ClaimNumber__c) && claim.ContactId != null)
                {
                    idSet.add(claim.ContactId);
                }
            }

            if ( !idSet.isEmpty() )
            {
                String whereClause = 'ClaimNumber__c!=NULL';
                // Define the context for the RollupSummariesUtil.summarize() method
                RollupSummariesUtil.Context cont = new RollupSummariesUtil.Context(
                    Contact.SobjectType,
                    Case.SobjectType,
                    Schema.SObjectType.Case.fields.ContactId,
                    whereClause
                    );

                // RollupSummaryField for the NumClaims__c field
                cont.add(
                    new RollupSummariesUtil.RollupSummaryField(
                        Schema.SObjectType.Contact.fields.NumClaims__c,
                        Schema.SObjectType.Case.fields.Id,
                        RollupSummariesUtil.summaryOperation.Count
                        )
                    );

                // Call summarize method with context and parent records
                Sobject[] responseObject = RollupSummariesUtil.summarize(cont, idSet);

                responseObject = (Contact[]) responseObject;

                if ( responseObject != null && !responseObject.isEmpty() )
                {
                    update responseObject;
                }
            }
        }
    }

    public static final Map<String, String> mapCountryTranslationField = new Map<String, String> {
        'France' => 'French__c',
        'Germany' => 'German__c'
    };

    /**
     * Método que asocia el contacto o la póliza en los casos creados por email-to-case y web-to-case
     * y setea la traduccion del tipo y subtipo del caso dependiendo del pais
     * @author nbizkarra
     * @date 1/09/2020
     **/
    public static void assignContactToCase(List<Case> newList)
    {
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        Map<String, Order> mapPolicies = new Map<String, Order>();
        SET<String> keys = new Set<String>();

        if (newList != null)
        {
            // nts (agonzalezisasi) - 11/ene/2020 - fix Multipartner
            // Get the configuration
            AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
            // Get the Country that is not EMEA (Spain)
            String IBA_EMEA_NON_COUNTRY = adminSetup.IBA_EMEA_Non_Country__c;
            // Get the EMEA prefix
            String IBA_EMEA = adminSetup.IBA_EMEA_Prefix__c;
            // Get the Multi-Partner prefixes if any
            Map<String, String> mapMultiPartner = new Map<String, String>();
            for(String pair: adminSetup.Multi_Partners__c.split(';') )
            {
                List<String> values = pair.split(':');
                if( values.size() == 2 )
                {
                    mapMultiPartner.put(values.get(0), values.get(1) );
                }
            }

            for (Case caso : newList)
            {
                if ( !String.isBlank(caso.Origin) && ( caso.Origin.equals('Web') || caso.Origin.equals('Email') ) )
                {
                    //Si se ha informado el número de póliza, buscar la póliza y asignar el cliente correspondiente
                    if (caso.PolicyNum__c != null)
                    {
                        // nts (agonzalezisasi) - 11/ene/2020 - fix Multipartner
                        if( caso.Partner__c != null )   // Is a multipartner
                        {
                            if( mapMultiPartner.containsKey(caso.Partner__c) )
                            {
                                String partnerName = mapMultiPartner.get(caso.Partner__c);
                                caso.PolicyNum__c = partnerName + '-' + caso.PolicyNum__c;
                            }
                        }
                        else     // Is not multipartner
                        {   // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                            if (caso.sourceCountry__c != IBA_EMEA_NON_COUNTRY)   // Is not Spain => EMEA (france, germany)
                            {
                                caso.PolicyNum__c = IBA_EMEA + '-' + caso.PolicyNum__c;
                            }
                        }

                        List<Order> policies = new List<Order>();
                        policies = [
                            SELECT ID, ContactId__c, LegalEntity__c
                            FROM Order
                            WHERE (RecordType.DeveloperName = :Label.PolicyGI OR RecordType.DeveloperName = :Label.PolicyLife)
                            AND PolicyNum__c = :caso.PolicyNum__c
                        ];

                        if (policies != null && policies.size() > 0)
                        {
                            caso.ContactId = policies[0].ContactId__c;
                            caso.Policy__c = policies[0].Id;
                            caso.LegalEntity__c = policies[0].LegalEntity__c;
                        }
                    }
                    else
                    {
                        //Si no se ha informado el número de poliza asignar cliente por mail y entidad legal (Solo si hay 1 cliente con ese mail)
                        List<Contact> contactoSF = [
                            SELECT id FROM Contact
                            WHERE Email = :caso.SuppliedEmail AND LegalEntity__c = :caso.LegalEntity__c
                        ];

                        if (contactoSF != null && contactoSF.size() == 1)
                        {
                            caso.ContactId = contactoSF.get(0).id;
                        }
                    }

                    //Si el caso es de la web de francia, asignar traducción del tipo y subtipo para la respuesta automática
                    if ( caso.Origin.equals('Web') && !String.isBlank(caso.SourceCountry__c) )
                    {
                        if ( mapCountryTranslationField.containsKey(caso.SourceCountry__c) )
                        {
                            String fieldName = mapCountryTranslationField.get(caso.SourceCountry__c);
                            String queryType = 'SELECT ' + fieldName + ' FROM Label_Translations__mdt WHERE label = \'' + caso.Type + '\'';
                            String querySubtype = 'SELECT ' + fieldName + ' FROM Label_Translations__mdt WHERE label = \'' + caso.Subtype__c + '\'';

                            List<Label_Translations__mdt> TypeTranslaton = Database.query(queryType);
                            List<Label_Translations__mdt> SubTypeTranslation = Database.query(querySubtype);

                            if ( TypeTranslaton != null && !TypeTranslaton.isEmpty() )
                            {
                                caso.Type_translation__c = (String) TypeTranslaton[0].get(fieldName);
                            }

                            if ( SubTypeTranslation != null && !SubTypeTranslation.isEmpty() )
                            {
                                caso.Subtype_translation__c = (String) SubTypeTranslation[0].get(fieldName);
                            }
                        }
                    }
                }
            }
        }
    }


    /**
     * Método que asocia el ContactId y el AccountId del caso dependiendo del SuppliedEmail
     * Esto solamente funcionará para los Email-To-Case
     * Se hace uso del AccountSearchService dado que se necesita usar SOSL en los
     * ContactPointEmail ya que hacen querys no selectivas por campos no indexados
     * @date 25/01/2021
     **/
    public static void assignAccountAndContactFromSuppliedEmail(List<Case> newList)
    {
        //No se ejecuta bulkificado, sino solo en aquellas ocasiones que entra un Email-To-Case (no es bulk)
        if(newList.size() == 1)
        {
            for(Case caso : newList)
            {
                //Solo se hace algo si llegó relleno el campo del Email-To-Case
                if(!String.isBlank(caso.SuppliedEmail))
                {
                    //Utilizar el email del SuppliedEmail
                    List<String> emailsToSearch = new List<String>();
                    emailsToSearch.add(caso.SuppliedEmail);

                    //Utilizar el scope del caso
                    AccountSearchService.Scope scope = new AccountSearchService.Scope();
                    scope.scope = null; //FIXME: Cambiar esto por caso.Scope__c cuando se haya refactorizado AccountSearchService y la picklist de caso coincida en valores

                    //Utilizar el AccountSearchService
                    List<Account> matchedAccounts = new List<Account>();
                    matchedAccounts = AccountSearchService.findCustomersByEmail(emailsToSearch, scope);

                    //Solo se continua si se ha encontrado un único cliente; si hay más de uno no se sabría por cuál decidir
                    if(matchedAccounts.size() == 1)
                    {
                        //Se asigna al caso la cuenta y el contacto
                        caso.AccountId = matchedAccounts[0].Id;
                        caso.ContactId = matchedAccounts[0].PersonContactId;
                    }
                }
            }
        }
    }

}
