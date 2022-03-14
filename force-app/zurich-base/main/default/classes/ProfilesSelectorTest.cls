@IsTest
public with sharing class ProfilesSelectorTest {
    
    @isTest
    public static void test_getAuthorizedProfiles()
    {
        List<String> nombresPerfiles = new List<String>();
        nombresPerfiles.add('System Administrator');

        Test.startTest();
        Map<Id, Profile> perfiles = ProfilesSelector.getAuthorizedProfiles(nombresPerfiles);
        Test.stopTest();

        System.assertEquals(1, perfiles.values().size(), 'Ha debido encontrar el perfil indicado');
    }

}
