import { createElement } from "lwc";
import WarningAndAgreementViewer from "c/warningAndAgreementViewer";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getWarnings from "@salesforce/apex/WarningAndAgreementViewerController.getWarnings";
// Mock ddata
const mockGWarnings = require("./data/WarningAndAgreementViewerData.json");
// Mock getAccountList Apex wire adapter
jest.mock(
  "@salesforce/apex/WarningAndAgreementViewerController.getWarnings",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-warning-and-agreement-viewer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  describe("getWarnings @wire data", () => {
    /**
     * Renderuzado de los registros en la tablade datos
     * @author pitt.olvera@seidor.com
     * @date 14/08/2024
     */
    it("renders one record", () => {
      getWarnings.emit(mockGWarnings);
      const element = createElement("c-warning-and-agreement-viewer", {
        is: WarningAndAgreementViewer
      });
      document.body.appendChild(element);

      // Emit data from @wire

      return Promise.resolve().then(() => {
        // Select elements for validation
        const warningElements = element.shadowRoot.querySelectorAll("p");
        expect(warningElements.length).toBe(mockGWarnings.length);
        expect(warningElements[0].textContent).toBe(mockGWarnings[0].Name);
      });
    });

    /**
     *
     * @author pitt.olvera@seidor.com
     * @date 14/08/2024
     */
    it("checks object and sets warning to false for other objects", () => {
      const element = createElement("c-warning-and-agreement-viewer", {
        is: WarningAndAgreementViewer
      });
      element.salesforceObject = "SomeOtherObject__c";

      document.body.appendChild(element);

      return Promise.resolve().then(() => {
        expect(element.warning).toBe(false);
      });
    });

    /**
     *
     * @author pitt.olvera@seidor.com
     * @date 14/08/2024
     */
    it("displays toast message on disableAgreements with no selected records", async () => {
      const element = createElement("c-warning-and-agreement-viewer", {
        is: WarningAndAgreementViewer
      });
      document.body.appendChild(element);

      const showToastEventSpy = jest.spyOn(
        ShowToastEvent.prototype,
        "constructor"
      );

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

    /**
     *
     * @author pitt.olvera@seidor.com
     * @date 14/08/2024
     */
    it("calls Apex methods and processes records correctly on connectedCallback", async () => {
      const element = createElement("c-warning-and-agreement-viewer", {
        is: WarningAndAgreementViewer
      });

      document.body.appendChild(element);

      return Promise.resolve().then(async () => {
        await element.connectedCallback();
        expect(element.allRecords.length).toBe(2);
        expect(element.recordsToShow.length).toBe(1);
        expect(element.showedSize).toBe(1);
      });
    });
  });
});
