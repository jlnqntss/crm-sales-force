/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 12/08/2023
 * @last modified by  : jgallaga
**/
public with sharing class AccountLeadUtil
{

    /**
     * @description Funcionalidad para conseguir el Id de usuario del agente intermediario
     *              al que se le debe asignar la cuenta de Lead. A partir de los parametros
     *              recibidos se realizará una búsqueda del agente mediante la configuración
     *              de metadatos.
     * @param       Account - acc
     *              Un registro de cuenta
     * @param       String - intermediaryCode
     *              Código de intermediario del agente
     * @param       String - origin
     *              Origen desde donde proviene la información a gestionar
     * @param       String - language
     *              Idioma a utilizar para asignar el agente que le corresponde
     * @param       String - portalCode
     *              Código postal con el que se puede obtener el agente
     * @return      String
     *              Puede devolver el Id del Agente si se encuentra la configuración correcta.
     *              Si no puede que devuelva el Id del usuario por defecto o el valor 'CONTACT_CENTER'
     */
    public static String leadAssignment(Account acc, String intermediaryCode, String origin, String language, String postalCode)
    {
        if(String.isNotBlank(intermediaryCode))
        {
            return AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode);
        }

        if(acc != null)
        {
            return acc.Intermediary_Name__r.INFOIntermediaryCode__c;
        }

        if(String.isNotBlank(language) && language != 'ES')
        {
            return AccountLeadAssignment.getAssignedUserIdByLanguage(language);
        }

        return AccountLeadAssignment.getAssignedUserIdByAssignmentType(origin, postalCode);
    }

}