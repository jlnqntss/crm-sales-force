/**
 * @description       : Clase que se encarga de generar una picklist dinámica para el componente LWC 'usefulLinks'.
 * @author            : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   13-12-2022   amiranda   Initial Version
 **/
public with sharing class ContentWorkspacesPicklist extends VisualEditor.DynamicPickList
{
    @testVisible
    private static final String DEFAULT_CONTENTWORKSPACE = 'Enlaces de interés';

    /**
     * @description Método que recupera la biblioteca establecida por defecto. En este caso es la biblioteca 'Enlaces de interés'.
     * @author amiranda
     * @date 13-12-2022
     * @return VisualEditor.DataRow Elemento por defecto de la picklist dinámica
     * @see usefulLinks.js-meta.xml
     **/
    public override VisualEditor.DataRow getDefaultValue()
    {
        VisualEditor.DataRow defaultValue = null;

        for ( VisualEditor.DataRow row : getValues().getDataRows() )
        {
            if ( row.isSelected() )
            {
                defaultValue = row;
            }
        }

        return defaultValue;
    }

    /**
     * @description Método que devuelve en forma de picklist dinámica las librerías que hay en 'Archivos' en Salesforce.
     * @author amiranda
     * @date 13-12-2022
     * @return VisualEditor.DynamicPickListRows Picklist dinámica con las librerías que se encuentran en 'Archivos' en Salesforce
     * @see usefulLinks.js-meta.xml
     **/
    public override VisualEditor.DynamicPickListRows getValues()
    {
        VisualEditor.DynamicPickListRows dynamicContentWorkspaces = new VisualEditor.DynamicPickListRows();

        // Se recuperan todas las librerías del sistema
        for (ContentWorkspace contentWorkspace : [SELECT Name FROM ContentWorkspace])
        {
            VisualEditor.DataRow row;

            if ( contentWorkspace.Name != null && contentWorkspace.Name.equals(DEFAULT_CONTENTWORKSPACE) )
            {
                // Se establece como librería por defecto la librería 'Enlaces de interés'
                row = new VisualEditor.DataRow(contentWorkspace.Name, contentWorkspace.Name, true);
            }
            else
            {
                row = new VisualEditor.DataRow( contentWorkspace.Name, contentWorkspace.Name );
            }

            dynamicContentWorkspaces.addRow(row);
        }

        return dynamicContentWorkspaces;
    }
}