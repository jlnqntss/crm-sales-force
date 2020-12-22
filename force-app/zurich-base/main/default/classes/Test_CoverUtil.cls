/**
 * Clases de test para CoverUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */

@isTest(SeeAllData = false)
public with sharing class Test_CoverUtil
{
    @testSetup
    static void makeData()
    {}

    @IsTest
    static void test_createCovers()
    {
        Map<String, Cover__c> subCoversToInsertQuote = new Map<String, Cover__c>();
        Map<String, Cover__c> updateCover = new Map<String, Cover__c>();
        Map<String, Cover__c> mapCovers = new Map<String, Cover__c>();

        OrderItem item = new OrderItem(itemId__c = '7777', ItemAge__c = 2);
        List<Cover__c> listCovers = new List<Cover__c>();
        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000
            );
        listCovers.add(cover);
        Cover__c cover2 = new Cover__c(
            CoverId__c = '2',
            ParentCoverId__c = '1',
            Name = 'Sub-Robo',
            Description__c = 'SubCobertura por robo',
            SumInsured__c = 150
            );
        listCovers.add(cover2);

        String LegalEntity = Label.GeneralInsurance;
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Test.startTest();
        //covers no existen en Salesforce
        CoverUtil.addCovers(
            item,
            listCovers,
            subCoversToInsertQuote,
            mapCovers,
            updateCover,
            LegalEntity,
            recordOwner
            );
        System.assert (
            updateCover != null &&
            subCoversToInsertQuote != null,
            'Test_CoverUtil: Error al insertar covers y subcovers nuevas'
            );

        Test.stopTest();
    }

    @IsTest
    static void test_updateCover()
    {
        Map<String, Cover__c> subCoversToInsertQuote = new Map<String, Cover__c>();
        Map<String, Cover__c> updateCover = new Map<String, Cover__c>();
        Map<String, Cover__c> mapCovers = new Map<String, Cover__c>();

        OrderItem item = new OrderItem(itemId__c = '7777', ItemAge__c = 2);
        List<Cover__c> listCovers = new List<Cover__c>();
        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000,
            LegalEntity__c = Label.GeneralInsurance
            );
        listCovers.add(cover);

        cover.CoverId__c = item.itemId__c + '-' + cover.Name;
        insert cover;

        SET<String> keys = new Set<String>();
        keys.add(cover.CoverId__c);
        mapCovers = SystemUtil.CoversSelector(keys);

        String LegalEntity = Label.GeneralInsurance;
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Test.startTest();

        //covers  existen en Salesforce
        CoverUtil.addCovers(
            item,
            listCovers,
            subCoversToInsertQuote,
            mapCovers,
            updateCover,
            LegalEntity,
            recordOwner
            );
        System.assert (
            updateCover != null,
            'Test_CoverUtil: Error al insertar covers y subcovers existentes'
            );

        Test.stopTest();
    }
}