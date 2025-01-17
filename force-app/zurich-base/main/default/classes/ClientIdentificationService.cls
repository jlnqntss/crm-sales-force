public with sharing class ClientIdentificationService
{

    public static Set<String> currentReceivedFields = new Set<String>(); // Campos que nos envían desde el JSON
    public static Set<String> requiredFieldsMetadataSet = new Set<String>(); // Campos obligatorios

    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String EMPTY_FIELD_STATUSCODE = 'EMPTY_FIELD';
    public static final String FIELD_REQUIRED_MESSAGE = 'A required field is empty';

    public ClientIdentificationService()
    {}

    public static String processData(Client receivedData, String finding)
    {
        switch on finding {
            // 1 - POST /people: Procesa la búsqueda de clientes
            when 'findByPolicyNumber' {
                return getByPolicyNumber(receivedData);
            }
            when 'findByPhone' {
                return getByPhone(receivedData);
            }
            when 'findByRegistrationNumber' {
                return getByRegistrationNumber(receivedData);
            }
            when else {
                return 'error';
            }
        }
    }

    
    /**
     * Método para recuperar la información de una persona en base a un Teléfono
     *
     * @author arcortazar
     * @date
     * @last modified on  : 11-01-2024
     * @last modified by  : jfherrero
     */
    
    public static String getByPolicyNumber(Client receivedData)
    {
        if ( String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.policyNumber) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      FIELD_REQUIRED_MESSAGE
                      );
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();
        AssetsSelector assetsSelector = new AssetsSelector();

        SearchResult resultado = new SearchResult();
        resultado.isValidPolicy = false;

        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        resultado.existsNationalID = false;
        resultado.existsPolicy = false;

        // Comprobamos si existe una poliza asignada al DNI que nos envían:
        // 1.- Obtenemos el ID del Account
        List<Account> cuentasEncontradas = accountsSelector.findByNationalId(new List<String> { receivedData.nationalID }, '');
        List<Policy__c> polizasEncontradas = new List<Policy__c>();

        if( !cuentasEncontradas.isEmpty() )
        {
            resultado.existsNationalID = true;
            polizasEncontradas = policiesSelector.selectByInfoPolicyNumberAndNationalId(new List<String> { receivedData.nationalID },new List<String> { receivedData.policyNumber });
        }
        else
        {
            resultado.existsNationalID = false;
            polizasEncontradas = policiesSelector.selectByNumber(receivedData.policyNumber);
        }

        if( !polizasEncontradas.isEmpty() )
        {
            resultado.existsPolicy = true;
            if(polizasEncontradas[0].PolicyStatus__c == 'V')
            {
                resultado.isValidPolicy = true;
            }
        }

        // Tan solo si los tres flags son true les vamos a pasar los valores
        if (resultado.existsNationalID && resultado.existsPolicy && resultado.isValidPolicy)
        {
            resultado.policyEndDate = polizasEncontradas[0].EndDate__c;
            resultado.policyStartDate = polizasEncontradas[0].StartDate__c;
            resultado.policyVersion = polizasEncontradas[0].policyVersion__c;
            
            List<String> listaPolizas = new List<String>();
            for (Policy__c p : polizasEncontradas)
            {
                listaPolizas.add(p.id);
            }
            
            List<Asset> obtainedAssets = assetsSelector.selectByPolicyID(listaPolizas);
            if(!obtainedAssets.isEmpty())
            {
                resultado.policyInfoInsuredObject = obtainedAssets[0].INFOInsuredObjectCode__c;
            }

            Map<Id, Product2> obtainedProductsMap = getPolicyProductsMap(polizasEncontradas);
                
            if(obtainedProductsMap?.size() > 0)
            {
                resultado.technicalCode =  obtainedProductsMap.get(polizasEncontradas[0].ProductId__c).TechnicalCode__c;
            }
        } 

        return resultado.toString();

    }

    /**
     * Método para recuperar la información de una persona en base a un Teléfono
     *
     * @author arcortazar
     * @date
     * @last modified on  : 30-10-2023
     * @last modified by  : jfherrero
     */
    
    public static String getByPhone(Client receivedData)
    {
        SearchResultLong resultado = new SearchResultLong();
        List<InsuredObject> listaObjetos = new List<InsuredObject>();
        resultado.objects = listaObjetos;
        
        // Comprobamos si los datos nos vienen rellenos
        if ( String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.phoneNumber) || String.isBlank(receivedData.groupDescription) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      FIELD_REQUIRED_MESSAGE
                      );
        }

        String composedPhoneNumber = String.join(new List<String>{receivedData.phonePrefix, receivedData.phoneNumber}, '');

        // Buscamos account por DNI + Telefono
        AccountsSelector accountsSelector = new AccountsSelector();

        List<Account> cuentasEncontradas = accountsSelector.findByNationalIdAndPhoneNumber(new List<String> { receivedData.nationalID }, '', new List<String> {composedPhoneNumber, receivedData.phoneNumber});

        if (cuentasEncontradas?.size() > 0)
        {
            resultado.existsPhoneNumber = true;
        }
        
        //En las clases test no vamos a recibir cuentas encontradas porque hay implicadas consultas SOSL.
        //Por tanto, utilizaremos esta clase visible por test para cubrir el código
        resultado = setInsuredObjectsByPhone(receivedData, composedPhoneNumber, resultado, listaObjetos, cuentasEncontradas);
        
        return resultado.toString();
	}
    
    //NUEVO
    /**
     * Método para recuperar la información de una persona en base a un Número de Matrícula
     *
     * @author jfherrero
     * @date 24/10/2023
     */
    
    public static String getByRegistrationNumber(Client receivedData)
    {
        SearchResultLong resultado = new SearchResultLong();
        List<InsuredObject> listaObjetos = new List<InsuredObject>();
        resultado.objects = listaObjetos;

        // Comprobamos si los datos nos vienen rellenos
        if ( String.isBlank(receivedData.registrationNumber) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      FIELD_REQUIRED_MESSAGE
                      );
        }

        List<String> listaRegNumbers = new List<String>{receivedData.registrationNumber};
            
		// Buscamos primero el Asset a través de su matrícula
		AssetsSelector assetsSelector = new AssetsSelector();
        List<Asset> listaAssets = assetsSelector.selectByRegistrationNumber(listaRegNumbers); //Necesitamos Modelo del vehículo, Marca del vehículo
        Set<String> policyIds = new Set<String>();
        
        for(Asset asset : listaAssets)
        {
            policyIds.add(asset.PolicyId__c);
        }
        
        // Si hay assets recuperamos las pólizas
        if (listaAssets.size()>0)
        {  	
            resultado.existsRegistrationNumber = true;
            
            // Sacamos las pólizas asociadas a las matrículas
        	Map<String, Policy__c> policyMap = getPolicyMap(policyIds, receivedData.groupDescription);
            
            // Sacamos los productos asociados a esas pólizas
            Map<Id, Product2> obtainedProductsMap = getPolicyProductsMap(policyMap.values());
            
            // Si los assets tienen pólizas, recuperamos los tomadores y los partners
            if (policyMap.size()>0)
        	{
                //Obtenemos los datos de los tomadores y los partners
            	Map<String, Account> accountMap = getAccountMap(policyMap); 
                
            	// Para cada asset recuperado vamos a generar un 
                for(Asset a : listaAssets)
                {
                    InsuredObject obj = setInsuredObjectByRegistrationNumber(a, policyMap, accountMap, obtainedProductsMap);
                    listaObjetos.add(obj);
                }
                
                resultado.objects = listaObjetos;
            }        
        }
        return resultado.toString();
    }

    //#region Métodos auxiliares
    /**
     * Método que carga el set de campos que hemos recibido desde el JSON
     *
     * @author arcortazar
     * @date 09/06/2022
     */
    public static void setCurrentFields(String field)
    {
        currentReceivedFields.add(field.toLowerCase());
    }

    /**
     * Método que valida que no falte ninguno de los campos requeridos
     *
     * @return List<String> fieldsNotFound listado de campos no encontrado en el JSON
     * @author rlopez
     * @date 21/10/2020
     */

     public static void validateReceivedInformation(Client receivedData, String identificationType)
     {
        // Obtenemos los campos que son mandatorios
        List<Client_Identification__mdt> allFieldsMetadataSet = Client_Identification__mdt.getAll().values();
        List<Client_Identification__mdt> requiredFieldsMetadataSet = new List<Client_Identification__mdt>();
        for (Client_Identification__mdt m : allFieldsMetadataSet)
        {
            if(m.Identification__c.equals('All') || m.Identification__c.contains(identificationType))
            {
                requiredFieldsMetadataSet.add(m);
            }
        }

        // Comprobamos que entre los recibidos están los mandatorios
        List<String> fieldsNotFound = new List<String>();
        for (Client_Identification__mdt field : requiredFieldsMetadataSet)
        {
            if ( !currentReceivedFields.contains( field.Label.toLowercase() ) )
            {
                fieldsNotFound.add( field.Label.toLowercase() );
            }
        }

        // Si no están, lanzamos excepción
        if( !fieldsNotFound.isEmpty() )
        {
            throw new ClientIdentificationException(
                      INVALID_FIELD_STATUSCODE,
                      'The following fields are missing: ' +
                      fieldsNotFound.toString()
                      );
        }
    }
    
    /**
     * Método para generar el mapa de pólizas
     *
     * @author jfherrero
     * @date 03/11/2023
     */
    private static Map<String, Policy__c> getPolicyMap(Set<String> policyIds, String groupDescription)
    {
        Map<String, Policy__c> policyMap = new Map<String, Policy__c>(); 
        // Preparamos mapa de pólizas
        PoliciesSelector policiesSelector = new PoliciesSelector();
        
        List<Policy__c> policyList = policiesSelector.selectByIdAndRecordType(policyIds, new Set<String>{groupDescription}, new Set<String>()); //Necesitamos Name -> Número de Póliza
        
        for(Policy__c policy : policyList)
        {
            policyMap.put(policy.Id, policy);
        }
        
        return policyMap;
    }
    
    /**
     * Método para recuperar información de productos asociados a las pólizas
     *
     * @author jfherrero
     * @date 11/01/2024
     */
    @TestVisible
    private static Map<Id, Product2> getPolicyProductsMap(List<Policy__c> polizasEncontradas)
    {                
        List<String> productIds = new List<String>();
        
        for (Policy__c pol : polizasEncontradas)
        {     
            if (pol.ProductId__c != null)
            {
                productIds.add(pol.ProductId__c);
            }
        }
        
        List<Product2> obtainedProducts = new ProductsSelector(
            							new Set<String> {'Id', 'Name', 'CommercialCode__c', 'TechnicalCode__c'}
                        				).selectByID(productIds);
        
        Map<Id, Product2> obtainedProductsMap = new Map<Id, Product2>();
        
        for (Product2 prod : obtainedProducts)
        {
            obtainedProductsMap.put (prod.Id, prod);
        }
        
        return obtainedProductsMap;
    }

    /**
     * Método para generar el mapa de Accounts relacionados con las pólizas
     * vamos a necesitar a los tomadores y a los partners
     *
     * @author jfherrero
     * @date 03/11/2023
     */
    private static Map<String, Account> getAccountMap(Map<String, Policy__c> policyMap)
    {
        Map<String, Account> accountMap = new Map<String, Account>();
        
        Set<Id> holderIds = new Set<Id>();
        
        for (String pol : policyMap.keySet())
        {
            if (policyMap.get(pol).PolicyHolder__c != null)
            {
                holderIds.add(policyMap.get(pol).PolicyHolder__c);
            }
            if (policyMap.get(pol).Partner__c != null)
            {
                holderIds.add(policyMap.get(pol).Partner__c);
            }
        }
        
        AccountsSelector accountsSelector = new AccountsSelector();
        List<Account> accountList = accountsSelector.selectById(holderIds);             
        
        for(Account holder : accountList)
        {
            accountMap.put(holder.Id, holder);
        }
        
        return accountMap;
    }
    
   /**
     * Método para generar el mapa de pólizas
     *
     * @author jfherrero
     * @date 03/11/2023
     */
    private static InsuredObject setInsuredObjectByRegistrationNumber(Asset asset, Map<String, Policy__c> policyMap,
                                                                      Map<String, Account> accountMap, Map<Id, Product2> obtainedProductsMap)
    {
        InsuredObject obj = new InsuredObject();

        // Datos del asset
        obj.model = asset.Model__c;
        obj.brandName = asset.BrandName__c;
        
        // Datos de la póliza
        if(policyMap.get(asset.PolicyId__c) != null)
        {
            obj.policyName = policyMap.get(asset.PolicyId__c).Name;
            obj.policyStatus = policyMap.get(asset.PolicyId__c).PolicyStatus__c ;
            obj.policyEndDate = policyMap.get(asset.PolicyId__c).EndDate__c;
            obj.policyStartDate = policyMap.get(asset.PolicyId__c).StartDate__c;
            
            if(obtainedProductsMap.get(policyMap.get(asset.PolicyId__c).ProductId__c) != null)   
            {
                obj.technicalCode = obtainedProductsMap.get(policyMap.get(asset.PolicyId__c).ProductId__c).TechnicalCode__c;
            }
            
            
            // Datos del tomador de la póliza
            if (accountMap.get(policyMap.get(asset.PolicyId__c).PolicyHolder__c) != null)
            {
                obj.holderName = accountMap.get(policyMap.get(asset.PolicyId__c).PolicyHolder__c).Name;
                obj.holderNationalId = accountMap.get(policyMap.get(asset.PolicyId__c).PolicyHolder__c).NationalId__c;
            }
            
            // Datos del partner
            if (accountMap.get(policyMap.get(asset.PolicyId__c).Partner__c) != null)
            {
                obj.partnerSector = accountMap.get(policyMap.get(asset.PolicyId__c).Partner__c).PartnerSector__c;
            }
        }
        
        return obj;
    }
    
   /**
    * 
    */
    @TestVisible
    private static SearchResultLong setInsuredObjectsByPhone(Client receivedData, String composedPhoneNumber, SearchResultLong resultado,
                                                             List<InsuredObject> listaObjetos, List<Account> cuentasEncontradas)
    {
        if(!cuentasEncontradas.isEmpty())
        {
            PoliciesSelector policiesSelector = new PoliciesSelector();
            AssetsSelector assetsSelector = new AssetsSelector();
            
            resultado.nationalID = receivedData.nationalID;
            resultado.phoneNumber = composedPhoneNumber;

            List<Policy__c> polizasEncontradas = policiesSelector.selectByHolderAndGroupDescription(cuentasEncontradas[0].id, receivedData.groupDescription);
            
            if(!polizasEncontradas.isEmpty())
            {
                Map<Id, Product2> obtainedProductsMap = getPolicyProductsMap(polizasEncontradas);
                
                Map<Id, Policy__c> mapaPolizas = new Map<Id, Policy__c>();
                List<Id> listaPolIds = new List<Id>();
                for(Policy__c pol : polizasEncontradas)
                {
                    listaPolIds.add(pol.id);
                    mapaPolizas.put(pol.id, pol);
                }

                List<Asset> listaAssets = assetsSelector.selectByPolicyID(listaPolIds);
                for(Asset a : listaAssets)
                {
                    InsuredObject obj = new InsuredObject();

                    // Datos correspondientes al Asset
                    obj.name = a.Name;
                    obj.registrationNumber = a.RegistrationNumber__c;
                    obj.model = a.Model__c;
                    obj.addressType = a.AddressType__c;
                    obj.addressName = a.AddressName__c; 
                    obj.addressNumber = a.AddressNumber__c;
                    obj.addressAdditionalInfo = a.AddressAdditionalInfo__c;
                    obj.city = a.City__c; 

                    // Datos correspondientes a la poliza como tal
                    obj.policyInfoInsuredObject = a.INFOInsuredObjectCode__c;
                    obj.policyName = mapaPolizas.get(a.PolicyId__c).Name;
                    obj.policyEndDate = mapaPolizas.get(a.PolicyId__c).EndDate__c;
                    obj.policyStartDate = mapaPolizas.get(a.PolicyId__c).StartDate__c;
                    obj.policyVersion = mapaPolizas.get(a.PolicyId__c).PolicyVersion__c;
                    
                    if(obtainedProductsMap.get(mapaPolizas.get(a.PolicyId__c).ProductId__c) != null)
                    {
                        obj.technicalCode = obtainedProductsMap.get(mapaPolizas.get(a.PolicyId__c).ProductId__c).TechnicalCode__c;
                    }

                    listaObjetos.add(obj);
                }

                resultado.objects = listaObjetos;
            }
        }
        return resultado;
    }
    
    //#endregion


    //#region Inner Classes
    /**
     * Representa la información del cliente que llega desde Thunder
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class Client
    {
        public Client()
        {}

        public String fullName {
            get;
            set {
                setCurrentFields('fullName');
                fullName = value;
            }
        }

        public String nationalID {
            get;
            set {
                setCurrentFields('nationalID');
                nationalID = value;
            }
        }
        
        public String policyNumber {
            get;
            set {
                setCurrentFields('policyNumber');
                policyNumber = value;
            }
        }
        
        public String phonePrefix {
            get;
            set {
                setCurrentFields('phonePrefix');
                phonePrefix = value;
            }
        }
        
        public String phoneNumber {
            get;
            set {
                setCurrentFields('phoneNumber');
                phoneNumber = value;
            }
        }

        public String groupDescription {
            get;
            set {
                setCurrentFields('groupDescription');
                groupDescription = value;
            }
        }

        public String registrationNumber {
            get;
            set {
                setCurrentFields('registrationNumber');
                registrationNumber = value;
            }
        }
        
        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class SearchResult
    {
        public Boolean isValidPolicy;
        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        public Boolean existsNationalID;
        public Boolean existsPolicy;
        public Date policyEndDate;
        public Date policyStartDate;
        public String policyVersion;
        public String policyInfoInsuredObject;

        // arcortazar - 31/01/2023 - [OCS-5874]
        public String technicalCode;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }
   
    public class SearchResultLong
    {
        public String nationalID;
        public String phoneNumber;
        public Boolean existsPhoneNumber;
        public Boolean existsRegistrationNumber;
        public List<InsuredObject> objects;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    public class InsuredObject 
    {
        //Policy info
        public String policyName;
        public String technicalCode;
        public String policyInfoInsuredObject;
        public String policyStatus;
        public Date policyStartDate;
        public Date policyEndDate;
        public String policyVersion;
        public String partnerSector;
        //Holder info
        public String holderName;
        public String holderNationalId;
        //Object info
        public String name;
        public String brandName;
        public String registrationNumber;
        public String model;
        public String addressType;
        public String addressName;
        public String addressNumber;
        public String addressAdditionalInfo;
        public String city;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }


    //#endregion

    //#region Excepciones

    @TestVisible
    public class ClientIdentificationException extends Exception
    {
        public String statusCode;
        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        /**
         * Constructor por defecto
         * @author arcortazar
         * @created date: 09/06/2022
         */
        public ClientIdentificationException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }

    //#endregion
}