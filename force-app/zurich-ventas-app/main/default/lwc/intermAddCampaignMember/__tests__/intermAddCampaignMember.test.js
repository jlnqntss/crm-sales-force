import { createElement } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import IntermAddCampaignMember from "c/intermAddCampaignMember";
import getContacts from "@salesforce/apex/IntermAddCampaignMemberController.getContacts";

// Definir el mock de datos directamente en el código
const mockContactsData = require("./data/getContacts.json");
const mockCampaingsData = require("./data/getCampaings.json");

// Mockear el adaptador de Apex
jest.mock(
  "@salesforce/apex/IntermAddCampaignMemberController.getContacts",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);
jest.mock(
  "lightning/uiRecordApi",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-interm-add-campaign-member", () => {
  afterEach(() => {
    // Restablecer el DOM después de cada prueba
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("muestra los datos de cuentas en la tabla", async () => {
    // Crear el elemento
    const element = createElement("c-interm-add-campaign-member", {
      is: IntermAddCampaignMember
    });
    console.log("element: " + element.outerHTML);
    // Añadir el componente al DOM
    document.body.appendChild(element);
    console.log("element2: " + element.outerHTML);

    // Emitir datos del mock en el adaptador de wire
    getContacts.emit(mockContactsData);

    // Esperar a que se resuelvan las promesas y actualicen el DOM
    await Promise.resolve();

    // Seleccionar la tabla y verificar que contiene los datos
    const showModalButton =
      element.shadowRoot.querySelector("lightning-button");
    showModalButton.dispatchEvent(new CustomEvent("click", { detail: {} }));

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data).toEqual(mockContactsData);

    // Verificar que se muestra el número correcto de filas
    expect(datatable.data.length).toBe(mockContactsData.length);
  });

  // Función para esperar a que las promesas asíncronas se resuelvan
  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }
});
