import { createElement } from "lwc";
import WarningAndAgreementViewer from "c/warningAndAgreementViewer";
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import getFields from "@salesforce/apex/WarningAndAgreementViewerController.getFields";
import getWarnings from "@salesforce/apex/WarningAndAgreementViewerController.getWarnings";
import getAgreements from "@salesforce/apex/WarningAndAgreementViewerController.getAgreements";
import getAccountById from "@salesforce/apex/WarningAndAgreementViewerController.getAccountById";
import cancelAgreements from "@salesforce/apex/WarningAndAgreementViewerController.cancelAgreements";
import cancelWarnings from "@salesforce/apex/WarningAndAgreementViewerController.cancelWarnings";
import checkPermission from "@salesforce/apex/WarningAndAgreementViewerController.checkPermission";
import createRelatedAccount from "@salesforce/apex/WarningAndAgreementViewerController.createRelatedAccount";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const getFieldsAdapter = registerApexTestWireAdapter(getFields);
const getWarningsAdapter = registerApexTestWireAdapter(getWarnings);
const getAgreementsAdapter = registerApexTestWireAdapter(getAgreements);
const getAccountByIdAdapter = registerApexTestWireAdapter(getAccountById);
const checkPermissionAdapter = registerApexTestWireAdapter(checkPermission);

describe("c-warning-and-agreement-viewer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders component with default values", () => {
    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });

    document.body.appendChild(element);

    const title = element.shadowRoot.querySelector('h1');
    expect(title).toBeDefined();
  });

  it("checks object and sets warning to true for CustomerWarning__c", () => {
    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });
    element.salesforceObject = 'CustomerWarning__c';

    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      expect(element.warning).toBe(true);
    });
  });

  it("checks object and sets warning to false for other objects", () => {

    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });
    element.salesforceObject = 'SomeOtherObject__c';

    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      expect(element.warning).toBe(false);
    });
  });

  it("displays toast message on disableAgreements with no selected records", async () => {

    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });
    document.body.appendChild(element);

    const showToastEventSpy = jest.spyOn(ShowToastEvent.prototype, 'constructor');
    
    element.template.querySelector = jest.fn().mockReturnValue({
      getSelectedRows: () => []
    });

    await element.disableAgreements();

    expect(showToastEventSpy).toHaveBeenCalledWith({
      title: "Acuerdos No Desactivados",
      message: "No hay elementos seleccionados",
      variant: "error"
    });
  });

  it("calls Apex methods and processes records correctly on connectedCallback", async () => {
    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });

    checkPermission.mockResolvedValue(true);
    getAccountById.mockResolvedValue({ Id: '001', Name: 'Test Account' });
    getWarnings.mockResolvedValue([{ Id: '001', IsActive__c: true }, { Id: '002', IsActive__c: false }]);

    document.body.appendChild(element);

    return Promise.resolve().then(async () => {
      await element.connectedCallback();
      expect(element.allRecords.length).toBe(2);
      expect(element.recordsToShow.length).toBe(1);
      expect(element.showedSize).toBe(1);
    });
  });
});
