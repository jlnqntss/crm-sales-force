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
     * Obtiene un listado de Objetivos dado un año 
     * @param data: datos seleccionados en el componente LWC
     * @param year: String con el año a consultar
     * @return año de entrada + 1 
     * @author dmunoz
     * @date 06/07/2022
     */
    @AuraEnabled
    public static Map<String, String> cloneRecords(String data, String year) {
        try { // SDM_Objetivos_ToastCloneRecord -> mensaje Ok

            System.debug('input ' + data);
            Map<String, String> result = new Map<String, String>();
            String toastMessage = '';
            String title;
            String variant;
            String newYear;

            if (data == null || year == null || String.isEmpty(year)) {
                title = System.Label.SDM_Objetivos_Error;
                variant = 'error';
                toastMessage = System.Label.SDM_Objetivos_ErrorInput;
                newYear = String.valueOf(Date.today().Year());

            } else {
                List<Objective__c> objectivesList = (List<Objective__c>) JSON.deserialize(
                    data,
                    List<Objective__c>.class
                );

                List<Objective__c> objectivesToClone = new List<Objective__c>();
                newYear = String.valueOf(Integer.valueOf(year) + 1);

                // comparo los objetivos de este año con los del año siguiente
                Map<String, String> compareRecordsMap = compareSelectedWithNextYearRecords(objectivesList, newYear);

                if ('true'.equals(compareRecordsMap.get('hasDuplicate'))) {
                    System.debug('hay duplicado');
                    title = System.Label.SDM_Objetivos_Error;
                    variant = 'error';
                    toastMessage = System.Label.SDM_Objetivos_DuplicateRecords;
                    newYear = year; // reseteo el año al de entrada
                    
                    result.put('duplicateIds', compareRecordsMap.get('duplicateIds'));
                } else {
                    System.debug('no hay duplicado');
                    // multiplico el porcentaje x100 y añado el valor de año
                    objectivesToClone = getClonedObjectives(objectivesList, newYear);
                    System.debug('Ready to insert: ' + objectivesToClone);

                    // inserto
                    if (!objectivesToClone.isEmpty()) {
                        insert objectivesToClone;

                        // preparo la salida del toast
                        variant = 'success';
                        title = System.Label.SDM_Objetivos_Success;
                        toastMessage = System.Label.SDM_Objetivos_ToastCloneRecord;
                    }                   
                }                
            }

            result.put('title', title);
            result.put('variant', variant);
            result.put('toastMessage', toastMessage);
            result.put('year', newYear);       
            
            return result;

        } catch (Exception e) {
            System.debug('error traza ' + e.getStackTraceString());
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

    /**
     * En función del numero de resultados de updateRecords seteo los valores que va a tener el toast a mostrar
     * @param selectedObjectivesList: lista de objetivos seleccionados en LWC
     * @param newYear: año +1 del año seleccionado en el LWC
     * @return map con la información para los duplicados
     * @author dmunoz
     * @date 06/07/2022
     */
    private static Map<String, String> compareSelectedWithNextYearRecords(List<Objective__c> selectedObjectivesList, String newYear) {
        Map<String, String> result = new Map<String, String>();
        String hasDuplicate = 'false';
        List<String> idsDuplicatesList = new List<String>();

        Set<String> externalIdsNextYear = getExternalIdObjectivesNextYear(newYear);

        // si externalIdsNextYear está vacio es un OK
        if (externalIdsNextYear.isEmpty()) {
            hasDuplicate = 'false';
        } else {
            // comparo los external id de los registros seleccionados con el externalId de los registros consultados
            String convertedExternalId;
            for(Objective__c obj: selectedObjectivesList) {
                convertedExternalId = getConvertedExternalId(obj.ExternalId__c, newYear); // sumo al external id un año para comparar correctamente
                for (String externalIdNextYear: externalIdsNextYear) {
                    if (convertedExternalId.equals(externalIdNextYear)) {
                        System.debug('duplicado para ' + obj.Id);
                        idsDuplicatesList.add(obj.Id); // guardar los ids que coinciden
                    }
                }                    
            }
        }

        if (!idsDuplicatesList.isEmpty()) {
            hasDuplicate = 'true';
        } else {
            hasDuplicate = 'false';
        }

        result.put('hasDuplicate', hasDuplicate);
        result.put('duplicateIds', String.join(idsDuplicatesList, ','));

        System.debug('result compareSelectedWithNextYearRecords ' + result);

        return result;
    }

    /**
     * Obtener la lista de ExternalId de los registros para el año +1
     * @param newYear: año +1 del año seleccionado en el LWC
     * @return Set con los ExternalId obtenidos de la BD
     * @author dmunoz
     * @date 06/07/2022
     */
    private static Set<String> getExternalIdObjectivesNextYear(String newYear) {
        Set<String> result = new Set<String>();

        List<Objective__c> nextYearObjectives = ObjectivesSelector.selectObjectivesByYear(newYear);

        for (Objective__c obj: nextYearObjectives) {
            result.add(obj.ExternalId__c);
        }

        return result;
    }

    /**
     * Para poder comparar los External Ids de los registros seleccionados, tengo que convertirlos a año+1 para ver si son iguales con los obtenidos de la query año +1
     * @param externalId: external id del objetivo seleccionado a clonar
     * @param newYear: año +1 del año seleccionado en el LWC
     * @return string con el external id modificado
     * @author dmunoz
     * @date 06/07/2022
     */
    private static String getConvertedExternalId(String externalId, String newYear) {
        String result = '';

        // corto el externalId por -
        String[] externalIdSplit = externalId.split('-');

        // modifico el año
        externalIdSplit[0] = newYear;

        // join de los elementos
        result = String.join(externalIdSplit, '-');

        return result;
    }

    /**
     * Clonamos los objetivos de entrada preparando los datos, con año +1 y porcentajes x100
     * @param objectivesList: lista de objetivos seleccionados a clonar
     * @param newYear: año +1 del año seleccionado en el LWC
     * @return lista de objetivos clonados
     * @author dmunoz
     * @date 06/07/2022
     */
    private static List<Objective__c> getClonedObjectives(List<Objective__c> objectivesList, String newYear) {
        
        List<Objective__c> result = new List<Objective__c>();
        if (!objectivesList.isEmpty()) {
            Objective__c objClone;                
            for (Objective__c objective: objectivesList) {
                objective.Year__c = newYear;      
                objective.January__c = objective.January__c * 100;
                objective.February__c = objective.February__c * 100;
                objective.March__c = objective.March__c * 100;
                objective.April__c = objective.April__c * 100;
                objective.May__c = objective.May__c * 100;
                objective.June__c = objective.June__c * 100;
                objective.July__c = objective.July__c * 100;
                objective.August__c = objective.August__c * 100;
                objective.September__c = objective.September__c * 100;
                objective.October__c = objective.October__c * 100;
                objective.November__c = objective.November__c * 100;
                objective.December__c = objective.December__c * 100;

                objClone = objective.clone(false, false, false, false);
                result.add(objClone);
            }
        }
        return result;
    }
}
