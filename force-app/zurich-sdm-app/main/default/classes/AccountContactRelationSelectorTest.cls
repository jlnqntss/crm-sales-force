/**
 * Clase de test para la clase selectora del sobject AccountContactRelation
 * 
 * @author nts (agonzalezisasi)
 * @date 09/11/2021
 */
@isTest
public class AccountContactRelationSelectorTest 
{
    public static final Integer NUM_INTERMEDIARIES = 5;

    @TestSetup
    public static void createScenario()
    {
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(
            '001', AccountsSelector.RT_NAME_INTERMEDIARY, NUM_INTERMEDIARIES
        );
        for(Integer i=0; i<NUM_INTERMEDIARIES; i++ ) {
            intermediaryAccounts[i].put(
                AccountsSelector.SDM_MAINEMAIL_FIELD, 
                String.format(TestDataFactorySDM.MAINEMAIL_EMAIL, new List<String>{String.valueOf(i)})
            );
        }
        insert intermediaryAccounts;

        // Creacion de los contactos para el proceso de relacion de contactos
        // La insercion del contacto ya genera relaciones con las cuentas por lo que no hay que crear los ACRs
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(
            intermediaryAccounts, 
            ContactsSelector.RT_NAME_CONTACT, 
            1
        );
        for( Integer i=0; i<NUM_INTERMEDIARIES; i++ ) {
            contacts[i].Email = String.format(
                TestDataFactorySDM.MAINEMAIL_EMAIL, new List<String>{String.valueOf(i)}
            );
        }
        insert contacts;
    }

    /**
     * Test del metodo que recupera los ATMs por los ids de usuario
     */
    @isTest
    static void findByIntermediary()
    {
        List<Account> intermediaries = [SELECT Id FROM Account];

        Test.startTest();
        List<AccountContactRelation> acrs = (new AccountContactRelationSelector()).findByIntermediaries(intermediaries);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, acrs, 'Deberia haber alguna relacion cuenta contacto');
        System.assertEquals(NUM_INTERMEDIARIES, acrs.size(), 'Deberia haber ' + NUM_INTERMEDIARIES + ' relaciones cuenta contacto');
    }

}
