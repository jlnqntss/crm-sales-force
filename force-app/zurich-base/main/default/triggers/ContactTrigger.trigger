/**
 * Trigger de actualización de campos de contacto
 **
 * @author nbizkarra
 * @date 15/04/2020
 */
trigger ContactTrigger on Contact(
    before insert, after insert,
    before update, after update,
    before delete, after delete
    )
{
    TriggerFactory.createHandler(Contact.sObjectType);

}