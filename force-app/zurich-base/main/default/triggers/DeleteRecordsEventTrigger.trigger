trigger DeleteRecordsEventTrigger on DeleteRecordsEvent__e (after insert)
{
    if (Trigger.New != null)
    {
        DeleteRecordsEventUtil.handleEvents(Trigger.New);
    }
}