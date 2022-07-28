import { createElement } from "lwc";
import ObjectivesView from "c/objectivesView";
import getObjetives from "@salesforce/apex/ObjectivesViewController.getObjetives";

// Realistic data with a list of contacts
const mockGetContactList = require("./data/getObjetives.json");

// Mock getContactList Apex wire adapter
jest.mock(
  "@salesforce/apex/ObjectivesViewController.getObjetives",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-objectives-view", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("Se comprueba el título de la aplicación.", () => {
    // Arrange
    const element = createElement("c-objectives-view", {
      is: ObjectivesView
    });
    // Act
    document.body.appendChild(element);

    // Emit data from @wire
    getObjetives.emit(mockGetContactList);

    // Wait for any asynchronous DOM updates
    //await flushPromises();

    // Assert
    expect(element.shadowRoot.querySelector("lightning-card").title).toBe(
      "c.SDM_Objetivos_Title"
    );
  });
});
