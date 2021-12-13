/**
 * Trigger de actualización de campos de EmailMessage
 **
 * @author nts (agonzalezisasi)
 * @date 01/12/2021
 */
trigger EmailMessageTrigger on EmailMessage(before insert, after insert, before update, after update, before delete, after delete)
{
    TriggerFactory.createHandler(EmailMessage.sObjectType);
}