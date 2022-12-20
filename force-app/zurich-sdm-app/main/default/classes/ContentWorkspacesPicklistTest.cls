/**
 * @description       : Clase de test que comprueba el correcto funcionamiento de la clase ContentWorkspacesPicklist
 * @author            : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   14-12-2022   amiranda   Initial Version
 **/
@isTest
public with sharing class ContentWorkspacesPicklistTest
{

    /**
     * @description Método que comprueba la generación de la picklist dinámica junto al valor por defecto de dicha lista.
     * @author amiranda
     * @date 14-12-2022
     **/
    @isTest
    static void test_contentWorkspaceDynamicPicklist()
    {
        List<ContentWorkspace> contentWorkspaces = [SELECT Id FROM ContentWorkspace];

        ContentWorkspacesPicklist cwPicklist = new ContentWorkspacesPicklist();

        // Se comprueba que la cantidad de librerías en el sistema coincide con las de la picklist dinámica
        System.assertEquals( contentWorkspaces.size(),
                             cwPicklist.getValues().size(),
                             'La cantidad de librerías no coincide.' );

        // Se comprueba que la librería por defecto es correcta
        System.assertEquals(ContentWorkspacesPicklist.DEFAULT_CONTENTWORKSPACE,
                            cwPicklist.getDefaultValue().getLabel(),
                            'La librería por defecto seleccionada no es correcta.');
    }
}