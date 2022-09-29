/**
 * Clase Apex controladora del componente LWC ObjectivesView
 */
public with sharing class ObjectivesViewController {

    /**
     * Obtiene un listado de Objetivos dado un año 
     * @param year: String con el año a consultar
     * @return Listado de objetivos
     * @author dmunoz
     * @date 06/07/2022
     */
    @AuraEnabled(cacheable=true)
    public static List<Objective__c> getObjetives(String year){
        try {
            List<Objective__c> result = ObjectivesSelector.selectObjectivesByYear(year);

            for (Objective__c o: result) {
                o.January__c = o.January__c/100;
                o.February__c = o.February__c/100;
                o.March__c = o.March__c/100;
                o.April__c = o.April__c/100;
                o.May__c = o.May__c/100;
                o.June__c = o.June__c/100;
                o.July__c = o.July__c/100;
                o.August__c = o.August__c/100;
                o.September__c = o.September__c/100;
                o.October__c = o.October__c/100;
                o.November__c = o.November__c/100;
                o.December__c = o.December__c/100;
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Obtiene un listado de años para el selector según los valores de la picklist Year__c del objeto Objetivos     
     * @return Listado de años
     * @author dmunoz
     * @date 06/07/2022
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getSelectorYearList(){
        try {

            List<String> result = new List<String>();

            Schema.DescribeFieldResult fieldResult = Objective__c.Year__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                result.add(pickListVal.getLabel());
            }           

            return result;            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    
    

    /**
     * Actualiza los registros modificados por la edicion in line del componente
     * @param data: datos modificados en el componente LWC
     * @return map con los atributos para los mensajes toast y si procede argumentos para construir el objeto error
     * @author dmunoz
     * @date 06/07/2022
     */
    @AuraEnabled
    public static Map<String, String> updateObjectives(String data) {
        Map<String, String> result = new Map<String, String>();
        Map<String, String> updateResultMap = new Map<String, String>();
        Map<String, String> toastInfoMap = new Map<String, String>();
        String variant; // variante del toast: success, warning, error
        String toastMessage; // mensaje a mostrar en el toast
        String title; // titulo del toast

        String errorIds = '';
        String errorMessage = '';

        try {
            if (data != null) {
                List<Objective__c> objectivesForUpdate = (List<Objective__c>) JSON.deserialize(
                    data,
                    List<Objective__c>.class
                );
    
                System.debug('actualizar ' + objectivesForUpdate);
                updateResultMap = updateRecords(objectivesForUpdate);
                toastInfoMap = getToastInfoUpdateRecords(updateResultMap.get('numSuccess'), updateResultMap.get('numFailures'));
    
                title = toastInfoMap.get('title');
                variant = toastInfoMap.get('variant');
                toastMessage = toastInfoMap.get('toastMessage');    
                   
            } else {
                variant = 'error';
                title = System.Label.SDM_Objetivos_Error;
                toastMessage = System.Label.SDM_Objetivos_ErrorInput;
                errorIds = '';
                errorMessage = '';
            }

            result.put('title', title);
            result.put('variant', variant);
            result.put('toastMessage', toastMessage); 
            result.put('errorIds', updateResultMap.get('errorIds'));
            result.put('errorMessage', updateResultMap.get('errorMessage'));
    
        } catch (Exception e) {
            System.debug('error trace ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());            
        }
            
        System.debug('result ' + result);
        return result;
    }



    /********************************* Métodos Auxiliares ********************************************************************/

    /**
     * Llamada a BD para actualizar registros
     * @param objectivesForUpdate: datos a actualizar enviados por el componente LWC
     * @return map con los atributos para los mensajes toast y si procede argumentos para construir el objeto error
     * @author dmunoz
     * @date 06/07/2022
     */
    private static Map<String, String> updateRecords(List<Objective__c> objectivesForUpdate) {
        Map<String, String> result = new Map<String, String>();
        Integer numSuccess = 0;
        Integer numFailures = 0;
        List<String> idsList = new List<String>(); // lista ids con error
        String errorIds = ''; // ids concatenados para el json a montar en el controlador JS. Ej id1,id2,...,idn
        List<String> recordErrorsList = new List<String>(); // añado los errores de cada registro aquí para hacer join con ","
        String recordErrors = ''; // aqui hago el join de recordErrorsList para cada registro, variable auxiliar
        List<String> errorList = new List<String>(); // añado los errores calculados en recordErrors
        String errorMessage = ''; // err1,err2|err1|err1 separo los errores de cada id por |

        Database.SaveResult[] srList = Database.update(objectivesForUpdate, false);
                
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {                    
                numSuccess++;

            } else {
                numFailures++;
                idsList.add(sr.getId());

                for(Database.Error err : sr.getErrors()) {
                    recordErrorsList.add(err.getMessage());
                }
                
                // hago join, añado a la lista de errores finales y blanqueo variables
                recordErrors = String.join(recordErrorsList, ',');
                recordErrorsList.clear();
                errorList.add(recordErrors);

                recordErrors = '';
            }
        }

        errorIds = String.join(idsList, ',');
        errorMessage = String.join(errorList, '|');

        result.put('numSuccess', String.valueOf(numSuccess));
        result.put('numFailures', String.valueOf(numFailures));
        result.put('errorIds', errorIds);
        result.put('errorMessage', errorMessage);

        return result;
    }

    /**
     * En función del numero de resultados de updateRecords seteo los valores que va a tener el toast a mostrar
     * @param numSuccessInput: numero de registros actualizados con exito
     * @param numFailuresInput: numero de registros actualizados con error
     * @return map con los atributos para los mensajes toast y si procede argumentos para construir el objeto error
     * @author dmunoz
     * @date 06/07/2022
     */
    private static Map<String, String> getToastInfoUpdateRecords(String numSuccessInput, String numFailuresInput) {
        Map<String, String> result = new Map<String, String>();
        String variant; // variante del toast: success, warning, error
        String toastMessage; // mensaje a mostrar en el toast
        String title; // titulo del toast

        Integer numSuccess = Integer.valueOf(numSuccessInput);
        Integer numFailures = Integer.valueOf(numFailuresInput);

        if (numSuccess > 0 && numFailures == 0) {
            variant = 'success';
            title = System.Label.SDM_Objetivos_Success;
            toastMessage = String.format(System.Label.SDM_Objetivos_ToastMessage, new List<String> {String.valueOf(numSuccess)});
        } else if (numSuccess > 0 && numFailures > 0) {
            variant = 'warning';
            title = System.Label.SDM_Objetivos_Warning;
            toastMessage = String.format(System.Label.SDM_Objetivos_ToastMessageWithError, new List<String> {String.valueOf(numSuccess), String.valueOf(numFailures)});
        } else if (numFailures > 0) {
            variant = 'error';
            title = System.Label.SDM_Objetivos_Error;
            toastMessage = String.format(System.Label.SDM_Objetivos_ToastMessageWithError, new List<String> {String.valueOf(numSuccess), String.valueOf(numFailures)});
        }

        result.put('variant', variant);
        result.put('title', title);
        result.put('toastMessage', toastMessage);

        return result;
    }
}
