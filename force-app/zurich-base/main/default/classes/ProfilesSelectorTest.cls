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

    @isTest
    static void test_getLoggedUserProfile() {

        Profile userProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];

        Test.startTest();
        String logedUserProfile = ProfilesSelector.getLoggedUserProfile();

        Test.stopTest();

        System.assertEquals(userProfile.Name, logedUserProfile, 'Debe coincidir el perfil del usuario');
    }

}
