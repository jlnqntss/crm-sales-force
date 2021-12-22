/**
 * Clase para generar los escenarios de pruebas de los test para el proyecto SDM
 **
 * @author nts
 * @date 05/07/2021
 */
@isTest
public class TestDataFactorySDM
{
    public static final String ACCOUNT_LEGAL_ENTITY = '001';
    public static final String AGRUPATION_CIF = '1111';

    public static final String TERRITORY_EMAIL = 'territorymanager{0}@invalid.com';
    public static final String BUSINESS_EMAIL = 'rn{0}@invalid.com';

    public static final String MAINEMAIL_TEXT = 'Cto Pcipal';
    public static final String MAINEMAIL_EMAIL = 'cto.principal{0}@invalid.com';
    public static final String CONTACT_FIELD = 'Email';

    public static final String RN_FIELD = AccountsSelector.SDM_RN_FIELD;
    public static final String RN_NAME = 'ZONA ZURICH CENTRALIZADOS';

    public static final String PLAN_PERMSET = SettingsSDM.PERMSET_COMERCIAL_PLAN;
    public static final String RN_PROFILE = SettingsSDM.PROFILE_RN;
    public static final String RN_ROL = SettingsSDM.SF_ROLE_RN_DEVNAME;
    public static final String DT_PROFILE = SettingsSDM.PROFILE_DT;
    public static final String DT_ROL = SettingsSDM.SF_ROLE_DT_DEVNAME;

    public static final String PLAN_1_NAME = 'Plan 1';

    /**
     * Metodo que crea datos de configuracion de prueba para los Account Team Members (ATM)
     *
     * @author nts (agonzalezisasi)
     * @date 02/07/2021
     */
    public static List<SDMAccountTeamRole__mdt> getSDMSettingsATM(string role, string field)
    {
        List<SDMAccountTeamRole__mdt> settings = new List<SDMAccountTeamRole__mdt>();
        settings.add(new SDMAccountTeamRole__mdt(
            Label= 'testATM',
            DeveloperName= 'testATM',
            Role__c= role,
            IntermediaryField__c= field,
            Status__c= 'Active'
        ));
        return settings;
    }

    /**
     * Metodo que crea datos de configuracion de prueba para los Account Contact Relation (ACR)
     *
     * @author nts (agonzalezisasi)
     * @date 02/07/2021
     */
    public static List<SDMAccountContactRelation__mdt> getSDMSettingsACR(string role, string field, string text)
    {
        List<SDMAccountContactRelation__mdt> settings = new List<SDMAccountContactRelation__mdt>();

        settings.add(
            new SDMAccountContactRelation__mdt(
                Label= 'testATM',
                DeveloperName= 'testATM',
                Role__c= role,
                IntermediaryField__c= field,
                NameText__c= text
            )
        );

        return settings;
    }

    /**
     * Metodo que genera un objeto de tipo configuracion del indicador del plan comercial
     */
    public static SDMCommercialPlan__mdt generateSDMSettingsPlan(String indicator, String calcType, string firstField, string secondField)
    {
        return new SDMCommercialPlan__mdt(
                Label= 'testPlanSum',
                DeveloperName= 'testPlanSum',
                Indicator__c= indicator,
                CalculationType__c= calcType,
                FirstField__c= firstField,
                SecondField__c= secondField
        );
    }

    /**
     * Metodo que crea los datos de prueba para el mantenimiento de mediadores
     */
    public static void intermediarySetupData()
    {
        // Creacion de las Agrupaciones de Mediadores
        List<Account> agrupations = TestDataFactory.generateAccounts(
            ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_AGRUPATION, 1
        );
        agrupations[0].NationalId__c = AGRUPATION_CIF;
        insert agrupations;

        // Creacion de los Mediadores
        List<Account> intermediaries = TestDataFactory.generateAccounts(ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_INTERMEDIARY, 10);
        for( Integer i=0; i<intermediaries.size(); i++ ) {
            // Para la agrupacion de mediadores
            intermediaries[i].NationalId__c = AGRUPATION_CIF;
            // Para el equipo de cuentas
            intermediaries[i].put(AccountsSelector.SDM_DT_EMAIL_FIELD, String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)}));
            intermediaries[i].Status__c = '001';
            // Para la relacion de contactos
            intermediaries[i].put(AccountsSelector.SDM_MAINEMAIL_FIELD, String.format(MAINEMAIL_EMAIL, new List<String>{String.valueOf(i)}));
        }
        insert intermediaries;

        // Creacion de los usuarios para el equipo de cuentas
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        System.assertEquals(1, profiles.size(), 'El perfil SDM RN deberia existir');
        List<User> users = TestDataFactory.generateUsersByProfile(profiles[0].Id, 10);
        for( Integer i=0; i<users.size(); i++ ) {
            users[i].Email = String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)});
        }
        insert users;

        // 4 Contactos para los 4 primeros Mediadores, creara ACRs sin Rol
        List<Account> intermediariesToCreateContact = new List<Account>();
        intermediariesToCreateContact.add(intermediaries[0]);
        intermediariesToCreateContact.add(intermediaries[1]);
        intermediariesToCreateContact.add(intermediaries[2]);
        intermediariesToCreateContact.add(intermediaries[3]);

        // Creacion de los contactos para el proceso de relacion de contactos
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediariesToCreateContact, ContactsSelector.RT_NAME_CONTACT, 1);
        for( Integer i=0; i<4; i++ ) {
            contacts[i].Email = String.format(MAINEMAIL_EMAIL, new List<String>{String.valueOf(i)});
        }
        insert contacts;

        // Asignamos el rol a las ACRs creadas al insertar los contactos
        List<AccountContactRelation> acrs = [SELECT Id, Roles FROM AccountContactRelation WHERE ContactId IN :contacts];
        System.assertEquals(4, acrs.size(), 'Deberian existir 4 ACRs');
        for(AccountContactRelation acr: acrs) {
            acr.Roles = 'Other rol';
        }
        update acrs;
    }

    /**
     * Metodo que crea los datos de prueba para el calculo del kpi de los planes comerciales
     */
    public static void planComercialSetupData()
    {
        // Creacion de las Agrupaciones de Mediadores
        List<Account> agrupations = TestDataFactory.generateAccounts(
            ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_AGRUPATION, 1
        );
        agrupations[0].NationalId__c = AGRUPATION_CIF;
        insert agrupations;

        // Creacion de los Mediadores (3)
        List<Account> intermediaries = TestDataFactory.generateAccounts(
            ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_INTERMEDIARY, 3
        );
        for( Integer i=0; i<intermediaries.size(); i++ ) {
            // Para la agrupacion de mediadores
            intermediaries[i].NationalId__c = AGRUPATION_CIF;
            // Para el equipo de cuentas
            intermediaries[i].put(AccountsSelector.SDM_DT_EMAIL_FIELD, String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)}));
            // Lo marcamos como activo (valores 001 o 002)
            intermediaries[i].Status__c = '001';
        }
        insert intermediaries;

        // Creacion de los usuarios para el equipo de cuentas (3)
        User thisUser = new User(Id= UserInfo.getUserId());
        System.runAs (thisUser) {
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :RN_PROFILE];
            System.assertEquals(1, profiles.size(), 'El perfil SDM_RN deberia existir');

            List<User> users = TestDataFactory.generateUsersByProfile(profiles[0].Id, 3);            
            for( Integer i=0; i<users.size(); i++ ) {
                users[i].Email = String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)});
            }
            insert users;

            List<PermissionSet> permSetPlan = [SELECT Id FROM PermissionSet WHERE name = :PLAN_PERMSET];
            System.assertEquals(1, permSetPlan.size(), 'Deberia haber 1 permission set');

            List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
            // Para cada usuario
            for( Integer i=0; i<users.size(); i++ ) {
                newAssignments.add(new PermissionSetAssignment(
                    PermissionSetId = permSetPlan[0].Id,
                    AssigneeId = users[i].Id
                ));
            }
            insert newAssignments;
        }

        // Asignacion de la agrupacion y creacion de los equipos de cuentas
        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD
        );
        // asignacion de la agrupacion
        sdm.assignIntermediaryAgrupation(intermediaries);
        // creacion del equipo de cuenta
        sdm.assignIntermediaryAccountTeam(intermediaries);
        // asignacion del equipo de cuenta tambien a la agrupacion 
        sdm.assignAgrupationAccountTeam(sdm.listAgrupationCIFs);
        
        // comprobamos que ha ido todo bien
        String soql = String.format(
            'SELECT Id FROM Account WHERE Id IN :intermediaries AND ParentId != null AND {0} != null', 
            new List<String> {AccountsSelector.SDM_DT_EMAIL_FIELD});
        List<Account> checkIntermediary = Database.query(soql);
        System.assertEquals(false, checkIntermediary.isEmpty(), 'Deberia haber mediadores con agrupacion y rol');

        // Debido a lo que parece un bug en el deploy, si el valor "Particulares" del SegmentoCliente__c no existe
        // como valor de picklist, falla uno de los test. Por tanto este valor tiene que existir en la picklist
        // El fallo es que los campos formula EstructuraDetalle__c y EstructuraUnificada__c no se calculan bien
        Boolean existValue = false;
        Schema.DescribeFieldResult fieldResult = KPI__c.SegmentoCliente__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : ple) {
            if( p.getValue() == 'Particulares' ) existValue = true;
        }
        System.assertEquals(true, existValue, 'El valor "Particulares" no existe en la picklist KPI__c.SegmentoCliente__c');
        // Generacion de los KPIs ---------------------------------------------
        List<KPI__c> kpisAll = new List<KPI__c>();
        List<KPI__c> kpis = TestDataFactorySDM.generateKPIs(intermediaries, 2);
        System.assertEquals(6, kpis.size(), 'Se deberian haber generado 6 KPIs');
        // Primer mediador => suma [10=10] El segundo KPI no se considera en el filtrado
        kpis[0].PN__c = 10;
        kpis[0].ProductGroup__c = 'AUTOS';
        kpis[1].PN__c = 15;
        kpis[1].ProductGroup__c = 'HOGAR';
        // Segundo mediador => ratio [20/50=0,4]
        kpis[2].TotalLoad__c = 12;
        kpis[2].Income__c = 20;
        kpis[2].ProductGroup__c = 'AUTOS';
        kpis[3].TotalLoad__c = 8;
        kpis[3].Income__c = 30;
        kpis[3].ProductGroup__c = 'ACCIDENTES';
        // Tercer mediador => crecimiento [(140/80)-1=0,75]
        kpis[4].PoliciesPN__c = 100;
        kpis[4].PA_PoliciesPN__c = 35;
        kpis[5].PoliciesPN__c = 40;
        kpis[5].PA_PoliciesPN__c = 45;
        kpisAll.addAll(kpis);
        // Añadimos un kpi que este fuera de la fecha de los planes (01/09/2021 a 30/09/2021). No deberia contar
        kpis = TestDataFactorySDM.generateKPIs(new List<Account>{intermediaries[0]}, 1);
        kpis[0].PN__c = 13;
        kpis[0].ProductGroup__c = 'AUTOS';
        kpis[0].CalcYear__c = '2021'; // mismo que los planes
        kpis[0].CalcMonth__c = '10'; // no entra en los planes (no deberia contar el kpi)
        kpisAll.addAll(kpis);
        // Añadimos un kpi Anual. No deberia contar para los mensuales
        kpis = TestDataFactorySDM.generateKPIs(new List<Account>{intermediaries[0]}, 2);
        kpis[0].PN__c = 13;
        kpis[0].Temporalidad__c = KPIsSelector.TEMPORALIDAD_YTD;
        kpis[0].CalcMonth__c = '8'; // aunque no mes de ejecucion (9), si deberia contar por ser ultimo mes disponible
        kpis[1].PN__c = 5;
        kpis[1].Temporalidad__c = KPIsSelector.TEMPORALIDAD_YTD;
        kpis[1].CalcMonth__c = '7'; // aunque es anual, es foto anterior y no deberia contar
        kpisAll.addAll(kpis);
        
        insert kpisAll;

        // Recuperamos los equipos de cuenta para que los usuarios de los mediadores
        // creen los planes
        List<AccountTeamMember> atms = [
            SELECT UserId, AccountId
            FROM AccountTeamMember
            WHERE AccountId IN :intermediaries
        ];
        System.assertEquals(3, atms.size(), 'Deberia haber 3 registros de ATMs');
        Map<Id, Id> mapATMs = new Map<Id, Id>();
        for(AccountTeamMember atm: atms) {
            mapATMs.put(atm.AccountId, atm.UserId);
        }

        // Generacion de los planes comerciales -------------------------------
        List<PlanComercial__c> plans = TestDataFactorySDM.generatePlans(intermediaries, 1);
        
        User userPlan = new User(
            Id= mapATMs.get(plans[0].Intermediary__c)
        );
        System.runAs(userPlan) {
            // Plan del primer mediador
            plans[0].Name = PLAN_1_NAME;
            plans[0].AssignedTo__c = userPlan.Id;
            plans[0].Indicator__c = 'PN';
            plans[0].Intermediary__c = agrupations[0].Id;
            plans[0].Product__c = 'Autos';
            insert plans[0];
        }
        
        // Plan del segundo mediador
        userPlan = new User(
            Id= mapATMs.get(plans[1].Intermediary__c)
        );
        System.runAs(userPlan) {
            plans[1].Name = 'Plan 2';
            plans[1].AssignedTo__c = userPlan.Id;
            plans[1].Indicator__c = 'Ratio_Claim';
            plans[1].Product__c = PlanComercialSDM.ALL_VALUE;
            insert plans[1];
        }

        // Plan del tercer mediador
        userPlan = new User(
            Id= mapATMs.get(plans[2].Intermediary__c)
        );
        System.runAs(userPlan) {
            plans[2].Name = 'Plan 3';
            plans[2].AssignedTo__c = userPlan.Id;
            plans[2].Indicator__c = 'Ratio_PoliciesPNIncreas';
            plans[2].Intermediary__c = null;
            insert plans[2];
        }

        // Creacion de un plan anual para el mediador del primer plan
        plans = TestDataFactorySDM.generatePlans(new List<Account>{intermediaries[0]}, 1);
        plans[0].Name = 'Plan 4';
        plans[0].AccumulateType__c= PlanComercialSelector.ACCUMULATE_TYPE_YRD;
        plans[0].StartDate__c= Date.newInstance(2021, 1, 1);
        plans[0].EndDate__c= Date.newInstance(2021, 12, 31);
        userPlan = new User(
            Id= mapATMs.get(intermediaries[0].Id)
        );
        System.runAs(userPlan) {
            plans[0].AssignedTo__c = userPlan.Id;
            insert plans[0];
        }
    }

    /**
     * Metodo que crea los datos de prueba para la gestion de los planes comerciales anuales
     */
    public static void anualPlanSetupData(Integer actualYear, String directorEmailField)
    {
        // 1. Creacion de usuarios DT y RN
        List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE name = :PLAN_PERMSET];
        System.assertEquals(1, permSet.size(), 'Deberia haber un permission set SDM de plan comercial');
        Id permSetPlanId = permSet[0].Id;

        // RN: Perfil y PermissionSetGroup
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :RN_PROFILE];
        System.assertEquals(1, profiles.size(), 'El perfil SDM RN deberia existir');
        Id profileRNId = profiles[0].Id;
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Developername = :RN_ROL];
        System.assertEquals(1, roles.size(), 'El rol SDMUser deberia existir');
        Id rnRolId = roles[0].Id;

        // Usuario DT: Perfil y PermissionSetGroup
        profiles = [SELECT Id FROM Profile WHERE Name = :DT_PROFILE];
        System.assertEquals(1, profiles.size(), 'El perfil SDM Director deberia existir');
        Id profileDTId = profiles[0].Id;
        roles = [SELECT Id FROM UserRole WHERE Developername = :DT_ROL];
        System.assertEquals(1, roles.size(), 'El rol SDM_DT deberia existir');
        Id dtRolId = roles[0].Id;

        String dtEmail = String.format(TestDataFactorySDM.TERRITORY_EMAIL, new List<String>{String.valueOf(0)});
        String rnEmail = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(0)});

        // Creacion de usuarios en entorno aparte
        User dtUser;
        User rnUser;
        User thisUser = new user(Id= UserInfo.getUserId());
        System.runAs(thisUser) {
            List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();

            // Creacion de los usuarios
            List<User> users = TestDataFactory.generateUsersByProfile(profileDTId, 2);
            // Usuario DT
            users[0].Email = dtEmail;
            users[0].UserRoleId = dtRolId;
            // Usuario RN
            users[1].ProfileId = profileRNId;
            users[1].Email = rnEmail;
            users[1].UserRoleId = rnRolId;
            insert users;

            // Asignacion de permissionsetgroups
            newAssignments.add(new PermissionSetAssignment(
                PermissionSetId = permSetPlanId,
                AssigneeId = users[0].Id
            ));
            newAssignments.add(new PermissionSetAssignment(
                PermissionSetId = permSetPlanId,
                AssigneeId = users[1].Id
            ));
            insert newAssignments;

            dtUser = users[0];
            rnUser = users[1];
        }

        System.assertNotEquals(null, dtUser?.Id, 'El usuario DT deberia existir y tener Id valido');
        System.assertNotEquals(null, rnUser?.Id, 'El usuario RN deberia existir y tener Id valido');
        

        // 2. Creacion de los Mediadores (3) del RN
        List<Account> intermediaries = TestDataFactory.generateAccounts(
            TestDataFactorySDM.ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_INTERMEDIARY, 3
        );
        // Los mediadores tendran todos el mismo DT y el mismo RN
        for( Integer i=0; i<intermediaries.size(); i++ ) {
            // Para la agrupacion de mediadores
            intermediaries[i].NationalId__c = TestDataFactorySDM.AGRUPATION_CIF;
            // Para el equipo de cuentas
            intermediaries[i].put(directorEmailField, dtEmail);
            intermediaries[i].put(AccountsSelector.SDM_RN_EMAIL_FIELD, rnEmail);

            // Lo marcamos como activo (valores 001 o 002)
            intermediaries[i].Status__c = '001';
        }
        insert intermediaries;

        Test.startTest();
        // 3. Ejecutamos el batch para tener el equipo de cuentas (ATM)
        IntermediarySDMBatch batch = new IntermediarySDMBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        // 3 mediadores por 2 usuarios (DT y RN) = 6 ATMs
        System.assertEquals(6, atms.size(), 'Deberia haber 6 ATMs para los mediadores.');

        // 4. Creamos los planes
        Id rtPlanAnualId = (new PlanComercialSelector()).rtPlanAnualId;

        List<PlanComercial__c> dtPlans = TestDataFactorySDM.generatePlansWithoutIntermediary(1);
        // Plan DT
        dtPlans[0].Name = PLAN_1_NAME;
        dtPlans[0].StartDate__c = Date.newInstance(actualYear, 1, 1);
        dtPlans[0].EndDate__c = Date.newInstance(actualYear, 12, 31);
        dtPlans[0].AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
        dtPlans[0].AssignedTo__c = dtUser.Id;
        dtPlans[0].TargetKPINumber__c = 5;
        dtPlans[0].RecordTypeId = rtPlanAnualId;
        System.runAs(dtUser) {
            insert dtPlans;
        }

        // Plan RN
        List<PlanComercial__c> rnPlans = TestDataFactorySDM.generatePlansWithoutIntermediary(1);        
        rnPlans[0].Name = PLAN_1_NAME;
        rnPlans[0].StartDate__c = Date.newInstance(actualYear, 1, 1);
        rnPlans[0].EndDate__c = Date.newInstance(actualYear, 12, 31);
        rnPlans[0].AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
        rnPlans[0].AssignedTo__c = rnUser.Id;
        rnPlans[0].ParentPlan__c = dtPlans[0].Id;
        rnPlans[0].TargetKPINumber__c = 5;
        rnPlans[0].RecordTypeId = rtPlanAnualId;
        System.runAs(dtUser) {
            insert rnPlans;
        }

        // Planes para mediadores
        List<PlanComercial__c> intermediaryPlans = TestDataFactorySDM.generatePlans(intermediaries, 1);
        for(PlanComercial__c plan: intermediaryPlans) {
            plan.Name = PLAN_1_NAME;
            plan.StartDate__c = Date.newInstance(actualYear, 1, 1);
            plan.EndDate__c = Date.newInstance(actualYear, 12, 31);
            plan.AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
            plan.AssignedTo__c = rnUser.Id;
            plan.ParentPlan__c = rnPlans[0].Id;
            plan.TargetKPINumber__c = 1;
            plan.RecordTypeId = rtPlanAnualId;
        }
        System.runAs(rnUser) {
            insert intermediaryPlans;
        }
    }

    /**
     * Metodo que genera KPIs para unos mediadores
     */
    public static List<KPI__c> generateKPIs(List<Account> intermediaries, Integer num)
    {
        List<KPI__c> kpis = new List<KPI__c>();

        for(Account a: intermediaries) {
            for(Integer i=0;i<num;i++) {
                KPI__c kpi = new KPI__c(
                    Intermediary__c= a.Id,
                    ProductGroup__c= 'AUTOS',
                    SegmentoCliente__c= 'Particulares',
                    Temporalidad__c= KPIsSelector.TEMPORALIDAD_MONTH,
                    CalcYear__c= '2021',
                    CalcMonth__c= '9'
                );

                kpis.add(kpi);
            }
        }

        return kpis;
    }

    /**
     * Metodo que genera Planes comerciales para unos mediadores
     */
    public static List<PlanComercial__c> generatePlans(List<Account> intermediaries, Integer num)
    {
        List<PlanComercial__c> plans = new List<PlanComercial__c>();

        for(Account a: intermediaries) {
            for(Integer i=0;i<num;i++) {
                PlanComercial__c plan = new PlanComercial__c(
                    StartDate__c= Date.newInstance(2021, 9, 1),
                    EndDate__c= Date.newInstance(2021, 9, 30),
                    SendNotifications__c= PlancomercialSelector.SEND_NOTIFICATION_ABOVE_THRESHOLD,
                    Intermediary__c= a.Id,
                    AssignedTo__c= UserInfo.getUserId(),
                    Actual_KPI__c= null,
                    Indicator__c= 'PN',
                    Product__c= 'Autos',
                    Segment__c= 'Particulares',
                    AccumulateType__c= PlanComercialSelector.ACCUMULATE_TYPE_MONTH
                );

                plans.add(plan);
            }
        }

        return plans;
    }

    /**
     * Metodo que genera Planes comerciales sin mediadores
     */
    public static List<PlanComercial__c> generatePlansWithoutIntermediary(Integer num)
    {
        List<PlanComercial__c> plans = new List<PlanComercial__c>();

        for(Integer i=0;i<num;i++) {
            PlanComercial__c plan = new PlanComercial__c(
                StartDate__c= Date.newInstance(2021, 9, 1),
                EndDate__c= Date.newInstance(2021, 9, 30),
                SendNotifications__c= PlancomercialSelector.SEND_NOTIFICATION_ABOVE_THRESHOLD,
                Intermediary__c= null,
                Actual_KPI__c= null,
                Indicator__c= 'PN',
                Product__c= 'Autos',
                Segment__c= 'Particulares',
                TargetKPINumber__c = 5,
                AccumulateType__c= PlanComercialSelector.ACCUMULATE_TYPE_MONTH
            );

            plans.add(plan);
        }

        return plans;
    }
}