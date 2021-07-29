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

    public static final String TERRITORY_ROL = 'TerritoryManager';
    public static final String TERRITORY_EMAIL = 'territorymanager{0}@invalid.com';
    public static final String TERRITORY_FIELD = 'TerritoryManagerEmail__c';
    public static final String BUSINESS_ROL = 'BusinessManager';

    public static final String MAINEMAIL_ROL = 'Principal';
    public static final String MAINEMAIL_FIELD = 'MainEmail__c';
    public static final String MAINEMAIL_TEXT = 'Cto Pcipal';
    public static final String MAINEMAIL_EMAIL = 'cto.principal{0}@invalid.com';
    public static final String CONTACT_FIELD = 'Email';

    public static final String RN_FIELD = 'TerritorialDirection__c';
    public static final String RN_NAME = 'ZONA ZURICH CENTRALIZADOS';
    
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
    public static void IntermediarySetupData()
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
            intermediaries[i].put(TERRITORY_FIELD, String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)}));
            intermediaries[i].IntermediaryStatus__c = 'Active';
            // Para la relacion de contactos
            intermediaries[i].put(MAINEMAIL_FIELD, String.format(MAINEMAIL_EMAIL, new List<String>{String.valueOf(i)}));
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
    public static void PlanComercialSetupData()
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
            intermediaries[i].put(TERRITORY_FIELD, String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)}));
            intermediaries[i].IntermediaryStatus__c = 'Active';
        }
        insert intermediaries;

        // Creacion de los usuarios para el equipo de cuentas (3)
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        System.assertEquals(1, profiles.size(), 'El perfil SDM RN deberia existir');
        List<User> users = TestDataFactory.generateUsersByProfile(profiles[0].Id, 3);
        for( Integer i=0; i<users.size(); i++ ) {
            users[i].Email = String.format(TERRITORY_EMAIL, new List<String>{String.valueOf(i)});
        }
        insert users;

        // Asignacion de la agrupacion y creacion de los equipos de cuentas
        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            TestDataFactorySDM.TERRITORY_ROL, TestDataFactorySDM.TERRITORY_FIELD
        );
        // asignacion de la agrupacion
        sdm.assignIntermediaryAgrupation(intermediaries);
        // creacion del equipo de cuenta
        sdm.assignIntermediaryAccountTeam(intermediaries);
        // comprobamos que ha ido todo bien
        String soql = String.format(
            'SELECT Id FROM Account WHERE Id IN :intermediaries AND ParentId != null AND {0} != null', 
            new List<String> {TestDataFactorySDM.TERRITORY_FIELD});
        List<Account> checkIntermediary = Database.query(soql);
        System.assertEquals(false, checkIntermediary.isEmpty(), 'Deberia haber mediadores con agrupacion y rol');

        // Generacion de los KPIs ---------------------------------------------
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
        insert kpis;

        // Recuperamos los equipos de cuenta para que los usuarios de los mediadores
        // creen los planes
        List<AccountTeamMember> atms = [
            SELECT UserId, AccountId
            FROM AccountTeamMember
            WHERE AccountId IN :intermediaries
        ];
        System.assertEquals(3, atms.size(), 'Deberia haber 3 registros de ATMs');
        Map<Id, AccountTeamMember> mapATMs = new Map<Id, AccountTeamMember>();
        for(AccountTeamMember atm: atms) {
            mapATMs.put(atm.AccountId, atm);
        }

        // Generacion de los planes comerciales -------------------------------
        List<PlanComercial__c> plans = TestDataFactorySDM.generatePlans(intermediaries, 1);
        System.assertEquals(3, plans.size(), 'Se deberian haber generado 3 planes');
        User userPlan = new User(
            Id= mapATMs.get(plans[0].Intermediary__c).UserId
        );
        // System.runAs(userPlan) {
            // Plan del primer mediador
            plans[0].AssignedTo__c = userPlan.Id;
            plans[0].Indicator__c = 'PN';
            plans[0].Intermediary__c = agrupations[0].Id;
            plans[0].Product__c = 'Autos';
            // insert plans[0];
        // }
        
        // Plan del segundo mediador
        userPlan = new User(
            Id= mapATMs.get(plans[1].Intermediary__c).UserId
        );
        // System.runAs(userPlan) {
            plans[1].AssignedTo__c = userPlan.Id;
            plans[1].Indicator__c = 'Ratio_Claim';
            plans[1].Product__c = PlanComercialSDM.ALL_VALUE;
            // insert plans[1];
        // }

        // Plan del tercer mediador
        userPlan = new User(
            Id= mapATMs.get(plans[2].Intermediary__c).UserId
        );
        // System.runAs(userPlan) {
            plans[2].AssignedTo__c = userPlan.Id;
            plans[2].Indicator__c = 'Ratio_PoliciesPNIncreas';
            // insert plans[2];
        // }
        insert plans;
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
                    Temporalidad__c= 'Mensual'
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
                    StartDate__c= Date.today().addDays(-5),
                    EndDate__c= Date.today().addDays(30),
                    SendNotifications__c= '01',
                    Intermediary__c= a.Id,
                    Actual_KPI__c= null,
                    Indicator__c= 'PN',
                    Product__c= 'Autos',
                    Segment__c= 'Particulares',
                    AccumulateType__c= 'Mensual'
                );

                plans.add(plan);
            }
        }

        return plans;
    }
}