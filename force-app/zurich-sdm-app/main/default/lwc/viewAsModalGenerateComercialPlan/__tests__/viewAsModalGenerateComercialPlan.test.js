import { createElement } from "lwc";
import ViewAsModalGenerateComercialPlan from "c/viewAsModalGenerateComercialPlan";
import getSDMUsersList from "@salesforce/apex/ViewAsModalGeneratePlanController.getSDMUsersList";
import SDM_PlanAnual_ViewAsModalSubmit from "@salesforce/label/c.SDM_PlanAnual_ViewAsModalSubmit"; // Aquí importas el label

// Import mock data to send through the wire adapter.
const getSDMUsersListData = require("./data/mockUserData.json");
// Create new Wire Data Service Mock Adapter
jest.mock(
  "@salesforce/apex/ViewAsModalGeneratePlanController.getSDMUsersList",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-view-as-modal-generate-comercial-plan", () => {
  afterEach(() => {
    // Clean up the DOM after each test
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  /**
   * Verifica que el selectedUserId se actualice correctamente cuando el usuario selecciona una opción en el combobox.
   * @author pitt.olvera@seidor.com
   * @date 26/08/2024
   */
  it("Renderizado de opciones en el Combobox", async () => {
    const element = createElement("c-view-as-modal-generate-comercial-plan", {
      is: ViewAsModalGenerateComercialPlan
    });
    document.body.appendChild(element);

    // Emit data from the wire adapter
    getSDMUsersList.emit(getSDMUsersListData);

    await Promise.resolve();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox).not.toBeNull();
    expect(combobox.options.length).toBe(2);
    expect(combobox.options[0].label).toBe("User 1");
    expect(combobox.options[0].value).toBe("001");
    expect(combobox.options[1].label).toBe("User 2");
    expect(combobox.options[1].value).toBe("002");
  });

  /**
   * Verifica que el selectedUserId se actualice correctamente cuando el usuario selecciona una opción en el combobox.
   * @author pitt.olvera@seidor.com
   * @date 26/08/2024
   */
  it("Evento de cambio en el Combobox", async () => {
    const element = createElement("c-view-as-modal-generate-comercial-plan", {
      is: ViewAsModalGenerateComercialPlan
    });
    document.body.appendChild(element);

    // Emit data from the wire adapter
    getSDMUsersList.emit(getSDMUsersListData);

    await Promise.resolve();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "002" } })
    );

    await Promise.resolve();

    expect(combobox.value).toBe("002");
  });

  /**
   * Prueba que el filtro de usuarios funcione correctamente y actualice la lista filtrada de opciones
   * @author pitt.olvera@seidor.com
   * @date 26/08/2024
   */
  it("Filtrado de usuarios basado en el input", async () => {
    const element = createElement("c-view-as-modal-generate-comercial-plan", {
      is: ViewAsModalGenerateComercialPlan
    });
    document.body.appendChild(element);

    // Emit data from the wire adapter
    getSDMUsersList.emit(getSDMUsersListData);

    await Promise.resolve();
    const inputElement = element.shadowRoot.querySelector("lightning-input");
    inputElement.dispatchEvent(
      new CustomEvent("change", { detail: { value: "User 1" } })
    );

    await Promise.resolve();
    const combobox = element.shadowRoot.querySelector("lightning-combobox");

    expect(combobox.options.length).toBe(1);
    expect(combobox.options[0].label).toBe("User 1");
  });

  /**
   * Asegura que el botón de Submit se deshabilite cuando no haya coincidencias en las opciones filtradas.
   * @author pitt.olvera@seidor.com
   * @date 26/08/2024
   */
  it("Deshabilitar el botón de Submit si no hay coincidencias", async () => {
    const element = createElement("c-view-as-modal-generate-comercial-plan", {
      is: ViewAsModalGenerateComercialPlan
    });
    document.body.appendChild(element);

    // Emit data from the wire adapter
    getSDMUsersList.emit(getSDMUsersListData);

    await Promise.resolve();
    const inputElement = element.shadowRoot.querySelector("lightning-input");
    inputElement.value = "Nonexistent User";
    inputElement.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Not Existing User" } })
    );

    await Promise.resolve();

    // Selecciona el footer donde está el botón
    const footer = element.shadowRoot.querySelector("lightning-modal-footer");
    const submitButton = footer.querySelector("lightning-button");

    expect(submitButton.label).toBe(SDM_PlanAnual_ViewAsModalSubmit);
    expect(submitButton.disabled).toBe(true);
  });
});
