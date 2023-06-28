/*
 * Esta acción es llamada desde un flow para separar los diferentes email que puedan estar presentes en el "to" del EmailMessage
 * @author lrodriguez6@seidor.es
 * @date 26/06/2023
 */
public class SplitEmailAddress
{
    /*
     * Método realiza split en un String
     * Puede ser llamado por distintos flows al mismo tiempo, por eso el parámetro de entrada es una Lista de String
     * y el de salida es una lista de listas
     * @author lrodriguez6@seidor.es
     * @date 27/06/2023
     * @param List<String> FlowInputs flowInputs String recibidos desde el flow
     * @return List<List<String>> Lista de respuestas que reciben los flows
     */
    @InvocableMethod
    (  
        label='Split String'
        description='Returns a list of String'
    )
    public static List<List<String>> SplitEmailAddress(List<FlowInputs> flowInputs)
    {
        List<String> listString = new List<String>();
        List<List<String>> listsToReturn = new List<List<String>>();

        
        for(FlowInputs currentInput : flowInputs)
        {
            listString=currentInput.stringToSplit.split('; ');
            listsToReturn.add(listString);
        }

        
        return listsToReturn;
    }
    /*0
    * Esta clase es usada para introducir  parametros en el método invocable
    * @author  lrodriguez6@seidor.es
    * @date 28/06/2023
    */
    public class FlowInputs
    {
        // registros 
        @InvocableVariable 
        public String stringToSplit;
    
    }
}