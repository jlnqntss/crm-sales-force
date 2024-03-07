/**
 * Clase trigger para el evento ZRMLeadATM__e
 *
 * @author dmunoz
 * @date 07/03/2024 
 */
trigger GenerateZRMLeadATMTrigger on ZRMLeadATM__e (after insert)
{
    if (Trigger.new != null)
    {
        GenerateZRMLeadATMUtil.handleEventAfterInsert(Trigger.New);
        
    }
}