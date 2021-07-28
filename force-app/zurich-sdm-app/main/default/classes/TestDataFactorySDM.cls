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
}