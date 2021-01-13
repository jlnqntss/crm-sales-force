trigger GenerateScopeEventTrigger on GenerateScopeEvent__e (after insert)
{
    if (Trigger.new != null)
    {
        try 
        {
            GenerateScopeUtil.handleEventsBatch(Trigger.New);

        } catch (Exception e) 
        {
            if (EventBus.TriggerContext.currentContext().retries < 9)
            {
                throw new EventBus.RetryableException( e.getMessage() );
            }
            else 
            {
                ErrorLogUtil.commitError(e, 'GenerateScopeEventTrigger', 'handleEventsBatch');
            }
        }
    }
}