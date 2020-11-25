/**
 * @description       : 
 * @author            : Enara Etxaniz
 * @group             : 
 * @last modified on  : 10-14-2020
 * @last modified by  : Enara Etxaniz
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   10-08-2020   Enara Etxaniz   Initial Version
**/
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
        Public_Group_Mapping__mdt mapping = [SELECT External_role_name__c 
                                        FROM  Public_Group_Mapping__mdt
                                        WHERE Salesforce_group_name__c = 'KLINC_CustomerCare_GI_France' LIMIT 1];            
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
                                                    new Map<String, String>{'roles' => '{crm=['+ mapping.External_role_name__c +']}'});
        User u = handler.createUser(null, sampleData);
        System.assertEquals('testuserlong@zurich-es.com', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);

        //insert(u);
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
                                        new Map<String, String>{'roles' => '{crm=['+ mapping.External_role_name__c +']}'});
        handler.updateUser(uid, null, sampleData);
        User updatedUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:uid];
        System.assertEquals('testnewuserlong@zurich-es.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        System.assertEquals('testNewLast', updatedUser.lastName);
        System.assertEquals('testNewFirst', updatedUser.firstName);

        // GroupMember groupMemberItem = [SELECT GroupId FROM GroupMember WHERE userOrGroupId = :uid LIMIT 1];
        // Group groupItem = [SELECT DeveloperName FROM Group WHERE Id = :groupMemberItem.GroupId LIMIT 1];
        // System.assertEquals(groupItem.DeveloperName, 'KLINC_CustomerCare_GI_France');
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
                                                        new Map<String, String>{});
            User u = handler.createUser(null, sampleData);
        }
        catch (Exception e)
        {
            System.assertEquals('OpenIDConnectRegHandler.RegHandlerException', e.getTypeName());
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
                                                        new Map<String, String>{'roles' => '{crm=[testFailProfile]}'});
            User u = handler.createUser(null, sampleData);
        }
        catch (Exception e)
        {
            System.assertEquals('OpenIDConnectRegHandler.RegHandlerException', e.getTypeName());
        }
    }
}