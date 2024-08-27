import { createElement } from "lwc";
import ZRMFiles from "c/ZRMFiles";
import getRelatedFilesByRecordId from "@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId";
// Import mock data to send through the wire adapter.
const mockFiles = require("./data/mockFileData.json");
// Create new Wire Data Service Mock Adapter
jest.mock(
  "@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-zrm-files", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  /**
   * Se comprueba que el componente muestra el listado de archivos cargado en el mock.
   * @author pitt.olvera@seidor.com
   * @date 27/08/2024
   */
  it("Renderizado de lista de archivos", async () => {
    // Arrange
    const element = createElement("c-zrm-files", {
      is: ZRMFiles
    });
    document.body.appendChild(element);

    // Simular la respuesta de la llamada a Apex
    getRelatedFilesByRecordId.emit(mockFiles);
    await Promise.resolve();

    // Assert
    const fileItems = element.shadowRoot.querySelector("div.slds-box");
    const childDiv = fileItems.querySelector("div.slds-grid");
    const childCol = childDiv.querySelector("div.slds-col");
    const fileIcon = childCol.querySelector("lightning-icon");
    expect(fileItems).not.toBeNull();
    expect(fileIcon.iconName).toBe("utility:document");
  });
});
