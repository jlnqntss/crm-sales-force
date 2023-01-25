/**
 *
 * @author nbizkarra
 * @date 23/04/2020
 */

public with sharing class CaseUtil
{
    /**
     * Método que inserta o actualiza un siniestro
     * @author nbizkarra
     * @date 23/04/2020
     **/
    public static void upsertClaim(Case claim)
    {
        
        Case claimSF = ExternalRequestUtil.mapClaims.get(claim.ClaimNumber__c);

        if ( claimSF != null ) //claim exists
        {
            claim.Id = claimSF.Id;
            ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
        }
        else //claim doesn't exist
        {
            
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
                if( !ExternalRequestUtil.isIBAMultiPartner && !ExternalRequestUtil.isEMEA &&(!claim.CustomerNum__c.contains('GI') && !claim.CustomerNum__c.contains('LIFE')))
                {
                    claim.CustomerNum__c = ContactUtil.adaptCustomerNum(claim.CustomerNum__c, policySF.LegalEntity__c);                    
                }

                if (claim.InsuredObjectId__c != null)
                {
                    OrderItem orderItemSF = ExternalRequestUtil.mapOrderItem.get( claim.InsuredObjectId__c );
                    if (orderItemSF != null)
                    {
                        claim.Product__c = orderItemSF.id;
                    }
                }

                
                Contact contactSF = ExternalRequestUtil.mapContacts.get( claim.CustomerNum__c );
                if ( contactSF != null ) //contact exists
                {
                    claim.ContactId = contactSF.Id;
                    ExternalRequestUtil.claimsToUpsert.put(claim.ClaimNumber__c, claim);
                }
                else
                {
                    
                    throw new IntegrationException(
                              Label.ClaimError + ' ' + claim.ClaimNumber__c + '. ' + Label.CustomerError + ' ' + claim.CustomerNum__c
                              );
                }
            }
            else // policy doesnt exist
            {
                
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
    public static void summaryTotalClaims(List<Case> newList)
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
     * Método que asocia el contacto o la póliza en los casos creados por web-to-case
     * y setea la traduccion del tipo y subtipo del caso dependiendo del pais
     * @author nbizkarra
     * @date 1/09/2020
     **/
    public static void assignContactToCase(List<Case> newList)
    {
        if (newList != null)
        {
            // nts (agonzalezisasi) - 11/ene/2020 - fix Multipartner
            // Get the configuration
            AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
            // Get the Country that is not EMEA (Spain)
            String iba_emea_non_country = adminSetup.IBA_EMEA_Non_Country__c;
            // Get the EMEA prefix
            String iba_emea = adminSetup.IBA_EMEA_Prefix__c;
            // Get the Multi-Partner prefixes if any
            Map<String, String> mapMultiPartner = new Map<String, String>();
            for( String pair: adminSetup.Multi_Partners__c.split(';') )
            {
                List<String> values = pair.split(':');
                if( values.size() == 2 )
                {
                    mapMultiPartner.put( values.get(0), values.get(1) );
                }
            }

            for (Case caso : newList)
            {   // Solo para casos de web, email to case no tiene rellenos los campos entidad legal y país hasta el afterinsert ( relleno por Workflows)
                // se podría filtrar por tipo de registro si se añade el campo al formulario
                if ( !String.isBlank(caso.Origin) &&  caso.Origin.equals('Web') )
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
                            if (caso.sourceCountry__c != iba_emea_non_country)   // Is not Spain => EMEA (france, germany)
                            {
                                caso.PolicyNum__c = iba_emea + '-' + caso.PolicyNum__c;
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
                            caso.CustomerFoundBy__c = 'Policy Number';
                        }
                    }
                    // nts (nbizkarra) - 25/Ene/2021 - Buscar por email, entidad legal, pais cuando Poliza nula o no encontrada
                    if ( String.isNotBlank(caso.SuppliedEmail) &&  String.isNotBlank(caso.LegalEntity__c)  &&  String.isNotBlank(caso.SourceCountry__c)
                         && caso.Policy__c == null)
                    {
                        //Si no se ha informado el número de poliza asignar cliente por mail y entidad legal (Solo si hay 1 cliente con ese mail)
                        List<Contact> contactoSF = [
                            SELECT id FROM Contact
                            WHERE Email = :caso.SuppliedEmail AND LegalEntity__c = :caso.LegalEntity__c
                                                                                   AND SourceCountry__c =: caso.SourceCountry__c AND Partner__c =: caso.Partner__c
                                                                                                                                                  AND (RecordType.DeveloperName =: Label.CustomerGI OR RecordType.DeveloperName =: Label.CustomerLife
                                                                                                                                                                                                                                  OR RecordType.DeveloperName =: Label.LeadGI OR RecordType.DeveloperName =: Label.LeadLife)
                        ];

                        if (contactoSF != null && contactoSF.size() == 1)
                        {
                            caso.ContactId = contactoSF.get(0).id;
                            caso.CustomerFoundBy__c = 'Email';
                        }
                    }

                    // nts (nbizkarra) - 25/Ene/2021 - Buscar cliente por teléfono si no se ha encontrado por póliza o email (solo si encuentra 1)
                    if ( String.isNotBlank(caso.SuppliedPhone) &&  String.isNotBlank(caso.LegalEntity__c)  &&  String.isNotBlank(caso.SourceCountry__c)
                         && caso.Policy__c == null && caso.ContactId == null)
                    {
                        List<Contact> contactoSF = [
                            SELECT id FROM Contact
                            WHERE MobilePhone = :caso.SuppliedPhone AND LegalEntity__c = :caso.LegalEntity__c
                                                                                         AND SourceCountry__c =: caso.SourceCountry__c AND Partner__c =: caso.Partner__c
                                                                                                                                                        AND (RecordType.DeveloperName =: Label.CustomerGI OR RecordType.DeveloperName =: Label.CustomerLife
                                                                                                                                                                                                                                        OR RecordType.DeveloperName =: Label.LeadGI OR RecordType.DeveloperName =: Label.LeadLife)
                        ];

                        if (contactoSF != null && contactoSF.size() == 1)
                        {
                            caso.ContactId = contactoSF.get(0).id;
                            caso.CustomerFoundBy__c = 'Phone';
                        }
                    }

                    //Si el caso es de la web de francia, asignar traducción del tipo y subtipo para la respuesta automática
                    if ( caso.Origin.equals('Web') && !String.isBlank(caso.SourceCountry__c) &&(mapCountryTranslationField.containsKey(caso.SourceCountry__c)) )
                    {
                        String fieldName = mapCountryTranslationField.get(caso.SourceCountry__c);
                        String queryType = 'SELECT ' + fieldName + ' FROM Label_Translations__mdt WHERE label = \'' + caso.Type + '\'';
                        String querySubtype = 'SELECT ' + fieldName + ' FROM Label_Translations__mdt WHERE label = \'' + caso.Subtype__c + '\'';

                        List<Label_Translations__mdt> typeTranslaton = Database.query(queryType);
                        List<Label_Translations__mdt> subTypeTranslation = Database.query(querySubtype);

                        if ( typeTranslaton != null && !typeTranslaton.isEmpty() )
                        {
                            caso.Type_translation__c = (String) typeTranslaton[0].get(fieldName);
                        }

                        if ( subTypeTranslation != null && !subTypeTranslation.isEmpty() )
                        {
                            caso.Subtype_translation__c = (String) subTypeTranslation[0].get(fieldName);
                        }
                    }
                }
            }
        }
    }

    /**
     * Método que asocia el contacto en los casos creados por email-to-case de Klinc
     * Ejecutado en afterInsert porque hasta entonces no se dispone de la entidad legal, pais y partner
     * @author nbizkarra
     * @date 26/01/2021
     **/
    public static void assignContactToCaseEmail(List<Case> newList)
    {
        List<Case> updateCases = new List<Case>();

        if (newList != null)
        {
            for (Case caso : newList)
            {
                if ( !checkRecursive.SetOfIDs.contains(caso.ID) )
                {
                    checkRecursive.SetOfIDs.add(caso.ID);
                    


                    

                    if ( !String.isBlank(caso.Origin) &&  caso.Origin.equals('Email') && String.isBlank(caso.CustomerFoundBy__c) &&
                         String.isNotBlank(caso.SuppliedEmail) &&  String.isNotBlank(caso.LegalEntity__c)  &&  String.isNotBlank(caso.SourceCountry__c)
                         && caso.RecordTypeId ==  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry').getRecordTypeId() )
                    {
                        List<Contact> contactoSF = [
                            SELECT id FROM Contact
                            WHERE Email = :caso.SuppliedEmail AND LegalEntity__c = :caso.LegalEntity__c
                                                                                   AND SourceCountry__c =: caso.SourceCountry__c AND Partner__c =: caso.Partner__c
                                                                                                                                                  AND (RecordType.DeveloperName =: Label.CustomerGI OR RecordType.DeveloperName =: Label.CustomerLife
                                                                                                                                                                                                                                  OR RecordType.DeveloperName =: Label.LeadGI OR RecordType.DeveloperName =: Label.LeadLife)
                        ];
                        //Asignar contacto solo si encuentra 1
                        if (contactoSF != null && contactoSF.size() == 1)
                        {
                            Case caseToUpdate = new Case();
                            caseToUpdate.id = caso.id;
                            caseToUpdate.ContactId = contactoSF.get(0).id;
                            caseToUpdate.CustomerFoundBy__c = 'Email';
                            updateCases.add(caseToUpdate);
                        }
                    }

                }
            }

            if ( updateCases != null && !updateCases.isEmpty() )
            {
                upsert updateCases;
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
                //Esta comparación se hace para que no afecte a KLINC
                if( caso.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId() && !String.isBlank(caso.SuppliedEmail))
                {
                    //Solo se hace algo si llegó relleno el campo del Email-To-Case
                    //Utilizar el email del SuppliedEmail
                    List<String> emailsToSearch = new List<String>();
                    emailsToSearch.add(caso.SuppliedEmail);

                    //Utilizar el scope del caso
                    //AccountSearchService.Scope scope = new AccountSearchService.Scope();
                    
                    //Utilizar el AccountSearchService
                    List<Account> matchedAccounts = new List<Account>();
                    matchedAccounts = AccountSearchService.findCustomersByEmail(emailsToSearch, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);

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

    /**BEFOREUPDATE
     * IMPORTANTE: la modificación del CaseMilestone no puede ser después de la actualización del caso
     * porque el caso ya se ha salido del entitlement process y salta el siguiente error:
     * "You can’t change the completion date on a milestone that’s already exited an entitlement process.: Completion Date"
     * Por eso tiene que ser modificado en el before
     * @date 25/01/2021
     **/
    public static void markMilestonesCompletedWhenClose(List<Case> newList, Map<Id,Case> oldMap)
    {
        List<Case> updatedCases = new List<Case>();
        List<CaseMilestone> caseMilestoneList = new List<CaseMilestone>();
        List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
        Case oldCase = new Case();
        Id rtOCSInquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();

        //Almacenar los casos que cumplen las condiciones
        for(Case caso : newList)
        {
            //Esta comparación se hace para que no afecte a KLINC
            if(caso.RecordTypeId == rtOCSInquiryId)
            {
                oldCase =  oldMap.get(caso.Id);
                //Solo se hace algo si se cerró el caso
                if(oldCase.Status != caso.Status && (caso.Status == 'Cerrado' || caso.Status == 'Merged' || caso.Status == 'Combinado') && caso.SlaExitDate == null)
                {
                    updatedCases.add(caso);
                }
            }
        }

        //Si hay casos a los que hay que completarles el Milestone:
        if( !updatedCases.isEmpty() )
        {
            //Recoger los milestones del tipo requerido
            caseMilestoneList = [SELECT Id, CaseId, CompletionDate FROM CaseMilestone WHERE CaseId IN :updatedCases AND MilestoneType.Name = 'Cierre Caso'];

            if( !caseMilestoneList.isEmpty() )
            {
                for(CaseMilestone cm : caseMilestoneList)
                {
                    //Evitar actualizar un milestone ya completado
                    if (cm.CompletionDate == null)
                    {
                        cm.CompletionDate = System.now(); //Marcarlo como completado
                        caseMilestoneListToUpdate.add(cm);
                    }
                }
                //Updatear ANTES el milestone que el caso para evitar el error de salida del EntitlementProcess
                if( !caseMilestoneListToUpdate.isEmpty() )
                {
                    //Evitar ids duplicados en la lista a actualziar
                    Map<Id, CaseMilestone> caseMilestoneDuplicates = new Map<Id, CaseMilestone>();
                    caseMilestoneDuplicates.putAll(caseMilestoneListToUpdate);
                    update caseMilestoneDuplicates.values();
                }
            }
        }
    }

     /**
     * Similar a markMilestonesCompletedWhenClose pero cuando los casos son usp. 
     * Completa milestones al poner un caso a cerrado o pendiente
     * @author jjuaristi@seidor.es
     * @date 24/10/2022
     * @param 
     * @return 
     */
    public static void completeUSPMilestonesWhenClosedOrPending(List<Case> newList, Map<Id,Case> oldMap)
    {
        Case oldCase = new Case();
        List<Case> updatedCases = new List<Case>();

        // Generar lista solo de USP
        List<Case> uspCases = generateUspCaseList(newList);

        for(Case caso : uspCases)
        {
            oldCase =  oldMap.get(caso.Id);
            //Solo se hace algo la actualización es a cerrado o pendiente de client/Intermediary
            if(oldCase.Status != caso.Status &&
                (
                    caso.Status == 'Cerrado' || caso.Status == 'Merged' || caso.Status == 'Combinado'
                    || 
                    caso.Status == 'Pendiente' && 
                    (
                        caso.PendingBy__c == 'Client' || caso.PendingBy__c == 'Intermediary'
                    ) 
                )
            )
            {
                updatedCases.add(caso);
            }
            completeCaseMilestones(updatedCases, 'Respuesta Interacción');
        }
    }

    private static void completeCaseMilestones(List<Case> updatedCases, string milestoneName)
    {
        List<CaseMilestone> caseMilestoneList = new List<CaseMilestone>();
        List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
        // Lanzar query para recuperar los milestones
        caseMilestoneList = [SELECT Id, CaseId, CompletionDate FROM CaseMilestone WHERE CaseId IN :updatedCases AND MilestoneType.Name =:milestoneName];
        if( !caseMilestoneList.isEmpty() )
        {
            for(CaseMilestone cm : caseMilestoneList)
            {
                //Evitar actualizar un milestone ya completado
                if (cm.CompletionDate == null)
                {
                    cm.CompletionDate = System.now(); //Marcarlo como completado
                    caseMilestoneListToUpdate.add(cm);
                }
            }
            //Updatear ANTES el milestone que el caso para evitar el error de salida del EntitlementProcess
            if( !caseMilestoneListToUpdate.isEmpty() )
            {
                //Evitar ids duplicados en la lista a actualziar
                Map<Id, CaseMilestone> caseMilestoneDuplicates = new Map<Id, CaseMilestone>();
                caseMilestoneDuplicates.putAll(caseMilestoneListToUpdate);
                update caseMilestoneDuplicates.values();
            }
        }

    }

    /**
     * Método que a partir de una lista de casos devuelve la lista de casos con RecordType USPInquiry
     * @author jjuaristi@seidor.es
     * @date 24/10/2022
     * @param Lista de casos
     * @return Lista de casos USP
     */
    private static List<Case> generateUspCaseList(List<Case> cases)
    {
        Id rtUSPId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        List<Case> uspCases = new List<Case>();

        for(Case currentCase : cases)
        {
            if(currentCase.RecordTypeId == rtUSPId)
            {
                uspCases.add(currentCase);
            }
        }
        return uspCases;
    }
    
    /**
     * Método utilizado por RelateCasesToNewAccountsBatch para relacionar casos con cuentas
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     * @param [List<Case> casesToRelate] casos que ha recuperado el batch, [String daysToRetrieve] días desde la creación
     * @return List<Case> casos a actualizar
     */
    public static List<Case> relateCasesToNewAccounts (List<Case> casesToRelate, String daysToRetrieve)
    {
        // Lista para almacenar solo los registros que hay que actualizar
        List<Case> casesToUpdate = new List<Case>();

        // La lógica solo se recorre si la lista no es nula, para evitar excepciones
        if(casesToRelate != null && !casesToRelate.isEmpty())
        {
            // Se obtiene la lista de cifs
            List<String> cifs = generateCifList(casesToRelate);
            
            // Query a Account para recuperar los clientes creados en las últimas 24 horas
            // y con cif contenido por los casos recogidos en el batch
            List<Account> accountsToRelate = new AccountsSelector().findByCIFAndCreationDate(cifs, daysToRetrieve);

            // Si no hay cuentas no recorremos la lista para evitar excepciones
            if(accountsToRelate != null && !accountsToRelate.isEmpty())
            {
                //Mapa para identificar cada cuenta con su cif
                Map<String, Account> mapAccountsToRelateByCIF = AccountUtil.generateMapByCif(accountsToRelate);

                // Se recorre la lista de casos a relacionar
                for(Case currentCase : casesToRelate)
                {
                    // Si alguna cuenta tiene el mismo cif que el caso, se tienen que relacionar
                    if(mapAccountsToRelateByCIF.get(currentCase.RobotDocumentId__c)!=null)
                    {
                        // Se hace la relación
                        currentCase.MediatedCustomer__c = mapAccountsToRelateByCIF.get(currentCase.RobotDocumentId__c).Id;
                        // Se añade el caso a la lista de casos a actualizar
                        casesToUpdate.add(currentCase);
                    }
                }
            }
        }
        return casesToUpdate;
    }

    /**
     * Método que devuelve una lista con los cifs de los casos que recibe por parámetro
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     * @param Lista de casos
     * @return Lista de cifs
     */
    private static List<String> generateCifList(List<Case> cases)
    {
        List<String> cifs = new List<String>();
        if(cases != null && !cases.isEmpty())
        {
            // Se recorre la lista de casos para generar la lista de CIFs 
            for(Case currentCase : cases)
            {
                cifs.add(currentCase.RobotDocumentId__c);
            }
        }
        return cifs;
    }

    /**
     * Método que crea un caso a partir de un caso padre ya existente y un email entrante
     * @author arcortazar
     * @date 18/11/2022
     * @param {Case padre} caso que se va a copiar
     * @param {EmailMessage email} email del que vamos a obtener el subject y la descripción
     * @param {Boolean setTypification} indica si vamos a mantener la tipificación del caso padre (true) o no (false)
     * @return Case 
     */
    public static Case createCaseFromParent(Case padre, EmailMessage email, Boolean setTypification)
    {
        Case casoHijo = new Case(
                        Status='Asignado',
                        CallCenter__c = padre?.CallCenter__c,
                        Origin = padre?.Origin,
                        SourceArea__c = padre?.SourceArea__c,
                        ParentId=padre?.Id,
                        AccountId=padre?.AccountId,
                        RecordTypeId=padre?.RecordTypeId, 
                        PolicyId__c = padre?.PolicyId__c,
                        OfferId__c = padre?.OfferId__c,
                        ClaimId__c = padre?.ClaimId__c,
                        MediatedCustomer__c = padre?.MediatedCustomer__c
                    );

        // Comprobamos si el cuerpo y el asunto del mensaje son demasiado largos.. Si es así, los acortamos.
        casoHijo.Subject = email?.Subject.length() > 255 ? email?.Subject.substring(0, 254) : email?.Subject;
        casoHijo.Description = email?.TextBody.length() > 32000 ? email?.TextBody.substring(0, 29999) : email?.TextBody;

        if (setTypification)
        {
            casoHijo.Type = padre?.Type;
            casoHijo.Subtype__c = padre?.Subtype__c;
            casoHijo.TypeN3__c = padre?.TypeN3__c;
        }
        return casoHijo;
    }

     /**
     * Método utilizado por RelateCasesToNewOffersBatch para relacionar casos con ofertas
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     * @param [List<Case> [casesToRelate] casos que ha recuperado el batch, [String daysToRetrieve] días desde la creación
     * @return List<Case> casos a actualizar
     */
    public static List<Case> relateCasesToNewOffers (List<Case> casesToRelate, String daysToRetrieve)
    {
        // Lista para almacenar solo los registros que hay que actualizar
        List<Case> casesToUpdate = new List<Case>();

        // La lógica solo se recorre si la lista no es nula, para evitar excepciones
        if(casesToRelate != null && !casesToRelate.isEmpty())
        {
            // Se obtiene la lista de ofertas generadas
            List<String> ofertasGeneradas = generateCreateOfferList(casesToRelate);
            
            // Query a Opportunity para recuperar las ofertas creados en las últimas 24 horas
            // y con oferta generada contenido por los casos recogidos en el batch
            List<Opportunity> offersToRelate = new OpportunitiesSelector().findByCreatedOfferAndCreationDate(ofertasGeneradas, daysToRetrieve);

            // Si no hay ofertas no recorremos la lista para evitar excepciones
            if(offersToRelate != null && !offersToRelate.isEmpty())
            {
                //Mapa para identificar cada oferta con su oferta generada
                Map<String, Opportunity> mapOffersToRelateByCreatedOffer = OpportunityUtil.generateMapByCreatedOffer(offersToRelate);

                // Se recorre la lista de casos a relacionar
                for(Case currentCase : casesToRelate)
                {
                    // Si alguna oferta tiene la misma oferta generada que el caso, se tienen que relacionar
                    if(mapOffersToRelateByCreatedOffer.get(currentCase.CreatedOffer__c)!=null)
                    {
                        // Se hace la relación  
                        currentCase.OfferId__c = mapOffersToRelateByCreatedOffer.get(currentCase.CreatedOffer__c).Id;
                        // Se añade el caso a la lista de casos a actualizar
                        casesToUpdate.add(currentCase);
                    }
                }
            }
        }
        return casesToUpdate;
    }

    /**
     * Método que devuelve una lista con el campo oferta generada de los casos que recibe por parámetro
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     * @param Lista de casos
     * @return Lista de ofertas generadas
     */
    private static List<String> generateCreateOfferList(List<Case> cases)
    {
        List<String> createOffers = new List<String>();
        if(cases != null && !cases.isEmpty())
        {
            // Se recorre la lista de casos para generar la lista de ofertas generadas 
            for(Case currentCase : cases)
            {
                createOffers.add(currentCase.CreatedOffer__c);
            }
        }
        return createOffers;
    }
    /**
     * Método que devuelve una lista de cuentas para el calculo de conversion ratio 
     * @author lrodriguez6@seidor.es
     * @date 25/01/2023
     * @param Lista de casos
     * @return Lista de cuentas
     */

    public static List<Account> generateAccountRatio(List<Case> cases)
    {
        Map <Id, Decimal> mapAllIntermediaryCases= new Map <Id,Decimal>();
        Map <Id, Decimal> mapWonIntermediaryCases= new Map <Id,Decimal>();
        
        List<Account> allIntermediary= new List<Account>();


        for(Case currentCase:cases)
            {   
                if(mapAllIntermediaryCases.get(currentCase.AccountId)==null && mapWonIntermediaryCases.get(currentCase.Id)==null)
                {
                    mapAllIntermediaryCases.put(currentCase.AccountId,0);
                    mapWonIntermediaryCases.put(currentCase.AccountId,0);

                }
                
                mapAllIntermediaryCases.put(currentCase.AccountId,(mapAllIntermediaryCases.get(currentCase.AccountId)+1));
                        
                if(currentCase.QuotationStage__c=='Won')
                {       
                    mapWonIntermediaryCases.put(currentCase.AccountId,(mapWonIntermediaryCases.get(currentCase.AccountId)+1));
                }
            }


                for(Id idCuenta: mapAllIntermediaryCases.keySet())
                {
                    Account acc=new Account();
                    acc.Id=idCuenta;
                    acc.USPConversionRatio__c=(mapWonIntermediaryCases.get(acc.Id)/mapAllIntermediaryCases.get(acc.Id)); 
                    allIntermediary.add(acc);    
                }

    return allIntermediary;

    }
}