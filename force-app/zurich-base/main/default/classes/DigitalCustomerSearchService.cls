public without sharing class DigitalCustomerSearchService
{//Se necesita without sharing para que se hagan querys con usuarios de OCS en Klinc

    /**
     * Busca y encuentra pólizas de KLINC clientes a través del DNI del contacto de KLINC.
     * @param nationalId : String - Nº de documento.
     * @return Devuelve el listado de orders encontrado
     */
    public static Order[] findPoliciesByCustomerDocument(String nationalId)
    {
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});

        return ordersSelector.selectByDNI(nationalId);
    }

    /**
     * Busca y encuentra pólizas de KLINC clientes a través del Email del contacto de KLINC.
     * @param email : String - email.
     * @return Devuelve el listado de orders encontrado
     */
    public static Order[] findPoliciesByCustomerEmail(String email)
    {
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});

        return ordersSelector.selectByEmail(email);
    }

    /**
     * Busca y encuentra pólizas de KLINC clientes a través del MobilePhone del contacto de KLINC.
     * @param phone : String - MobilePhone.
     * @return Devuelve el listado de orders encontrado
     */
    public static Order[] findPoliciesByCustomerPhone(String phone)
    {
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});

        return ordersSelector.selectByMobilePhone(phone);
    }
}
