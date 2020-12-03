/**
 * Clase virtual que contiene la lógica para recuperar los campos necesarios
 * de una query invocada desde un selector
 *
 * @date 03/12/2020
 * @author rlopez
 */
public virtual class BaseSelector
{

    //Esta propiedad indica el objeto Salesforce del que vamos a extraer los campos necesarios en la query
    //  - Si no se indica el objeto, solo se recupera el Id del objeto Salesforce (Campo común y básico de cualquier registro)
    protected String sObjectToQuery {get; set;}

    //Dado un objeto Salesforce:
    //  1.  Si se han especificado los campos necesarios, comprueba que los campos existen
    //      en el objeto y si es así los mantiene en el Set, sino los elimina
    //  2.  Sí no se ha especificado ningún campo, se incluirán en la query todos los campos
    //      del objeto que sean obligatorios o external ID
    protected Set<String> fieldsToQuery
    {
        get
        {
            if( String.isNotBlank(this.sObjectToQuery) )
            {
                SObjectType currentObjectType = Schema.getGlobalDescribe().get(this.sObjectToQuery);
                Map<String,Schema.SObjectField> currentTypeFields = currentObjectType.getDescribe().fields.getMap();

                if( fieldsToQuery == null || fieldsToQuery.isEmpty() )
                {
                    fieldsToQuery = new Set<String>();

                    //Recuperamos los required y externalIds
                    for( Schema.SObjectField sObjectField: currentTypeFields.values() )
                    {
                        //Si el campo es requerido o externalId, lo incluimos en el Set de campos a recuperar en la query
                        if(sObjectField.getDescribe().isNillable() != true || sObjectField.getDescribe().isExternalId() == true)
                        {
                            fieldsToQuery.add( sObjectField.getDescribe().getName() );
                        }
                    }
                }
                else
                {
                    //Comprobamos que los campos existen en los campos del objeto, si alguno no existe lo eliminamos del Set
                    for(String field: fieldsToQuery)
                    {
                        if( !currentTypeFields.containsKey(field) )
                        {
                            fieldsToQuery.remove(field);
                        }
                    }

                    if( fieldsToQuery.isEmpty() )
                    {
                        fieldsToQuery.add('Id');
                    }
                }

                return fieldsToQuery;
            }
            else
            {
                return new Set<String> {'Id'};
            }
        }
        set;
    }
}