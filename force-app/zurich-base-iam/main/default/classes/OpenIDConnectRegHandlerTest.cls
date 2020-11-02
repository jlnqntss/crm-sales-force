@isTest
private class OpenIDConnectRegHandlerTest
{
    /**
     * @description Test de cración y actualización de usuario de manera exitosa loas datos de entrada se encuentran en Auth.UserData
     * Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testCreateAndUpdateUser()
    {
        Profile_mapping__mdt mapping = [
            SELECT External_profile_name__c
            FROM Profile_mapping__mdt
            WHERE
            Salesforce_profile_name__c = 'System Administrator'
                                         OR Salesforce_profile_name__c = 'Administrador del sistema'
                                                                         LIMIT 1
        ];
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleData = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            'testuser@example.org',
            null,
            'testuserlong',
            UserInfo.getLocale(),
            'facebook',
            null,
            new Map<String, String> {
            'roles' = > '{crm=[' +
                      mapping.External_profile_name__c +
                      ']}'
        });

        User u = handler.createUser(null, sampleData);
        System.assertEquals('testuserlong@zurich-es.com', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);
        insert (u);
        String uid = u.id;

        sampleData = new Auth.UserData(
            'testNewId',
            'testNewFirst',
            'testNewLast',
            'testNewFirst testNewLast',
            'testnewuser@example.org',
            null,
            'testnewuserlong',
            UserInfo.getLocale(),
            'facebook',
            null,
            new Map<String, String> {
            'roles' = > '{crm=[' +
                      mapping.External_profile_name__c +
                      ']}'
        }
            );
        handler.updateUser(uid, null, sampleData);
        User updatedUser = [
            SELECT userName, email, firstName, lastName, alias
            FROM user
            WHERE id = :uid
        ];
        System.assertEquals('testnewuserlong@zurich-es.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        System.assertEquals('testNewLast', updatedUser.lastName);
        System.assertEquals('testNewFirst', updatedUser.firstName);
    }

    /**
     * @Description Se fuerza la excepción no informando el rol en los datos de entrada.
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testFailCreateUserNoProfile()
    {
        try
        {
            OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
            Auth.UserData sampleData = new Auth.UserData(
                'testId',
                'testFirst',
                'testLast',
                'testFirst testLast',
                'testuser@example.org',
                null,
                'testuserlong',
                UserInfo.getLocale(),
                'facebook',
                null,
                new Map<String, String> {}
                );
            User u = handler.createUser(null, sampleData);
        }
        catch (Exception e)
        {
            System.assertEquals(
                'OpenIDConnectRegHandler.RegHandlerException',
                e.getTypeName()
                );
        }
    }

    /**
     * @Description Se fuerza la excepción, se informa un rol no válido en los datos de entrada.
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testFailCreateUserNoValidProfile()
    {
        try
        {
            OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
            Auth.UserData sampleData = new Auth.UserData(
                'testId',
                'testFirst',
                'testLast',
                'testFirst testLast',
                'testuser@example.org',
                null,
                'testuserlong',
                UserInfo.getLocale(),
                'facebook',
                null,
                new Map<String, String> { 'roles' = > '{crm=[testFailProfile]}' }
                );
            User u = handler.createUser(null, sampleData);
        }
        catch (Exception e)
        {
            System.assertEquals(
                'OpenIDConnectRegHandler.RegHandlerException',
                e.getTypeName()
                );
        }
    }
}