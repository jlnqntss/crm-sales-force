/**
 * @description       : Batch centrado en el borrado de los registros marcados como anonimo. A partir de los registros
 *                      obtenidos los metadatados de propagación (GDPRPropagationOrder__mdt) y en el orden inverso al
 *                      indicado por el índice para aquellas entrada que tegan IsAnonymize__c a verdadero,
 *                      se iran borrando los registros de cada tipo de entidad.
 *                      El proceso buscará cualquier registro que tenga a verdadero el campo definido en BlockingField__c
 *                      para dicha entidad.
 *                      Cada metadato contiene la entidad de Salesforce sobre la que actuar y el campo sobre el que buscar
 *                      a ver si la anonimización es verdadero.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 19/10/2023
 * @last modified by  : jgallaga
**/
public without sharing class GDPRDeleteAnonymizedRecordsBatch implements Database.Batchable<Sobject>
{

    private String currentDeleteIndex;
    GDPRPropagationOrder__mdt currentObjectParameters;

    /**
     * @description El constructor sin parametros comenzará el proceso por el íncide mas alto,
     *              que pudiera existir en los metadatos, por lo que preparamos el Batch con el índice 0.
     *              Este indice hará que el proceso busque el metadato con indice mayor para comenzar
     *              en sentido descendente.
     * @author      jgallaga | 19/10/2023
     */
    public GDPRDeleteAnonymizedRecordsBatch()
    {
        currentDeleteIndex = '0';

        // Busca el metadato para el indice indicado, como recibe el 0, en realidad buscará el mas alto
        currentObjectParameters = prepareBatch(currentDeleteIndex);

        currentDeleteIndex = currentObjectParameters.IndexOrder__c; // Asignamos el primer indice con el que trabajar
    }

    /**
     * @description Constructor para lanzar el proceso de borrado a partir del índice recibido por parametro.
     *              Si el valor es nulo, se asignará el indice 0 para empezar desde el comienzo.
     *              El indice 0 hará que el proceso busque el metadato con indice mayor para comenzar
     *              en sentido descendente.
     * @author      jgallaga | 19/10/2023
     * @param       nextIndex
     *              Indica que identifica el siguiente metadato con los parametros de la entidad a borrar.
     */
    public GDPRDeleteAnonymizedRecordsBatch(String nextIndex)
    {
        if(String.isBlank(nextIndex))
        {
            nextIndex = '0';
        }

        currentDeleteIndex = nextIndex;

        // Busca el metadato para el indice indicado, si recibe 0, buscará el mas alto
        currentObjectParameters = prepareBatch(currentDeleteIndex);
        currentDeleteIndex = currentObjectParameters.IndexOrder__c; // Como es posible haber comenzado con indice 0, reasignamos el indice actual en uso
    }

    /**
     * @description Metodo que comprueba que se recupera correctamente el metadato para el indice
     *              recibido. De no ser así, se lanzará una excepción para indicar que no existe
     *              configuración para dicho índice. Puede ocurrir si en los metadatos a los índices
     *              les falta algún registro entre el índice menor y mayor.
     * @param       nextIndex
     *              Índice del metadato a recuperar
     * @return      GDPRPropagationOrder__mdt
     *              Registro del metadato con la configuración sobre los campos a utilizar para le proceso.
     */
    private GDPRPropagationOrder__mdt prepareBatch(String nextindex)
    {
        currentObjectParameters = getPropagationMedataByIndex(nextindex);

        if(currentObjectParameters == null)
        {
            throw new NoSuchElementException('No se ha encontrado ninguna configuración en los metadatos');
        }

        return currentObjectParameters;
    }

    /**
     * @description A partir del metadato obtenido en el constructor, se realiza la query para encontrar
     *              todos los registros que sobre la entidad indice, tienen el campo definido a true.
     *              El metadato recuperado es de tipo anonimización, por lo que el campo BlockingField__c
     *              en realidad tiene el API name del campo anonimizado.
     * @author      jgallaga | 19/10/2023
     */
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String anonymizingField = currentObjectParameters.BlockingField__c;
        String sObjectName = currentObjectParameters.SObjectAPIName__c;

        String query = 'SELECT Id FROM ' + sObjectName + ' WHERE ' + anonymizingField + ' = true';

        // En caso de contacto, los que pertenecen a una person account no se pueden borrar
        if(sObjectName == Contact.getSObjectType().getDescribe().getName())
        {
            query = query + ' AND Account.isPersonAccount = false';
        }

        return Database.getQueryLocator(query);
    }

    /**
     * @description Por cada Scope se intentan borrar los registros recibidos. Para evitar que el borrado frene
     *              el proceso por un error, se utiliza la clase Database. Los registros que no consigan borrarse
     *              crearán un registro de error.
     * @author      jgallaga |19/10/2023
     */
    public void execute(Database.BatchableContext bc, List<Sobject> scope)
    {
        Database.DeleteResult[] deleteOperations = Database.delete(scope, false); // All or none a falso. Los que no se puedan no evita que se borre el resto

        for(Database.DeleteResult currentDeleteOpertaion : deleteOperations)
        {
            if(! currentDeleteOpertaion.isSuccess())
            {
                ErrorLogUtil.commitError('ERROR', 'No se pudo eliminar el registro: ' + currentDeleteOpertaion.getErrors()[0].getMessage(), 'GDPRDeleteAnonymizedRecordsBatch');
            }
        }
    }

    /**
     * @description Al finalizar el scope para le borrado de la entidad que toque, se decrementa el indice
     *              y se busca el siguiente metadato para lanzar de nuevo el proceso para la siguiente
     *              entidad. Si el índice llega a 0, el proceso finaliza.
     * @author      jgallaga | 19/10/2023
     */
    public void finish(Database.BatchableContext bc)
    {
        Integer nextIndex = Integer.valueOf(currentDeleteIndex) - 1; // Vamos a la inversa en el borrado

        if(nextIndex > 0 && getPropagationMedataByIndex(String.valueOf(nextIndex)) != null)
        {
            Database.executeBatch(new GDPRDeleteAnonymizedRecordsBatch(String.valueOf(nextIndex)));
        }
    }

    /**
     * @description Recoge el metadato con los parametros de borrado para el indice recibido.
     *              En cambio, si el índice es nulo o 0, el proceso buscará el metadato con el
     *              índice mayor. El metadato será del conjunto de metadato de anonimizado, que
     *              son aquellos cuyo campo IsAnonymize__c sea verdadero.
     * @author      jgallaga | 19/10/2023
     * @param       index
     *              ïndice del metadato que se quiere recuperar
     * @return      GDPRPropagationOrder__mdt
     *              Registro de metadato encontrado para le índice encontrado, o en caso contrario
     *              el de mayor indice disponible.
     */
    public static GDPRPropagationOrder__mdt getPropagationMedataByIndex(String index)
    {
        GDPRPropagationOrder__mdt result;
        Integer receivedIndex;

        if(String.isBlank(index))
        {
            receivedIndex = 0;
        }
        else
        {
            receivedIndex = Integer.valueOf(index);
        }

        Integer maxIndex = 0;

        for(GDPRPropagationOrder__mdt currentMetadata : GDPRPropagationOrder__mdt.GetAll().Values())
        {
            if(! currentMetadata.IsAnonymize__c) // No nos interesa si no es metadato de anonimizar o es un Sobject con lookup polimorfico
            {
                continue;
            }

            Integer metadataIndex = Integer.valueOf(currentMetadata.IndexOrder__c);

            if(receivedIndex == 0 && maxIndex < metadataIndex) // Se busca el mayor
            {
                maxIndex = metadataIndex;
                result = currentMetadata;
                continue;
            }

            if(receivedIndex == metadataIndex) // Se busca el siguiente en la lista
            {
                result = currentMetadata;
                break;
            }

        }

        return result;
    }

}