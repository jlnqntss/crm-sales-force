/**
 * Clase encapsular consultas a los metadatos de tipo Transformer
 **
 * @author xsobera
 * @date 30/10/2020
 */
public with sharing class TransformerSelector
{
    private static String getFieldListString()
    {
        return ' Id, DeveloperName, Label, OriginEntity__c, OriginField__c, SalesforceEntity__c, SalesforceField__c ';
    }

    private static String getSObjectName()
    {
        return ' Transformer__mdt ';
    }

    private static String getOrderBy()
    {
        return ' OriginEntity__c ASC ';
    }

    /**
     * Obtiene un listado de metadatos filtrado por Origen
     * @param String originSystem.  Si null, devolver Lista vacía.
     * @return Listado de metadatos
     * @author xsobera
     * @date 30/10/2020
     */
    public static List<Transformer__mdt> selectMetadataByOrigin(String originSystem)
    {
        //Devolver lista vacía
        if (String.isBlank(originSystem))
        {
            return new List<Transformer__mdt>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE Origin__c LIKE :originSystem ORDER BY {2}',
            new List<String>{ getFieldListString(), getSObjectName(), getOrderBy() }
        );

        return (List<Transformer__mdt>) Database.query(query);
    }
}