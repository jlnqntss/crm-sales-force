trigger GenerateScopeEventTrigger on GenerateScopeEvent__e (after insert)
{
    if (Trigger.new != null)
    {
        GenerateScopeUtil.handleEventsBatch(Trigger.New);
    }
}