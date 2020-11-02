/**
 * Clases de test para TransformerSelector
 **
 * @author xsobera
 * @date 30/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class TransformerSelectorTest
{
    @IsTest
    static void test_selectMetadataByOrigin()
    {
        List<Transformer__mdt> settings;

        settings = TransformerSelector.selectMetadataByOrigin('NO EXISTE');
        System.assertEquals(0, settings.size(), '[0] No se ha devuelto una lista vacía');
        settings = TransformerSelector.selectMetadataByOrigin(null);
        System.assertEquals(0, settings.size(), '[1] No se ha devuelto una lista vacía');
        settings = TransformerSelector.selectMetadataByOrigin(Transformer.ORIGIN_NAME_INFO);
        System.assertEquals(true, settings.size() > 0, '[2] No se han devuelto metadatos');
    }
}
