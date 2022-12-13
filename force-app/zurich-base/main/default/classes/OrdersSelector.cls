public without sharing class OrdersSelector extends RecordsSelector
{ //Se necesita without sharing para que se hagan querys con usuarios de OCS en Klinc
    public static final String RECORDTYPE_DEVELOPER_NAME = 'RecordType.DeveloperName';
    public OrdersSelector()
    {
        super(Order.getSObjectType());
    }

    /**
     * KLINC: Busca pólizas activas a partir de DNI
     * @date 23/02/2021
     * @param String dni  DNI del contacto
     * @return List<Order> Listado de pólizas KLINC sobre los que se ha realizado match
     */
    public List<Order> selectByDNI(String dni)
    {
        if(dni != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq(RECORDTYPE_DEVELOPER_NAME, Label.PolicyLife),
                Query.conditionGe(RECORDTYPE_DEVELOPER_NAME, Label.PolicyGI)
            );

            this.baseQuery.addConditionEq('ContactId__r.DNI__c', dni).addConditionEq(Order.PolicyStatus__c, Label.PolicyStatusActive).addCondition(condition);

            return (List<Order>) this.baseQuery.run();
        }
        else
        {
            return new List<Order>();
        }
    }

    /**
     * KLINC: Busca pólizas activas a partir de Email
     * @date 23/02/2021
     * @param String email  Email del contacto
     * @return List<Order> Listado de pólizas KLINC sobre los que se ha realizado match
     */
    public List<Order> selectByEmail(String email)
    {
        if(email != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq(RECORDTYPE_DEVELOPER_NAME, Label.PolicyLife),
                Query.conditionGe(RECORDTYPE_DEVELOPER_NAME, Label.PolicyGI)
            );

            this.baseQuery.addConditionEq('ContactId__r.Email', email).addConditionEq(Order.PolicyStatus__c, Label.PolicyStatusActive).addCondition(condition);

            return (List<Order>) this.baseQuery.run();
        }
        else
        {
            return new List<Order>();
        }
    }

    /**
     * KLINC: Busca pólizas activas a partir de mobilephone
     * @date 23/02/2021
     * @param String mobilephone  mobilephone del contacto
     * @return List<Order> Listado de pólizas KLINC sobre los que se ha realizado match
     */
    public List<Order> selectByMobilePhone(String mobilephone)
    {
        if(mobilephone != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq(RECORDTYPE_DEVELOPER_NAME, Label.PolicyLife),
                Query.conditionGe(RECORDTYPE_DEVELOPER_NAME, Label.PolicyGI)
            );

            this.baseQuery.addConditionEq('ContactId__r.MobilePhone', mobilephone).addConditionEq(Order.PolicyStatus__c, Label.PolicyStatusActive).addCondition(condition);

            return (List<Order>) this.baseQuery.run();
        }
        else
        {
            return new List<Order>();
        }
    }

}
