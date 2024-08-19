import { createElement } from "lwc";
import ZRMFiles from "c/ZRMFiles";
import { registerTestWireAdapter } from "@salesforce/wire-service-jest-util";
import getRelatedFilesByRecordId from "@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId";

// Registrar adaptador de prueba para getRelatedFilesByRecordId
const mockGetRelatedFilesByRecordId = registerTestWireAdapter(
  getRelatedFilesByRecordId
);

describe("c-zrm-files", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("TODO: test case generated by CLI command, please fill in test logic", () => {
    // Arrange
    const element = createElement("c-zrm-files", {
      is: ZRMFiles
    });

    // Act: Simular los datos que el componente debería recibir de @wire
    const mockFiles = [
      {
        fileId: "001",
        fileTitle: "Archivo1.pdf",
        fileDownloadUrl:
          "/services/data/v50.0/sobjects/ContentVersion/0681U00000Iu6tQQAR",
        fileIcon: "utility:document",
        deleteEnabled: true
      },
      {
        fileId: "002",
        fileTitle: "Archivo2.pdf",
        fileDownloadUrl:
          "/services/data/v50.0/sobjects/ContentVersion/0681U00000Iu6tQQAA",
        fileIcon: "utility:document",
        deleteEnabled: false
      }
    ];

    // Simular la respuesta de la llamada a Apex
    mockGetRelatedFilesByRecordId.emit({ data: mockFiles });

    // Acts
    document.body.appendChild(element);

    // Assert
    const fileItems = element.shadowRoot.querySelectorAll(".slds-box");
    expect(fileItems.length).toBe(2); // Verificar que se renderizan 2 archivos

    // Puedes agregar más aserciones para verificar el contenido de los archivos
    expect(fileItems[0].textContent).toContain("Archivo1.pdf");
    expect(fileItems[1].textContent).toContain("Archivo2.pdf");
  });
});
