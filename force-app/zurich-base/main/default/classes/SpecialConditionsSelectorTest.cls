@IsTest
public with sharing class SpecialConditionsSelectorTest {
    
    @IsTest
    static void test()
    {
        new SpecialConditionsSelector().findAgreements('235', 'DT Madrid');
    }
}
