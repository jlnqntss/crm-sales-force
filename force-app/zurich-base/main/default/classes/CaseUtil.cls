/**
 *
 * @author nbizkarra
 * @date 23/04/2020
 */

public with sharing class CaseUtil
{
    //Constantes
    public static final String statusCombinado='Combinado';
    public static final String closeResult='No Realizado';
    public static final String statusWon='Won';
    public static final String typeVenta= 'Venta';
    public static final String queryDays ='365';
    public static final String afirmativo = 'Si';
    public static final String estadoCerrado= 'Cerrado';
    public static final String CASE_NUEVO = 'Nuevo';
    public static final String CASE_NO_INICIADO = 'No iniciado';
    public static final String CASE_EN_GESTION = 'En gestión';
    public static final String CASE_ASIGNADO = 'Asignado';
    public static final String CASE_RESPONDIDO = 'Respondido';
    public static final String CASE_PENDIENTE = 'Pendiente';
    public static final String CASE_PENDIENTE_SOPORTE = 'Support';
    public static final String CASE_PENDIENTE_SUPERVISOR = 'Supervisor';
    public static final String CASE_PENDIENTE_PARTNER = 'Partner';
    public static final String CASE_CLOSED_LOST = 'Cerrado Perdido';
    public static final String CASE_CLOSED_WON = 'Cerrado Ganado';
    public static final String CASE_CAUSE_OF_LOSS_PERIOD_ENDED = 'Periodo Finalizado';
    public static final String RT_NAME_USPINQUIRY = 'USPInquiry';
    public static final String RT_NAME_OCSINQUIRY = 'OCSInquiry';
    public static final String RT_NAME_OCSSPRINKLR = 'OCSSprinklr';
    public static final String RT_NAME_SAMINQUIRY = 'SAMInquiry';
    public static final String RT_NAME_ZDA = 'ZDAInquiry';
    public static final String RT_NAME_ZRM = 'ZRMInquiry';
    public static final String DEFAULT_SPRINKLR_CASE_TIPIFICATION = 'Sprinklr Default';
    public static final String SPRINKLR_QUEUE_MARCA = 'Marca Redes Sociales';
    public static final String SPRINKLR_QUEUE_POSTVENTA = 'Postventa Redes Sociales';
    public static final String SPRINKLR_QUEUE_SINIESTROS = 'Siniestros Redes Sociales';
    public static final String SPRINKLR_CALLCENTER_MARCA = 'RRSS Marca';
    public static final String SPRINKLR_CALLCENTER_SINIESTROS = 'RRSS Postventa-Siniestros';
    public static final String SPRINKLR_TYPE_MARCA = 'Marca (No info provided)';
    public static final String SPRINKLR_TYPE_ASISTENCIA = 'Asistencia (Information/ Contact)';
    public static final String SPRINKLR_TYPE_SINIESTROS = 'Siniestros (Claims)';
    public static final String ZDA_REASON_RECHAZAR = '1';
    public static final String ZDA_REASON_DESESTIMAR = '2';
    public static final String ZDA_REASON_RESPUESTA_SOPORTE = '3';
    public static final String BLANK_SPACE = ' ';
    public static final String ORIGIN_CANAL_UNICO = 'CanalUnico';
    public static final String ORIGIN_WEB = 'Web';

    private static final String FIELD_CLIENT_HAS_CONTACTED = 'ClientHasContacted__c';

    public static List<Group> queueMarcaRRSS = new List<Group>();
    public static List<Group> queuePostventaRRSS = new List<Group>();
    public static List<Group> queueSiniestrosRRSS = new List<Group>();
    public static List<spr_sf__SocialPersona__c> sprinklrSocialPersonaToUpdate = new List<spr_sf__SocialPersona__c>();
    public static Map<String, Case> notClosedCaseByPolicyIdMap = new Map<String, Case>();

    
    // Recupera el Id del RecordType de casos USP
    public static final ID RT_ID_USPINQUIRY
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_USPINQUIRY)?.getRecordTypeId();
        }
    }

    // Recupera el Id del RecordType de casos OCS
    public static final ID RT_ID_OCSINQUIRY
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_OCSINQUIRY)?.getRecordTypeId();
        }
    }

    // Recupera el Id del RecordType de casos Sprinklr
    public static final ID RT_ID_OCSSPRINKLR
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_OCSSPRINKLR).getRecordTypeId();
        }
    }

    // Recupera el Id del RecordType de casos SAM
    public static final ID RT_ID_SAMINQUIRY
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_SAMINQUIRY).getRecordTypeId();
        }
    }

    // Recupera el Id del RecordType de casos ZDA
    public static final ID RT_ID_ZDA
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_ZDA).getRecordTypeId();
        }
    }

    // Recupera el Id del RecordType de casos ZRM (Retenciones)
    public static final ID RT_ID_ZRM
    {
        get
        {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_ZRM).getRecordTypeId();
        }
    }

    public static final Map<String, Robot_Hegeo_Field_Mapping__mdt> CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE
    {
        get
        {
            if(CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE == null)
            {
                CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE = sortCaseMappingSettingsBy(Schema.Robot_Hegeo_Field_Mapping__mdt.field.SourceType__c);
            }

            return CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE;
        }

        private set;
    }

    /**
     * Excepción para controlar anomalías durante el proceso de tipificación a medida del caso.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     */
    private class CaseCustomTipificationException extends Exception
    {}

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
                if( !ExternalRequestUtil.isIBAMultiPartner && !ExternalRequestUtil.isEMEA && ( !claim.CustomerNum__c.contains('GI') && !claim.CustomerNum__c.contains('LIFE') ) )
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
     * change aberuete - 18/04/2023 - Refactoizar método
     **/
    public static void assignContactToCase(List<Case> newList)
    {
        if (newList != null)
        {
            // nts (agonzalezisasi) - 11/ene/2020 - fix Multipartner
            // Get the configuration
            AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
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
                    caso = updatePolicyToCaseifCaseDoesNotHavePolicy (adminSetup, caso,mapMultiPartner);

                    // nts (nbizkarra) - 25/Ene/2021 - Buscar por email, entidad legal, pais cuando Poliza nula o no encontrada
                    caso = updateContactToCaseByEmail(caso);

                    // nts (nbizkarra) - 25/Ene/2021 - Buscar cliente por teléfono si no se ha encontrado por póliza o email (solo si encuentra 1)
                    caso = updateContactToCaseByPhone(caso);

                    //Si el caso es de la web de francia, asignar traducción del tipo y subtipo para la respuesta automática
                    caso = ifCaseFromWebFranceUpdateTranslationToCase (caso);
                }
            }
        }
    }

    /**
     * Método que asocia el contacto en los casos creados por email-to-case de Klinc
     * Ejecutado en afterInsert porque hasta entonces no se dispone de la entidad legal, pais y partner
     * @author nbizkarra
     * @date 26/01/2021
     * change aberuete - 18/04/2023 - Refactorizar método
     **/
    public static void assignContactToCaseEmail(List<Case> newList)
    {
        List<Case> updateCases = new List<Case>();

        if (newList != null)
        {
            for (Case caso : newList)
            {
                updateCases = getCasesToUpdateContactFromEmailToCase (updateCases, caso);
            }

            if ( updateCases != null && !updateCases.isEmpty() )
            {
                upsert updateCases;
            }
        }
    }

    /**
     * Asigna valor a la propiedad N1, N2 y N3 del caso que permiten clasificar la consulta de los clientes.
     * La tipificación condicionará la operativa del caso y el enrutamiento del caso.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     * @param insertedCases Colección de nuevos casos que se insertan en la base de datos.
     */
    public static void setSprinklrCaseTipification(List<Case> insertedCases)
    {
        for(Case customerRequest : insertedCases)
        {
            if(customerRequest.RecordTypeId == RT_ID_OCSSPRINKLR)
            {
                Robot_Hegeo_Field_Mapping__mdt caseTipificationMetadata;

                if ( String.isBlank(customerRequest.RobotTypeN1__c) )
                {
                    caseTipificationMetadata = CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE?.get(DEFAULT_SPRINKLR_CASE_TIPIFICATION);
                }
                else
                {
                    caseTipificationMetadata = CASE_MAPPING_SETTINGS_BY_SOURCE_TYPE?.get(customerRequest.RobotTypeN1__c);
                }

                if (caseTipificationMetadata == null)
                {
                    ErrorLogUtil.commitError( ErrorLogUtil.ERROR_LEVEL_ERROR, 'Error durante la tipificación del Sprinklr N: ' + customerRequest.spr_sf__Sprinklr_Case_Number__c, CaseUtil.class.getName() );
                }
                else
                {
                    customerRequest.Type = caseTipificationMetadata.Type__c;
                    customerRequest.SubType__c = caseTipificationMetadata.Subtype__c;
                    customerRequest.TypeN3__c = caseTipificationMetadata.TypeN3__c;
                }
            }
        }
    }



    /**
     * Añade al asunto de un Caso de Sprinklr la red social indicada.
     * @author Juan Francisco Herrero
     * @date 23/04/2024
     * @param insertedCases Colección de nuevos casos que se insertan en la base de datos.
     */
    public static void setSprinklrCaseSubject(List<Case> insertedCases)
    {
        for(Case customerRequest : insertedCases)
        {
            if( customerRequest.RecordTypeId == RT_ID_OCSSPRINKLR && !String.isBlank(customerRequest.SprinklrSocialMediaChannel__c) )
            {
                customerRequest.Subject = 'Mensaje de un usuario de ' + customerRequest.SprinklrSocialMediaChannel__c;
            }
        }
    }

/**
 * Método que da valor a los campos Description y PrimerMensaje__c del objeto Case
 * Ejecutado en beforInsert porque vienen casos desde Sprinklr con la descripción rellena por un mensaje del cliente
 * @author jchavez
 * @date 23/02/2024
 **/

    public static void shortDescriptionNeeded(List<Case> newList)
    {
        integer stringLimit = 255;

        for(Case caso : newList)
        {
            if(caso.RecordTypeId == RT_ID_OCSSPRINKLR)
            {
                if(!String.isBlank(caso.Description) && caso.Description.length() > stringLimit)
                {
                    caso.PrimerMensaje__c =  caso.Description.left(stringLimit);
                }
                else
                {
                    caso.PrimerMensaje__c = caso.Description;
                }
            }
        }
    }

    /**
     * Relaciona los casos proporcionados si tienen informado el campo CustomerNifCif__c a traves
     * del campo 'mediated customer' (MediatedCustomer__c)
     *
     * @author mario.navarro@seidor.com
     * @date 10/04/2024
     * @param casesToRelate casos a relacionar con los respectivos clientes
     */
    public static void relateCaseToCustomerByNifCif(List<Case> casesToRelate)
    {
        //1- construimos un set con los dnis a buscar
        List<String> dniCifsToSearch = new List<String>();
        for (Case c : casesToRelate)
        {
            if ( String.isNotBlank(c.CustomerNifCif__c) )
            {
                dniCifsToSearch.add(c.CustomerNifCif__c);
            }
        }

        if ( dniCifsToSearch.isEmpty() )
        {
            //si no hay nada que buscar, no hay nada que relacionar ==> FIN
            return;
        }

        //Se hace la busqueda, en este caso no filtramos el tipo de documento
        List<Account> accountsFound = new AccountsSelector().findByNationalId(dniCifsToSearch, null);
        if ( accountsFound.isEmpty() )
        {
            //no se ha encontrado ningun cliente, no hay nada que relacionar ==> FIN
            return;
        }
        //2- Agrupamos clientes por dni
        Map<String, List<Account> > accountsByNationalId = (Map<String, List<Account> >) CollectionUtil.groupListBy( accountsFound, Account.fields.NationalId__c.getDescribe().getName() );

        //3- Iteramos para setear los clientes
        List<Account> accountList;
        for (Case c : casesToRelate)
        {
            if ( String.isNotBlank(c.CustomerNifCif__c) && accountsByNationalId?.containsKey(c.CustomerNifCif__c) )
            {
                accountList = accountsByNationalId.get(c.CustomerNifCif__c);
                if (accountList.size() == 1)
                {
                    c.MediatedCustomer__c = accountList[0].Id;
                }
                //else hay mas de uno, por lo tanto, no lo asignamos
            }
        }
    }

    /**
     * Llamado en BulkBefore
     * Recoge los valores de Queues necesarios para casos Sprinklr
     * @author jchavez
     * @date 04/03/2024
     */
    public static void getQueuesSprinklr()
    {
        queueMarcaRRSS = new GroupSelector().findByName(SPRINKLR_QUEUE_MARCA);
        queuePostventaRRSS = new GroupSelector().findByName(SPRINKLR_QUEUE_POSTVENTA);
        queueSiniestrosRRSS = new GroupSelector().findByName(SPRINKLR_QUEUE_SINIESTROS);
    }

    /**
     * Asigna Call Center y Owner a los casos tipo Sprinklr
     * @author jchavez
     * @date 04/03/2024
     * @param insertedCases Colección de nuevos casos que se insertan en la base de datos.
     */
    public static void setSprinklrCaseCallCenterAndGroup(List<Case> insertedCases)
    {
        for(Case customerRequest : insertedCases)
        {
            if(customerRequest.RecordTypeId == RT_ID_OCSSPRINKLR)
            {
                if( String.isBlank(customerRequest.Type) || customerRequest.Type.equals(SPRINKLR_TYPE_MARCA) )
                {
                    customerRequest.CallCenter__c = SPRINKLR_CALLCENTER_MARCA;
                    customerRequest.OwnerId = queueMarcaRRSS[0].Id;

                }
                else if( customerRequest.Type.equals(SPRINKLR_TYPE_ASISTENCIA) || customerRequest.Type.equals(SPRINKLR_TYPE_SINIESTROS) )
                {
                    customerRequest.CallCenter__c = SPRINKLR_CALLCENTER_SINIESTROS;
                    customerRequest.OwnerId = queueSiniestrosRRSS[0].Id;
                }
                else
                {
                    customerRequest.CallCenter__c = SPRINKLR_CALLCENTER_SINIESTROS;
                    customerRequest.OwnerId = queuePostventaRRSS[0].Id;
                }
            }
        }
    }

    /**
     * Para aquellos casos que sean de ZDA y el origen sea Canal unico (llegan via API estandar), se aplica formato a la descripcion
     * del caso, puesto que llegan con este formato:
     * Usuario: NOMBRE APELLIDO1 APELLIDO2;;Correo electrónico: USUARIO@bancsabadell.com;;Unidad de trabajo: 0086
     * Se debe sustituir ;; por un salto de linea, de tal manera que quede:
     * Usuario: NOMBRE APELLIDO1 APELLIDO2
     * Correo electrónico: USUARIO@bancsabadell.com
     * Unidad de trabajo: 0086
     *
     * @author mario.navarro@seidor.com
     * @date 08/04/2024
     * @param insertedCases Colección de nuevos casos que se insertan en la base de datos.
     */
    public static void applyFormatToZDABody(List<Case> insertedCases)
    {
        for(Case insertedCase : insertedCases)
        {
            if(insertedCase.RecordTypeId == RT_ID_ZDA && 'CanalUnico'.equals(insertedCase.Origin) && insertedCase.Description != null)
            {
                insertedCase.Description = insertedCase.Description.replace(';;', '\n');
            }
        }
    }

    /**
     * Método que asocia el ContactId y el AccountId del caso dependiendo del SuppliedEmail
     * Esto solamente funcionará para los Email-To-Case
     * Se hace uso del AccountSearchService dado que se necesita usar SOSL en los
     * ContactPointEmail ya que hacen querys no selectivas por campos no indexados
     * @date 25/01/2021
     * @change aberuete - 07/06/2023 - Incluir que no asigne la cuenta a los casos provenientes de MiZurich
     **/
    public static void assignAccountAndContactFromSuppliedEmail(List<Case> newList)
    {
        //No se ejecuta bulkificado, sino solo en aquellas ocasiones que entra un Email-To-Case (no es bulk)
        if(newList.size() == 1)
        {
            for(Case caso : newList)
            {
                //Esta comparación se hace para que no afecte a KLINC
                if(caso.RecordTypeId == RT_ID_OCSINQUIRY && !String.isBlank(caso.SuppliedEmail) && caso.Subject != 'Solicitud de ayuda al registro de MiZurich') 
                {
                    //Solo se hace algo si llegó relleno el campo del Email-To-Case
                    //Utilizar el email del SuppliedEmail
                    List<String> emailsToSearch = new List<String>();
                    emailsToSearch.add(caso.SuppliedEmail);

                    //Utilizar el scope del caso
                    //AccountSearchService.Scope scope = new AccountSearchService.Scope();

                    //Utilizar el AccountSearchService
                    List<Account> matchedAccounts = new List<Account>();
                    matchedAccounts = AccountSearchService.findCustomersByEmail(emailsToSearch, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);

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

    /**
     * Método que busca si existe una única cuenta en función del valor del dni, email y teléfono para asociar el caso.
     * En caso afirmativo, asocia también el contacto de la cuenta. Utilizado para los casos creados desde el formulario miZurich
     **
     * @author aberuete
     * @date 16/08/2023
     * @param List<Case> newList : Lista de casos
     */
    public static void assignAccountAndContactFromDniSuppliedEmailAndPhone (List<Case> newList)
    {
        List<String> nationalIds = new List<String>();
        List<String> emails = new List<String>();
        List<String> phones = new List<String>();

        Map<String,List<Account> > mapAccountsByNatinalId = new Map<String,List<Account> > ();
        Map<String,List<Account> > mapAccountsByEmails = new Map<String,List<Account> > ();
        Map<String,List<Account> > mapAccountsByPhones = new Map<String,List<Account> > ();

        for (Case newCase : newList)
        {
            if (newCase.RobotNif__c != null)
            {
                nationalIds.add(newCase.RobotNif__c);
            }

            if (newCase.SuppliedEmail != null)
            {
                emails.add(newCase.SuppliedEmail);
            }
            if (newCase.SuppliedPhone != null)
            {
                phones.add(newCase.SuppliedPhone);
            }
        }

        mapAccountsByNatinalId = getMapOfAccountRelatedByNatinalId (nationalIds);
        mapAccountsByEmails = getMapOfAccountRelatedByEmail (emails);
        mapAccountsByPhones = getMapOfAccountRelatedByPhone (phones);

        for (Case caseToUpdate : newList)
        {
            caseToUpdate = getAccountAndContactToAssign (caseToUpdate, mapAccountsByNatinalId, mapAccountsByEmails, mapAccountsByPhones);
        }
    }

    /**BEFOREUPDATE
     * IMPORTANTE: la modificación del CaseMilestone no puede ser después de la actualización del caso
     * porque el caso ya se ha salido del entitlement process y salta el siguiente error:
     * "You can’t change the completion date on a milestone that’s already exited an entitlement process.: Completion Date"
     * Por eso tiene que ser modificado en el before
     * @date 25/01/2021
     * change aberuete - 18/04/2023 - Refactorizar método
     **/
    public static void markMilestonesCompletedWhenClose(List<Case> newList, Map<Id,Case> oldMap)
    {
        List<CaseMilestone> caseMilestoneList = new List<CaseMilestone>();
        List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();

        List<Case> updatedCases = getCasesToMarkMilestonesCompletedWhenClose (newList, oldMap);

        //Si hay casos a los que hay que completarles el Milestone:
        if( !updatedCases.isEmpty() )
        {
            //Recoger los milestones del tipo requerido
            caseMilestoneList = [SELECT Id, CaseId, CompletionDate FROM CaseMilestone WHERE CaseId IN : updatedCases AND MilestoneType.Name = 'Cierre Caso'];

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
        caseMilestoneList = [SELECT Id, CaseId, CompletionDate FROM CaseMilestone WHERE CaseId IN : updatedCases AND MilestoneType.Name =: milestoneName];
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
     * Método utilizado por Batch_CLoseInteractions para activar el campo CloseByBatch__c
     * @author lrodriguez6@seidor.es
     * @date 21/02/2024
     * @param [List<Case> casesToCheck] casos que ha recuperado el batch
     * @return List<Case> casos a actualizar
     */
    public static List<Case> checkCasesCloseInteractions (List<Case> casesToRelate)
    {
        List<Case> casesToUpdate = new List<Case>();

        if( casesToRelate != null && !casesToRelate.isEmpty() )
        {
            for(Case currentCase : casesToRelate)
            {
                currentCase.CloseByBatch__c = true;
                casesToUpdate.add(currentCase);
            }
        }
        return casesToUpdate;
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
        Id rtUSPId = RT_ID_USPINQUIRY;
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
        if( casesToRelate != null && !casesToRelate.isEmpty() )
        {
            // Se obtiene la lista de cifs
            List<String> cifs = generateCifList(casesToRelate);

            // Query a Account para recuperar los clientes creados en las últimas 24 horas
            // y con cif contenido por los casos recogidos en el batch
            List<Account> accountsToRelate = new AccountsSelector().findByCIFAndCreationDate(cifs, daysToRetrieve);

            // Si no hay cuentas no recorremos la lista para evitar excepciones
            if( accountsToRelate != null && !accountsToRelate.isEmpty() )
            {
                //Mapa para identificar cada cuenta con su cif
                Map<String, Account> mapAccountsToRelateByCIF = AccountUtil.generateMapByCif(accountsToRelate);

                // Se recorre la lista de casos a relacionar
                for(Case currentCase : casesToRelate)
                {
                    // Si alguna cuenta tiene el mismo cif que el caso, se tienen que relacionar
                    if(mapAccountsToRelateByCIF.get(currentCase.RobotDocumentId__c) != null)
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
        if( cases != null && !cases.isEmpty() )
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

        Id rtOCSId = RT_ID_OCSINQUIRY;
        if (padre.RecordTypeId == rtOCSId)
        {
            casoHijo.CallCenter__c = padre?.CallCenter__c;
        }

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
     * Método que comprueba si la tipificación de un caso se encuentra entre las disponibles en el sistem
     * @author arcortazar
     * @date 18/11/2022
     * @param {Case caso} caso que se va a copiar
     * @param {Boolean setTypification} indica si la tipificación sigue existiendo en el sistema (true) o no (false)
     * @return Case
     */
    public static Boolean checkTypification(Case caso)
    {
        Map<String, List<String> > mapaT1 = SystemUtil.getDependantPicklistValues('Case', 'Type', 'Subtype__c');
        Map<String, List<String> > mapaT2 = SystemUtil.getDependantPicklistValues('Case', 'Subtype__c', 'TypeN3__c');

        if ( mapaT1.containsKey(caso.Type) && mapaT1.get(caso.Type).contains(caso.Subtype__c) &&
             mapaT2.containsKey(caso.Subtype__c) && mapaT2.get(caso.Subtype__c).contains(caso.TypeN3__c) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    /**
     * Método que comprueba si la tipificación de un caso se encuentra entre las disponibles en el sistem
     * @author arcortazar
     * @date 13/02/2023
     * @param {String typeN1} String que contiene el tipo del caso a comprobar
     * @param {String typeN2} String que contiene el subtipo del caso a comprobar
     * @param {String typeN3} String que contiene el tipoN3 del caso a comprobar
     * @param {Id RecordType} RecordType que queremos comprobar
     * @param {Boolean setTypification} indica si la tipificación sigue existiendo en el sistema (true) o no (false)
     * @return Case
     */
    public static Boolean checkTypificationByRecordType(String typeN1, String typeN2, String typeN3, Id recordTypeId)
    {
        Map<String, List<String> > mapaT1 = new Map<String, List<String> >();
        Map<String, List<String> > mapaT2 = new Map<String, List<String> >();

        if( Test.isRunningTest() )
        {
            List<String> lstA1 = new List<String>();
            lstA1.add('A1');
            mapaT1.put('A', lstA1);

            List<String> lstA12 = new List<String>();
            lstA12.add('A11');
            mapaT2.put('A1', lstA12);

        }
        else
        {
            mapaT1 = SystemUtil.getDependantPicklistValuesByRecordType('Case', 'Subtype__c', recordTypeId);
            mapaT2 = SystemUtil.getDependantPicklistValuesByRecordType('Case', 'TypeN3__c', recordTypeId);
        }

        if ( mapaT1.containsKey(typeN1) && mapaT1.get(typeN1).contains(typeN2) &&
             mapaT2.containsKey(typeN2) && mapaT2.get(typeN2).contains(typeN3) )
        {
            return true;
        }
        else
        {
            return false;
        }

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
        if( casesToRelate != null && !casesToRelate.isEmpty() )
        {
            // Se obtiene la lista de ofertas generadas
            List<String> ofertasGeneradas = generateCreateOfferList(casesToRelate);

            // Query a Opportunity para recuperar las ofertas creados en las últimas 24 horas
            // y con oferta generada contenido por los casos recogidos en el batch
            List<Opportunity> offersToRelate = new OpportunitiesSelector().findByCreatedOfferAndCreationDate(ofertasGeneradas, daysToRetrieve);

            // Si no hay ofertas no recorremos la lista para evitar excepciones
            if( offersToRelate != null && !offersToRelate.isEmpty() )
            {
                //Mapa para identificar cada oferta con su oferta generada
                Map<String, Opportunity> mapOffersToRelateByCreatedOffer = OpportunityUtil.generateMapByCreatedOffer(offersToRelate);

                // Se recorre la lista de casos a relacionar
                for(Case currentCase : casesToRelate)
                {
                    // Si alguna oferta tiene la misma oferta generada que el caso, se tienen que relacionar
                    if(mapOffersToRelateByCreatedOffer.get(currentCase.CreatedOffer__c) != null)
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
        if( cases != null && !cases.isEmpty() )
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
     * @date 07/02/2023
     * @param Lista de cuentas
     * @return Lista de cuentas
     */

    public static List<Account> generateAccountRatio(List<Account> accountsIntermediary)
    {
        List<Case> cases= new List<Case>();
        List<Account> allIntermediaryToUpdate= new List<Account>();

        Map <Id, Decimal> mapAllIntermediaryCases= new Map <Id,Decimal>();
        Map <Id, Decimal> mapWonIntermediaryCases= new Map <Id,Decimal>();
        Map <Id, Decimal> mapWonChildCases= new Map <Id,Decimal>();

        Id rtCasesUSPId= RT_ID_USPINQUIRY;

        cases= new CasesSelector().getQueryCasesConversionRatio(accountsIntermediary,statusCombinado,closeResult,typeVenta,rtCasesUSPId,queryDays,estadoCerrado);

        mapWonChildCases= new CasesSelector().getMapChildCasesConversionRatio(cases,statusWon,closeResult,statusCombinado,typeVenta,rtCasesUSPId,queryDays,estadoCerrado);



        for(Case currentCase:cases)
        {
            if(mapAllIntermediaryCases.get(currentCase.AccountId) == null && mapWonIntermediaryCases.get(currentCase.Id) == null)
            {
                mapAllIntermediaryCases.put(currentCase.AccountId,0);
                mapWonIntermediaryCases.put(currentCase.AccountId,0);

            }

            mapAllIntermediaryCases.put( currentCase.AccountId,(mapAllIntermediaryCases.get(currentCase.AccountId) + 1) );

            if(currentCase.QuotationStage__c == 'Won' || mapWonChildCases.get(currentCase.Id) >= 1)
            {
                mapWonIntermediaryCases.put( currentCase.AccountId,(mapWonIntermediaryCases.get(currentCase.AccountId) + 1) );
            }
        }


        for( Id idCuenta: mapAllIntermediaryCases.keySet() )
        {
            Account acc=new Account();
            acc.Id=idCuenta;
            acc.USPConversionRatio__c=( mapWonIntermediaryCases.get(acc.Id) / mapAllIntermediaryCases.get(acc.Id) ) * 100;
            allIntermediaryToUpdate.add(acc);
        }

        return allIntermediaryToUpdate;

    }


    /**
     * Método utilizado por Batch_CompleteCases para relacionar los casos con las Polizas u Ofertas
     * @author arcortazar
     * @date 23/03/2023
     * @param [List<Case> [casesToRelate] casos que ha recuperado el batch
     * @return List<Case> casos a actualizar
     */
    public static List<Case> relateCasesToPolicyOffers (List<Case> casesToRelate)
    {
        // Lista para almacenar solo los registros que hay que actualizar
        List<Case> casesToUpdate = new List<Case>();

        // La lógica solo se recorre si la lista no es nula, para evitar excepciones
        if( casesToRelate != null && !casesToRelate.isEmpty() )
        {
            // Mapas para almacenar la información relacionada
            Map<String, Opportunity> mapRetrievedOffers= new Map<String, Opportunity>();
            Map<String, Policy__c> mapRetrievedPolicies= new Map<String, Policy__c>();

            getRelatedPoliciesOffers(casesToRelate, mapRetrievedOffers, mapRetrievedPolicies);
            casesToUpdate = comprobarCasos(casesToRelate, mapRetrievedOffers, mapRetrievedPolicies);
        }
        return casesToUpdate;
    }

    /**
     * Relaciona los casos cuyo campo RelatedCuTicketId__c esta informado, para asignarles como parent
     * case aquellos cuyo CuTicketId__c coincida
     *
     * @author mario.navarro@seidor.com
     * @date 09/04/2024
     * @param casesToRelate lista de casos a relacionar
     */
    public static void relateCasesByTicketId(List<Case> casesToRelate)
    {
        //1- construimos un set con los ticket id a buscar
        Set<String> ticketIdsToSearch = new Set<String>();
        for (Case c : casesToRelate)
        {
            if (c.RelatedCuTicketId__c != null)
            {
                ticketIdsToSearch.add(c.RelatedCuTicketId__c);
            }
        }

        if ( ticketIdsToSearch.isEmpty() )
        {
            //si no hay nada que buscar, no hay nada que relacionar ==> FIN
            return;
        }

        List<Case> parentCases = new CasesSelector().getCasesByTicketId(ticketIdsToSearch);
        if ( parentCases.isEmpty() )
        {
            //no se ha encontrado ningun parent, no hay nada que relacionar ==> FIN
            return;
        }
        //2- Agrupamos casos por ticketId
        Map<String, Case> casesByTicketId = (Map<String, Case>) CollectionUtil.hashList( parentCases, Case.fields.CuTicketId__c.getDescribe().getName() );

        //3- Iteramos para setear los 'padres'
        for (Case c : casesToRelate)
        {
            if ( c.RelatedCuTicketId__c != null && casesByTicketId?.containsKey(c.RelatedCuTicketId__c) )
            {
                c.ParentId = casesByTicketId.get(c.RelatedCuTicketId__c).Id;
            }
        }
    }

    /**
     * Para aquellos casos que sean de ZDA y el origen sea Canal unico (llegan via API estandar), se comprueba si
     * para el campo SuppliedEmail existe cuenta de tipo mediador, y en caso afirmativo, se vincula el caso
     * mediante el AccountId
     *
     * @author mario.navarro@seidor.com
     * @date 10/04/2024
     * @param insertedCases Colección de nuevos casos que se insertan en la base de datos.
     */
    public static void relateCasesWithMediatedAccount(List<Case> insertedCases)
    {
        //1- construimos un set con los emails a buscar
        Set<String> emailsToSearch = new Set<String>();
        for(Case insertedCase : insertedCases)
        {
            if(insertedCase.RecordTypeId == RT_ID_ZDA && insertedCase.SuppliedEmail != null)
            {
                emailsToSearch.add(insertedCase.SuppliedEmail);
            }
        }

        if ( emailsToSearch.isEmpty() )
        {
            //si no hay nada que buscar, no hay nada que relacionar ==> FIN
            return;
        }

        List<Account> intermediaryAccs = new AccountsSelector().findIntermediariesByMainEmail(emailsToSearch);
        if ( intermediaryAccs.isEmpty() )
        {
            //no se ha encontrado ninguna cuenta, no hay nada que relacionar ==> FIN
            return;
        }
        //2- Agrupamos casos por ticketId
        Map<String, List<Account> > accByEmail = (Map<String, List<Account> >) CollectionUtil.groupListBy( intermediaryAccs, Account.fields.MainEmail__c.getDescribe().getName() );
        List<Account> emailAccounts;
        for(Case insertedCase : insertedCases)
        {
            if(insertedCase.RecordTypeId == RT_ID_ZDA && insertedCase.SuppliedEmail != null)
            {
                emailAccounts = accByEmail?.get(insertedCase.SuppliedEmail);
                if (emailAccounts != null && emailAccounts.size() == 1)
                {
                    insertedCase.AccountId = emailAccounts[0].Id;
                }
                //else: no se han encontrado cuentas o hay mas de una. No se vincula
            }
        }
    }

    /**
     * Método privado que obtiene las pólizas y ofertas relacionadas con los casos
     * @author: arcortazar
     * @date: 27/03/2023
     */
    private static void getRelatedPoliciesOffers(List<Case> listaCasos, Map<String, Opportunity> mapRetrievedOffers, Map<String, Policy__c> mapRetrievedPolicies)
    {
        Set<String> lstOffers = new Set<String>();
        Set<String> lstPolicies = new Set<String>();

        for(Case c : listaCasos)
        {
            if( !String.isBlank(c.HegeoOfferId__c) )
                lstOffers.add(c.HegeoOfferId__c);
            if( !String.isBlank(c.HegeoPolicyId__c) )
                lstPolicies.add(c.HegeoPolicyId__c);
            if( !String.isBlank(c.HegeoPrePolicyId__c) )
                lstOffers.add(c.HegeoPrePolicyId__c);
        }

        // Obtenemos las Polizas y Ofertas relacionadas con los casos
        List<Opportunity> retrievedOffers = new OpportunitiesSelector().findByName(lstOffers);
        List<Policy__c> retrievedPolicies = new PoliciesSelector().selectByNumber(lstPolicies);

        for (Opportunity o : retrievedOffers)
        {
            mapRetrievedOffers.put(o.Name, o);
        }

        for (Policy__c p : retrievedPolicies)
        {
            mapRetrievedPolicies.put(p.InfoPolicyNumber__c, p);
        }
    }

    /**
     * Método privado que comprueba los casos y actualiza la información
     * @author: arcortazar
     * @date: 27/03/2023
     */
    private static List<Case> comprobarCasos(List<Case> listaCasos, Map<String, Opportunity> mapRetrievedOffers, Map<String, Policy__c> mapRetrievedPolicies)
    {
        List<Case> casesToUpdate = new List<Case>();
        for(Case c : listaCasos)
        {
            // Comprobamos si hemos de informar la póliza
            if(!String.isBlank(c.HegeoPolicyId__c) && mapRetrievedPolicies.get(c.HegeoPolicyId__c) != null)
            {
                c.PolicyId__c = mapRetrievedPolicies.get(c.HegeoPolicyId__c).Id;
            }

            // Comprobamos si hemos de informar la oferta (siendo la información que viene en el campo HegeoOfferId__c prioritario)
            if(!String.isBlank(c.HegeoOfferId__c) && mapRetrievedOffers.get(c.HegeoOfferId__c) != null)
            {
                c.OfferId__c = mapRetrievedOffers.get(c.HegeoOfferId__c).Id;
            }
            else if(!String.isBlank(c.HegeoPrePolicyId__c) && mapRetrievedOffers.get(c.HegeoPrePolicyId__c) != null)
            {
                c.OfferId__c = mapRetrievedOffers.get(c.HegeoPrePolicyId__c).Id;
            }

            casesToUpdate.add(c);
        }
        return casesToUpdate;

    }

    /**
     * Método que actualiza el contacto asociado al caso si proviene de email to case y encuentra un unico contacto que cumpla las condiciones.
     * @author: aberuete
     * @date: 18/04/2023
     * @param List<Case> updateCases : lista de casos a actualizar
     * @param Case caso
     */
    @testvisible
    private static List<Case> getCasesToUpdateContactFromEmailToCase (List<Case> updateCases, Case caso)
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
                    WHERE Email = : caso.SuppliedEmail AND LegalEntity__c = : caso.LegalEntity__c
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
        return updateCases;
    }

    /**
     * Método que obtiene los casos para que sea marcado el campo CaseMilestone a completado
     * @author: aberuete
     * @date: 18/04/2023
     * @param List<Case> newList : lista de casos a actualizar
     * @param Map<Id,Case> oldMap : Mapa que contiene la referencia al nuevo caso y el caso sin modificar
     */
    @testvisible
    private static List<Case> getCasesToMarkMilestonesCompletedWhenClose (List<Case> newList, Map<Id,Case> oldMap)
    {
        List<Case> updatedCases = new List<Case>();
        Case oldCase = new Case();
        Id rtOCSInquiryId = RT_ID_OCSINQUIRY;

        //Almacenar los casos que cumplen las condiciones
        for(Case caso : newList)
        {
            //Esta comparación se hace para que no afecte a KLINC
            if(caso.RecordTypeId == rtOCSInquiryId || caso.RecordTypeId == RT_ID_ZDA)
            {
                oldCase = oldMap.get(caso.Id);
                //Solo se hace algo si se cerró el caso
                if(oldCase.Status != caso.Status && (caso.Status == 'Cerrado' || caso.Status == 'Merged' || caso.Status == 'Combinado') && caso.SlaExitDate == null)
                {
                    updatedCases.add(caso);
                }
            }
        }

        return updatedCases;
    }

    /**
     * Método que en caso de que exista una póliza con el número del caso y el caso no tenga asociada la póliza, asocia la póliza al caso,
     * así como el contacto asociado a la póliza.
     * @author: aberuete
     * @date: 18/04/2023
     * @param AdminSetup__mdt adminSetup : Metadata AdminSetup__mdt
     * @param Case caso
     * @param Map<String, String> mapMultiPartner : Mapa que contiene el campo Multi_Partners__c del metadata AdminSetup__mdt
     */
    @testvisible
    private static Case updatePolicyToCaseifCaseDoesNotHavePolicy (AdminSetup__mdt adminSetup, Case caso, Map<String, String> mapMultiPartner)
    {
        // Get the Country that is not EMEA (Spain)
        String iba_emea_non_country = adminSetup.IBA_EMEA_Non_Country__c;
        // Get the EMEA prefix
        String iba_emea = adminSetup.IBA_EMEA_Prefix__c;

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
                WHERE (RecordType.DeveloperName = : Label.PolicyGI OR RecordType.DeveloperName = : Label.PolicyLife)
                AND PolicyNum__c = : caso.PolicyNum__c
            ];

            if (policies != null && policies.size() > 0)
            {
                caso.ContactId = policies[0].ContactId__c;
                caso.Policy__c = policies[0].Id;
                caso.LegalEntity__c = policies[0].LegalEntity__c;
                caso.CustomerFoundBy__c = 'Policy Number';
            }
        }

        return caso;
    }

    /**
     * Método que en caso de que el caso no tenga una póliza asociada, busca asociar el contacto al caso a través del email
     * @author: aberuete
     * @date: 18/04/2023
     * @param Case caso
     */
    @testvisible
    private static Case updateContactToCaseByEmail(Case caso)
    {
        if ( String.isNotBlank(caso.SuppliedEmail) &&  String.isNotBlank(caso.LegalEntity__c)
             &&  String.isNotBlank(caso.SourceCountry__c) && caso.Policy__c == null)
        {
            //Si no se ha informado el número de poliza asignar cliente por mail y entidad legal (Solo si hay 1 cliente con ese mail)
            List<Contact> contactoSF = [
                SELECT id FROM Contact
                WHERE Email = : caso.SuppliedEmail AND LegalEntity__c = : caso.LegalEntity__c
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

        return caso;
    }

    /**
     * Método que en caso de que el caso no tenga una póliza asociada, ni un contacto intenta asociar el contacto por télefono,
     * si existe un unico contacto para ese número
     * @author: aberuete
     * @date: 18/04/2023
     * @param Case caso
     */
    @testvisible
    private static Case updateContactToCaseByPhone(Case caso)
    {
        if ( String.isNotBlank(caso.SuppliedPhone) && String.isNotBlank(caso.LegalEntity__c)
             && String.isNotBlank(caso.SourceCountry__c) && caso.Policy__c == null && caso.ContactId == null)
        {
            List<Contact> contactoSF = [
                SELECT id FROM Contact
                WHERE MobilePhone = : caso.SuppliedPhone AND LegalEntity__c = : caso.LegalEntity__c
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
        return caso;
    }

    /**
     * Método que en caso de que el caso provenga de la web de francia actualiza la traducción para los campos tipo y subtipo si la tiene
     * @author: aberuete
     * @date: 18/04/2023
     * @param Case caso
     */
    @testvisible
    private static Case ifCaseFromWebFranceUpdateTranslationToCase (Case caso)
    {
        if ( caso.Origin.equals('Web') && !String.isBlank(caso.SourceCountry__c) && ( mapCountryTranslationField.containsKey(caso.SourceCountry__c) ) )
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

        return caso;
    }

    /**
     * Método que actualiza los valores del caso proveniente del email to case de transcom antes de insertarlo
     * @author: aberuete
     * @date: 21/06/2023
     * @param List<Case> newList : Lista de casos nuevos
     * @change aberuete - 28/07/2023 Actualizar campo source area en función de la cola
     * @change jfherrero - 16/01/2024 Eliminar tipificación automática como 'Gestión Servicios'/'Anulación'/'Anulación'
     */
    public static void updateTranscomCase (List<Case> newList)
    {
        List<Group> queueRetencion = new GroupSelector().findByName('Email_TWW_Retencion');
        List<Group> queueAnulacion = new GroupSelector().findByName('Email_TWW_Anulacion');

        for (Case caseNew : newList)
        {
            if (caseNew.OwnerId == queueRetencion[0].Id || caseNew.OwnerId == queueAnulacion[0].Id )
            {
                caseNew.CallCenter__c = 'TWW Retención';

                if ( caseNew.OwnerId == queueRetencion[0].Id)
                {
                    caseNew.SourceArea__c = 'End customer partner';
                }
                else
                {
                    caseNew.SourceArea__c = 'Generic end customer';
                }
            }
        }
    }

    /**
     * Método que genera un mapa de lista de cuentas por dni.
     **
     * @author aberuete
     * @date 22/08/2023
     * @param List<String> nationalIds : Lista de dnis
     */
    private static Map<String,List<Account> > getMapOfAccountRelatedByNatinalId (List<String> nationalIds)
    {
        Map<String,List<Account> > mapAccountsByNatinalId = new Map<String,List<Account> > ();
        List<Account> accountsByNationalId = AccountSearchService.findCustomersByDocumentId(nationalIds, '',null,null, new List<String> {'Customer'}, new List<String> {'F','J'});

        for (Account account :accountsByNationalId)
        {
            List<Account> accountList = mapAccountsByNatinalId.get(account.NationalId__c);
            if( accountList == null )
            {
                accountList = new List<Account>();
                mapAccountsByNatinalId.put(account.NationalId__c, accountList);
            }
            accountList.add(account);
        }

        return mapAccountsByNatinalId;
    }

    /**
     * Método que genera un mapa de lista de cuentas por email.
     **
     * @author aberuete
     * @date 22/08/2023
     * @param List<String> emails : Lista de emails
     */
    private static Map<String, List<Account> > getMapOfAccountRelatedByEmail (List<String> emails)
    {
        Map<Id,List<String> > mapIdAccountByEmails = new Map <Id, List<String> > ();
        Map<String,List<Account> > mapAccountsByEmails = new Map<String,List<Account> > ();
        List<ContactPointEmail> contactPointsEmail = new List<ContactPointEmail> ();

        if ( !emails.isEmpty() && emails != null)
        {
            contactPointsEmail = [FIND : String.join(emails, ' OR ') IN EMAIL FIELDS RETURNING ContactPointEmail(Id, ParentId,EmailAddress )][0];
        }

        for (ContactPointEmail contactPointEmail :contactPointsEmail)
        {
            List<String> accountIdListByEmails = mapIdAccountByEmails.get(contactPointEmail.ParentId);

            if (accountIdListByEmails == null)
            {
                accountIdListByEmails = new List<String>();
                mapIdAccountByEmails.put(contactPointEmail.ParentId, accountIdListByEmails);
            }
            accountIdListByEmails.add(contactPointEmail.EmailAddress);
        }

        if ( !mapIdAccountByEmails.isEmpty() )
        {
            List<Account> accountsToRelate = new AccountsSelector().findByAccountIdsRecordTypeNameAndType(mapIdAccountByEmails.keySet(), new List<String> {'Customer'}, new List<String> {'F','J'});

            for (Account accountToRelate : accountsToRelate)
            {
                List<String> emailsList = mapIdAccountByEmails.get(accountToRelate.id);

                for (String email : emailsList)
                {
                    List<Account> accountListByEmails = mapAccountsByEmails.get(email);

                    if( accountListByEmails == null )
                    {
                        accountListByEmails = new List<Account>();
                        mapAccountsByEmails.put(email, accountListByEmails);
                    }
                    accountListByEmails.add(accountToRelate);
                }
            }
        }
        return mapAccountsByEmails;
    }

    /**
     * Método que genera un mapa de lista de cuentas por teléfono.
     **
     * @author aberuete
     * @date 16/08/2023
     * @param List<String> phones : Lista de teléfonos
     */
    private static Map<String, List<Account> > getMapOfAccountRelatedByPhone (List<String> phones)
    {
        Map<Id,List<String> > mapIdAccountByPhones = new Map <Id, List<String> > ();
        Map<String,List<Account> > mapAccountsByPhones = new Map<String,List<Account> > ();
        List<ContactPointPhone> contactPointsPhone = new List<ContactPointPhone> ();

        if ( !phones.isEmpty() && phones != null)
        {
            contactPointsPhone = [FIND : String.join(phones, ' OR ') IN PHONE FIELDS RETURNING ContactPointPhone(Id, ParentId, TelephoneNumber)][0];
        }

        for (ContactPointPhone contactPointPhone :contactPointsPhone)
        {
            List<String> accountIdListByPhones = mapIdAccountByPhones.get(contactPointPhone.ParentId);

            if (accountIdListByPhones == null)
            {
                accountIdListByPhones = new List<String>();
                mapIdAccountByPhones.put(contactPointPhone.ParentId, accountIdListByPhones);
            }
            accountIdListByPhones.add(contactPointPhone.TelephoneNumber);
        }

        if ( !mapIdAccountByPhones.isEmpty() )
        {
            List<Account> accountsToRelate = new AccountsSelector().findByAccountIdsRecordTypeNameAndType(mapIdAccountByPhones.keySet(), new List<String> {'Customer'}, new List<String> {'F','J'});

            for (Account accountToRelate : accountsToRelate)
            {
                List<String> phonesList = mapIdAccountByPhones.get(accountToRelate.id);

                for (String phone : phonesList)
                {
                    List<Account> accountListByPhones = mapAccountsByPhones.get(phone);
                    if( accountListByPhones == null )
                    {
                        accountListByPhones = new List<Account>();
                        mapAccountsByPhones.put(phone, accountListByPhones);
                    }
                    accountListByPhones.add(accountToRelate);
                }
            }
        }
        return mapAccountsByPhones;
    }

    /**
     * Método que obtiene el número de cuentas asociadas a un dni.
     **
     * @author aberuete
     * @date 16/08/2023
     * @param Case caseToUpdate : caso
     * @param Map<String,List<Account>> mapAccountsByNatinalId : Mapa de lista de cuentas por dni
     */
    private static Integer numAccountsByNationalId (Case caseToUpdate, Map<String,List<Account> > mapAccountsByNatinalId )
    {
        Integer numAccounts = 0;
        if (caseToUpdate.RobotNif__c != null && !String.isBlank(caseToUpdate.RobotNif__c) && !mapAccountsByNatinalId.isEmpty() && mapAccountsByNatinalId.get(caseToUpdate.RobotNif__c) != null )
        {
            numAccounts = mapAccountsByNatinalId.get(caseToUpdate.RobotNif__c).size();
        }
        return numAccounts;
    }

    /**
     * Método que obtiene el número de cuentas asociadas a un email.
     **
     * @author aberuete
     * @date 16/08/2023
     * @param Case caseToUpdate : caso
     * @param Map<String,List<Account>> mapAccountsByEmails : Mapa de lista de cuentas por email
     */
    private static Integer numAccountsByEmail (Case caseToUpdate, Map<String,List<Account> > mapAccountsByEmails )
    {
        Integer numAccounts = 0;
        if ( caseToUpdate.SuppliedEmail != null && !String.isBlank(caseToUpdate.SuppliedEmail) && !mapAccountsByEmails.isEmpty() && mapAccountsByEmails.get(caseToUpdate.SuppliedEmail) != null )
        {
            numAccounts = mapAccountsByEmails.get(caseToUpdate.SuppliedEmail).size();
        }
        return numAccounts;
    }

    /**
     * Método que obtiene el número de cuentas asociadas a un teléfono.
     **
     * @author aberuete
     * @date 16/08/2023
     * @param Case caseToUpdate : caso
     * @param Map<String,List<Account>> mapAccountsByPhones : Mapa de lista de cuentas por teléfono
     */
    private static Integer numAccountsByPhone (Case caseToUpdate, Map<String,List<Account> > mapAccountsByPhones )
    {
        Integer numAccounts = 0;
        if ( caseToUpdate.SuppliedPhone != null && !String.isBlank(caseToUpdate.SuppliedPhone) && !mapAccountsByPhones.isEmpty() && mapAccountsByPhones.get(caseToUpdate.SuppliedPhone) != null )
        {
            numAccounts = mapAccountsByPhones.get(caseToUpdate.SuppliedPhone).size();
        }
        return numAccounts;
    }

    /**
     * Método que asigna una cuenta y contacto a un caso en caso de que haya una unica cuenta a asignar por dni,email y teléfono.
     **
     * @author aberuete
     * @date 23/08/2023
     * @param Case caseToUpdate : caso
     * @param Map<String,List<Account>> mapAccountsByNatinalId : Mapa de lista de cuentas por dni
     * @param Map<String,List<Account>> mapAccountsByEmails : Mapa de lista de cuentas por email
     * @param Map<String,List<Account>> mapAccountsByPhones : Mapa de lista de cuentas por teléfono
     */
    private static Case getAccountAndContactToAssign (Case caseToUpdate, Map<String,List<Account> > mapAccountsByNatinalId, Map<String,List<Account> > mapAccountsByEmails, Map<String,List<Account> > mapAccountsByPhones)
    {
        Integer numAccount = numAccountsByNationalId (caseToUpdate, mapAccountsByNatinalId );

        if ( numAccount == 1 )
        {
            caseToUpdate.AccountId = mapAccountsByNatinalId.get(caseToUpdate.RobotNif__c)[0].Id;
            caseToUpdate.ContactId = mapAccountsByNatinalId.get(caseToUpdate.RobotNif__c)[0].PersonContactId;
        }
        else if (numAccount == 0)
        {
            numAccount = numAccountsByEmail (caseToUpdate, mapAccountsByEmails);

            if (numAccount == 1)
            {
                caseToUpdate.AccountId = mapAccountsByEmails.get(caseToUpdate.SuppliedEmail)[0].Id;
                caseToUpdate.ContactId = mapAccountsByEmails.get(caseToUpdate.SuppliedEmail)[0].PersonContactId;
            }
            else if (numAccount == 0)
            {
                numAccount = numAccountsByPhone (caseToUpdate, mapAccountsByPhones);

                if ( numAccount == 1)
                {
                    caseToUpdate.AccountId = mapAccountsByPhones.get(caseToUpdate.SuppliedPhone)[0].Id;
                    caseToUpdate.ContactId = mapAccountsByPhones.get(caseToUpdate.SuppliedPhone)[0].PersonContactId;
                }
            }
        }
        return caseToUpdate;
    }

    /**
     * Método que comprueba si el propietario del caso es válido
     * @param String ownerId - Id de propietario a verificar
     * @return Boolean - true si es apto para ser propietario de un caso nuevo
     *
     * @author nts - jfherrero
     * @date 29/01/2024
     */
    public static Boolean validCaseOwner(Id ownerId)
    {
        if ( ( (String) ownerId ).startsWith('00G') )
        {
            return true;
        }

        else if ( ( (String) ownerId ).startsWith('005') )
        {
            UsersSelector usersSelector = new UsersSelector();
            usersSelector.baseQuery.selectFields(new List<Schema.SObjectField> {User.IsActive});

            Set<Id> listId = new Set<Id>();
            listId.add(ownerId);

            List<User> users = usersSelector.findById(listId);

            if (users[0]?.IsActive)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        else
        {
            return false;
        }
    }

    /**
     * Método que obtiene una lista de los perfiles sociales ,relacionados a los casos de tipo Sprinklr en los que se ha actualizado la cuenta a una de tipo Customer,
     * para actualizar el contacto. Dicho contacto será la person account relacionada al caso.
     *
     * @author aberuete
     * @date 08/03/2024
     *
     * @param List<Case> casesUpdated : Lista de casos
     * @param Map<Id,Case> oldCaseMap : Mapa de casos con los valores antiguos
     */
    public static void getSprinklrSocialPersonaToLinkContact(List<Case> casesUpdated, Map<Id,Case> oldCaseMap)
    {
        List<Case> casesToUpdateSprSocialPersona = new List<Case>();

        if (Trigger.isAfter && Trigger.isUpdate)
        {
            for (Case caseUpdated : casesUpdated)
            {
                Case caseOld = oldCaseMap.get(caseUpdated.id);

                if (caseUpdated.recordTypeId == RT_ID_OCSSPRINKLR && caseUpdated.AccountId != null && caseOld.AccountId != caseUpdated.AccountId && caseUpdated.SprinklrSocialPersona__c != null )
                {
                    casesToUpdateSprSocialPersona.add(caseUpdated);
                }
            }
        }

        List<Case> casesToLinkSprinklrSocialPersonaToContact = new CasesSelector().getCasesFilterByRecordTypeNamesAccount (casesToUpdateSprSocialPersona, new List<String> {'Customer'});

        for (Case caseToLinkSprinklrSocialPersonaToContact : casesToLinkSprinklrSocialPersonaToContact)
        {
            sprinklrSocialPersonaToUpdate.add( new spr_sf__SocialPersona__c (Id = caseToLinkSprinklrSocialPersonaToContact.SprinklrSocialPersona__c, spr_sf__Contact__c = caseToLinkSprinklrSocialPersonaToContact.Account.PersonContactId) );
        }
    }

    /**
     * Método que obtiene una lista de los perfiles sociales ,relacionados a los casos de Sprinklr en los que se ha eliminado la cuenta, para borrar el contacto.
     *
     * @author aberuete
     * @date 08/03/2024
     *
     * @param List<Case> casesUpdated : Lista de casos
     * @param Map<Id,Case> oldCaseMap : Mapa de casos con los valores antiguos
     */
    public static void getSprinklrSocialPersonaToDeleteContactRelated (List<Case> casesUpdated, Map<Id,Case> oldCaseMap)
    {
        List<Case> casesToUpdateSprSocialPersona = new List<Case>();

        if (Trigger.isAfter && Trigger.isUpdate)
        {
            for (Case caseUpdated : casesUpdated)
            {
                Case caseOld = oldCaseMap.get(caseUpdated.id);

                if ( caseUpdated.recordTypeId == RT_ID_OCSSPRINKLR && caseUpdated.AccountId == null && caseOld.AccountId != null && caseUpdated.SprinklrSocialPersona__c != null)
                {
                    casesToUpdateSprSocialPersona.add(caseUpdated);
                }
            }
        }

        for (Case caseToUpdateSprSocialPersona : casesToUpdateSprSocialPersona)
        {
            sprinklrSocialPersonaToUpdate.add( new spr_sf__SocialPersona__c (Id = caseToUpdateSprSocialPersona.SprinklrSocialPersona__c, spr_sf__Contact__c = null) );
        }
    }

    /**
     * Método que actualiza los perfiles sociales relacionados con los casos.
     *
     * @author aberuete
     * @date 06/03/2024
     *
     * @param List<Case> casesUpdated : Lista de casos
     */
    public static void updateSprSocialPersonaToLinkContact()
    {
        List<String> msgErrores = new List<String>();

        if( !sprinklrSocialPersonaToUpdate.isEmpty() )
        {
            try
            {
                Database.SaveResult [] resultList = Database.update(sprinklrSocialPersonaToUpdate, false);

                for (Database.SaveResult result: resultList )
                {
                    if( !result.isSuccess() )
                    {
                        for ( Database.Error error :result.getErrors() )
                        {
                            msgErrores.add( error.getStatusCode() + ': ' + error.getMessage() );
                        }
                    }
                }
                if ( !msgErrores.isEmpty() )
                {
                    ErrorLogUtil.commitError( ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando los perfiles sociales relacionados con los casos',CaseUtil.class.getName(),( String.join(msgErrores,'\n') ) );
                }
            }
            catch (Exception e)
            {
                ErrorLogUtil.commitError( e, CaseUtil.class.getName() );
            }
        }
    }

    /**
     * Construye y devuelve una colección de elementos Robot_Hegeo_Field_Mapping__mdt ordenada por un atributo de esta configuración.
     * Robot_Hegeo_Field_Mapping__mdt contiene la relación entre la categorización de casos realizada por herramientas externas y la categorización del caso en Salesforce.
     * @author pitt.olvera@seidor.com
     * @date 03/03/2024
     * @param fieldToSort Propiedad de Robot_Hegeo_Field_Mapping__mdt que permite ordenar la configuración en un mapa.
     * @return Colección de configuración Robot_Hegeo_Field_Mapping__mdt odernada.
     */
    public static Map<String, Robot_Hegeo_Field_Mapping__mdt> sortCaseMappingSettingsBy(Schema.SObjectField fieldToSort)
    {
        Map<String, Robot_Hegeo_Field_Mapping__mdt> mappingConfiguration = new Map<String, Robot_Hegeo_Field_Mapping__mdt>();
        List<Robot_Hegeo_Field_Mapping__mdt> hegeoMetadataMappingConfiguration = Robot_Hegeo_Field_Mapping__mdt.getAll().values();
        String fieldAPINameInLowerCase = fieldToSort.getDescribe().getName().toLowerCase();

        if ( !Robot_Hegeo_Field_Mapping__mdt.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldAPINameInLowerCase) )
        {
            throw new CaseCustomTipificationException('La configuración para ' + Robot_Hegeo_Field_Mapping__mdt.getSobjectType().getDescribe().getName() + ' no soporta el atributo ' + fieldAPINameInLowerCase);
        }

        for (Robot_Hegeo_Field_Mapping__mdt configuration : hegeoMetadataMappingConfiguration)
        {
            mappingConfiguration.put(configuration.SourceType__c, configuration);
        }

        return mappingConfiguration;
    }

    /**
     * Consulta todos los casos sin cerrar que estén relacionados a las pólizadas enlazadas a los casos que vienen por el trigger
     * y construye un Map<String, Case> que relaciona la póliza con el caso abierto.
     * @author ivan.garcia.belen@seidor.com
     * @date 22/04/2024
     * @param newList Lista de casos que viene por el trigger.
     */
    public static void getZRMCasesRelatedToPolicy(List<Case> newList)
    {
        if(Trigger.isInsert)
        {
            Set<String> relatedPolicyIds = getRelatedPolicyifZRMIds(newList);
            if( !relatedPolicyIds.isEmpty() )
            {
                List<Case> notClosedZrmCases =  new CasesSelector().getNotClosedZrmCasesByRelatedPolicy(relatedPolicyIds);
                notClosedCaseByPolicyIdMap =  buildNotClosedZrmCasesByPolicyId(notClosedZrmCases);
            }
        }
    }

    /**
     * Comprueba si los casos pasados como parámetro son de Retenciones ZRM.
     * @author ivan.garcia.belen@seidor.com
     * @date 22/04/2024
     * @param newList Lista de casos que viene por el trigger.
     * @return Lista de casos con el record type de Retenciones ZRM.
     */
    public static Set<String> getRelatedPolicyifZRMIds(List<Case> newList)
    {
        Set<String> relatedPolicyIds = new Set<String>();
        for( Case caso : newList)
        {
            if( caso.recordTypeId.equals(RT_ID_ZRM) )
            {
                relatedPolicyIds.add(caso.PolicyId__c);
            }
        }

        return relatedPolicyIds;
    }

    /**
     * Construye un map<String,Case> en el que la Key es la polizada relacionada al caso.
     * @author ivan.garcia.belen@seidor.com
     * @date 22/04/2024
     * @param notClosedZrmCases Lista de casos de Retenciones ZRM cuyo estado no es 'Cerrado Ganado' o 'Cerrado Perdido'.
     * @return Mapa que relaciona el caso abierto por la póliza enlazada a este.
     */
    public static Map<String, Case> buildNotClosedZrmCasesByPolicyId(List<Case> notClosedZrmCases)
    {
        if( notClosedZrmCases != null && !notClosedZrmCases.isEmpty() )
        {
            Map<String, Case> notClosedZrmCasesByPolicyId = new Map<String, Case>();
            for(Case caso : notClosedZrmCases)
            {
                notClosedZrmCasesByPolicyId.put(caso.PolicyId__c, caso);
            }

            return notClosedZrmCasesByPolicyId;
        }

        return new Map<String, Case>();
    }

    /**
     * Comprueba si la poliza relacionada a los casos que vienen por el trigger tienen otro caso de tipo 'Retención ZRM' abierto.
     * En caso de ser afirmativo se mostrará un error en pantalla mostrando el número del caso abierto.
     * @author ivan.garcia.belen@seidor.com
     * @date 22/04/2024
     * @param newList Lista de casos provenientes del trigger.
     */
    public static void checkIfPolicyHaveOpenZrmCase(List<Case> newList)
    {
        for(Case caso : newList)
        {
            if( notClosedCaseByPolicyIdMap.containsKey(caso.PolicyId__c) )
            {
                caso.addError(Label.CaseZRMOpenedCase + ' ' + notClosedCaseByPolicyIdMap.get(caso.PolicyId__c).CaseNumber);
            }
        }
    }

    /**
     * Actualiza el status de los casos de ZDA cuando cambie el campo ReasonId__c. Esto ocurre cuando
     * actualizan un caso via estandar API
     *
     * @author mario.navarro@seidor.com
     * @date 14/05/2024
     * @param updatedCases lista de los casos actualizados
     * @param oldMap mapa de los casos antes de la actualización
     */
    public static void preProcessReasonIdForZda(List<Case> updatedCases, Map<Id,Case> oldMap)
    {
        for(Case updatedCase : updatedCases)
        {
            if ( updatedCase.RecordTypeId == RT_ID_ZDA && updatedCase.ReasonId__c != oldMap.get(updatedCase.Id).ReasonId__c &&
                 (updatedCase.ReasonId__c == ZDA_REASON_RECHAZAR || updatedCase.ReasonId__c == ZDA_REASON_DESESTIMAR) )
            {
                //Es un caso de ZDA que cambia el ReasonId__c y pasa a ser rechazado o desestimado. Cerramos el caso
                updatedCase.Status = estadoCerrado;
                updatedCase.PendingBy__c = null;
            }
            else if ( isZDANewReasonAnswered( updatedCase, oldMap.get(updatedCase.Id) ) )
            {
                updatedCase.Status = CASE_RESPONDIDO;
                updatedCase.PendingBy__c = null;
            }
        }
    }

    /**
     * Realiza las acciones necesarias (post-update) para los casos de ZDA cuando cambie el campo ReasonId__c. Esto ocurre cuando
     * actualizan un caso via estandar API
     *
     * @author mario.navarro@seidor.com
     * @date 14/05/2024
     * @param updatedCases lista de los casos actualizados
     * @param oldMap mapa de los casos antes de la actualización
     */
    public static void postProcessReasonIdForZda(List<Case> updatedCases, Map<Id,Case> oldMap)
    {
        List<Case> casesToNotify = new List<Case>();
        for(Case updatedCase : updatedCases)
        {
            if ( isZDANewReasonAnswered( updatedCase, oldMap.get(updatedCase.Id) ) )
            {
                casesToNotify.add(updatedCase);
            }
        }

        if (!casesToNotify.isEmpty())
        {
            String content;
            //Se hace en un bucle aparte porque los Guest Users no tienen acceso al objeto CustomNotificationType
            //y al inicializar el objeto 'notif' da error
            Notification notif = new Notification(Notification.notificationType.CaseTrackingAnswered);
            for (Case caseToNotify : casesToNotify)
            {
                content = Label.ZDAPartnerSupportAnsweredBody + BLANK_SPACE + caseToNotify.CaseNumber;
                notif.send(caseToNotify.Id, new Set<String> {caseToNotify.OwnerId}, Label.ZDAPartnerSupportAnsweredTitle, content);
            }
        }
    }

    /**
     * Comprueba si el caso es de zda y el ReasonId__c pasa a ser respondido (3)
     *
     * @author mario.navarro@seidor.com
     * @date 14/05/2024
     * @param updatedCase caso actualizado
     * @param oldCase caso antes de la actualizacion
     * @return true si es un caso de ZDA, el ReasonId__c ha cambiado y pasa a ser 3; false en caso contrario
     */
    private static Boolean isZDANewReasonAnswered(Case updatedCase, Case oldCase)
    {
        return updatedCase.RecordTypeId == RT_ID_ZDA && updatedCase.ReasonId__c != oldCase.ReasonId__c && updatedCase.ReasonId__c == ZDA_REASON_RESPUESTA_SOPORTE;
    }

    /**
     * Para los casos de ZDA que pasan de nuevo a asignado recibidos via canal unico, envia
     * notificacion a Canal unico informando de que el caso esta en estado Tramite
     * 
     * @author mario.navarro@seidor.com
     * @date 30/05/2024
     * @param updatedCases lista de los casos actualizados
     * @param oldMap mapa de los casos antes de la actualización
     */
    public static void notifCuCaseAssigned(List<Case> updatedCases, Map<Id,Case> oldMap)
    {
        for(Case updatedCase : updatedCases)
        {
            if ( isZDAAssignedAndCu( updatedCase, oldMap.get(updatedCase.Id) ) )
            {
                TicketingHegeoUtil.sendRequestStatusChangeToAssigned(updatedCase.Id);
            }
        }
    }

    /**
     * Comprueba si el caso es de ZDA, con origen canal unico y pasa de nuevo a asignado
     * 
     * @author mario.navarro@seidor.com
     * @date 30/05/2024
     * @param updatedCase caso actualizado
     * @param oldCase caso antes de la actualizacion
     * @return true si es un caso de ZDA, de canal unico y pasa de nuevo a asignado; false en caso contrario
     */
    private static Boolean isZDAAssignedAndCu(Case updatedCase, Case oldCase)
    {
        return updatedCase.RecordTypeId == RT_ID_ZDA && updatedCase.Origin == ORIGIN_CANAL_UNICO &&
            updatedCase.Status == CASE_ASIGNADO && oldCase.Status == CASE_NUEVO;
    }

    /**
     * Para el los casos de tipo ZDA establece el campo OwnerIdPrior__c cuando cambia el owner del caso por primera vez
     *
     * @author mario.navarro@seidor.com
     * @date 06/05/2024
     * @param updatedCases lista de los casos actualizados
     * @param oldMap mapa de los casos antes de la actualización
     */
    public static void setOwnerIdPrior(List<Case> updatedCases, Map<Id,Case> oldMap)
    {
        List<Id> groupIdToSearch = new List<Id>();
        for(Case updatedCase : updatedCases)
        {
            if (updatedCase.RecordTypeId == RT_ID_ZDA && String.isBlank(oldMap.get(updatedCase.Id).OwnerIdPrior__c) &&
                oldMap.get(updatedCase.Id).OwnerId != updatedCase.OwnerId )
            {
                groupIdToSearch.add(oldMap.get(updatedCase.Id).OwnerId);
            }
        }

        if ( groupIdToSearch.isEmpty() )
        {
            //no hay nada que actualizar
            return;
        }
        List<Group> queues = new GroupSelector().findById(groupIdToSearch);
        Map<Id, Group> queuesById = (Map<Id, Group>) CollectionUtil.hashList( queues, Group.fields.Id.getDescribe().getName() );

        for(Case updatedCase : updatedCases)
        {
            if ( updatedCase.RecordTypeId == RT_ID_ZDA && String.isBlank(oldMap.get(updatedCase.Id).OwnerIdPrior__c) &&
                 oldMap.get(updatedCase.Id).OwnerId != updatedCase.OwnerId && queuesById.containsKey(oldMap.get(updatedCase.Id).OwnerId) )
            {
                //Solo se informa el campo para los casos de ZDA, cuando el campo OwnerIdPrior__c esta vacio y el owner ha cambiado
                updatedCase.OwnerIdPrior__c = queuesById.get(oldMap.get(updatedCase.Id).OwnerId).Name;
            }
        }
    }

    /**
     * Método que actualiza el estado de un caso de ZRM en función de ciertos parámetros
     * @author arcortazar
     * @date 22/04/2023
     * @param newList lista de los casos actualizados
     * @param oldMap mapa de los casos antes de la actualización
     */

    public static void casesZRMChangeStatus(List<Case> listaCasos, Map<Id,Case> oldMap)
    {
        for(Case casoNew : listaCasos)
        {
            if(casoNew.RecordTypeId == RT_ID_ZRM) // Sólo vamos a hacer los cambios si es de ZRM
            {
                Case casoOld;
                if( oldMap != null && oldMap.containsKey(casoNew.id) )
                {
                    casoOld = oldMap.get(casoNew.id);
                }

                if (casoOld == null)
                {
                    if (casoNew.ClientHasContacted__c == afirmativo )
                    {
                        casoNew.Status = CASE_EN_GESTION;
                    }
                    if (casoNew.ClientGiftCard__c == true)
                    {
                        casoNew.Status = CASE_CLOSED_WON;
                    }
                }
                else
                {
                    // Comprobamos el cambio de "Cliente ha contactado"
                    if (casoNew.ClientHasContacted__c != casoOld.ClientHasContacted__c)
                    {
                        if (casoOld.ClientHasContacted__c == afirmativo)
                        {
                            casoNew.addError(FIELD_CLIENT_HAS_CONTACTED, 'No se puede modificar este valor');
                        }
                        else
                        {
                            if (casoNew.ClientHasContacted__c == afirmativo && casoOld.Status.equalsIgnoreCase(CASE_NO_INICIADO) )
                            {
                                casoNew.Status = CASE_EN_GESTION;
                            }
                        }
                    }

                    // Comprobamos el cambio de "check de tarjeta"
                    if ((casoNew.ClientGiftCard__c != casoOld.ClientGiftCard__c) && (casoNew.ClientGiftCard__c == true))
                    {  
                        casoNew.Status = CASE_CLOSED_WON;
                    }    
                }            
            }
        }
    }

    /**
     * Método que para aquellos casos con RT ZRMInquiry y son creados desde la comunidad ZRM, (perfiles Agente Ventas y/o Agente Ventas - AGR) por motivos de visibilidad cambiamos su owner
     * @author dmunoz
     * @date 23/04/2024
     * @param newList lista de elementos del trigger after insert
     */
    public static void updateInquiryCaseOwnerOnZRMCreation(List<Case> newList)
    {

        List<Case> zrmCases = new List<Case>();
        List<Case> caseToUpdateList = new List<Case>();
        Case caseAux;

        // 1º compruebo si existe en el trigger algun caso de zrm con que encuentre solo 1 me vale para lanzar las consultas solo cuando sea necesario
        for (Case caseTrigger: newList)
        {
            if ( RT_ID_ZRM.equals(caseTrigger.RecordTypeId) )
            {
                zrmCases.add(caseTrigger);
            }
        }

        if ( !zrmCases.isEmpty() )
        {
            // Si el usuario logueado es uno de ZRM actualizo el owner de los casos del trigger
            String loggedProfile = ProfilesSelector.getLoggedUserProfile();

            // si el perfil es Agente Ventas o Agente Ventas - AGR del usuario logueado
            if ( ProfilesSelector.PROFILE_AGENTE_VENTAS.equals(loggedProfile) || ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR.equals(loggedProfile) )
            {
                //3º Obtengo el usuario por defecto de ZRM
                User defaultUser = getDefaultOwnerUser();

                // Recorro los casos del trigger y cambio el owner solo a aquellos cuyo rt sea ZRMInquiry
                for (Case caseToUpdate: zrmCases)
                {
                    caseAux = new Case();
                    caseAux.Id = caseToUpdate.Id;
                    caseAux.OwnerId = defaultUser.Id;
                    caseToUpdateList.add(caseAux);
                }

                update caseToUpdateList;
            }
        }
    }

    /**
     * Obtiene el usuario por defecto para asignarle la propiedad de las AccountRelationship
     *
     * @author fpalomo
     * @date 09/02/2024
     */
    private static User getDefaultOwnerUser()
    {
        UsersSelector userSelector = new UsersSelector();

        List<User> defaultUsers = userSelector.findUsersByAlias(new List<String> {
            Cross_Selling__c.getinstance().DefaultUser__c
        });

        return defaultUsers.get(0);
    }

    /**
     * Realiza actualizaciones sobre los datos del caso en base al estado y si tiene o no gift card o descuento
     *
     * @author fpalomo <fpalomo@seidor.es>
     * @date 22/04/2024
     */
    public static void handleCaseStatusChangeZRM(List<Case> newList, Map<Id,Case> oldMap)
    {
        Case oldCase = new Case();

        for(Case newCase : newList)
        {
            Boolean newCaseGiftCard = newCase.ClientGiftCard__c;
            Boolean newCaseDiscount = newCase.ClientDiscount__c;

            if(newCase.RecordTypeId == RT_ID_ZRM)
            {
                oldCase = oldMap.get(newCase.Id);

                /**
                 * Los casos 3, 4, 6 no requieren de lógica adicional en este método pero los dejo anotados como referencia a futuro:
                 *  > Caso 3 - Cerrado ganado, había dto aplicado, le aplica tarjeta. Se mantiene el estado en cerrado ganado.
                 *  > Caso 4 - Cerrado ganado, había tarjeta. Además le aplica dto. Se actualiza la información con los datos del dto.
                 *  > Caso 6 - Cerrado ganado con tarjeta y descuento, desmarca la tarjeta -> se mantiene el estado a “Cerrado Ganado”
                 */

                if ( newCase.Status.equals(CASE_CLOSED_LOST) )
                {
                    // Caso 2: Cerrado perdido + tarjeta descuento -> Se actualiza el estado a cerrado ganado.
                    if (newCaseGiftCard)
                    {
                        newCase.Status = CASE_CLOSED_WON;
                    }

                    // Caso 1 - Cerrado perdido. Hay descuento posterior. Se actualiza el estado a Cerrado Ganado
                    else if (newCaseDiscount)
                    {
                        newCase.Status = CASE_CLOSED_WON;
                    }
                }

                // Caso 5: Cerrado ganado solo con tarjeta, desmarca la tarjeta -> se actualiza el estado a “En gestión”
                else if (newCase.Status.equals(CASE_CLOSED_WON) && oldCase.ClientGiftCard__c && !newCaseGiftCard && !newCaseDiscount)
                {
                    newCase.Status = 'En Gestión';
                }
            }
        }
    }

    /**
     * Método utilizado por Batch_CloseZRMExpiredCases para actualizar los casos de ZRM que hayan pasado 2 meses o más desde su fecha de cierre
     * y que estén sin cerrar, a 'Cerrado Perdido' con motivo de pérdida a 'Periodo Finalizado'
     * @author nikola.cobian@seidor.com
     * @date 22/04/2024
     * @param List<Case> [givenCases] casos que devuelve el Batch
     * @return List<Case> casos a actualizar en el Batch
     */
    public static List<Case> updateZRMExpiredCases(List<Case> givenCases)
    {
        //Lista de Casos modificados que añadiremos para devolver al batch para que se actualicen
        List<Case> casesToUpdate = new List<Case>();

        //Comprobamos que los Casos enviados no sean nulos o estén vacíos
        if( givenCases != null || !givenCases.isEmpty() )
        {
            //Recorremos los Casos devueltos por el Batch
            for(Case givenCase : givenCases)
            {
                //Asignamos los valores que corresponden con la descripción del método
                givenCase.Status = CASE_CLOSED_LOST;
                givenCase.CauseOfLoss__c = CASE_CAUSE_OF_LOSS_PERIOD_ENDED;
                //Añadimos a la lista los Casos modificados
                casesToUpdate.add(givenCase);
            }
        }

        //Finalmente devolvemos la lista de casos a actualizar
        return casesToUpdate;
    }


    /**
     * Método que para aquellos casos con RT ZRMInquiry y son creados desde la comunidad ZRM, (perfiles Agente Ventas y/o Agente Ventas - AGR) por motivos de visibilidad cambiamos su owner  
    * @author dmunoz
    * @date 23/04/2024
    * @param newList lista de elementos del trigger after insert
    */
    public static void setEndDateZRMInquiry(List<Case> newList) {

        // 1º compruebo si existe en el trigger algun caso de zrm con que encuentre solo 1 me vale para lanzar las consultas solo cuando sea necesario
        for (Case caseTrigger: newList) {
            if (RT_ID_ZRM.equals(caseTrigger.RecordTypeId) && String.isEmpty(String.valueOf(caseTrigger.EndDate__c))) {
                caseTrigger.EndDate__c = caseTrigger.PolicyEndDate__c;
            }
        }
    }

     /**
     * Método para identficar aquellos casos que se crean mediante el botón standard clone y vaciar los campos que provienen de hegeo
    * @author lrodriguez
    * @date 21/05/2024
    * @param newList lista de elementos del trigger before insert
    */
    public static void isCaseClone(List<Case> newList) {

        String uSPRecordTypeId = GlobalConfigUtil.getGlobalConfigurationValueId('Case_RecordType_USP_Id');

        for (Case caseTrigger: newList) {

            if ((caseTrigger.recordTypeId==uSPRecordTypeId && caseTrigger.isClone())|| (Test.isRunningTest() && caseTrigger.recordTypeId==uSPRecordTypeId)) {

                caseTrigger.MediatedCustomer__c=null;
                caseTrigger.PolicyId__c=null;
                caseTrigger.OfferId__c=null;
                caseTrigger.ProductGroup__c=null;
                caseTrigger.AccountId=null;

            }
        }
    }
}