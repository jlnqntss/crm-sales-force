/**
 * @description       : Clase que propaga la configuración de visibiliad GDPR a partir del campo Blocked__c o Anonimized__c.
 *                      En el metadato GDPRPropagationOrder__mdt se definen que Sobject participan en el proceso GDPR, donde
 *                      viene indicado un campo formula (FormulaField__c) que mira si el registro relacionado se encuentra bloqueado
 *                      y un campo bloqueo (BlockingField__c) que incica cual es el campo a bloquear en dicho Sobject. El registro
 *                      origen será la cuenta.
 *                      Si en algun momento la cuenta se marca para desblequear, el proceso se encargará de desmarcar también
 *                      su jerarquía.
 *                      Este proceso también se encarga de propagar la anonimización entre los registros y al final del proceso
 *                      lanzará el proceso de borrado de dichos registros.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 04-16-2024
 * @last modified by  : mfernandezcarrera
**/
public without sharing class GDPRPropagateBlockedFieldBatch implements Database.Batchable<sObject>
{
    private GDPRPropagationOrder__mdt currentSObjectPropagationParameters;
    private Boolean isAnonymizeMode; // Indica si se esta propagando el campo Blocked o Anonymized
    private String whereLocalClause;

    public GDPRPropagateBlockedFieldBatch(Boolean isAnonymize)
    {
        currentSObjectPropagationParameters = getMetadataParameters('1', isAnonymize);
    }

    public GDPRPropagateBlockedFieldBatch(String indexValue, Boolean isAnonymize)
    {
        currentSObjectPropagationParameters = getMetadataParameters(indexValue, isAnonymize);
    }

    public GDPRPropagateBlockedFieldBatch(String indexValue, Boolean isAnonymize, String whereClause)
    {
        currentSObjectPropagationParameters = getMetadataParameters(indexValue, isAnonymize);
        whereLocalClause=whereClause;

    }

    /**
     * @description Metodo que obtiene el metadato sobre la propagación correspondiente
     *              al indice recibido y el modo de propagación.
     * @author      jgallaga | 16/10/2023
     * @param       indexValue
     *              Posición del metadato en el orden de propagación
     * @param       isAnonymize
     *              Indica si el metadato a recoger es para la propagación del campo blocked
     *              o para el campo anonymized
     * @thorws      NoSuchElementException
     *              Si no existe un metadatado para el indice y modo indicado, lanzará una excepción
     */
    private GDPRPropagationOrder__mdt getMetadataParameters(String indexValue, Boolean isAnonymize)
    {
        if(isAnonymize == null)
        {
            isAnonymize = false;
        }

        isAnonymizeMode = isAnonymize;

        if(String.isBlank(indexValue))
        {
            indexValue = '1';
        }

        GDPRPropagationOrder__mdt foundMetadataRecord;

        foundMetadataRecord = getMetadataByIndex(indexValue, isAnonymize);

        if(foundMetadataRecord == null)
        {
            throw new NoSuchElementException('No se ha encontrado ninguna configuración en los metadatos para el índice 1');
        }

        return foundMetadataRecord;
    }
    
    /**
     * @description El metodo execute del batch recogera los parametros indicados en los metadatos
     *              para generar una query que recogera todos aquellos registros que estén
     *              marcados para propagar el valor de bloqueo o anonimizado a partir del campo formula
     *              del registro al que apunta, si este ha cambiado de estado.
     * @author      jgallaga | 16/10/2023
     */
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String  scopeQuery;
        String formulaField = currentSObjectPropagationParameters.FormulaField__c;
        String blockingField = currentSObjectPropagationParameters.BlockingField__c;
        String sObjectName = currentSObjectPropagationParameters.SObjectAPIName__c;

        scopeQuery =
            'SELECT ' + formulaField + ' , ' + blockingField +
            ' FROM ' + sObjectName +
            ' WHERE ((' + formulaField + ' = true AND ' + blockingField + ' = false) OR (' + formulaField + ' = false AND ' + blockingField + ' = true)) ';

        if(String.isNotBlank(whereLocalClause))
        {
            scopeQuery += whereLocalClause;
        }

        return Database.getQueryLocator(scopeQuery);
    }

    /**
     * @description La función del execute para este Batch es pasar el valor del campo formula que
     *              indica el estado al que debe poner los valores de anonimizado o bloqueado en el resgitro actual.
     *              Los parametros del metadato indican que campos deben actualizarse.
     * @author      jgallaga | 16/10/2023
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        String blockingField = currentSObjectPropagationParameters.BlockingField__c;
        String formulaField = currentSObjectPropagationParameters.FormulaField__c;

        for(sObject currentsObject : scope)
        {
            currentsObject.put(blockingField, currentsObject.get(formulaField));
        }

        Database.SaveResult[] updateResults = Database.update(scope, false);

        for(Database.SaveResult updateResult : updateResults)
        {
            if(! updateResult.isSuccess())
            {
                ErrorLogUtil.commitError('ERROR', 'No se pudo actualizar el registro: ' + updateResult.getErrors()[0].getMessage(), 'GDPRPropagateBlockedFieldBatch');
            }
        }
    }

    /**
     * @description Una vez finalizado el scope, se comprueba si existe un siguiente metadato para el
     *              siguiente índice. De existir, se vuelve a lanzar el Batch de propagación. Si no
     *              existe, pero esta en modo anonimizado, se lanzará el Batch de borrado de registros.
     * @author      jgallaga | 16/10/2023
     */
    public void finish(Database.BatchableContext bc)
    {
        Integer index = Integer.valueOf(currentSObjectPropagationParameters.IndexOrder__c) + 1;

        String nextIndex = String.valueOf(index);

        //Se recoge el siguiente metadato de propagación que NO tenga el campo IsPolymorphicSobject a true
        GDPRPropagationOrder__mdt nextPropagationMetadata = getMetadataByIndex(nextIndex, isAnonymizeMode);

        if(nextPropagationMetadata != null)
        {
            // Recogemos el indice del metadato encontrado para asegurar el orden, por si habia algun polimórfico en medio
            nextIndex = nextPropagationMetadata.IndexOrder__c;
            Database.executeBatch(new GDPRPropagateBlockedFieldBatch(nextIndex, isAnonymizeMode));
        }
        else if(isAnonymizeMode)
        {
            Database.executeBatch(new GDPRDeleteAnonymizedRecordsBatch());
        }
    }

    /**
     * @description Metodo para recoger el metadato con los parametros de propagación a partir del indice
     *              y el modo de propagación. Se asegura que el siguiente metadato a utilizar no es
     *              un polimórfico ya que esos casos se gestiona la propagación mediante Trigger Flow.
     * @author      jgallaga | 16/10/2023
     * @param       indexValue
     *              Indice del metadatado que se queire recoger
     * @param       isAnonymize
     *              Invida si el metadato a recoger debe ser sobre propagacion de Blocked o Anonymized
     * @return      GDPRPropagationOrder__mdt
     *              Es el metadado encontrado para la siguiente propagación.
     */
    private GDPRPropagationOrder__mdt getMetadataByIndex(String indexValue, Boolean isAnonymize)
    {
        GDPRPropagationOrder__mdt foundMetadata;

        if(String.isblank(indexValue))
        {
            indexValue='1';
        }

        if(isAnonymize == null)
        {
            isAnonymize = false;
        }

        Boolean searchMetada = true;

        while(searchMetada)
        {
            try
            {
                foundMetadata = searchMetadata(indexValue, isAnonymize);
            }
            catch(Exception unexpectedError)
            {
                ErrorLogUtil.commitError(unexpectedError, 'PropagateBlockedFieldBatch', 'finish');
                throw unexpectedError;
            }

            if(foundMetadata == null)
            {
                break;
            }

            if(foundMetadata.IsPolymorphicSobject__c)
            {
                indexValue = String.valueOf(Integer.valueOf(indexValue) + 1);
                continue;
            }

            searchMetada = false;
        }

        return foundMetadata;
    }

    /**
     * @description Para asegurar que el siguiente metadato que se recoge corresponde al indice que se desea
     *              pero no se quiere tener en cuenta aquellos que representen un Sobject con lookup polimorfico,
     *              se realiza un for de todos los registros disponibles para encontrar al adecuado.
     *              Si se llega al final del indice y ya no quedan mas metadatos, se devuelve un null.
     * @author      jgallaga | 16/10/2023
     * @param       indexValue
     *              Indice del metadatado que se queire recoger
     * @param       isAnonymize
     *              Invida si el metadato a recoger debe ser sobre propagacion de Blocked o Anonymized
     * @return      GDPRPropagationOrder__mdt
     *              Es el metadado encontrado para la siguiente propagación.
     */
    private GDPRPropagationOrder__mdt searchMetadata(String indexValue, Boolean isAnonymize)
    {
        for(GDPRPropagationOrder__mdt gdprPropOrder : GDPRPropagationOrder__mdt.GetAll().Values())
        {
            if(gdprPropOrder.IndexOrder__c == indexValue && gdprPropOrder.IsAnonymize__c == isAnonymize)
            {
                return gdprPropOrder;
            }
        }

        return null;
    }
}