
global class GenesysCloudRegHandler implements Auth.RegistrationHandler{
global boolean canCreateUser(Auth.UserData data) {
  return false;
}

global User createUser(Id portalId, Auth.UserData data){
    
  if(!canCreateUser(data)) {
    //Returning null or throwing an exception fails the SSO flow
    return null;
  }
  if(data.attributeMap.containsKey('sfdc_networkid')) {
    //We have a community id, so create a user with community access
    Account a = [SELECT Id FROM account WHERE name='Acme'];
    Contact c = new Contact();
    c.accountId = a.Id;
    c.email = data.email;
    c.firstName = data.firstName;
    c.lastName = data.lastName;
    insert(c);

    //possibly ensure there are enough org licenses to create a user. Must be 80 characters or less.
    User u = new User();
    Profile p = [SELECT Id FROM profile WHERE name='Customer Portal User'];
    u.username = data.username + '@acmecorp.com';
    u.email = data.email;
    u.lastName = data.lastName;
    u.firstName = data.firstName;
    String alias = data.username;
    //Alias must be 8 characters or less
    if(alias.length() > 8) {
      alias = alias.substring(0, 8);
    }
    u.alias = alias;
    u.languagelocalekey = UserInfo.getLocale();
    u.localesidkey = UserInfo.getLocale();
    u.emailEncodingKey = 'UTF-8';
    u.timeZoneSidKey = 'America/Los_Angeles';
    u.profileId = p.Id;
    u.contactId = c.Id;
    return u;
  } else {
    //This is not a community, so create a regular standard user
    User u = new User();
    Profile p = [SELECT Id FROM profile WHERE name='Standard User'];
    //possibly ensure there are enough org licenses to create a user. Must be 80 characters
    //or less.
    u.username = data.username + '@myorg.com';
    u.email = data.email;
    u.lastName = data.lastName;
    u.firstName = data.firstName;
    String alias = data.username;
    //Alias must be 8 characters or less
    if(alias.length() > 8) {
      alias = alias.substring(0, 8);
    }
    u.alias = alias;
    u.languagelocalekey = UserInfo.getLocale();
    u.localesidkey = UserInfo.getLocale();
    u.emailEncodingKey = 'UTF-8';
    u.timeZoneSidKey = 'America/Los_Angeles';
    u.profileId = p.Id;
    return u;
  }
}

global void updateUser(Id userId, Id portalId, Auth.UserData data){
  User u = new User(id=userId);
  u.email = data.email;
  u.lastName = data.lastName;
  u.firstName = data.firstName;
  update(u);
}
}