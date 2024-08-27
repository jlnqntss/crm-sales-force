import { createElement } from "lwc";
import WarningAndAgreementViewer from "c/warningAndAgreementViewer";
import getFields from "@salesforce/apex/WarningAndAgreementViewerController.getFields";
import getWarnings from "@salesforce/apex/WarningAndAgreementViewerController.getWarnings";
// Mock ddata
const mockGWarnings = require("./data/WarningAndAgreementViewerData.json");
const mockGWarningFields = require("./data/WarningFields.json");
// Mock getAccountList Apex wire adapter
jest.mock(
  "@salesforce/apex/WarningAndAgreementViewerController.getFields",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);
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

  /**
   * Renderizado de los registros en la tabla de datos, comprueba que se cargan los datos del mock.
   * @author pitt.olvera@seidor.com
   * @date 14/08/2024
   */
  it("Renderizado de los botones de Warning", async () => {
    const element = createElement("c-warning-and-agreement-viewer", {
      is: WarningAndAgreementViewer
    });
    document.body.appendChild(element);

    // Emit data from @wire Apex Controller
    getFields.emit(mockGWarningFields);
    getWarnings.emit(mockGWarnings);
    await Promise.resolve();

    // Select elements for validation
    const warningButtons =
      element.shadowRoot.querySelectorAll("c-custom-datatable");
    expect(warningButtons).not.toBeNull();
  });
});
