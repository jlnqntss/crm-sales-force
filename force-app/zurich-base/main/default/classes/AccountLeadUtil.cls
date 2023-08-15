/**
 * @author overes
 * @date 09/08/2023
 */

public class AccountLeadUtil
{
    /**
     * FIXME: añadir una descripción
     * @author overes
     * @date 08/08/2023
     */
    public static void checkLeadDuplicates(List<Account> newList)
    { //FIXME: convertir SObject en listado de Accounts
        // comprobar que son accounts lo que recibo
        // invocar al método leadDuplicate...
        AccountUtil.checkOwner(newList);
        for (Account acc : newList)
        {
            if (leadDuplicatesControl(acc.NationalId__c, acc.Phone) != null) 
            {
                acc.NationalId__c.addError('Ya existe un Cuenta con el mismo Documento de identidad o Teléfono');
                // ❔ mostrar el error en el campo o general??
            }
        }
    }

    /**
     * FIXME: añadir una descripción
     * El proceso de control de duplicados recibe como datos de entrada 2 campos (NIF y/o Número de Teléfono) y devuelve la Cuenta de tipo Cliente o de tipo Lead localizada, en el caso de que se localice alguna.
     * @author overes
     * @date 08/08/2023
     * @return acc
     */
    public static Account leadDuplicatesControl(String documentID, String phone) 
    { //FIXME: revisar valor devuelto --> devuelve la cuenta de tipo Cliente o tipo Lead en caso que se localice alguna
        Account acc = new Account(); //FIXME: revisar si se ha de un new Account()
        if (documentID != null) //comprueba si el NIF está informado
        {
            List<Account> accList = [SELECT Id, RecordType.Name, NationalId__c FROM account WHERE NationalId__c =:documentID AND (RecordType.Name ='Customer' OR RecordType.Name ='Business Customer')];
            if (!accList.isEmpty())
            /*
            *          El método valida que existe un registro del objeto Cuenta
            *          con RecordType “Customer” o “Business Customer” con el valor del campo
            *          Documento de identidad (API Name: NationalID__c) igual al valor de documentID.
            */
            {//Si: El método finaliza devolviendo el registro de Cuenta-Cliente mediante acc
                acc = accList.get(0); //FIXME: revisar nomenclatura
                return acc;
            } else
            /**
            *  Sino:   El método valida que existe un registro del objeto Cuenta
            *          con RecordType “Lead” con el valor del campo
            *          Documento de identidad (API Name: NationalID__c) igual al valor de documentID.
            */
            {
                List<Account> accLeadList = [SELECT Id, RecordType.Name, NationalId__c FROM account WHERE NationalId__c =:documentID AND RecordType.Name ='Lead'];
                if (!accLeadList.isEmpty())
                { //Si: El método finaliza devolviendo el registro de Cuenta-Lead mediante acc
                    acc = accLeadList.get(0); //FIXME: revisar nomenclatura
                    return acc;
                }
            }
        } else
        {
            if(phone != null)
            /**
             *      El método valida que existe un registro del objeto Cuenta con RecordType Lead
             *      con el valor del campo Teléfono (API Name: Phone) igual al valor de Phone.
             */
            {
                List<Account> accPhoneList = [SELECT Id, RecordType.Name, NationalId__c FROM account WHERE Phone =:phone AND RecordType.Name ='Lead' ORDER BY CreatedDate DESC];
                if (accPhoneList.size() == 1) //Si existe solo una Cuenta-Lead, el método finaliza devolviendo el registro de la misma mediante acc.
                {
                    acc = accPhoneList.get(0);
                    return acc;
                }
                if (accPhoneList.size() > 1) //Si existe más de una Cuenta-Lead, el método finaliza devolviendo el registro Cuenta-Lead más reciente mediante acc.
                {
                    acc = accPhoneList.get(0);
                    return acc;
                }
            } else //Sino: El método finaliza devolviendo null.
            {
                return null; //FIXME: comprobar nomenclatura
            }
        }
        return acc;
    }
}