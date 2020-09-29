public without sharing class PreferenceCentreProcessController {
  /**
   * @Description: Metodo que actualiza el contacto
   *
   * @Author: iortega 2020-06-04
   */
  public static void doUpdate(Contact contact) {
    try {
      update contact;
    } catch (Exception e) {
      ErrorLogUtil.commitError(
        e,
        'PreferenceCentreProcessController',
        contact.Id
      );
    }
  }

  /**
   * @Description: Metodo que inserta un miebro de campaña
   *
   * @Author: iortega 2020-06-04
   */
  public static void doInsert(List<CampaignMember> memberToInsertList) {
    try {
      insert memberToInsertList;
    } catch (Exception e) {
      ErrorLogUtil.commitError(
        e,
        'PreferenceCentreProcessController',
        memberToInsertList[0].ContactId
      );
    }
  }

  /**
   * @Description: Metodo que elimina un miebro de campaña
   *
   * @Author: iortega 2020-06-04
   */
  public static void doDelete(List<CampaignMember> membersToDeleteList) {
    try {
      delete membersToDeleteList;
    } catch (Exception e) {
      ErrorLogUtil.commitError(
        e,
        'PreferenceCentreProcessController',
        membersToDeleteList[0].ContactId
      );
    }
  }
}
