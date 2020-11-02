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
        System.debug('- - - - - ExternalRequestUtil.processClaim - - - - -');
        Case claimSF = ExternalRequestUtil.mapClaims.get(claim.ClaimNumber__c);

        if (
            claimSF != null //claim exists
            )
        {
            claim.Id = claimSF.Id;
            ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
        }
        else //claim doesn't exist
        {
            Order policySF = ExternalRequestUtil.mapPolicies.get(claim.PolicyNum__c);

            if (
                policySF != null //policy exists
                )
            {
                claim.RecordTypeId = SystemUtil.getClaimRecordType();
                claim.LegalEntity__c = policySF.LegalEntity__c;
                claim.OwnerId = ExternalRequestUtil.recordOwner.id;
                claim.Policy__c = policySF.id;
                claim.CustomerNum__c = ContactUtil.adaptCustomerNum(
                    claim.CustomerNum__c,
                    policySF.LegalEntity__c
                    );

                if (claim.sourceCountry__c != 'Spain')
                {
                    claim.CustomerNum__c = 'EMEA-' + claim.CustomerNum__c;
                }

                if (claim.InsuredObjectId__c != null)
                {
                    OrderItem orderItemSF = ExternalRequestUtil.mapOrderItem.get(
                        claim.InsuredObjectId__c
                        );
                    if (orderItemSF != null)
                    {
                        claim.Product__c = orderItemSF.id;
                    }
                }

                Contact contactSF = ExternalRequestUtil.mapContacts.get(
                    claim.CustomerNum__c
                    );

                if (
                    contactSF != null //contact exists
                    )
                {
                    claim.ContactId = contactSF.Id;
                    ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
                }
                else
                {
                    System.debug('Error: Cliente no existe');
                    throw new IntegrationException(
                              Label.ClaimError +
                              ' ' +
                              claim.ClaimNumber__c +
                              '. ' +
                              Label.CustomerError +
                              ' ' +
                              claim.CustomerNum__c
                              );
                }
            }
            else
            {
                System.debug('Error: Póliza no existe');
                throw new IntegrationException(
                          Label.ClaimError +
                          ' ' +
                          claim.ClaimNumber__c +
                          '. ' +
                          Label.PolicyNotExisting +
                          ' ' +
                          claim.PolicyNum__c
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

            if (!idSet.isEmpty() )
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

                if (responseObject != null && !responseObject.isEmpty() )
                {
                    update responseObject;
                }
            }
        }
    }

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
            for (Case caso : newList)
            {
                if (
                    !String.isBlank(caso.Origin) &&
                    (caso.Origin.equals('Web') || caso.Origin.equals('Email') )
                    )
                {
                    //Si se ha informado el número de póliza, buscar la póliza y asignar el cliente correspondiente
                    if (caso.PolicyNum__c != null)
                    {
                        if (caso.sourceCountry__c != 'Spain')
                        {
                            caso.PolicyNum__c = 'EMEA-' + caso.PolicyNum__c;
                        }

                        List<Order> policies = new List<Order>();
                        policies = [
                            SELECT ID, ContactId__c, LegalEntity__c
                            FROM Order
                            WHERE
                                (RecordType.DeveloperName = :Label.PolicyGI
                                                            OR RecordType.DeveloperName = :Label.PolicyLife)
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
                            SELECT id
                            FROM Contact
                            WHERE
                            Email = :caso.SuppliedEmail
                                    AND LegalEntity__c = :caso.LegalEntity__c
                        ];

                        if (contactoSF != null && contactoSF.size() == 1)
                        {
                            caso.ContactId = contactoSF.get(0).id;
                        }
                    }

                    //Si el caso es de la web de francia, asignar traducción del tipo y subtipo para la respuesta automática
                    if (
                        caso.Origin.equals('Web') && !String.isBlank(caso.SourceCountry__c)
                        )
                    {
                        if (caso.SourceCountry__c.equals('France') )
                        {
                            List<Label_Translations__mdt> TypeTranslaton = [
                                SELECT French__c
                                FROM Label_Translations__mdt
                                WHERE label = :caso.Type
                            ];
                            List<Label_Translations__mdt> SubTypeTranslation = [
                                SELECT French__c
                                FROM Label_Translations__mdt
                                WHERE label = :caso.Subtype__c
                            ];

                            if (TypeTranslaton != null)
                            {
                                caso.Type_translation__c = TypeTranslaton[0].French__c;
                            }

                            if (SubTypeTranslation != null)
                            {
                                caso.Subtype_translation__c = SubTypeTranslation[0].French__c;
                            }
                        }
                    }
                }
            }
        }
    }
}
