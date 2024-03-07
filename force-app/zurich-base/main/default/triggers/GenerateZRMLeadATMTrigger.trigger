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
        try
        {
            GenerateZRMLeadATMUtil.handleEventAfterInsert(Trigger.New);

        }
        catch (Exception e)
        {
            if (EventBus.TriggerContext.currentContext().retries < 9)
            {
                throw new EventBus.RetryableException( e.getMessage() );
            }
            else
            {
                ErrorLogUtil.commitError(e, 'GenerateZRMLeadATMTrigger', 'handleEventAfterInsert');
            }
        }
    }
}