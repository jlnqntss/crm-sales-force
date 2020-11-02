/**
 * Trigger que captura los eventos de error
 **
 * @author nts
 * @date 02/04/2020
 */
trigger ErrorEventTrigger on Error_Event__e(after insert)
{
    if (Trigger.New != null)
    {
        ErrorLogUtil.handleErrors(Trigger.New);
    }
}