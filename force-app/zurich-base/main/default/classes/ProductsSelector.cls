public with sharing class ProductsSelector extends BaseSelector
{
    //#region Contructores
    public ProductsSelector()
    {}

    public ProductsSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Product2';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca Products a partir del Commercial Product Code
     *
     * @author rlopez
     * @date 25/11/2020
     * @param  commercialProductCodes     Listado de Commercial Product Codes
     * @param  technicalProductCodes     Listado de Technical Product Codes
     *
     * @return                            Listado de Product2 sobre los que se ha realizado match
     */
    public List<Product2> selectByCommercialPCAndTechnicalPC(Set<String> commercialProductCodes, Set<String> technicalProductCodes)
    {
        if(commercialProductCodes != null && technicalProductCodes != null)
        {
            String query = String.format(
                'SELECT {0} FROM Product2 ' +
                'WHERE CommercialCode__c IN : commercialProductCodes AND TechnicalCode__c IN : technicalProductCodes',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Product2>) Database.query(query);
        }
        else
        {
            return new List<Product2>();
        }
    }


    /**
     * Busca pólizas a partir de InfoPolicyNumber__c (Número de Póliza en transaccional INFO)
     * No se tiene en cuenta activa o no ya que se busca por un número de póliza específico
     *
     * @author xsobera
     * @date 20/01/2021
     * @param String policyNumber Número de póliza a buscar
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     */
    public List<Product2> selectByID(String productId)
    {
        if(String.isNotBlank(productId))
        {
            String query = String.format(
                'SELECT {0} FROM Product2 ' +
                'WHERE Id = : productId',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Product2>) Database.query(query);
        }
        else
        {
            return new List<Product2>();
        }
    }
}