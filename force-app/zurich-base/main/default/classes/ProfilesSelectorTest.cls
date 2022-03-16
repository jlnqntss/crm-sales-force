@IsTest
public with sharing class ProfilesSelectorTest {
    
    @isTest
    public static void test_getAuthorizedProfiles_OK()
    {
        List<String> nombresPerfiles = new List<String>();
        nombresPerfiles.add('System Administrator');

        Test.startTest();
        Map<Id, Profile> perfiles = ProfilesSelector.getProfilesByName(nombresPerfiles);
        Test.stopTest();

        System.assertEquals(1, perfiles.values().size(), 'Ha debido encontrar el perfil indicado');
    }

    @isTest
    public static void test_getAuthorizedProfiles_NOK()
    {
        List<String> nombresPerfiles = new List<String>();
        nombresPerfiles.add('Perfil inventado');

        Test.startTest();
        Map<Id, Profile> perfiles = ProfilesSelector.getProfilesByName(nombresPerfiles);
        Test.stopTest();

        System.assertEquals(0, perfiles.values().size(), 'No debe encontrar ningún perfil');
    }

}
