import { createElement } from "lwc";
import ControlIntermediaryMensualPlanNotifications from "c/controlIntermediaryMensualPlanNotifications";

describe("c-control-intermediary-mensual-plan-notifications", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("TODO: test case generated by CLI command, please fill in test logic", () => {
    // Arrange
    const element = createElement(
      "c-control-intermediary-mensual-plan-notifications",
      {
        is: ControlIntermediaryMensualPlanNotifications
      }
    );

    // Act
    document.body.appendChild(element);

    expect(1).toBe(1);
  });
});
