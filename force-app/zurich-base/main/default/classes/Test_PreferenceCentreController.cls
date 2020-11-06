/**
 * @description       :
 * @author            : Enara Etxaniz
 * @group             :
 * @last modified on  : 09-16-2020
 * @last modified by  : Enara Etxaniz
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   09-16-2020   Enara Etxaniz   Initial Version
 **/
@isTest
public class Test_PreferenceCentreController {
  //#Region testSetup
  @testSetup
  static void makeData() {
    //Account
    Account account = new Account(Name = 'Account1', CustomerNum__c = '1234');
    insert account;

    //Contact GI
    Contact customerGI = new Contact(
      Email = 'test@test.com',
      Birthdate = Date.valueOf('1990-01-01'),
      LastName = 'ContactGI',
      AccountId = account.Id,
      CustomerNum__c = 'GI-1234',
      LegalEntity__c = Label.GeneralInsurance,
      RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI)
    );
    insert customerGI;

    //Contact Life
    Contact customerLife = new Contact(
      Email = 'test@test.com',
      Birthdate = Date.valueOf('1990-01-01'),
      LastName = 'ContactLife',
      AccountId = account.Id,
      CustomerNum__c = 'Life-1234',
      LegalEntity__c = Label.LifeInsurance,
      RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerLife)
    );
    insert customerLife;

    //Campaign contacto GI no suscrito
    Campaign campaignGI = new Campaign(
      Name = 'CampaignGI',
      LegalEntity__c = Label.GeneralInsurance,
      Type = 'Suscripcion',
      IsActive = true
    );
    insert campaignGI;

    //Campaign contacto Life no suscrito
    Campaign campaignLife = new Campaign(
      Name = 'CampaignLife',
      LegalEntity__c = Label.LifeInsurance,
      Type = 'Suscripcion',
      IsActive = true
    );
    insert campaignLife;

    //Campaign contacto GI suscrito
    Campaign campaignContGI = new Campaign(
      Name = 'campaignContGI',
      LegalEntity__c = Label.GeneralInsurance,
      Type = 'Suscripcion',
      IsActive = true
    );
    insert campaignContGI;

    CampaignMember campaignMemberGI = new CampaignMember(
      ContactId = customerGI.Id,
      CampaignId = campaignContGI.Id
    );
    insert campaignMemberGI;

    //Campaign contacto Life suscrito
    Campaign campaignContLife = new Campaign(
      Name = 'campaignContLife',
      LegalEntity__c = Label.LifeInsurance,
      Type = 'Suscripcion',
      IsActive = true
    );
    insert campaignContLife;

    CampaignMember campaignMemberLife = new CampaignMember(
      ContactId = customerLife.Id,
      CampaignId = campaignContLife.Id
    );
    insert campaignMemberLife;

    //Campaing to test translation
    Campaign campaignTranslate = new Campaign(
      Name = 'Productos_y_servicios',
      LegalEntity__c = Label.GeneralInsurance,
      Type = 'Suscripcion',
      IsActive = true
    );
    insert campaignTranslate;

    CampaignMember campaignMemberTrans = new CampaignMember(
      ContactId= customerGI.Id,
      CampaignId = campaignTranslate.Id
    );
    insert campaignMemberTrans;
  }
  //#endregion

  //#Region test_processRequest

  @isTest
  static void processRequest_testGICampaignSuscription() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.GeneralInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignGI = [SELECT Id FROM Campaign WHERE Name = 'CampaignGI'];

    Campaign campaignContGI = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContGI'
    ];

    //Test en el que se suscribe en la que no está suscrito // HasOptedOutOfEmail sin cambios
    PreferenceCentreController.CampaignStatus campaignStatusGI = new PreferenceCentreController.CampaignStatus(
      campaignGI.Id,
      'CampaignGI',
      '',
      '',
      true
    );
    PreferenceCentreController.CampaignStatus campaignStatusContGI = new PreferenceCentreController.CampaignStatus(
      campaignContGI.Id,
      'campaignContGI',
      '',
      '',
      true
    );
    campaigns.add(campaignStatusGI);
    campaigns.add(campaignStatusContGI);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, false, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> membercampaignLife = [
      SELECT ContactId
      FROM CampaignMember
      WHERE CampaignId = :campaignGI.Id AND ContactId = :Id
    ];
    List<CampaignMember> memberCampaigns = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];

    System.assertEquals(1, membercampaignLife.size());
    System.assertEquals(3, memberCampaigns.size());
  }

  @isTest
  static void processRequest_testLifeCampaignSuscription() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'CampaignLife'
    ];

    Campaign campaignContLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContLife'
    ];

    //Test en el que se suscribe en la que no está suscrito // HasOptedOutOfEmail sin cambios
    PreferenceCentreController.CampaignStatus campaignStatusLife = new PreferenceCentreController.CampaignStatus(
      campaignLife.Id,
      'CampaignLife',
      '',
      '',
      true
    );
    PreferenceCentreController.CampaignStatus campaignStatusContLife = new PreferenceCentreController.CampaignStatus(
      campaignContLife.Id,
      'campaignContLife',
      '',
      '',
      true
    );
    campaigns.add(campaignStatusLife);
    campaigns.add(campaignStatusContLife);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, false, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> membercampaignLife = [
      SELECT ContactId
      FROM CampaignMember
      WHERE CampaignId = :campaignLife.Id AND ContactId = :Id
    ];

    List<CampaignMember> memberCampaigns = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];

    System.assertEquals(1, membercampaignLife.size());
    System.assertEquals(2, memberCampaigns.size());
  }

  @isTest
  static void processRequest_testGICampaignDesuscription() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.GeneralInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignGI = [SELECT Id FROM Campaign WHERE Name = 'CampaignGI'];

    Campaign campaignContGI = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContGI'
    ];

    //Test en el que se desuscribe en la que está suscrito // HasOptedOutOfEmail sin cambios
    PreferenceCentreController.CampaignStatus campaignStatusGI = new PreferenceCentreController.CampaignStatus(
      campaignGI.Id,
      'campaignGI',
      '',
      '',
      false
    );
    PreferenceCentreController.CampaignStatus campaignStatusContGI = new PreferenceCentreController.CampaignStatus(
      campaignContGI.Id,
      'campaignContGI',
      '',
      '',
      false
    );
    campaigns.add(campaignStatusGI);
    campaigns.add(campaignStatusContGI);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, false, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> member = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];
    // Only campaign translate left
    System.assertEquals(1, member.size());
  }

  @isTest
  static void processRequest_testLifeCampaignDesuscription() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'CampaignLife'
    ];

    Campaign campaignContLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContLife'
    ];

    //Test en el que se desuscribe en la que está suscrito // HasOptedOutOfEmail sin cambios
    PreferenceCentreController.CampaignStatus campaignStatusLife = new PreferenceCentreController.CampaignStatus(
      campaignLife.Id,
      'CampaignLife',
      '',
      '',
      false
    );
    PreferenceCentreController.CampaignStatus campaignStatusContLife = new PreferenceCentreController.CampaignStatus(
      campaignContLife.Id,
      'campaignContLife',
      '',
      '',
      false
    );
    campaigns.add(campaignStatusLife);
    campaigns.add(campaignStatusContLife);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, false, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> member = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];
    System.assertEquals(0, member.size());
  }

  @isTest
  static void processRequest_testGIHasOptedOutOfEmail() {
    //When
    String hashedId;
    String Id;
    Boolean hasOptedOutOfEmail;
    List<Contact> c = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail
      FROM Contact
      WHERE LegalEntity__c = :Label.GeneralInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
      hasOptedOutOfEmail = c[0].HasOptedOutOfEmail;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignGI = [SELECT Id FROM Campaign WHERE Name = 'CampaignGI'];

    Campaign campaignContGI = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContGI'
    ];

    //Test en el que se deja como están las campañas // HasOptedOutOfEmail a true, el contacto se da de baja
    PreferenceCentreController.CampaignStatus campaignStatusGI = new PreferenceCentreController.CampaignStatus(
      campaignGI.Id,
      'campaignGI',
      '',
      '',
      false
    );
    PreferenceCentreController.CampaignStatus campaignStatusContGI = new PreferenceCentreController.CampaignStatus(
      campaignContGI.Id,
      'campaignContGI',
      '',
      '',
      true
    );
    campaigns.add(campaignStatusGI);
    campaigns.add(campaignStatusContGI);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, true, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> membercampaignGI = [
      SELECT ContactId
      FROM CampaignMember
      WHERE CampaignId = :campaignGI.Id AND ContactId = :Id
    ];
    List<CampaignMember> memberCampaigns = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];
    Contact contacto = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail
      FROM Contact
      WHERE LegalEntity__c = :Label.GeneralInsurance
    ];

    System.assertEquals(0, membercampaignGI.size());
    // Campaign LI and translate left
    System.assertEquals(2, memberCampaigns.size());
    System.assertEquals(true, contacto.HasOptedOutOfEmail);
  }

  @isTest
  static void processRequest_testLifeHasOptedOutOfEmail() {
    //When
    String hashedId;
    String Id;
    Boolean hasOptedOutOfEmail;
    List<Contact> c = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
      hasOptedOutOfEmail = c[0].HasOptedOutOfEmail;
    }

    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();

    Campaign campaignLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'CampaignLife'
    ];

    Campaign campaignContLife = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'campaignContLife'
    ];

    //Test en el que se deja como están las campañas // HasOptedOutOfEmail a true, el contacto se da de baja
    PreferenceCentreController.CampaignStatus campaignStatusLife = new PreferenceCentreController.CampaignStatus(
      campaignLife.Id,
      'CampaignLife',
      '',
      '',
      false
    );
    PreferenceCentreController.CampaignStatus campaignStatusContLife = new PreferenceCentreController.CampaignStatus(
      campaignContLife.Id,
      'campaignContLife',
      '',
      '',
      true
    );
    campaigns.add(campaignStatusLife);
    campaigns.add(campaignStatusContLife);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, true, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> membercampaignLife = [
      SELECT ContactId
      FROM CampaignMember
      WHERE CampaignId = :campaignLife.Id AND ContactId = :Id
    ];
    List<CampaignMember> memberCampaigns = [
      SELECT ContactId
      FROM CampaignMember
      WHERE ContactId = :Id
    ];
    Contact contacto = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    System.assertEquals(0, membercampaignLife.size());
    System.assertEquals(1, memberCampaigns.size());
    System.assertEquals(true, contacto.HasOptedOutOfEmail);
  }

  @isTest
  static void getContactData_testgetContactDataNull() {
    //When
    String hashedId = 'testing';

    //Test
    Test.startTest();
    PreferenceCentreController.getContactData(''); // for coverage
    Contact contacto = PreferenceCentreController.getContactData(hashedId);
    Test.stopTest();

    //Then
    System.assertEquals(null, contacto.LastName);
  }

  @isTest
  static void getContactData_testgetContactDataOK() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    //Test
    Test.startTest();
    Contact contacto = PreferenceCentreController.getContactData(hashedId);
    Test.stopTest();

    //Then
    System.assertEquals(Id, contacto.Id);
  }

  @isTest
  static void getAllCampaigns_testgetAllLifeCampaignsOK() {
    //When
    String hashedId;
    String Id;
    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.LifeInsurance
    ];

    if (c != null & c.size() > 0) {
      hashedId = c[0].HashedId__c;
      Id = c[0].Id;
    }

    //Test
    Test.startTest();
    PreferenceCentreController.getAllCampaigns( '', null ); // for coverage
    List<PreferenceCentreController.CampaignStatus> campaigns = PreferenceCentreController.getAllCampaigns(
      hashedId,
      null
    );
    Test.stopTest();

    //Then
    System.assertEquals(2, campaigns.size());
  }

  @isTest
  static void getAllCampaigns_testgetAllGICampaignsOK() {
    //When
    String hashedId;

    List<Contact> c = [
      SELECT Id, Name, HashedId__c
      FROM Contact
      WHERE LegalEntity__c = :Label.GeneralInsurance
    ];
    System.assert(true, !c.isEmpty());

    hashedId = c[0].HashedId__c;

    //Test
    Test.startTest();
    List<PreferenceCentreController.CampaignStatus> campaigns = PreferenceCentreController.getAllCampaigns(
      hashedId,
      null
    );
    Test.stopTest();

    //Then
    System.assertEquals(3, campaigns.size());
  }

  /**
   * Test: Partner 
   * 
   * @author nts (agonzalezisasi)
   * @date 05/11/2020
   */
  @isTest
  static void processRequest_testGIHasOptedOutOfEmail_Partner() {
    //When
    Account account = new Account(Name = 'Account2', CustomerNum__c = '5678');
    insert account;

    //Contact GI
    Contact customerPartner = new Contact(
      Email = 'partner@test.com',
      Birthdate = Date.valueOf('1990-01-01'),
      LastName = 'partnerGI',
      AccountId = account.Id,
      CustomerNum__c = 'Orange-GI-5678',
      LegalEntity__c = Label.GeneralInsurance,
      RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
      Partner__c = 'Orange Seguros'
    );
    insert customerPartner;
    
    List<Contact> c = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail FROM Contact WHERE Id = :customerPartner.Id
    ];
    System.assertEquals(1, c.size());

    String hashedId = c[0].HashedId__c;
    String Id = c[0].Id;
    Boolean hasOptedOutOfEmail = c[0].HasOptedOutOfEmail;

    Campaign campaignGI = [SELECT Id FROM Campaign WHERE Name = 'CampaignGI'];
    Campaign campaignContGI = [SELECT Id FROM Campaign WHERE Name = 'campaignContGI'];

    CampaignMember campaignMemberGI = new CampaignMember(
      ContactId = customerPartner.Id,
      CampaignId = campaignGI.Id
    );
    insert campaignMemberGI;
    CampaignMember campaignMemberContGI = new CampaignMember(
      ContactId = customerPartner.Id,
      CampaignId = campaignContGI.Id
    );
    insert campaignMemberContGI;

    //Test en el que se deja como están las campañas // HasOptedOutOfEmail a true, el contacto se da de baja
    PreferenceCentreController.CampaignStatus campaignStatusGI = new PreferenceCentreController.CampaignStatus(
      campaignGI.Id, 'campaignGI', '', '', false 
    );
    PreferenceCentreController.CampaignStatus campaignStatusContGI = new PreferenceCentreController.CampaignStatus(
      campaignContGI.Id, 'campaignContGI', '', '', true
    );
    List<PreferenceCentreController.CampaignStatus> campaigns = new List<PreferenceCentreController.CampaignStatus>();
    campaigns.add(campaignStatusGI);
    campaigns.add(campaignStatusContGI);

    //Test
    Test.startTest();
    PreferenceCentreController.processRequest(hashedId, true, campaigns);
    Test.stopTest();

    //Then
    List<CampaignMember> membercampaignGI = [
      SELECT ContactId FROM CampaignMember WHERE CampaignId = :campaignGI.Id AND ContactId = :Id
    ];
    List<CampaignMember> memberCampaigns = [
      SELECT ContactId FROM CampaignMember WHERE ContactId = :Id
    ];
    Contact contacto = [
      SELECT Id, HashedId__c, HasOptedOutOfEmail FROM Contact WHERE Id = :Id
    ];

    System.assertEquals(0, membercampaignGI.size());
    System.assertEquals(1, memberCampaigns.size());
    System.assertEquals(true, contacto.HasOptedOutOfEmail);
  }

  /**
   * Test: switching to different languages for a campaign
   * 
   * @author nts (agonzalezisasi)
   * @date 04/11/2020
   */
  @isTest
  static void test_switchLanguage()
  {
     //When
    String hashedId;

    List<Contact> c = [SELECT Id, HashedId__c FROM Contact WHERE LegalEntity__c = :Label.GeneralInsurance ];
    System.assertEquals(true, !c.isEmpty());

    hashedId = c[0].HashedId__c;

    //Test
    Test.startTest();
    PreferenceCentreController.getAllCampaigns( hashedId, 'fr' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'en_US' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'de' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'it' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'ja' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'es_MX' );
    PreferenceCentreController.getAllCampaigns( hashedId, 'pt_BR' );
    PreferenceCentreController.getAllCampaigns( hashedId, null );
    Test.stopTest();
  }
}