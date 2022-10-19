/*
 * Esta acción es llamada desde un flow para eliminar los registros duplicados en base a un campo
 * @author lrodriguez6@seidor.es
 * @date 10/10/2022
 */
public class RemoveDuplicatesAction
{
    /*
     * Método que elimina los registros duplicados
     * Puede ser llamado por distintos flows al mismo tiempo, por eso el parámetro de entrada es una lista
     * y el de salida es una lista de listas
     * @author lrodriguez6@seidor.es
     * @date 10/10/2022
     * @param List<FlowInputs> flowInputs Registros recibidos desde el flow
     * @return List<List<SObject>> Lista de respuestas que reciben los flows
     */
    @InvocableMethod
    (  
        label='Remove duplicates' 
        description='Returns a list of areas corresponding to the selected scaling type'
    )
    public static List<List<SObject>> removeDuplicates(List<FlowInputs> flowInputs)
    {
        List<List<SObject>> listsToReturn = new List<List<SObject>>();
        
        // Bucle utilizado para recorrer los input de cada uno de los flows
        for(FlowInputs currentInput : flowInputs)
        {
            List<SObject> filteredList= new List<SObject>();
            List<Object> valuesAdded = new List<Object>();
            // Se recorre la lista de registros recibida
            for (SObject currentRecord:currentInput.listToRemove)
            {
                if(filteredList.isEmpty() || !valuesAdded.contains(currentRecord.get(currentInput.fieldApiName)))
                {
                    //Si el registro no está repetido se añade a la lista
                    filteredList.add(currentRecord);
                    valuesAdded.add(currentRecord.get(currentInput.fieldApiName));
                }
            }
            listsToReturn.add(FilteredList);
        }
        return listsToReturn;
    }
    /*
    * Esta clase es usada para introducir dos parametros en el método invocable
    * @author  lrodriguez6@seidor.es
    * @date 10/10/2022
    */
    public class FlowInputs
    {
        // Lista de registros 
        @InvocableVariable 
        public List<SObject> listToRemove;
        // Nombre api del campo en base al cual se van a eliminar duplicados
        @InvocableVariable 
        public String fieldApiName;
    }
}