/**
 * Acción invocable para ejecutar la lógica de obtención de valores de picklist
 * disponibles por recordtype para el objeto Case
 *
 * @author mario.navarro@seidor.com
 * @date 15/04/2024
 */
public with sharing class AvailableCasePicklistValuesByRtAction
{

    /**
     * Obtiene los valores disponibles para un picklist concreto para el objeto caso y
     * un identificador de recordtype concreto.
     * Lo retorna dentro de una lista de casos, en el campo ActivityDescription__c para que
     * pueda ser utilizado en un Flow para crear un Choice set (si se incluye los valores
     * posibles en un picklist, no deja utilizarlo)
     *
     * @author mario.navarro@seidor.com
     * @date 15/04/2024
     * @param picklistRequests la lista de requests, que deben tener el nombre del picklist y el id del recordtype
     * @return la matriz de casos, con el campo ActivityDescription__c informado
     */
    @InvocableMethod
    (
        label='Find available picklist for recordtype'
               description='Obtiene los valores disponibles para un picklist de caso en funcion de un recordtype concreto'
                            category='Other'
    )
    public static List<List<Case> > findValues(List<AvailableCasePicklistValuesByRtActionRequest> picklistRequests)
    {
        List<List<Case> > returnList = new List<List<Case> >();
        List<Case> caseList;
        Map<String, String> picklistMap;
        List<String> picklistLabels;
        for (AvailableCasePicklistValuesByRtActionRequest picklistRequest : picklistRequests)
        {
            picklistMap = SystemUtil.getPicklistValuesByRecordtype('Case', picklistRequest.fieldName, picklistRequest.recordTypeId);
            picklistLabels = picklistMap.values();
            picklistLabels.sort();//que se retorne ordenado alfabeticamente
            caseList = new List<Case>();
            for (String val : picklistLabels)
            {
                caseList.add( new Case(ActivityDescription__c = val) );
            }
            returnList.add(caseList);
        }

        return returnList;
    }

    public class AvailableCasePicklistValuesByRtActionRequest
    {
        @InvocableVariable(label='Picklist name' description='Nombre API del campo picklist del que obtener los valores' required=true)
        public String fieldName;

        @InvocableVariable(label='Recordtype Id' description='Identificador del recordtype para el que queremos obtener los valores posibles del picklist' required=true)
        public String recordTypeId;
    }
}