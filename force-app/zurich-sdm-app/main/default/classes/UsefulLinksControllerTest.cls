/**
 * @description       : Clase de test que comprueba el correcto funcionamiento de la clase UsefulLinksController
 * @author            : amiranda
 * @date              : 15-12-2022
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   14-12-2022   amiranda   Initial Version
 **/
@isTest
public with sharing class UsefulLinksControllerTest
{

    private static final Integer NUM_LINKS = 15;
    private static final Integer LIMIT_LINKS = 8;
    private static final String CW_NAME = 'UsefulLinksControllerTest';
    private static final String CW_PERMISSION_TYPE = 'Admin';

    @TestSetup
    static void makeData()
    {
        // Se genera una librería para almacenar los archivos de tipo link
        ContentWorkspace cw = new ContentWorkspace(
            Name = CW_NAME
            );
        insert cw;

        // Se recupera el Id del tipo de permiso 'Admin'
        ContentWorkspacePermission cwp = [SELECT Id FROM ContentWorkspacePermission WHERE Type =: CW_PERMISSION_TYPE];

        /*
         * Generar ficheros de tipo link. Es necesario insertarlo en otra transacción
         * puesto que no se pueden combinar DMl de objeto setup y no setup.
         */
        System.runAs( new User( Id = UserInfo.getUserId() ) )
        {
            List<ContentVersion> cvs = new List<ContentVersion>();

            for (Integer index = 0; index < NUM_LINKS; index++)
            {
                ContentVersion cv = new ContentVersion (
                    ContentUrl = 'https://test.com',
                    FirstPublishLocationId = cw.Id,
                    OwnerId = UserInfo.getUserId(),
                    Title = 'cv' + index
                    );

                cvs.add(cv);
            }

            insert cvs;
        }
    }

    /**
     * @description Test que comprueba el funcionamiento del método getLibraryId
     * cuando se le pasa un nombre de una librería existente
     * @author amiranda
     * @date 15-12-2022
     **/
    @isTest
    static void getLibraryIdTest_ok()
    {
        ContentWorkspace cw = [SELECT Id, Name FROM ContentWorkspace WHERE Name =: CW_NAME];

        Test.startTest();
        String cwId = UsefulLinksController.getLibraryId(cw.Name);
        Test.stopTest();

        System.assertEquals(cw.Id, cwId, 'El Id de las librerías no coincide.');
    }

    /**
     * @description Test que compreuba el funcionamiento del método getLibraryId
     * cuando se le pasa un nombre de una librería no existente
     * @author amiranda | 15-12-2022
     **/
    @isTest
    static void getLibraryIdTest_ko()
    {
        String exceptionType;

        Test.startTest();
        try
        {
            // Se intenta recuperar el Id de una librería no existente
            String cwId = UsefulLinksController.getLibraryId('Librería no existente');
        }
        catch (Exception ex)
        {
            exceptionType = ex.getTypeName();
        }
        Test.stopTest();

        System.assert (String.isNotEmpty(exceptionType), 'No se ha generado ninguna excepción.');
        System.assertEquals('System.AuraHandledException', exceptionType, 'No se ha generado una excepción de tipo "AuraHandledException".');
    }

    /**
     * @description Test que comprueba el correcto funcionamiento del método getLink
     * @author amiranda
     * @date 14-12-2022
     **/
    @isTest
    static void getLinkTest()
    {
        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace WHERE Name =: CW_NAME];

        Test.startTest();
        List<ContentVersion> cvs = UsefulLinksController.getLinks(cw.Id, LIMIT_LINKS);
        Test.stopTest();

        System.assertEquals(LIMIT_LINKS,
                            cvs.size(),
                            'Se han recuperado más links del límite establecido.');
    }

    /**
     * @description Test que comprueba si se recupera el tipo de permiso que tiene
     * un usuario al que se le ha dado acceso de forma directa a una librería de archivos.
     * @author amiranda
     * @date 14-12-2022
     **/
    @isTest
    static void getContentWorkspacePermissionTypeTest_userMember()
    {
        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace WHERE Name =: CW_NAME];

        Test.startTest();
        String cwpType = UsefulLinksController.getContentWorkspacePermissionType( cw.Id, UserInfo.getUserId() );
        Test.stopTest();

        System.assertEquals(CW_PERMISSION_TYPE, cwpType, 'El tipo de permiso no es correcto.');
    }

    /**
     * @description Test que comprueba si se recupera el tipo de permiso que tiene
     * un usuario al que se la ha dado acceso a través de un grupo público del
     * que es miembro a una librería de archivos.
     * @author amiranda
     * @date 14-12-2022
     */
    @isTest
    static void getContentWorkspacePermissionTypeTest_groupMember()
    {
        User user = new User(
            Username = 'testuser@nts-solutions.com.invalid',
            LastName = 'testUser',
            Email = 'testuser@nts-solutions.com.invalid',
            Alias = 'testUser',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey='Europe/Rome',
            LocaleSidKey='es_ES',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='es'
            );
        insert user;

        // Se crea un nuevo grupo al que se añadirá como miembro al nuevo usuario
        Group g = new Group(
            DeveloperName = 'TestGroup',
            Name = 'TestGroup'
            );
        insert g;

        // Se crea este objeto que representa la relación entre un usuario/grupo y un grupo
        GroupMember gm = new GroupMember(
            GroupId = g.Id,
            UserOrGroupId = user.Id
            );
        insert gm;

        // Se añade al nuevo grupo como miembre de la librería de archivos que se ha creado previamente
        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace WHERE Name =: CW_NAME];
        ContentWorkspacePermission cwp = [SELECT Id FROM ContentWorkspacePermission WHERE Type =: CW_PERMISSION_TYPE];
        ContentWorkspaceMember cwm = new ContentWorkspaceMember(
            ContentWorkspaceId = cw.Id,
            ContentWorkspacePermissionId = cwp.Id,
            MemberId = g.Id
            );
        insert cwm;

        Test.startTest();
        String cwpType = UsefulLinksController.getContentWorkspacePermissionType(cw.Id, user.Id);
        Test.stopTest();

        System.assert (String.isNotEmpty(cwpType), 'No se recupera ningún tipo de permiso.');
        System.assertEquals(CW_PERMISSION_TYPE, cwpType, 'El tipo de permiso no es correcto.');
    }

}