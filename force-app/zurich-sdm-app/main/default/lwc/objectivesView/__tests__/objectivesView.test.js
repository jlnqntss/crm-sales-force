import { createElement } from "lwc";
import ObjectivesView from "c/objectivesView";

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

    // Assert
    expect(element.shadowRoot.querySelector("lightning-card").title).toBe(
      "Objectives"
    );
  });
});
