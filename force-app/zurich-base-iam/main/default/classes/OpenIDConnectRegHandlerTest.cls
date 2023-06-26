/**
 * @description       :
 * @author            : Enara Etxaniz
 * @group             :
 * @last modified on  : 01-02-2021
 * @last modified by  : nts (agonzalezisasi)
 * Modifications Log
 * Ver   Date         Author                Modification
 * 1.0   10-08-2020   Enara Etxaniz         Initial Version
 * 2.0   01-02-2021   nts (agonzalezisasi)  Refactorized the class for the new requirements
 * 3.0   07-06-2023   nts (dmunoz)          Adecuar a la nueva arquitectura el test
 *
 **/
@isTest
private class OpenIDConnectRegHandlerTest {

    static final string IAM_ROLE_A = 'IAM_ROLE_COMMUNITY';
    static final string IAM_ROLE_B = 'IAM_ROLE_OCS';
    static final string IAM_ROLE_A_NAME = 'TestRoleA';

    @TestSetup
    static void makeData(){
        TestDataFactorySDM.intermediarySetupData(); 
    }

    /**
     * Creates a list of AuthMapping__mdt to simulate the metadata configuration given a list of roles
     * separated by coma.
     *
     * @author nts (dmunoz)
     * @date 16/6/2023
     * @param {OpenIDConnectSalesforceCommunity handler} reference to the object OpenIDConnectSalesforceCommunity
     * @param {string roles} the list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     *
     */
    static Auth.UserData mockAuthData(OpenIDConnectRegHandler handler, string roles) {
        if (String.isBlank(roles)) {
            throw new OpenIDConnectRegHandler.RegHandlerException('No role specified for the test');
        }

        handler.testListAuthMappings = new List<AuthMapping__mdt>();        

        // IAM_ROLE_A
        if ( roles != null && roles.contains(IAM_ROLE_A) ) { // COMMUNITY
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE UserLicense.NAME = 'Partner Community'
                ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfile',
                                                  DeveloperName= 'TestProfile',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );        
        }

        // IAM_ROLE_B
        if (roles != null && roles.contains(IAM_ROLE_B)) { // LICENCIA SF
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE Name NOT IN :OpenIDConnectSalesforceLicense.SYS_ADMIN_TRANSLATIONS
                AND UserLicense.NAME = 'Salesforce'
                ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfile',
                                                  DeveloperName= 'TestProfile',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectSalesforceLicense.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 1
                                                  ) );              
        } 

        // return de data structure from IAM
        return getSampleDataIAM(roles);
    }


    /**
     * Creates the structure of Auth Data with the IAM roles
     *
     * @author nts (agonzalezisasi)
     * @date 01/02/2021
     * @param {string roleNames} a list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     */
    static Auth.UserData getSampleDataIAM(string roleNames) {


        String emailValue = 'testuser@example.org';
        Auth.UserData sampleDataIAM = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            emailValue,
            null,
            'testuserlong',
            UserInfo.getLocale(),
            'facebook',
            null,
            new Map<String, String> {});
        if( roleNames != null ) {
            sampleDataIAM.attributeMap.put(
                OpenIDConnectSalesforceCommunity.AUTH_DATA_MAP_NAME,
                '{crm=[' + roleNames + ']}'
                );            
        }

        return sampleDataIAM;
    }

    //////////////// Test IAM Community /////////////////////////////////////
    @isTest
    static void testCommunityRoleReceived() {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM); 
        Test.stopTest();

        System.assertEquals('CommunityUser', u.LastName, 'El apellido debe ser: CommunityUser');    
    }

    @isTest
    static void testUpdateCommunityRoleReceived() {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        User userQuery = [SELECT ID, LastName FROM User LIMIT 1];

        Test.startTest();
        handler.updateUser(userQuery.id, null, sampleDataIAM); 
        Test.stopTest();

        System.assertEquals(userQuery.lastname, userQuery.LastName, 'El apellido debe coincidir');    
    }



    //////////////// Test IAM SF License /////////////////////////////////////
    @isTest
    static void testSFLicenseRoleReceived() {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM); 
        Test.stopTest();

        System.assertEquals('SFUser', u.LastName, 'El apellido debe ser: SFUser');  
        
    }

    @isTest
    static void testUpdateSFLicenseRoleReceived() {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B);

        User userQuery = [SELECT ID, LastName FROM User LIMIT 1];

        Test.startTest();
        handler.updateUser(userQuery.id, null, sampleDataIAM); 
        Test.stopTest();

        System.assertEquals(userQuery.lastname, userQuery.LastName, 'El apellido debe coincidir');    
    }


    @isTest
    static void testExceptionThrow() {

        try {
            Auth.UserData sampleDataIAM = getSampleDataIAM(null);
            OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();

            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertEquals( 'OpenIDConnectRegHandler.RegHandlerException', e.getTypeName(), 'Se debe haber capturado una excepcion');
        }
    }
    
}
